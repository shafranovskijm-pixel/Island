extends SceneTree

const LearningSystem=preload("res://scripts/learning_system.gd")
const CraftingSystem=preload("res://scripts/crafting_system.gd")
const StationSystem=preload("res://scripts/crafting_station_system.gd")

func _init():
    var learning=LearningSystem.new()
    var crafting=CraftingSystem.new()
    var stations=StationSystem.new()

    assert(crafting.recipes.size()>=70)
    assert("building" in crafting.category_ids())
    assert("occult" in crafting.category_ids())

    learning.knowledge={"building":5.0,"foraging":5.0,"smithing":5.0,"medicine":5.0,"farming":5.0,"magic":5.0,"stealth":5.0}
    learning.study_progress={
        "carpentry":8.0,"woodcutting":4.0,"masonry":5.0,"mining":5.0,
        "smelting":5.0,"smithing":6.0,"survival":4.0,"textiles":4.0,
        "cooking":4.0,"farming":5.0,"alchemy":5.0,"occult":6.0
    }
    crafting.unlock_from_knowledge(learning)

    var resources={
        "wood":20.0,"plank":40.0,"stick":20.0,"rope":10.0,"stone":50.0,"clay":20.0,
        "coal":20.0,"iron_ore":12.0,"copper_ore":8.0,"fiber":20.0,"cloth":10.0,
        "sand":10.0,"herbs":10.0,"fish":10.0,"food":20.0,"iron_ingot":8.0,
        "stone_brick":20.0,"glass":6.0,"copper_ingot":4.0,"ritual_chalk":3.0,"oil":4.0
    }
    var inventory=[
        {"id":"knife","name":"каменный нож","kind":"tool","tool_type":"knife","durability":30.0},
        {"id":"hammer","name":"деревянный молоток","kind":"tool","tool_type":"hammer","durability":30.0}
    ]

    var bench=crafting.craft("workbench",learning,resources,inventory,"wilderness",["hand"])
    assert(bool(bench.get("ok",false)))
    var bench_item=inventory.back()
    var placed=stations.place_from_inventory(str(bench_item["id"]),inventory,Vector2(100,100))
    assert(bool(placed.get("ok",false)))
    assert("workbench" in stations.stations_near(Vector2(100,100),"wilderness"))

    var axe=crafting.craft("stone_axe",learning,resources,inventory,"wilderness",stations.stations_near(Vector2(100,100),"wilderness"))
    assert(bool(axe.get("ok",false)))
    assert(str(axe["item"].get("tool_type",""))=="axe")

    var furnace=crafting.craft("furnace",learning,resources,inventory,"wilderness",stations.stations_near(Vector2(100,100),"wilderness"))
    assert(bool(furnace.get("ok",false)))
    var furnace_item=inventory.back()
    assert(bool(stations.place_from_inventory(str(furnace_item["id"]),inventory,Vector2(115,100)).get("ok",false)))
    var near=stations.stations_near(Vector2(100,100),"wilderness")
    assert("furnace" in near)

    var before_ore=float(resources["iron_ore"])
    var ingot=crafting.craft("iron_ingot",learning,resources,inventory,"wilderness",near)
    assert(bool(ingot.get("ok",false)))
    assert(float(resources["iron_ore"])<before_ore)
    assert(str(ingot["item"].get("resource",""))=="iron_ingot")

    var categories=crafting.category_ids()
    assert(categories.size()>=9)
    print("SMOKE_V27_CRAFTING_OK recipes=",crafting.recipes.size()," stations=",stations.structures.size())
    quit(0)
