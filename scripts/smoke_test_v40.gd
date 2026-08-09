extends SceneTree

const Needs=preload("res://scripts/player_needs_system.gd")
const Animals=preload("res://scripts/animal_ecology_system.gd")

func _init():
    seed(17)
    var needs=Needs.new()
    var hunger_before=float(needs.state["hunger"]);var thirst_before=float(needs.state["thirst"])
    needs.tick(120.0,22.0,"storm",false)
    assert(float(needs.state["hunger"])>hunger_before)
    assert(float(needs.state["thirst"])>thirst_before)
    assert(float(needs.state["warmth"])<60.0)
    needs.eat(40);needs.drink(40);needs.sleep(2,1.0);needs.wash()
    assert(float(needs.state["hunger"])<hunger_before+2)
    assert(float(needs.state["thirst"])<thirst_before+2)
    assert(float(needs.state["hygiene"])==100.0)

    var animals=Animals.new();animals.setup();assert(animals.animals.size()>=5)
    var tamed=false
    for attempt in 10:
        var tame=animals.tame_near(Vector2(650,610),true,20)
        if bool(tame.get("success",false)):tamed=true;break
    assert(tamed)
    var has_player_pet=false
    for a in animals.animals:
        if bool(a.get("tamed",false)) and str(a.get("owner",""))=="player":has_player_pet=true
    assert(has_player_pet)

    var hunted=false
    for attempt in 12:
        var hunt=animals.hunt_near(Vector2(770,620),20)
        if bool(hunt.get("success",false)):hunted=true;assert(float(hunt.get("meat",0))>0);break
    assert(hunted)
    var saved=animals.serialize();var restored=Animals.new();restored.restore(saved);assert(restored.animals.size()==animals.animals.size())
    print("SMOKE_V40_NEEDS_ANIMALS_OK")
    quit(0)
