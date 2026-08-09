extends SceneTree
const Director=preload("res://scripts/emergent_scenario_director.gd")
func _init():
    var d=Director.new()
    var npcs=[
        {"id":"servant","name":"Слуга","alive":true,"rel":3,"role":"слуга","money":0,"memory":[],"stress":0},
        {"id":"guard","name":"Страж","alive":true,"rel":1,"role":"страж","money":2,"memory":[],"stress":0},
        {"id":"vampire","name":"Веспера","alive":true,"rel":4,"role":"дворянка occult","money":10,"memory":[],"stress":0},
        {"id":"priest","name":"Жрец","alive":true,"rel":0,"role":"жрец","money":3,"memory":[],"stress":0},
        {"id":"smuggler","name":"Сайра","alive":true,"rel":1,"role":"контрабандист","money":5,"memory":[],"stress":0}
    ]
    var estate={"residents":["servant","guard","vampire"],"staff":[{"npc_id":"servant","role":"servant"},{"npc_id":"guard","role":"guard"}],"treasury":60.0,"food_store":20.0,"pos":Vector2.ZERO}
    var ctx={"day":10,"hour":21.0,"npcs":npcs,"estate":estate,"castle_level":3,"locked_doors":0,"guards":1,"hunger":70.0,"unrest":70.0,"crime":75.0,"prosperity":20.0,"builders":0,"farmers":1,"tool_shortage":5,"food_market":3.0,"wanted":3,"influence":8,"reputation":6,"player_class":"wealthy","secrets":{"occult_order":true,"vampires":true,"crypt_entrance":true},"is_vampire":true,"blood":15.0,"bat_form":true,"temple_rep":-2,"has_boat":true,"sailing":3,"location":"tavern","player_pos":Vector2.ZERO}
    var candidates:Array=[]
    d._collect_household(ctx,candidates);d._collect_economy(ctx,candidates);d._collect_crime(ctx,candidates);d._collect_social(ctx,candidates);d._collect_occult(ctx,candidates);d._collect_sea(ctx,candidates);d._collect_politics(ctx,candidates)
    assert(candidates.size()>=25)
    var ids:Dictionary={};for c in candidates:ids[str(c["id"])]=true
    for must in ["bread_riot","tavern_brawl","blood_hunger","servant_theft","royal_envoy","drifting_wreck"]:assert(ids.has(must))
    var riot=d._execute({"id":"bread_riot"},ctx);assert(str(riot.get("text",""))!="");assert(float(riot.get("effects",{}).get("unrest",0))>0)
    var theft=d._execute({"id":"servant_theft"},ctx);assert(str(theft.get("text",""))!="");assert(float(estate["treasury"])<60.0)
    print("SMOKE_V34_SCENARIOS_OK candidates=",candidates.size())
    quit(0)
