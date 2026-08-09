extends RefCounted

var homes:Array=[]
var events:Array=[]
var last_day:=-1
var next_id:=1

func setup():
    if not homes.is_empty():return
    homes=[
        _home("room","Комната над таверной","tavern",2,2.0,Vector2(1500,850)),
        _home("slum","Комната в Нижних улицах","slums",5,0.8,Vector2(690,850)),
        _home("house","Дом у рынка","market",3,3.5,Vector2(760,610)),
        _home("house","Дом у рыбачьей бухты","fisher_cove",3,2.5,Vector2(430,800)),
        _home("mansion","Особняк на холме","castle",4,10.0,Vector2(900,470))
    ]

func _home(kind:String,name:String,location:String,capacity:int,rent:float,pos:Vector2)->Dictionary:
    var h={"id":"home_%d"%next_id,"kind":kind,"name":name,"location":location,"capacity":capacity,"rent":rent,"residents":[],"owner":"","condition":100.0,"pos":pos}
    next_id+=1;return h

func tick(npcs:Array,day:int,hour:float)->Array:
    if day==last_day or hour<8.0:return npcs
    last_day=day
    _remove_dead(npcs)
    for i in npcs.size():
        if not bool(npcs[i].get("alive",true)):continue
        _ensure_housing(npcs,i,day,hour)
        _charge_rent(npcs,i,day,hour)
        _consider_migration(npcs,i,day,hour)
    return npcs

func _remove_dead(npcs:Array):
    var alive:Dictionary={}
    for n in npcs:
        if bool(n.get("alive",true)):alive[str(n["id"])]=true
    for h in homes:
        var keep:Array=[]
        for id in h["residents"]:
            if alive.has(str(id)):keep.append(id)
        h["residents"]=keep

func _ensure_housing(npcs:Array,idx:int,day:int,hour:float):
    var n=npcs[idx];var id=str(n["id"]);var home_id=str(n.get("home_id",""))
    if home_id!="" and _home_exists(home_id):return
    var chosen=_best_affordable_home(float(n.get("money",0)),str(n.get("social_class","poor")),id)
    if chosen>=0:
        homes[chosen]["residents"].append(id);n["home_id"]=homes[chosen]["id"];n["homeless"]=false;n["home_location"]=homes[chosen]["location"];npcs[idx]=n
    else:
        n["home_id"]="";n["homeless"]=true;n["home_location"]="slums";n["stress"]=minf(100,float(n.get("stress",0))+8);npcs[idx]=n

func _charge_rent(npcs:Array,idx:int,day:int,hour:float):
    var n=npcs[idx];var hid=str(n.get("home_id",""));if hid=="":return
    var hi=_home_index(hid);if hi<0:return
    var rent=float(homes[hi]["rent"]);var money=float(n.get("money",0))
    if str(homes[hi].get("owner",""))==str(n["id"]):return
    if money>=rent:
        n["money"]=money-rent;npcs[idx]=n
    else:
        homes[hi]["residents"].erase(str(n["id"]));n["home_id"]="";n["homeless"]=true;n["home_location"]="slums";n["stress"]=minf(100,float(n.get("stress",0))+18);npcs[idx]=n
        events.append({"day":day,"hour":hour,"type":"eviction","text":"%s выселен за неуплату и оказался без жилья."%n["name"]})

func _consider_migration(npcs:Array,idx:int,day:int,hour:float):
    var n=npcs[idx];var cls=str(n.get("social_class","poor"));var hid=str(n.get("home_id",""));var current=_home_index(hid)
    if current<0:return
    var current_kind=str(homes[current]["kind"])
    if cls=="wealthy" and current_kind!="mansion":_move_to_kind(npcs,idx,"mansion",day,hour)
    elif cls=="comfortable" and current_kind in ["slum","room"]:_move_to_kind(npcs,idx,"house",day,hour)
    elif cls=="poor" and current_kind in ["house","mansion"]:_move_to_kind(npcs,idx,"slum",day,hour)

func _move_to_kind(npcs:Array,idx:int,kind:String,day:int,hour:float):
    var n=npcs[idx];var target=-1
    for i in homes.size():
        if str(homes[i]["kind"])==kind and homes[i]["residents"].size()<int(homes[i]["capacity"]):target=i;break
    if target<0:return
    var old=_home_index(str(n.get("home_id","")));if old>=0:homes[old]["residents"].erase(str(n["id"]))
    homes[target]["residents"].append(str(n["id"]));n["home_id"]=homes[target]["id"];n["home_location"]=homes[target]["location"];n["homeless"]=false;npcs[idx]=n
    events.append({"day":day,"hour":hour,"type":"move","text":"%s переехал: %s."%[n["name"],homes[target]["name"]]})

func add_player_home(kind:String,name:String,location:String,pos:Vector2)->Dictionary:
    var h=_home(kind,name,location,1,0.0,pos);h["owner"]="player";h["residents"]=["player"];homes.append(h);return h

func _best_affordable_home(money:float,cls:String,id:String)->int:
    var order=["slum","room","house","mansion"]
    if cls=="wealthy":order=["mansion","house","room","slum"]
    elif cls=="comfortable":order=["house","room","slum","mansion"]
    elif cls=="worker":order=["room","slum","house","mansion"]
    for kind in order:
        for i in homes.size():
            var h=homes[i]
            if str(h["kind"])==kind and h["residents"].size()<int(h["capacity"]) and money>=float(h["rent"])*2:return i
    return -1

func _home_exists(id:String)->bool:return _home_index(id)>=0
func _home_index(id:String)->int:
    for i in homes.size():
        if str(homes[i]["id"])==id:return i
    return -1

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out

func serialize()->Dictionary:return {"homes":homes,"next_id":next_id}
func restore(data:Dictionary):
    var h=data.get("homes",[]);if typeof(h)==TYPE_ARRAY:homes=h
    next_id=int(data.get("next_id",next_id))
