extends RefCounted

var events:Array=[]
var last_day:=-1

func tick(npcs:Array,properties:Array,production,day:int,hour:float)->Array:
    if day==last_day or hour<7.0:return npcs
    last_day=day
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)):continue
        var money=float(n.get("money",0));var stress=float(n.get("stress",0));var employed=str(n.get("employment_property",""))!=""
        if employed and stress>75 and randf()<0.16:
            _quit_job(npcs,i,properties,day,hour)
        elif not employed:
            _seek_job(npcs,i,properties,day,hour)
        _update_class(npcs,i,day,hour)
    return npcs

func _quit_job(npcs:Array,idx:int,properties:Array,day:int,hour:float):
    var id=str(npcs[idx]["id"]);var old=str(npcs[idx].get("employment_property",""))
    for p in properties:
        if str(p.get("id",""))==old:p["workers"].erase(id)
    npcs[idx]["employment_property"]="";events.append({"day":day,"hour":hour,"type":"quit","text":"%s бросил работу из-за условий жизни."%npcs[idx]["name"]})

func _seek_job(npcs:Array,idx:int,properties:Array,day:int,hour:float):
    var best:Dictionary={};var best_wage:=-1.0
    for p in properties:
        if not bool(p.get("active",true)) or p["workers"].size()>=int(p["worker_slots"]):continue
        var wage=float(p.get("wage",0));if wage>best_wage:best=p;best_wage=wage
    if best.is_empty():return
    var id=str(npcs[idx]["id"]);best["workers"].append(id);npcs[idx]["employment_property"]=best["id"]
    npcs[idx]["target"]=best.get("pos",npcs[idx].get("pos",Vector2.ZERO));events.append({"day":day,"hour":hour,"type":"job","text":"%s нашёл работу: %s."%[npcs[idx]["name"],best["name"]]})

func _update_class(npcs:Array,idx:int,day:int,hour:float):
    var n=npcs[idx];var money=float(n.get("money",0));var old=str(n.get("social_class","poor"));var cls=old
    if money>=220:cls="wealthy"
    elif money>=70:cls="comfortable"
    elif money>=15:cls="worker"
    else:cls="poor"
    if cls!=old:
        n["social_class"]=cls;npcs[idx]=n;events.append({"day":day,"hour":hour,"type":"class","text":"Положение %s изменилось: %s."%[n["name"],cls]})

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
