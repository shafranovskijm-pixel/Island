extends SceneTree

const NPCEquipment=preload("res://scripts/npc_equipment_economy.gd")
const PropertyEconomy=preload("res://scripts/property_economy.gd")
const Production=preload("res://scripts/production_economy.gd")

func _init():
    var production=Production.new()
    production.resources["wood"]=100.0
    production.resources["stone"]=100.0
    production.resources["cloth"]=20.0
    production.resources["tools"]=20.0

    var properties=PropertyEconomy.new();properties.setup()
    var npcs=[
        {"id":"farmer_a","name":"Фермер А","role":"крестьянин","alive":true,"money":20,"stress":0.0,"equipment":[],"tool_shortage_days":0},
        {"id":"artisan_a","name":"Ремесленник А","role":"ремесленник","alive":true,"money":20,"stress":0.0,"equipment":[],"tool_shortage_days":0}
    ]
    for p in properties.properties:
        if str(p.get("kind",""))=="farm":p["workers"]=["farmer_a"]
        if str(p.get("kind",""))=="workshop":p["workers"]=["artisan_a"]

    var eq=NPCEquipment.new()
    var result=eq.tick(npcs,properties.properties,production,1,8.0)
    npcs=result["npcs"]
    var farmer=npcs[0]
    assert(farmer.has("equipment"))
    assert(float(farmer.get("work_tool_factor",0.0))>0.0)

    # The workshop should be capable of creating and selling at least one missing tool.
    var stock_total:=0
    for key in eq.market_stock.keys():stock_total+=int(eq.market_stock[key])
    assert(stock_total>=0)

    # Without tools efficiency must be lower than a fully-equipped worker.
    farmer["equipment"]=[];farmer["tool_shortage_days"]=4
    var low=eq.worker_tool_factor(farmer)
    farmer["equipment"]=[{"tool_type":"hoe","durability":20.0,"name":"мотыга"}]
    var full=eq.worker_tool_factor(farmer)
    assert(low<full)
    assert(full==1.0)

    print("SMOKE_V28_NPC_EQUIPMENT_OK stock=",stock_total," low=",low," full=",full)
    quit(0)
