extends RefCounted

const CraftingCatalog=preload("res://scripts/crafting_catalog.gd")
var catalog=CraftingCatalog.new()
var recipes:Dictionary={}
var market_stock:Dictionary={}
var events:Array=[]
var last_day:=-1

func _init():
    recipes=catalog.all()
    market_stock={"stone_axe":1,"stone_pickaxe":1,"wooden_hammer":2,"stone_hoe":1,"fishing_rod":1,"stone_knife":2}

func tick(npcs:Array,properties:Array,production,day:int,hour:float)->Dictionary:
    if day==last_day or hour<7.2:
        _refresh_worker_factors(npcs)
        return {"npcs":npcs,"stock":market_stock}
    last_day=day
    _ensure_npc_equipment(npcs)
    _wear_work_tools(npcs,properties,day,hour)
    _workshop_production(npcs,properties,production,day,hour)
    _equip_workers(npcs,production,day,hour)
    _refresh_worker_factors(npcs)
    return {"npcs":npcs,"stock":market_stock}

func _ensure_npc_equipment(npcs:Array):
    for n in npcs:
        if not n.has("equipment"):n["equipment"]=[]
        if not n.has("tool_shortage_days"):n["tool_shortage_days"]=0
        if not n.has("work_tool_factor"):n["work_tool_factor"]=1.0

func _required_tool(npc:Dictionary)->String:
    var role=str(npc.get("role","")).to_lower()
    if "крест" in role or "фермер" in role:return "hoe"
    if "рыбак" in role:return "fishing_rod"
    if "лес" in role:return "axe"
    if "камен" in role or "шах" in role:return "pickaxe"
    if "стро" in role:return "hammer"
    if "ремес" in role or "кузне" in role:return "hammer"
    if "лекар" in role:return "knife"
    return ""

func _wear_work_tools(npcs:Array,properties:Array,day:int,hour:float):
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)):continue
        var required=_required_tool(n)
        if required=="":continue
        var idx=_tool_index(n.get("equipment",[]),required)
        if idx<0:
            n["tool_shortage_days"]=int(n.get("tool_shortage_days",0))+1
            n["stress"]=minf(100.0,float(n.get("stress",0))+2.0)
            npcs[i]=n
            continue
        var eq:Array=n["equipment"]
        eq[idx]["durability"]=float(eq[idx].get("durability",20.0))-1.0
        if float(eq[idx]["durability"])<=0:
            var broken_name=str(eq[idx].get("name","инструмент"));eq.remove_at(idx)
            events.append({"day":day,"hour":hour,"type":"npc_tool_break","npc_id":n["id"],"text":"У %s сломался %s."%[n["name"],broken_name]})
        n["equipment"]=eq;npcs[i]=n

func _workshop_production(npcs:Array,properties:Array,production,day:int,hour:float):
    var workshop_workers:=0
    var active_workshops:=0
    for p in properties:
        if str(p.get("kind",""))=="workshop" and bool(p.get("active",true)) and float(p.get("condition",0))>15:
            active_workshops+=1;workshop_workers+=p.get("workers",[]).size()
    if active_workshops<=0 or workshop_workers<=0:return

    var artisan_count:=0
    for n in npcs:
        var role=str(n.get("role","")).to_lower()
        if bool(n.get("alive",true)) and ("ремес" in role or "кузне" in role):artisan_count+=1
    if artisan_count<=0:return

    var capacity=mini(3,active_workshops+artisan_count)
    var priority=_shortage_priority(npcs)
    if priority.is_empty():return
    for k in capacity:
        var recipe_id=_recipe_for_tool(priority[k%priority.size()])
        if recipe_id=="":continue
        if not _consume_public_materials(recipe_id,production):
            events.append({"day":day,"hour":hour,"type":"crafting_shortage","text":"Мастерским не хватает сырья для изготовления рабочих инструментов."})
            break
        market_stock[recipe_id]=int(market_stock.get(recipe_id,0))+1
        events.append({"day":day,"hour":hour,"type":"npc_craft","text":"Островная мастерская изготовила: %s."%_recipe_name(recipe_id)})

func _shortage_priority(npcs:Array)->Array:
    var counts={"hoe":0,"axe":0,"pickaxe":0,"hammer":0,"fishing_rod":0,"knife":0}
    for n in npcs:
        if not bool(n.get("alive",true)):continue
        var t=_required_tool(n)
        if t!="" and _tool_index(n.get("equipment",[]),t)<0:counts[t]=int(counts.get(t,0))+1
    var keys:Array=[]
    for key in counts.keys():
        if int(counts[key])>0:keys.append(key)
    keys.sort_custom(func(a,b):return int(counts[a])>int(counts[b]))
    return keys

