extends RefCounted

var reputation := {
    "crown":0.0,"guard":0.0,"temple":0.0,"occult":0.0,"underworld":0.0,"merchants":0.0
}
var membership:Array=[]
var titles:Dictionary={}
var events:Array=[]

func change(faction:String,amount:float,day:int,hour:float,reason:String=""):
    if not reputation.has(faction):return
    reputation[faction]=clampf(float(reputation[faction])+amount,-100.0,100.0)
    _update_rank(faction,day,hour)
    if reason!="":events.append({"day":day,"hour":hour,"faction":faction,"amount":amount,"text":reason})

func _update_rank(faction:String,day:int,hour:float):
    var r=float(reputation[faction]);var new_title=""
    if r>=75:new_title=_rank_name(faction,3)
    elif r>=45:new_title=_rank_name(faction,2)
    elif r>=20:new_title=_rank_name(faction,1)
    if new_title!="" and str(titles.get(faction,""))!=new_title:
        titles[faction]=new_title
        if not membership.has(faction):membership.append(faction)
        events.append({"day":day,"hour":hour,"faction":faction,"amount":0,"text":"Новый статус: %s."%new_title})
    if r<-40 and membership.has(faction):
        membership.erase(faction);titles.erase(faction)
        events.append({"day":day,"hour":hour,"faction":faction,"amount":0,"text":"Фракция отвернулась от тебя."})

func _rank_name(faction:String,tier:int)->String:
    var ranks={
        "crown":["человек двора","королевский доверенный","правая рука Короны"],
        "guard":["помощник стражи","доверенный стражи","защитник острова"],
        "temple":["прихожанин","служитель Рассвета","голос храма"],
        "occult":["посвящённый","адепт Пепельной Луны","хранитель тайны"],
        "underworld":["связной","человек подполья","теневой хозяин"],
        "merchants":["поставщик","уважаемый торговец","магнат острова"]
    }
    return ranks.get(faction,["союзник","доверенный","лидер"])[clampi(tier-1,0,2)]

func can_access(faction:String,required:float)->bool:
    return float(reputation.get(faction,0))>=required

func dominant_faction()->String:
    var best="";var score=-INF
    for f in reputation.keys():
        if float(reputation[f])>score:score=float(reputation[f]);best=f
    return best

func betray(from_faction:String,to_faction:String,day:int,hour:float):
    change(from_faction,-45.0,day,hour,"Ты предал интересы фракции.")
    change(to_faction,18.0,day,hour,"Новая сторона оценила твою помощь.")

func serialize()->Dictionary:return {"reputation":reputation,"membership":membership,"titles":titles}
func restore(data:Dictionary):
    if typeof(data.get("reputation",{}))==TYPE_DICTIONARY:reputation=data["reputation"]
    if typeof(data.get("membership",[]))==TYPE_ARRAY:membership=data["membership"]
    if typeof(data.get("titles",{}))==TYPE_DICTIONARY:titles=data["titles"]
