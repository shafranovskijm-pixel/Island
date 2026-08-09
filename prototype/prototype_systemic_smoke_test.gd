extends SceneTree

const Systems = preload("res://prototype/prototype_systems.gd")

func _init():
    var s = Systems.new()

    assert(s.npc_profiles.size() >= 6)
    assert(s.factions.has("village"))
    assert(s.factions.has("guard"))
    assert(s.factions.has("dockers"))
    assert(int(s.relationships["innkeeper"]) == 0)

    s.tick(1, 17.0, {})
    assert(not s.ship_arrived)
    assert(s.current_price("bread") == 4)

    var away_buy = s.resolve_action("купить хлеб", {"near_npc":"", "coins":12, "hour":17.0, "near_dock":false})
    assert(not bool(away_buy["ok"]))
    assert(int(s.inventory.get("bread", 0)) == 0)

    var tavern_buy = s.resolve_action("купить хлеб", {"near_npc":"innkeeper", "coins":12, "hour":17.0, "near_dock":false})
    assert(bool(tavern_buy["ok"]))
    assert(int(tavern_buy["coin_delta"]) == -4)
    assert(int(s.inventory.get("bread", 0)) == 1)
    assert(int(s.market["bread_stock"]) == 6)

    s.record_talk("hunter")
    s.record_talk("hunter")
    s.record_talk("hunter")
    var bio = s.biography_line("hunter")
    assert(str(bio).find("Остромир") >= 0)

    s.tick(1, 18.5, {})
    assert(s.ship_arrived)
    assert(s.current_price("bread") == 3)
    var world_line = s.npc_world_line("innkeeper", {})
    assert(world_line.find("корабль") >= 0)
    assert(s.npc_world_line("bard", {}) == "")

    var sailor = s.resolve_action("попроситься матросом", {"near_npc":"", "coins":8, "hour":18.5, "near_dock":true})
    assert(bool(sailor["ok"]))
    assert(s.sailor_offer)
    assert(int(s.skills["seamanship"]) == 1)
    assert(int(s.factions["dockers"]) == 5)

    var sneak = s.resolve_action("пробраться на корабль", {"near_npc":"", "coins":8, "hour":23.0, "near_dock":true})
    assert(bool(sneak["ok"]))
    assert(s.boarded_ship)
    assert(int(s.skills["sneak"]) >= 2)

    var theft = s.resolve_action("украсть хлеб", {"near_npc":"innkeeper", "coins":8, "hour":12.0, "near_dock":false})
    assert(not bool(theft["ok"]))
    assert(s.heat >= 1)
    assert(int(s.relationships["innkeeper"]) < 0)
    assert(int(s.factions["village"]) < 0)

    var bribe = s.resolve_action("дать взятку стражнику", {"near_npc":"guard", "coins":20, "hour":12.0, "near_dock":false})
    assert(bool(bribe["ok"]))
    assert(int(bribe["coin_delta"]) < 0)
    assert(s.heat == 0)

    var beg = s.resolve_action("попросить милостыню", {"near_npc":"villager", "coins":0, "hour":12.0, "near_dock":false})
    assert(bool(beg["ok"]))
    assert(int(beg["coin_delta"]) == 1)
    var beg_again = s.resolve_action("попросить милостыню", {"near_npc":"villager", "coins":0, "hour":12.0, "near_dock":false})
    assert(not bool(beg_again["ok"]))

    print("PROTOTYPE_SYSTEMIC_SMOKE_OK")
    quit(0)
