extends RefCounted

var world_events: Array = []
var rng := RandomNumberGenerator.new()

func setup(npcs: Array):
    rng.randomize()
    for i in npcs.size():
        var npc = npcs[i]
        npc["traits"] = {
            "greed": rng.randf_range(0.1, 1.0),
            "sociability": rng.randf_range(0.1, 1.0),
            "lawfulness": rng.randf_range(0.1, 1.0),
            "curiosity": rng.randf_range(0.1, 1.0),
            "drink_tendency": rng.randf_range(0.0, 1.0)
        }
        npc["needs"] = {"hunger": rng.randf_range(0,35), "fatigue": rng.randf_range(0,25), "social": rng.randf_range(0,40)}
        npc["money"] = rng.randi_range(2,15)
        npc["state"] = "idle"
        npc["target"] = npc["pos"]
        npc["home"] = _home_for(i)
        npc["work"] = npc["pos"]
        npc["goal"] = _goal_for(npc)
        npcs[i] = npc

func _home_for(index: int) -> Vector2:
    var homes = [Vector2(560,760),Vector2(1040,760),Vector2(1380,790),Vector2(360,760),Vector2(870,180)]
    return homes[index % homes.size()]

func _goal_for(npc: Dictionary) -> String:
    match npc["id"]:
        "marek": return "накопить деньги и расширить торговлю"
        "lissa": return "найти богатую цель для крупной кражи"
        "kraken": return "собрать новую морскую команду"
        "thomas": return "купить лучшую сеть"
        "endar": return "найти следы древнего знания"
    return "прожить ещё один день"

func tick(npcs: Array, delta: float, hour: float, day: int) -> Array:
    var sim_hours := delta * 0.10
    for i in npcs.size():
        var npc = npcs[i]
        npc["needs"]["hunger"] = min(100.0, npc["needs"]["hunger"] + sim_hours * 6.0)
        npc["needs"]["fatigue"] = min(100.0, npc["needs"]["fatigue"] + sim_hours * 4.0)
        npc["needs"]["social"] = min(100.0, npc["needs"]["social"] + sim_hours * 3.0)
        _choose_state(npc, hour)
        _move_toward_target(npc, delta)
        _resolve_need(npc, day, hour)
        npcs[i] = npc
    return npcs

func _choose_state(npc: Dictionary, hour: float):
    var needs: Dictionary = npc["needs"]
    if needs["fatigue"] > 78.0 or hour < 6.0:
        npc["state"] = "sleeping"
        npc["target"] = npc["home"]
    elif needs["hunger"] > 70.0:
        npc["state"] = "seeking_food"
        npc["target"] = Vector2(1500,860)
    elif needs["social"] > 72.0 or (hour > 19.0 and float(npc["traits"]["sociability"]) > 0.55):
        npc["state"] = "tavern"
        npc["target"] = Vector2(1500,860)
    elif hour >= 7.0 and hour <= 18.0:
        npc["state"] = "working"
        npc["target"] = npc["work"]
    else:
        npc["state"] = "going_home"
        npc["target"] = npc["home"]

func _move_toward_target(npc: Dictionary, delta: float):
    var pos: Vector2 = npc["pos"]
    var target: Vector2 = npc["target"]
    var d := target - pos
    if d.length() > 8.0:
        pos += d.normalized() * 70.0 * delta
        npc["pos"] = pos

func _resolve_need(npc: Dictionary, day: int, hour: float):
    if npc["pos"].distance_to(npc["target"]) > 18.0:
        return
    match npc["state"]:
        "sleeping":
            npc["needs"]["fatigue"] = max(0.0, npc["needs"]["fatigue"] - 2.2)
        "seeking_food":
            if npc["money"] > 0:
                npc["money"] -= 1
                npc["needs"]["hunger"] = max(0.0, npc["needs"]["hunger"] - 55.0)
                _log(day,hour,"%s купил еду." % npc["name"])
        "tavern":
            npc["needs"]["social"] = max(0.0, npc["needs"]["social"] - 40.0)
            if npc["money"] > 0 and float(npc["traits"]["drink_tendency"]) > 0.55:
                npc["money"] -= 1
                _log(day,hour,"%s выпил в таверне." % npc["name"])

func _log(day: int, hour: float, text: String):
    if world_events.size() > 40:
        world_events.pop_front()
    if world_events.is_empty() or world_events.back().get("text","") != text:
        world_events.append({"day":day,"hour":hour,"text":text})

func recent_events(limit: int = 5) -> Array:
    var result: Array = []
    var start := maxi(0, world_events.size() - limit)
    for i in range(start, world_events.size()):
        result.append(world_events[i])
    return result