func _recipe_for_tool(tool:String)->String:
    return {"hoe":"stone_hoe","axe":"stone_axe","pickaxe":"stone_pickaxe","hammer":"wooden_hammer","fishing_rod":"fishing_rod","knife":"stone_knife"}.get(tool,"")

func _consume_public_materials(recipe_id:String,production)->bool:
    var cost={
        "stone_hoe":{"wood":2.0,"stone":2.0,"tools":0.2},
        "stone_axe":{"wood":2.0,"stone":3.0,"tools":0.2},
        "stone_pickaxe":{"wood":2.0,"stone":4.0,"tools":0.2},
        "wooden_hammer":{"wood":3.0,"tools":0.1},
        "fishing_rod":{"wood":3.0,"cloth":1.0,"tools":0.1},
        "stone_knife":{"wood":1.0,"stone":2.0,"tools":0.1}
    }.get(recipe_id,{})
    for key in cost.keys():
        if float(production.resources.get(key,0.0))<float(cost[key]):return false
    for key in cost.keys():production.resources[key]=float(production.resources.get(key,0.0))-float(cost[key])
    return true

func _equip_workers(npcs:Array,production,day:int,hour:float):
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)):continue
        var required=_required_tool(n)
        if required=="":continue
        if _tool_index(n.get("equipment",[]),required)>=0:
            n["tool_shortage_days"]=0;npcs[i]=n;continue
        var recipe_id=_recipe_for_tool(required)
        if int(market_stock.get(recipe_id,0))<=0:
            n["tool_shortage_days"]=int(n.get("tool_shortage_days",0))+1;npcs[i]=n;continue
        var price=_tool_price(recipe_id,production)
        var money=float(n.get("money",0))
        if money<price:
            n["tool_shortage_days"]=int(n.get("tool_shortage_days",0))+1;npcs[i]=n;continue
        n["money"]=int(maxf(0.0,money-price))
        var eq:Array=n.get("equipment",[])
        eq.append(_make_tool(recipe_id));n["equipment"]=eq;n["tool_shortage_days"]=0
        market_stock[recipe_id]=int(market_stock.get(recipe_id,0))-1
        events.append({"day":day,"hour":hour,"type":"npc_purchase","npc_id":n["id"],"text":"%s купил рабочий инструмент: %s."%[n["name"],_recipe_name(recipe_id)]})
        npcs[i]=n

func _refresh_worker_factors(npcs:Array):
    for i in npcs.size():
        npcs[i]["work_tool_factor"]=worker_tool_factor(npcs[i])

func worker_tool_factor(npc:Dictionary)->float:
    var required=_required_tool(npc)
    if required=="":return 1.0
    if _tool_index(npc.get("equipment",[]),required)>=0:return 1.0
    var days=int(npc.get("tool_shortage_days",0))
    return maxf(0.18,0.55-days*0.06)

func workforce_factor(npcs:Array,worker_ids:Array)->float:
    if worker_ids.is_empty():return 0.0
    var total:=0.0;var count:=0
    for id in worker_ids:
        var idx=_npc_index(npcs,str(id))
        if idx<0:continue
        total+=worker_tool_factor(npcs[idx]);count+=1
    if count==0:return 0.0
    return clampf(total/count,0.0,1.0)

func _make_tool(recipe_id:String)->Dictionary:
    var out:Dictionary=recipes.get(recipe_id,{}).get("output",{}).duplicate(true)
    out["id"]="npc_tool_%s_%d"%[recipe_id,Time.get_ticks_usec()]
    out["recipe_id"]=recipe_id
    return out

func _tool_index(equipment:Array,tool:String)->int:
    for i in equipment.size():
        var item:Dictionary=equipment[i]
        if float(item.get("durability",1.0))<=0:continue
        var tt=str(item.get("tool_type",""))
        if tt==tool:return i
        if tool=="fishing_rod" and tt in ["fishing_rod","fishing"]:return i
    return -1

func _tool_price(recipe_id:String,production)->float:
    var scarcity=1.0+clampf(float(production.hunger_pressure)/200.0,0.0,0.5)
    return {"stone_hoe":3.0,"stone_axe":4.0,"stone_pickaxe":5.0,"wooden_hammer":3.0,"fishing_rod":5.0,"stone_knife":2.0}.get(recipe_id,4.0)*scarcity

func _recipe_name(recipe_id:String)->String:
    return str(recipes.get(recipe_id,{}).get("output",{}).get("name",recipe_id))

func _npc_index(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out

func serialize()->Dictionary:return {"market_stock":market_stock,"last_day":last_day}
func restore(data:Dictionary):
    var s=data.get("market_stock",{});if typeof(s)==TYPE_DICTIONARY:market_stock=s
    last_day=int(data.get("last_day",last_day))
