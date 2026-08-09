extends RefCounted

var events:Array=[]
var last_day:=-1

func tick(npcs:Array,estate:Dictionary,day:int,hour:float):
    if estate.is_empty() or day==last_day or hour<19.0:return
    last_day=day
    var residents:Array=estate.get("residents",[])
    if residents.size()>=2:_resident_dynamics(npcs,residents,day,hour)
    if randf()<0.18:_guest_event(npcs,estate,day,hour)

func _resident_dynamics(npcs:Array,residents:Array,day:int,hour:float):
    var a_id=str(residents.pick_random());var b_id=str(residents.pick_random())
    if a_id==b_id:return
    var ai=_idx(npcs,a_id);var bi=_idx(npcs,b_id);if ai<0 or bi<0:return
    var a=npcs[ai];var b=npcs[bi]
    var a_rel=float(a.get("rel",0));var b_rel=float(b.get("rel",0))
    var jealousy=float(a.get("jealousy",0));var stress=float(a.get("stress",0))
    var roll=randf()
    if roll<0.35:
        a["rel"]=int(a_rel)+1;b["rel"]=int(b_rel)+1
        events.append({"type":"household_bond","text":"%s и %s хорошо провели вечер вместе."%[a["name"],b["name"]]})
    elif roll<0.55 and jealousy>20:
        a["stress"]=minf(100,stress+7);a["rel"]=int(a_rel)-1
        events.append({"type":"jealousy","text":"В доме вспыхнула ревность: %s поссорился с %s."%[a["name"],b["name"]]})
    elif roll<0.68:
        a["memory"].append({"type":"domestic_secret","about":b_id,"day":day})
        events.append({"type":"household_secret","text":"%s узнал личный секрет %s."%[a["name"],b["name"]]})
    npcs[ai]=a;npcs[bi]=b

func _guest_event(npcs:Array,estate:Dictionary,day:int,hour:float):
    var residents:Dictionary={}
    for id in estate.get("residents",[]):residents[str(id)]=true
    var guests:Array=[]
    for n in npcs:
        if bool(n.get("alive",true)) and not residents.has(str(n.get("id",""))) and int(n.get("rel",0))>=1:guests.append(n)
    if guests.is_empty():return
    var g:Dictionary=guests.pick_random();events.append({"type":"guest","npc_id":g["id"],"text":"%s пришёл в гости во владение героя."%g["name"]})

func feast(npcs:Array,estate:Dictionary)->Dictionary:
    if estate.is_empty():return {"ok":false,"reason":"Нет собственного дома."}
    if float(estate.get("food_store",0))<8:return {"ok":false,"reason":"Для пира нужно хотя бы 8 единиц еды в запасе дома."}
    estate["food_store"]=float(estate["food_store"])-8
    for id in estate.get("residents",[]):
        var i=_idx(npcs,str(id));if i>=0:npcs[i]["rel"]=int(npcs[i].get("rel",0))+1;npcs[i]["stress"]=maxf(0,float(npcs[i].get("stress",0))-8)
    events.append({"type":"feast","text":"Во владении устроили большой пир."});return {"ok":true}

func _idx(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
