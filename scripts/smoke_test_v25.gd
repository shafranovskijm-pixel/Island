extends SceneTree

const LearningSystem=preload("res://scripts/learning_system.gd")
const CraftingSystem=preload("res://scripts/crafting_system.gd")

func _init():
    var learning=LearningSystem.new()
    var crafting=CraftingSystem.new()
    var resources={"food":20.0,"wood":20.0,"stone":10.0,"cloth":5.0,"medicine":5.0,"tools":5.0}
    var inventory=[{"id":"knife_1","name":"нож","tool_type":"knife"},{"id":"hammer_1","name":"молоток","tool_type":"hammer"}]

    learning.theory["construction"]=2.0
    learning.practice["carpentry"]=3.0
    crafting.unlock_from_knowledge(learning)
    assert(bool(crafting.known_recipes.get("wooden_crate",false)))

    var before=float(resources["wood"])
    var result=crafting.craft("wooden_crate",learning,resources,inventory,"workshop")
    assert(bool(result.get("ok",false)))
    assert(float(resources["wood"])<before)
    assert(inventory.size()==3)
    assert(str(inventory.back().get("name",""))=="деревянный ящик")

    var learning2=LearningSystem.new()
    learning2.theory["construction"]=2.0
    learning2.practice["carpentry"]=0.0
    crafting.known_recipes.clear();crafting.unlock_from_knowledge(learning2)
    var blocked=crafting.can_craft("wooden_crate",learning2,resources,inventory,"workshop")
    assert(not bool(blocked.get("ok",false)))

    print("SMOKE_V25_OK")
    quit(0)
