extends RefCounted

var rng := RandomNumberGenerator.new()
var events: Array = []
var factions := {
    "council": {"name":"Совет острова","power":55.0,"wealth":65.0,"approval":50.0},
    "merchants": {"name":"Гильдия торговцев","power":45.0,"wealth":80.0,"approval":48.0},
    "guard": {"name":"Стража","power":60.0,"wealth":35.0,"approval":52.0},
    "underworld": {"name":"Подполье","power":28.0,"wealth":35.0,"approval":20.0},
    "temple": {"name":"Храм","power":32.0,"wealth":40.0,"approval":57.0}
}

func setup(npcs: Array):
    rng.randomize()
    for i in npcs.size():
        var npc = npcs[i]
        npc["age"] = rng.randi_range(19,62)
        npc["traits"] = npc.get("traits", {})
        npc["traits"].merge({
            "ambition":rng.randf(), "romantic":rng.randf(), "jealousy":rng.randf(),
            "greed":rng.randf(), "loyalty":rng.randf(), "aggression":rng.randf(),
            "honesty":rng.randf(), "lust":rng.randf(), "addiction":rng.randf(),
            "political":rng.randf(), "empathy":rng.randf(), "courage":rng.randf()
        }, true)
        npc["vice"] = _vice(npc)
        npc["faction"] = _faction_for(npc.get("id",""))
        npc["influence"] = rng.randf_range(0.0,15.0)
        npc["stress"] = rng.randf_range(0.0,25.0)
        npc["partner"] = ""
        npc["secrets"] = []
        npc["social"] = {}
        npcs[i] = npc
    _seed_relations(npcs)

func _vice(npc: Dictionary) -> String:
    var a: float = npc["traits"]["addiction"]
    var g: float = npc["traits"]["greed"]
    var l: float = npc["traits"]["lust"]
    if a > 0.72: return "алкоголь"
    if g > 0.78: return "жадность"
    if l > 0.78: return "похоть"
    if npc["traits"]["ambition"] > 0.82: return "власть"
    return ""

func _faction_for(id: String) -> String:
    match id:
        "marek": return "merchants"
        "lissa": return "underworld"
        "kraken": return "underworld"
        "thomas": return ""
        "endar": return "temple"
    return ""

func _seed_relations(npcs: Array):
    for i in npcs.size():
        for j in npcs.size():
            if i == j: continue
            var npc = npcs[i]
            npc["social"][npcs[j]["id"]] = {
                "friendship":rng.randf_range(-15,30), "trust":rng.randf_range(5,45),
                "respect":rng.randf_range(0,40), "fear":rng.randf_range(0,20),
                "attraction":rng.randf_range(0,45), "love":0.0, "jealousy":0.0,
                "resentment":rng.randf_range(0,12), "debt":0.0
            }
            npcs[i] = npc

func tick(npcs: Array, day: int, hour: float, delta: float) -> Array:
    var chance := delta * 0.08
    for i in npcs.size():
        var npc = npcs[i]
        npc["stress"] = clampf(float(npc["stress"]) + delta * 0.03, 0.0, 100.0)
        _vice_tick(npc, delta)
        npcs[i] = npc
    for i in npcs.size():
        for j in range(i + 1, npcs.size()):
            if npcs[i]["pos"].distance_to(npcs[j]["pos"]) < 95.0 and rng.randf() < chance:
                _meeting(npcs, i, j, day, hour)
    if hour > 11.9 and hour < 12.1 and rng.randf() < delta * 0.5:
        _politics_tick(npcs, day, hour)
    return npcs

func _meeting(npcs: Array, a: int, b: int, day: int, hour: float):
    var left = npcs[a]
    var right = npcs[b]
    var lr: Dictionary = left["social"][right["id"]]
    var rl: Dictionary = right["social"][left["id"]]
    var compatibility := (float(left["traits"]["empathy"]) + float(right["traits"]["empathy"])) * 0.5
    lr["friendship"] += rng.randf_range(-2.5,4.0) + compatibility
    rl["friendship"] += rng.randf_range(-2.5,4.0) + compatibility
    lr["trust"] += rng.randf_range(-1.0,2.0)
    rl["trust"] += rng.randf_range(-1.0,2.0)
    if float(lr["attraction"]) > 38.0 and float(lr["friendship"]) > 24.0:
        lr["love"] += rng.randf_range(0.2,1.5) * (0.4 + float(left["traits"]["romantic"]))
    if float(rl["attraction"]) > 38.0 and float(rl["friendship"]) > 24.0:
        rl["love"] += rng.randf_range(0.2,1.5) * (0.4 + float(right["traits"]["romantic"]))
    left["social"][right["id"]] = lr
    right["social"][left["id"]] = rl
    if left["partner"] == "" and right["partner"] == "" and float(lr["love"]) > 35.0 and float(rl["love"]) > 35.0:
        left["partner"] = right["id"]
        right["partner"] = left["id"]
        _log(day,hour,"%s и %s начали отношения." % [left["name"],right["name"]])
    elif (float(lr["resentment"]) > 35.0 or float(rl["resentment"]) > 35.0) and rng.randf() < 0.15:
        left["stress"] += 5.0; right["stress"] += 5.0
        _log(day,hour,"%s и %s крупно поссорились." % [left["name"],right["name"]])
    npcs[a] = left; npcs[b] = right

func _vice_tick(npc: Dictionary, delta: float):
    if npc["vice"] == "алкоголь" and float(npc["stress"]) > 45.0:
        npc["stress"] = maxf(0.0, float(npc["stress"]) - delta * 0.15)
        npc["money"] = max(0, int(npc.get("money",0)) - int(rng.randf() < delta * 0.015))
    elif npc["vice"] == "власть":
        npc["influence"] = minf(100.0, float(npc["influence"]) + delta * 0.008)

func _politics_tick(npcs: Array, day: int, hour: float):
    var candidate := -1
    var score := -1.0
    for i in npcs.size():
        var s := float(npcs[i]["traits"]["ambition"]) * 50.0 + float(npcs[i]["influence"])
        if s > score: score = s; candidate = i
    if candidate >= 0 and score > 45.0 and rng.randf() < 0.20:
        var npc = npcs[candidate]
        npc["influence"] += rng.randf_range(2.0,7.0)
        factions["council"]["approval"] = clampf(float(factions["council"]["approval"]) + rng.randf_range(-4,3),0,100)
        npcs[candidate] = npc
        _log(day,hour,"%s усилил своё влияние в политике острова." % npc["name"])

func alter_relation(npcs: Array, from_id: String, to_id: String, field: String, amount: float):
    for i in npcs.size():
        if npcs[i]["id"] == from_id and npcs[i]["social"].has(to_id):
            var r: Dictionary = npcs[i]["social"][to_id]
            r[field] = float(r.get(field,0.0)) + amount
            npcs[i]["social"][to_id] = r

func _log(day:int, hour:float, text:String):
    if events.size() > 120: events.pop_front()
    events.append({"day":day,"hour":hour,"text":text})

func recent_events(limit:int=6) -> Array:
    var out:Array=[]
    for i in range(maxi(0,events.size()-limit),events.size()): out.append(events[i])
    return out
