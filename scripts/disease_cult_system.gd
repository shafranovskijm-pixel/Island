extends RefCounted
var diseases:Dictionary={}
var cults:Dictionary={"temple":{"influence":55.0,"members":[]},"occult_order":{"influence":12.0,"members":[]}}
var events:Array=[]
var last_day:=-1
func infect(id:String,disease:String,severity:float=.5):diseases[id]={"disease":disease,"severity":severity,"days":0,"contagious":true};events.append({"type":"disease","text":"Кто-то заболел: %s."%disease})
func tick(day:int,npcs:Array,ctx:Dictionary):
    if day==last_day:return
    last_day=day
    for id in diseases.keys():
        var d=diseases[id];d["days"]=int(d.get("days",0))+1;d["severity"]=clampf(float(d.get("severity",.5))+randf_range(-.08,.12),0,1.5);diseases[id]=d
        var i=_npc_index(npcs,id)
        if i>=0:npcs[i]["health"]=maxf(0,float(npcs[i].get("health",100))-float(d["severity"])*5)
        if int(d["days"])>8 and float(d["severity"])<.35:diseases.erase(id);events.append({"type":"recovery","text":"Больной постепенно выздоровел."})
    if float(ctx.get("hunger",0))>55 and randf()<.08:_seed_random(npcs,"fever")
    if float(ctx.get("rats",0))>50 and randf()<.10:_seed_random(npcs,"dock_pox")
    cults["occult_order"]["influence"]=clampf(float(cults["occult_order"]["influence"])+(1.2 if bool(ctx.get("vampire_rumors",false)) else .1),0,100)
    cults["temple"]["influence"]=clampf(float(cults["temple"]["influence"])+(1.0 if diseases.size()>2 else -.2),0,100)
func recruit(npc:Dictionary,cult:String)->Dictionary:
    if not cults.has(cult):return {"ok":false,"reason":"Такого культа нет."}
    if int(npc.get("rel",0))<1:return {"ok":false,"reason":"Человек недостаточно доверяет тебе."}
    var id=str(npc.get("id",""));if id not in cults[cult]["members"]:cults[cult]["members"].append(id);events.append({"type":"cult_recruit","text":"%s вступает в %s."%[npc.get("name","Житель"),cult]})
    return {"ok":true}
func _seed_random(npcs:Array,disease:String):
    var live=[]
    for n in npcs:
        if bool(n.get("alive",true)):live.append(n)
    if live.is_empty():return
    var n=live.pick_random();var id=str(n.get("id",""));if not diseases.has(id):infect(id,disease,.45)
func _npc_index(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"diseases":diseases,"cults":cults,"last_day":last_day}
func restore(data:Dictionary):
    var d=data.get("diseases",{});if typeof(d)==TYPE_DICTIONARY:diseases=d
    var c=data.get("cults",{});if typeof(c)==TYPE_DICTIONARY:cults=c
    last_day=int(data.get("last_day",last_day))
