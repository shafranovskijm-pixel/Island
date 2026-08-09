extends RefCounted

var structures:Array=[]
var next_id:=1
var events:Array=[]

func stations_near(pos:Vector2,location_id:String,range:float=125.0)->Array:
    var result:Array=["hand"]
    var defaults={
        "workshop":["workbench","sawbench","forge"],
        "market":["workbench"],
        "tavern":["kitchen","campfire"],
        "fisher_cove":["campfire","workbench"],
        "temple":["alchemy"],
        "temple_archive":["alchemy"],
        "occult_lodge":["occult","alchemy"],
        "crypt":["occult"],
        "player_home":["hand"]
    }
    for station in defaults.get(location_id,[]):
        if station not in result:result.append(station)
    for structure in structures:
        if float(structure.get("condition",0))<=0:continue
        if pos.distance_to(structure.get("pos",Vector2.ZERO))<=range:
            var type=str(structure.get("station_type",structure.get("structure_type","")))
            if type!="" and type not in result:result.append(type)
    return result

func place_from_inventory(item_id:String,inventory:Array,pos:Vector2)->Dictionary:
    var idx=-1
    for i in inventory.size():
        if str(inventory[i].get("id",""))==item_id:
            idx=i;break
    if idx<0:return {"ok":false,"reason":"Предмет не найден."}
    var item:Dictionary=inventory[idx]
    if not bool(item.get("placeable",false)):return {"ok":false,"reason":"Этот предмет нельзя разместить в мире."}
    var station_type=str(item.get("station_type",item.get("structure_type","")))
    var structure=item.duplicate(true)
    structure["id"]="placed_%d"%next_id;next_id+=1
    structure["source_item_id"]=item_id
    structure["pos"]=pos
    structure["condition"]=float(structure.get("condition",100.0))
    structures.append(structure)
    inventory.remove_at(idx)
    events.append({"type":"place","text":"Размещено: %s."%structure.get("name","объект"),"structure":structure})
    return {"ok":true,"structure":structure,"station_type":station_type}

func pickup(structure_id:String,inventory:Array)->Dictionary:
    for i in structures.size():
        if str(structures[i].get("id",""))!=structure_id:continue
        var structure:Dictionary=structures[i]
        var item=structure.duplicate(true)
        item["id"]="picked_%d"%Time.get_ticks_msec()
        item.erase("pos")
        item.erase("source_item_id")
        inventory.append(item)
        structures.remove_at(i)
        events.append({"type":"pickup","text":"Поднято: %s."%item.get("name","объект")})
        return {"ok":true,"item":item}
    return {"ok":false,"reason":"Размещённый объект не найден."}

func first_placeable(inventory:Array)->Dictionary:
    for item in inventory:
        if bool(item.get("placeable",false)):return item
    return {}

func damage_near(pos:Vector2,amount:float,range:float=90.0):
    for structure in structures:
        if pos.distance_to(structure.get("pos",Vector2.ZERO))<=range:
            structure["condition"]=maxf(0.0,float(structure.get("condition",100.0))-amount)

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out

func serialize()->Dictionary:
    return {"structures":structures,"next_id":next_id}

func restore(data:Dictionary):
    var s=data.get("structures",[])
    if typeof(s)==TYPE_ARRAY:structures=s
    next_id=int(data.get("next_id",next_id))
