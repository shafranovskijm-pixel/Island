extends RefCounted

var boats:Array=[]
var events:Array=[]
var next_id:=1

func build_boat(kind:String)->Dictionary:
    var defs={
        "dinghy":{"name":"простая лодка","capacity":8.0,"crew":0,"speed":1.0,"condition":100.0,"fishing":1.0},
        "sloop":{"name":"небольшой шлюп","capacity":35.0,"crew":2,"speed":1.5,"condition":100.0,"fishing":1.4},
        "cutter":{"name":"парусный куттер","capacity":70.0,"crew":4,"speed":1.8,"condition":100.0,"fishing":1.6}
    }
    if not defs.has(kind):return {"ok":false,"reason":"Неизвестное судно."}
    var b=defs[kind].duplicate(true);b["id"]="boat_%d"%next_id;next_id+=1;b["kind"]=kind;b["owner"]="player";b["crew_ids"]=[];b["cargo"]={};b["docked"]="fisher_cove";boats.append(b)
    events.append({"type":"boat","text":"У героя появилось судно: %s."%b["name"]});return {"ok":true,"boat":b}

func player_boat()->Dictionary:
    for b in boats:
        if str(b.get("owner",""))=="player":return b
    return {}

func fish(learning,day:int,hour:float)->Dictionary:
    var idx=_player_boat_index();if idx<0:return {"ok":false,"reason":"Нужна собственная лодка."}
    var b=boats[idx];if float(b.get("condition",0))<=10:return {"ok":false,"reason":"Лодка слишком повреждена."}
    var bonus=1.0+float(learning.effective_bonus("fishing"))*.15
    var qty=randf_range(1.0,3.5)*float(b.get("fishing",1.0))*bonus
    b["cargo"]["fish"]=float(b["cargo"].get("fish",0))+qty;b["condition"]=maxf(0,float(b["condition"])-0.35);boats[idx]=b
    learning.practice("fishing",0.8,day,hour);events.append({"type":"boat_fishing","text":"С лодки поймано %.1f рыбы."%qty});return {"ok":true,"quantity":qty}

func sail_to(location:String)->Dictionary:
    var idx=_player_boat_index();if idx<0:return {"ok":false,"reason":"Нет своего судна."}
    boats[idx]["docked"]=location;boats[idx]["condition"]=maxf(0,float(boats[idx]["condition"])-1.0)
    events.append({"type":"sail","text":"Судно перешло к точке: %s."%location});return {"ok":true}

func _player_boat_index()->int:
    for i in boats.size():
        if str(boats[i].get("owner",""))=="player":return i
    return -1
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"boats":boats,"next_id":next_id}
func restore(data:Dictionary):
    var b=data.get("boats",[]);if typeof(b)==TYPE_ARRAY:boats=b
    next_id=int(data.get("next_id",next_id))
