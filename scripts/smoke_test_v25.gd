extends SceneTree

const LearningSystem=preload("res://scripts/learning_system.gd")
const CraftingSystem=preload("res://scripts/crafting_system.gd")

func _init():
    var learning=LearningSystem.new()
    var crafting=CraftingSystem.new()
    var resources={"plank":20.0,"stone":10.0,"cloth":5.0,"iron_ingot":3.0}
    var inventory=[
        {"id":"knife_1","name":"нож","tool_type":"knife","durability":20.0},
        {"id":"hammer_1","name":"молоток","tool_type":"hammer","durability":20.0}
    ]

    learning.knowledge["building"]=2.0
    learning.study_progress["carpentry"]=3.0
    crafting.unlock_from_knowledge(learning)
    assert(bool(crafting.known_recipes.get("wooden_crate",false)))

    var before=float(resources["plank"])
    var result=crafting.craft("wooden_crate",learning,resources,inventory,"workshop",["hand","workbench"])
    assert(bool(result.get("ok",false)))
    assert(float(resources["plank"])<before)
    assert(inventory.size()==3)
    assert(str(inventory.back().get("name",""))=="деревянный ящик")

    var learning2=LearningSystem.new()
    learning2.knowledge["building"]=2.0
    learning2.study_progress["carpentry"]=0.0
    crafting.known_recipes.clear();crafting.unlock_from_knowledge(learning2)
    var blocked=crafting.can_craft("wooden_crate",learning2,resources,inventory,"workshop",["hand","workbench"])
    assert(not bool(blocked.get("ok",false)))

    print("SMOKE_V25_OK")
    quit(0)
