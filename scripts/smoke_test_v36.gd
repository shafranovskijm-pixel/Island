extends SceneTree
const Objects=preload("res://scripts/physical_object_world.gd")
const Combat=preload("res://scripts/injury_combat_system.gd")
const Dice=preload("res://scripts/dice_engine.gd")
func _init():
    var o=Objects.new();o.setup();assert(o.objects.size()>=6)
    var bottle={}
    for x in o.objects:
        if str(x.get("tag",""))=="tavern_bottle":bottle=x;break
    assert(not bottle.is_empty());assert(bool(o.take(str(bottle["id"]),"player").get("ok",false)))
    var broken=o.break_object(str(bottle["id"]),"player");assert(bool(broken.get("ok",false)));assert(not broken.get("spawn",{}).is_empty())
    var c=Combat.new();var d=Dice.new();c.ensure("player");c.ensure("target")
    var attacker={"id":"player","combat_bonus":30};var target={"id":"target","name":"Тестовая цель","defense":0}
    var hit=c.attack(attacker,target,{"name":"осколок","damage":6.0,"weapon_type":"glass_shard"},d,30)
    assert(bool(hit.get("ok",false)));assert(bool(hit.get("hit",false)));assert(float(c.actor_state["target"]["hp"])<100.0)
    print("SMOKE_V36_PHYSICAL_COMBAT_OK")
    quit(0)
