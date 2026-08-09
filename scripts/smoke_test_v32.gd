extends SceneTree
const Castle=preload("res://scripts/castle_builder.gd")
const Estate=preload("res://scripts/estate_household_system.gd")
const Household=preload("res://scripts/household_social_system.gd")
func _init():
    var estate=Estate.new();var e=estate.create_estate("player",Vector2.ZERO,"Дом")
    var castle=Castle.new()
    for i in 8:
        assert(bool(castle.place("stone_wall",Vector2(i*32,0),str(e["id"])).get("ok",false)))
    assert(bool(castle.place("wooden_door",Vector2(0,32),str(e["id"])).get("ok",false)))
    var stats=castle.stats(str(e["id"]));assert(int(stats["castle_level"])>=1)
    var a={"id":"a","name":"А","alive":true,"rel":3,"jealousy":80,"stress":0,"memory":[],"pos":Vector2.ZERO}
    var b={"id":"b","name":"Б","alive":true,"rel":3,"jealousy":0,"stress":0,"memory":[],"pos":Vector2.ZERO}
    estate.estates[0]["residents"]=["a","b"];estate.estates[0]["food_store"]=10.0
    var npcs=[a,b];var household=Household.new();var feast=household.feast(npcs,estate.estates[0]);assert(bool(feast.get("ok",false)))
    assert(float(estate.estates[0]["food_store"])==2.0)
    print("SMOKE_V32_CASTLE_HOUSEHOLD_OK")
    quit(0)
