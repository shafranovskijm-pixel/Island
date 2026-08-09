extends RefCounted

const CraftingCatalog=preload("res://scripts/crafting_catalog.gd")

var catalog=CraftingCatalog.new()
var recipes:Dictionary={}
var known_recipes:Dictionary={}
var crafted_count:Dictionary={}
var events:Array=[]

func _init():
    recipes=catalog.all()

func unlock_from_knowledge(learning):
    for id in recipes.keys():
        var r:Dictionary=recipes[id]
        var theory=str(r.get("theory",""))
        var need=float(r.get("theory_required",0.0))
        if theory=="" or need<=0.0 or _theory_level(learning,theory)>=need:
            known_recipes[id]=true

func can_craft(id:String,learning,resources:Dictionary,inventory:Array,location_id:String,stations:Array=[])->Dictionary:
    if not recipes.has(id):return {"ok":false,"reason":"Неизвестный рецепт."}
    unlock_from_knowledge(learning)
    if not bool(known_recipes.get(id,false)):return {"ok":false,"reason":"Нужно сначала изучить теорию этого ремесла."}
    var r:Dictionary=recipes[id]

    var station=str(r.get("station","hand"))
    var station_pool:Array=stations.duplicate()
    if station_pool.is_empty():
        station_pool=["hand",location_id]
    if station!="hand" and station not in station_pool and station!=location_id:
        return {"ok":false,"reason":"Нужна станция: %s."%station}

    var allowed:Array=r.get("location",[])
    if not allowed.is_empty() and location_id not in allowed:
        return {"ok":false,"reason":"Здесь нет подходящих условий для работы."}

    var profession=str(r.get("profession",""))
    var practice_need=float(r.get("practice_required",r.get("practice",0.0)))
    if practice_need>0.0 and _practice_level(learning,profession)<practice_need:
        return {"ok":false,"reason":"Не хватает практики: %s %.1f/%.1f."%[profession,_practice_level(learning,profession),practice_need]}

    for key in r.get("inputs",{}).keys():
        var have=float(resources.get(key,0.0));var need=float(r["inputs"][key])
        if have+0.001<need:return {"ok":false,"reason":"Не хватает ресурса: %s (%.1f/%.1f)."%[key,have,need]}

    for tool in r.get("tools",[]):
        if _find_tool_index(inventory,str(tool))<0:return {"ok":false,"reason":"Нужен инструмент: %s."%tool}

    return {"ok":true,"station":station}

func craft(id:String,learning,resources:Dictionary,inventory:Array,location_id:String,stations:Array=[])->Dictionary:
    var check=can_craft(id,learning,resources,inventory,location_id,stations)
    if not bool(check.get("ok",false)):return check
    var r:Dictionary=recipes[id]
    for key in r.get("inputs",{}).keys():
        resources[key]=float(resources.get(key,0.0))-float(r["inputs"][key])

    var broken_tools=_damage_required_tools(inventory,r.get("tools",[]),1.0)
    var item:Dictionary=r["output"].duplicate(true)
    item["id"]="crafted_%s_%d"%[id,Time.get_ticks_usec()]
    item["recipe_id"]=id
    item["crafted"]=true
    _add_or_stack(inventory,item)

    crafted_count[id]=int(crafted_count.get(id,0))+1
    var profession=str(r.get("profession",""))
    if profession!="":
        learning.study_progress[profession]=float(learning.study_progress.get(profession,0.0))+0.45
    events.append({"type":"craft","text":"Создано: %s."%item.get("name",id),"recipe":id,"category":r.get("category","")})
    for tool_name in broken_tools:
        events.append({"type":"tool_break","text":"Инструмент сломался: %s."%tool_name})
    return {"ok":true,"item":item,"broken_tools":broken_tools,"station":check.get("station","hand")}

func recipes_by_category(category:String,learning=null)->Array:
    if learning!=null:unlock_from_knowledge(learning)
    var out:Array=[]
    for id in recipes.keys():
        if str(recipes[id].get("category",""))!=category:continue
        if learning!=null and not bool(known_recipes.get(id,false)):continue
        var entry=recipes[id].duplicate(true);entry["id"]=id;out.append(entry)
    out.sort_custom(func(a,b):return str(a["output"].get("name",a["id"]))<str(b["output"].get("name",b["id"])))
    return out

func category_ids()->Array:
    return catalog.categories()

func category_name(id:String)->String:
    return catalog.category_name(id)

func _theory_level(learning,skill:String)->float:
    if learning==null:return 0.0
    return float(learning.knowledge.get(skill,0.0))

func _practice_level(learning,skill:String)->float:
    if learning==null:return 0.0
    return float(learning.study_progress.get(skill,0.0))

func _find_tool_index(inventory:Array,tool:String)->int:
    for i in inventory.size():
        var item:Dictionary=inventory[i]
        if float(item.get("durability",1.0))<=0.0:continue
        var tt=str(item.get("tool_type",""))
        if tt==tool:return i
        if tool=="knife" and tt in ["knife","blade"]:return i
        if tool=="hammer" and tt in ["hammer","smith_hammer"]:return i
        if tool=="fire_source" and tt in ["fire_source","torch"]:return i
        var n=str(item.get("name","")).to_lower()
        if tool=="knife" and ("нож" in n or "клин" in n):return i
        if tool=="hammer" and "молот" in n:return i
    return -1

func _damage_required_tools(inventory:Array,tools:Array,amount:float)->Array:
    var broken:Array=[]
    for tool in tools:
        var idx=_find_tool_index(inventory,str(tool))
        if idx<0:continue
        if not inventory[idx].has("durability"):continue
        inventory[idx]["durability"]=float(inventory[idx]["durability"])-amount
        if float(inventory[idx]["durability"])<=0.0:
            broken.append(str(inventory[idx].get("name",tool)))
            inventory.remove_at(idx)
    return broken

func _add_or_stack(inventory:Array,item:Dictionary):
    var kind=str(item.get("kind",""))
    var quantity=float(item.get("quantity",1.0))
    if kind in ["resource","food","medicine","seed","ammo","drink"]:
        for existing in inventory:
            if str(existing.get("kind",""))!=kind:continue
            var same=false
            if kind=="resource":same=str(existing.get("resource",""))==str(item.get("resource",""))
            else:same=str(existing.get("subtype",existing.get("name","")))==str(item.get("subtype",item.get("name","")))
            if same:
                existing["quantity"]=float(existing.get("quantity",1.0))+quantity
                return
    inventory.append(item)

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out

func serialize()->Dictionary:
    return {"known_recipes":known_recipes,"crafted_count":crafted_count}

func restore(data:Dictionary):
    var k=data.get("known_recipes",{})
    if typeof(k)==TYPE_DICTIONARY:known_recipes=k
    var c=data.get("crafted_count",{})
    if typeof(c)==TYPE_DICTIONARY:crafted_count=c
