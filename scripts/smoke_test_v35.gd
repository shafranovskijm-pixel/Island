extends SceneTree
const Variety=preload("res://scripts/world_variety_system.gd")
const Chains=preload("res://scripts/scenario_chain_system.gd")
func _init():
    var v=Variety.new();v.tick(1,6.0,{"hunger":70.0,"unrest":65.0,"crime":60.0,"prosperity":20.0,"vampire_rumors":true,"foreigners":2,"fishing_pressure":1})
    assert(v.weather in ["clear","rain","storm","fog","wind"])
    assert(v.wildlife.has("fish"));assert(v.public_mood.has("fear"))
    v.add_rumor("Тестовый слух","test",.8);assert(v.rumors.size()==1)
    var c=Chains.new();c.ingest({"id":"servant_sees_vampire"},1);assert(c.chains.size()==1)
    c.chains[0]["next_day"]=2
    var out=c.tick(2,[]);assert(out.size()==1);assert(str(out[0].get("chain",""))=="vampire_secret")
    c.ingest({"id":"bread_riot"},2);assert(c.chains.size()>=2)
    print("SMOKE_V35_VARIETY_CHAINS_OK")
    quit(0)
