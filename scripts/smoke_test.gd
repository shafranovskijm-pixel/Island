extends SceneTree

const HistorySystem = preload("res://scripts/history_system.gd")
const NPCSimulation = preload("res://scripts/npc_simulation.gd")
const SocialSystem = preload("res://scripts/social_system.gd")
const AIBridge = preload("res://scripts/ai_bridge.gd")

func _init():
    var history = HistorySystem.new()
    var npc_sim = NPCSimulation.new()
    var social = SocialSystem.new()
    var ai = AIBridge.new()
    var npcs:Array = [
        {"id":"a","name":"А","role":"торговец","pos":Vector2(100,100),"color":Color.WHITE,"rel":0,"memory":[],"suspicion":0},
        {"id":"b","name":"Б","role":"моряк","pos":Vector2(110,105),"color":Color.WHITE,"rel":0,"memory":[],"suspicion":0},
        {"id":"c","name":"В","role":"стражник","pos":Vector2(115,110),"color":Color.WHITE,"rel":0,"memory":[],"suspicion":0}
    ]
    npc_sim.setup(npcs)
    social.setup(npcs)
    history.record(1,8.0,"arrival","Тестовый персонаж появился.",{"homeless":1.0})
    for step in 600:
        var hour := 8.0 + float(step) * 0.02
        var day := 1 + int(hour / 24.0)
        hour = fmod(hour,24.0)
        npcs = npc_sim.tick(npcs,0.2,hour,day)
        npcs = social.tick(npcs,day,hour,0.2)
    history.record(2,10.0,"work","Работал.",{"worker":3.0})
    if npcs.size() != 3:
        _fail("NPC count changed unexpectedly")
        return
    for npc in npcs:
        if not npc.has("traits") or not npc.has("social") or not npc.has("goal"):
            _fail("NPC systemic fields missing: %s" % npc.get("name","?"))
            return
    if social.factions.size() < 4:
        _fail("Faction system missing")
        return
    if history.events.size() < 2:
        _fail("History did not record events")
        return
    var proposal := ai.validate_proposal(ai.local_intention(npcs[0]))
    if not proposal.get("ok",false):
        _fail("AI fallback produced invalid action")
        return
    print("ISLAND_SMOKE_TEST_OK")
    print("NPCS=",npcs.size()," SOCIAL_EVENTS=",social.events.size()," HISTORY=",history.events.size())
    quit(0)

func _fail(text:String):
    push_error("ISLAND_SMOKE_TEST_FAILED: "+text)
    quit(1)
