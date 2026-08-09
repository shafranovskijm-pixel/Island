extends RefCounted

var placed:Array=[]
var events:Array=[]
var grid_size:=32.0
var next_id:=1

func place(piece:String,pos:Vector2,estate_id:String)->Dictionary:
    var snapped=Vector2(round(pos.x/grid_size)*grid_size,round(pos.y/grid_size)*grid_size)
    if _occupied(snapped):return {"ok":false,"reason":"Эта клетка уже занята."}
    var p={"id":"castle_piece_%d"%next_id,"piece":piece,"pos":snapped,"estate_id":estate_id,"condition":100.0}
    next_id+=1;placed.append(p);events.append({"type":"castle_build","text":"Построено: %s."%piece,"piece":p});return {"ok":true,"piece":p}

func remove_near(pos:Vector2,range:float=42.0)->Dictionary:
    var idx=-1;var d0=INF
    for i in placed.size():
        var d=pos.distance_to(placed[i]["pos"])
        if d<range and d<d0:idx=i;d0=d
    if idx<0:return {"ok":false,"reason":"Рядом нечего разбирать."}
    var p=placed[idx];placed.remove_at(idx);events.append({"type":"castle_remove","text":"Разобрано: %s."%p["piece"]});return {"ok":true,"piece":p}

func pieces_for_estate(estate_id:String)->Array:
    var out:Array=[]
    for p in placed:
        if str(p.get("estate_id",""))==estate_id:out.append(p)
    return out

func stats(estate_id:String)->Dictionary:
    var walls=0;var doors=0;var beds=0;var furniture=0;var occult=0
    for p in pieces_for_estate(estate_id):
        match str(p["piece"]):
            "stone_wall","wood_wall":walls+=1
            "wooden_door":doors+=1
            "simple_bed":beds+=1
            "wood_table","wood_chair":furniture+=1
            "occult_altar":occult+=1
    var castle_level=0
    if walls>=8 and doors>=1:castle_level=1
    if walls>=18 and beds>=2:castle_level=2
    if walls>=32 and beds>=4 and furniture>=4:castle_level=3
    return {"walls":walls,"doors":doors,"beds":beds,"furniture":furniture,"occult":occult,"castle_level":castle_level}

func _occupied(pos:Vector2)->bool:
    for p in placed:
        if p["pos"].distance_to(pos)<grid_size*.6:return true
    return false

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"placed":placed,"next_id":next_id}
func restore(data:Dictionary):
    var p=data.get("placed",[]);if typeof(p)==TYPE_ARRAY:placed=p
    next_id=int(data.get("next_id",next_id))
