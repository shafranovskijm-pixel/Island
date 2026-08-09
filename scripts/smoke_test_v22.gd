extends SceneTree

const HousingSystem=preload("res://scripts/housing_system.gd")
const HealthLifecycle=preload("res://scripts/health_lifecycle.gd")
const ProductionEconomy=preload("res://scripts/production_economy.gd")

func _init():
    var housing=HousingSystem.new();housing.setup()
    assert(housing.homes.size()>=5)
    var npcs=[
        {"id":"a","name":"A","alive":true,"money":100.0,"stress":0.0,"social_class":"comfortable","employment_property":"","pos":Vector2.ZERO},
        {"id":"b","name":"B","alive":true,"money":0.0,"stress":20.0,"social_class":"poor","employment_property":"","pos":Vector2.ZERO}
    ]
    npcs=housing.tick(npcs,1,9.0)
    assert(str(npcs[0].get("home_id",""))!="")
    assert(bool(npcs[1].get("homeless",false)) or str(npcs[1].get("home_id",""))!="")
    var production=ProductionEconomy.new();production.hunger_pressure=0.0;production.resources["medicine"]=5.0
    var life=HealthLifecycle.new();npcs=life.tick(npcs,production,2,7.0)
    assert(npcs[0].has("health"))
    print("V22 HOUSING/HEALTH SMOKE TEST OK")
    quit(0)
