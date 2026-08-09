extends RefCounted

var gods={
    "perun":{"name":"Перун","domains":["storm","war","oath"],"favor":0.0,"wrath":0.0,"known":false},
    "veles":{"name":"Велес","domains":["cattle","wealth","magic","underworld"],"favor":0.0,"wrath":0.0,"known":false},
    "mokosh":{"name":"Мокошь","domains":["earth","women","craft","fate"],"favor":0.0,"wrath":0.0,"known":false},
    "dazhbog":{"name":"Дажьбог","domains":["sun","prosperity","gift"],"favor":0.0,"wrath":0.0,"known":false},
    "stribog":{"name":"Стрибог","domains":["wind","travel","sea"],"favor":0.0,"wrath":0.0,"known":false}
}
var spirits={
    "domovoi":{"name":"Домовой","place":"estate","known":false,"relation":0.0},
    "leshy":{"name":"Леший","place":"forest","known":false,"relation":0.0},
    "vodyanoy":{"name":"Водяной","place":"water","known":false,"relation":0.0},
    "rusalka":{"name":"Русалка","place":"water","known":false,"relation":0.0}
}
var shrines:Array=[]
var pacts:Array=[]
var omens:Array=[]
var events:Array=[]
var next_shrine:=1
var last_day:=-1

func discover_deity(id:String)->Dictionary:
    if not gods.has(id):return {"ok":false}
    gods[id]["known"]=true;events.append({"type":"myth_discovery","text":"Герой впервые узнаёт имя: %s."%gods[id]["name"]});return {"ok":true,"god":gods[id]}

func discover_spirit(id:String)->Dictionary:
    if not spirits.has(id):return {"ok":false}
    spirits[id]["known"]=true;events.append({"type":"spirit_discovery","text":"Герой понимает, что за странностями может стоять %s."%spirits[id]["name"]});return {"ok":true}

func build_shrine(god_id:String,pos:Vector2)->Dictionary:
    if not gods.has(god_id) or not bool(gods[god_id]["known"]):return {"ok":false,"reason":"Герой ещё не знает, кому посвящать святилище."}
    var s={"id":"shrine_%d"%next_shrine,"god":god_id,"pos":pos,"offerings":0.0,"sanctity":10.0};next_shrine+=1;shrines.append(s);events.append({"type":"shrine","text":"Поставлено святилище: %s."%gods[god_id]["name"]});return {"ok":true,"shrine":s}

func offer(god_id:String,value:float,kind:String,day:int)->Dictionary:
    if not gods.has(god_id):return {"ok":false,"reason":"Неизвестное божество."}
    var mult=1.0
    if god_id=="perun" and kind in ["weapon","oath"]:mult=1.35
    elif god_id=="veles" and kind in ["coin","cattle","magic"]:mult=1.4
    elif god_id=="mokosh" and kind in ["cloth","food","craft"]:mult=1.35
    elif god_id=="dazhbog" and kind in ["food","coin","gift"]:mult=1.25
    elif god_id=="stribog" and kind in ["sail","fish","travel"]:mult=1.3
    gods[god_id]["favor"]=clampf(float(gods[god_id]["favor"])+value*.12*mult,-100,100)
    events.append({"type":"offering","text":"Подношение принято у святилища %s."%gods[god_id]["name"]});return {"ok":true,"favor":gods[god_id]["favor"]}

func swear_oath(god_id:String,text:String,day:int)->Dictionary:
    if god_id!="perun" and not bool(gods.get(god_id,{}).get("known",false)):return {"ok":false,"reason":"Нельзя клясться именем неизвестного бога."}
    pacts.append({"god":god_id,"text":text,"day":day,"kept":true,"broken":false});events.append({"type":"divine_oath","text":"Дана священная клятва именем %s."%gods[god_id]["name"]});return {"ok":true}

func break_latest_oath():
    for i in range(pacts.size()-1,-1,-1):
        if not bool(pacts[i].get("broken",false)):
            pacts[i]["broken"]=true;pacts[i]["kept"]=false;var g=str(pacts[i]["god"]);gods[g]["wrath"]=minf(100,float(gods[g]["wrath"])+25);events.append({"type":"oath_broken","text":"Священная клятва нарушена. %s разгневан."%gods[g]["name"]});return

func tick(day:int,weather:String,ctx:Dictionary):
    if day==last_day:return
    last_day=day
    if weather=="storm" and randf()<.28:_omen("perun","Гром ударил необычно близко, будто отвечая кому-то.")
    if float(ctx.get("wealth",0))>150 and randf()<.12:_omen("veles","Во сне герой видит рога, золото и корни огромного дерева.")
    if bool(ctx.get("estate",false)) and randf()<.10:_spirit_event("domovoi")
    if bool(ctx.get("forest",false)) and randf()<.08:_spirit_event("leshy")
    if bool(ctx.get("near_water",false)) and randf()<.08:_spirit_event("vodyanoy")

func blessing(god_id:String)->Dictionary:
    if not gods.has(god_id):return {}
    var f=float(gods[god_id]["favor"])
    if f<20:return {}
    return {
        "perun":{"combat":1+int(f/35),"storm_resist":.2},
        "veles":{"trade":1+int(f/35),"magic":1},
        "mokosh":{"farming":1+int(f/35),"craft":1},
        "dazhbog":{"prosperity":.08+f/1000.0},
        "stribog":{"sailing":1+int(f/35),"travel_risk":-.12}
    }.get(god_id,{})

func _omen(god_id:String,text:String):
    var o={"god":god_id,"text":text,"day":last_day};omens.append(o);events.append({"type":"omen","text":text,"god":god_id})
func _spirit_event(id:String):
    var s=spirits[id];if not bool(s["known"]) and randf()<.45:s["known"]=true
    events.append({"type":"spirit_event","spirit":id,"text":"Происходит странное событие, связанное с образом «%s»."%s["name"]})
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"gods":gods,"spirits":spirits,"shrines":shrines,"pacts":pacts,"omens":omens,"next_shrine":next_shrine,"last_day":last_day}
func restore(data:Dictionary):
    var g=data.get("gods",{});if typeof(g)==TYPE_DICTIONARY:gods=g
    var s=data.get("spirits",{});if typeof(s)==TYPE_DICTIONARY:spirits=s
    var sh=data.get("shrines",[]);if typeof(sh)==TYPE_ARRAY:shrines=sh
    var p=data.get("pacts",[]);if typeof(p)==TYPE_ARRAY:pacts=p
    var o=data.get("omens",[]);if typeof(o)==TYPE_ARRAY:omens=o
    next_shrine=int(data.get("next_shrine",next_shrine));last_day=int(data.get("last_day",last_day))
