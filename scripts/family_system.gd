extends RefCounted

var families:Dictionary={}
var events:Array=[]
var rng:=RandomNumberGenerator.new()
var next_tick_day:=3

func setup(npcs:Array):
    rng.randomize()
    for n in npcs:
        var id=str(n.get("id",""))
        if id=="":continue
        if not n.has("family_id") or str(n.get("family_id",""))=="":
            n["family_id"]="family_"+id
        var fid=str(n["family_id"])
        if not families.has(fid):families[fid]={"name":"Дом "+str(n.get("name",id)),"members":[id],"wealth":int(n.get("money",0)),"influence":int(n.get("influence",0)),"home":str(n.get("home_location",""))}
    _bind_royal_house(npcs)

func _bind_royal_house(npcs:Array):
    families["royal_house"]={"name":"Дом Чёрного Утёса","members":[],"wealth":120,"influence":100,"home":"castle"}
    for i in npcs.size():
        var id=str(npcs[i].get("id",""))
        if id in ["king","queen"]:
            npcs[i]["family_id"]="royal_house"
            if not families["royal_house"]["members"].has(id):families["royal_house"]["members"].append(id)
            if id=="king":npcs[i]["spouse_id"]="queen"
            if id=="queen":npcs[i]["spouse_id"]="king"

func tick(npcs:Array,day:int,hour:float)->Array:
    if day<next_tick_day or hour<18.0:return npcs
    next_tick_day=day+rng.randi_range(2,4)
    npcs=_form_marriages(npcs,day,hour)
    npcs=_family_drift(npcs,day,hour)
    return npcs

func _form_marriages(npcs:Array,day:int,hour:float)->Array:
    for i in npcs.size():
        var a=npcs[i]
        if not bool(a.get("alive",true)) or str(a.get("spouse_id",""))!="":continue
        var social:Dictionary=a.get("social",{})
        for other_id in social.keys():
            var rel:Dictionary=social[other_id]
            if float(rel.get("love",0))<65.0 or float(rel.get("trust",0))<45.0:continue
            var j=_find(npcs,str(other_id))
            if j<0 or str(npcs[j].get("spouse_id",""))!="":continue
            if rng.randf()>0.28:continue
            var b=npcs[j]
            a["spouse_id"]=str(b["id"]);b["spouse_id"]=str(a["id"])
            var fid=_merge_family(a,b)
            a["family_id"]=fid;b["family_id"]=fid
            var home=_choose_home(a,b)
            a["home_location"]=home;b["home_location"]=home
            npcs[i]=a;npcs[j]=b
            _log(day,hour,"%s и %s создали семью."%[a["name"],b["name"]],"marriage",str(a["id"]),str(b["id"]))
            return npcs
    return npcs

func _merge_family(a:Dictionary,b:Dictionary)->String:
    var fa=str(a.get("family_id","family_"+str(a["id"])))
    var fb=str(b.get("family_id","family_"+str(b["id"])))
    var chosen=fa if int(a.get("influence",0))>=int(b.get("influence",0)) else fb
    if not families.has(chosen):families[chosen]={"name":"Дом "+str(a["name"]),"members":[],"wealth":0,"influence":0,"home":""}
    for id in [str(a["id"]),str(b["id"])]:
        if not families[chosen]["members"].has(id):families[chosen]["members"].append(id)
    families[chosen]["wealth"]=int(families[chosen].get("wealth",0))+int(a.get("money",0))+int(b.get("money",0))
    families[chosen]["influence"]=maxi(int(families[chosen].get("influence",0)),maxi(int(a.get("influence",0)),int(b.get("influence",0))))
    return chosen

func _choose_home(a:Dictionary,b:Dictionary)->String:
    var ia=int(a.get("influence",0));var ib=int(b.get("influence",0))
    return str(a.get("home_location","slums")) if ia>=ib else str(b.get("home_location","slums"))

func _family_drift(npcs:Array,day:int,hour:float)->Array:
    for fid in families.keys():
        var fam:Dictionary=families[fid]
        fam["wealth"]=maxi(0,int(fam.get("wealth",0))+rng.randi_range(-2,3))
        if int(fam.get("wealth",0))>80:fam["influence"]=int(fam.get("influence",0))+1
        families[fid]=fam
    return npcs

func on_death(npcs:Array,npc_id:String,day:int,hour:float)->Array:
    var idx=_find(npcs,npc_id)
    if idx<0:return npcs
    var dead=npcs[idx];var spouse=str(dead.get("spouse_id",""));var fid=str(dead.get("family_id",""))
    if spouse!="":
        var si=_find(npcs,spouse)
        if si>=0:
            npcs[si]["spouse_id"]=""
            npcs[si]["stress"]=float(npcs[si].get("stress",0))+35.0
            npcs[si]["money"]=int(npcs[si].get("money",0))+int(dead.get("money",0))
    if families.has(fid):
        families[fid]["wealth"]=int(families[fid].get("wealth",0))+int(dead.get("money",0))
    _log(day,hour,"Смерть %s изменила положение семьи."%dead.get("name",npc_id),"inheritance",npc_id,spouse)
    return npcs

func _find(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1

func _log(day:int,hour:float,text:String,type:String,a:String,b:String):
    events.append({"day":day,"hour":hour,"type":type,"a":a,"b":b,"text":text})
    if events.size()>80:events.pop_front()

func serialize()->Dictionary:return {"families":families,"next_tick_day":next_tick_day}
func restore(data:Dictionary):
    if typeof(data.get("families",{}))==TYPE_DICTIONARY:families=data["families"]
    next_tick_day=int(data.get("next_tick_day",next_tick_day))
