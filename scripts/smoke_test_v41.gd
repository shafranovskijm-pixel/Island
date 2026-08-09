extends SceneTree

const Livestock=preload("res://scripts/livestock_system.gd")

func _init():
    var farm=Livestock.new()
    assert(bool(farm.buy("chicken").get("ok",false)))
    assert(bool(farm.buy("chicken").get("ok",false)))
    assert(bool(farm.buy("cow").get("ok",false)))
    assert(bool(farm.buy("horse").get("ok",false)))
    assert(farm.livestock.size()==4)
    var food=farm.tick(1,10.0);assert(food==6.0)
    var products=farm.collect_products(1);assert(float(products.get("egg",0))>=2.0);assert(float(products.get("milk",0))>=3.0)
    assert(not farm.first_horse().is_empty())
    assert(bool(farm.breed("chicken").get("ok",false)))
    var before=farm.livestock.size()
    for day in range(2,10):food=farm.tick(day,50.0)
    assert(farm.livestock.size()==before+1)
    var newborn_found=false
    for a in farm.livestock:
        if int(a.get("born_day",-1))==9 and str(a.get("species",""))=="chicken":newborn_found=true
    assert(newborn_found)
    var saved=farm.serialize();var restored=Livestock.new();restored.restore(saved);assert(restored.livestock.size()==farm.livestock.size())
    print("SMOKE_V41_LIVESTOCK_OK")
    quit(0)
