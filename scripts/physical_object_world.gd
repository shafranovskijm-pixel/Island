extends RefCounted

var objects:Array=[]
var events:Array=[]
var next_id:=1

func setup():
    _ensure("tavern_bottle","бутылка",Vector2(735,540),"glass",1.0,true,true)
    _ensure("tavern_mug","кружка",Vector2(770,550),"wood",1.0,true,true)
    _ensure("tavern_chair","стул",Vector2(700,575),"wood",4.0,true,true)
    _ensure("market_crate","ящик",Vector2(630,520),"wood",8.0,true,true)
    _ensure("grave_shovel","лопата",Vector2(1160,690),"metal",5.0,true,false)
    _ensure("port_rope","моток верёвки",Vector2(1510,680),"fiber",2.0,true,false)

func _ensure(tag:String,name:String,pos:Vector2,material:String,mass:float,breakable:bool,weaponizable:bool):
    for o in objects:
        if str(o.get("tag",""))==tag:return
    objects.append({"id":"world_obj_%d"%next_id,"tag":tag,"name":name,"pos":pos,"material":material,"mass":mass,"breakable":breakable,"weaponizable":weaponizable,"broken":false,"held_by":"","condition":100.0,"evidence":[],"contents":[]});next_id+=1

func nearby(pos:Vector2,range:float=95.0)->Array:
    var out:Array=[]
    for o in objects:
        if str(o.get("held_by",""))=="" and pos.distance_to(o.get("pos",Vector2.ZERO))<=range:out.append(o)
    return out

func take(object_id:String,holder:String)->Dictionary:
    var i=_idx(object_id);if i<0:return {"ok":false,"reason":"Предмет не найден."}
    if float(objects[i].get("mass",0))>18:return {"ok":false,"reason":"Слишком тяжело поднять."}
    objects[i]["held_by"]=holder;events.append({"type":"object_take","text":"Поднят предмет: %s."%objects[i]["name"]});return {"ok":true,"object":objects[i]}

func drop(object_id:String,pos:Vector2)->Dictionary:
    var i=_idx(object_id);if i<0:return {"ok":false,"reason":"Предмет не найден."}
    objects[i]["held_by"]="";objects[i]["pos"]=pos;events.append({"type":"object_drop","text":"Предмет оставлен: %s."%objects[i]["name"]});return {"ok":true}

func break_object(object_id:String,actor:String)->Dictionary:
    var i=_idx(object_id);if i<0:return {"ok":false,"reason":"Предмет не найден."}
    if not bool(objects[i].get("breakable",false)):return {"ok":false,"reason":"Это нельзя так просто сломать."}
    if bool(objects[i].get("broken",false)):return {"ok":false,"reason":"Предмет уже сломан."}
    objects[i]["broken"]=true;objects[i]["condition"]=0.0;objects[i]["evidence"].append({"actor":actor,"type":"broken"})
    var shard:Dictionary={}
    if str(objects[i].get("material",""))=="glass":
        shard={"id":"world_obj_%d"%next_id,"tag":"glass_shard","name":"острый осколок","pos":objects[i]["pos"],"material":"glass","mass":0.2,"breakable":false,"weaponizable":true,"damage":5,"broken":false,"held_by":"","condition":100.0,"evidence":[{"actor":actor,"type":"created"}],"contents":[]};next_id+=1;objects.append(shard)
    events.append({"type":"object_break","text":"Разбито: %s."%objects[i]["name"]});return {"ok":true,"spawn":shard}

func throw_at(object_id:String,target:Dictionary,actor:String)->Dictionary:
    var i=_idx(object_id);if i<0:return {"ok":false,"reason":"Предмет не найден."}
    objects[i]["held_by"]="";objects[i]["pos"]=target.get("pos",objects[i]["pos"]);objects[i]["evidence"].append({"actor":actor,"type":"thrown"})
    return {"ok":true,"impact":maxf(1.0,float(objects[i].get("mass",1))*2.0),"object":objects[i]}

func mark_blood(object_id:String,person_id:String):
    var i=_idx(object_id);if i>=0:objects[i]["evidence"].append({"type":"blood","person":person_id})

func _idx(id:String)->int:
    for i in objects.size():
        if str(objects[i].get("id",""))==id:return i
    return -1
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"objects":objects,"next_id":next_id}
func restore(data:Dictionary):
    var o=data.get("objects",[]);if typeof(o)==TYPE_ARRAY:objects=o
    next_id=int(data.get("next_id",next_id))
