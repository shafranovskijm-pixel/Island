extends SceneTree

const ResourceGathering=preload("res://scripts/resource_gathering.gd")
const PlayerFarming=preload("res://scripts/player_farming.gd")
const Learning=preload("res://scripts/learning_system.gd")

func _init():
    var learning=Learning.new()
    var gathering=ResourceGathering.new();gathering.setup()
    var inventory:Array=[];var skills:Dictionary={}
    var node:Dictionary={}
    for n in gathering.nodes:
        if str(n.get("kind",""))=="branches":node=n;break
    assert(not node.is_empty())
    var result=gathering.gather(str(node["id"]),inventory,learning,skills,1,8.0)
    assert(bool(result.get("ok",false)))
    assert(inventory.size()>0)
    assert(str(inventory[0].get("resource",""))=="wood")

    learning.knowledge["farming"]=2.0
    learning.study_progress["farming"]=1.0
    var farming=PlayerFarming.new();var plot=farming.create_plot("player",Vector2.ZERO)
    inventory.append({"id":"seed","kind":"seed","crop":"root","quantity":1.0})
    var planted=farming.plant(str(plot["id"]),"root",inventory,learning,1,9.0)
    assert(bool(planted.get("ok",false)))
    farming.water(str(plot["id"]),1,9.1)
    for d in range(2,9):farming.tick(d,"clear")
    var ready=false
    for p in farming.plots:
        if str(p.get("id",""))==str(plot["id"]):ready=bool(p.get("ready",false))
    assert(ready)
    var harvested=farming.harvest(str(plot["id"]),inventory,learning,9,8.0)
    assert(bool(harvested.get("ok",false)))
    var found_food=false
    for item in inventory:
        if str(item.get("kind",""))=="resource" and str(item.get("resource",""))=="food":found_food=true
    assert(found_food)
    print("V26 gathering/farming smoke test passed")
    quit(0)
