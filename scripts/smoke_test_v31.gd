extends SceneTree
const Estate=preload("res://scripts/estate_household_system.gd")
const Boats=preload("res://scripts/player_boat_system.gd")
const Vampire=preload("res://scripts/vampire_system.gd")
const Learning=preload("res://scripts/learning_system.gd")
func _init():
    var estate=Estate.new();var e=estate.create_estate("player",Vector2.ZERO,"Тестовый замок");assert(not e.is_empty())
    assert(bool(estate.add_piece(str(e["id"]),"stone_wall").get("ok",false)))
    var npc={"id":"servant","name":"Слуга","alive":true,"rel":3,"money":0,"pos":Vector2.ZERO}
    assert(bool(estate.hire(npc,"servant",3.0).get("ok",false)))
    assert(estate.player_estate()["staff"].size()==1)
    var boats=Boats.new();assert(bool(boats.build_boat("dinghy").get("ok",false)))
    var learning=Learning.new();learning.study_progress["fishing"]=3.0
    assert(bool(boats.fish(learning,1,10.0).get("ok",false)))
    var vamp=Vampire.new();var vespera={"id":"vampire","rel":4};var secrets={"vampires":true}
    assert(bool(vamp.turn(vespera,secrets).get("ok",false)))
    vamp.feed(250.0);assert("bat_form" in vamp.state["abilities"])
    assert(bool(vamp.toggle_bat().get("ok",false)))
    print("SMOKE_V31_LIFESTYLE_OK")
    quit(0)
