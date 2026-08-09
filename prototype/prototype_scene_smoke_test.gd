extends SceneTree

const Prototype = preload("res://prototype/prototype_v03.gd")

func _init():
    var p = Prototype.new()

    assert(p.npcs.size() >= 6)
    assert(p.systems.npc_profiles.size() >= 6)

    p.hour = 18.5
    p._apply_npc_schedules(true)
    var bard = _npc_by_id(p, "bard")
    assert(not bard.is_empty())
    assert(str(bard["mood"]) == "поёт")

    p.player = Vector2(720, 535)
    var before_coins = p.coins
    var buy = p.attempt_free_action("купить хлеб")
    assert(bool(buy["ok"]))
    assert(p.coins < before_coins)
    assert(int(p.systems.inventory.get("bread", 0)) == 1)

    p.systems.tick(1, 18.5, {})
    p.player = Vector2(350, 900)
    var sailor = p.attempt_free_action("попроситься матросом")
    assert(bool(sailor["ok"]))
    assert(p.systems.sailor_offer)

    p.hour = 23.0
    var sneak = p.attempt_free_action("пробраться на корабль")
    assert(bool(sneak["ok"]))
    assert(p.systems.boarded_ship)

    p.player = Vector2(50, 50)
    var impossible = p.attempt_free_action("купить хлеб")
    assert(not bool(impossible["ok"]))

    print("PROTOTYPE_V03_SCENE_SMOKE_OK")
    quit(0)

func _npc_by_id(p, npc_id):
    for n in p.npcs:
        if str(n["id"]) == npc_id:
            return n
    return {}
