extends SceneTree

const Systems = preload("res://prototype/prototype_systems_v04.gd")
const Prototype = preload("res://prototype/prototype_v04.gd")

func _init():
    var s = Systems.new()

    var tavern_context = {
        "near_npc": "innkeeper",
        "coins": 12,
        "hour": 17.0,
        "location": "tavern",
        "near_dock": false,
        "near_tracks": false,
        "tracks_found": false,
        "near_campfire": false,
        "campfire_lit": false,
    }
    s.tick(1, 17.0, {})
    var tavern_actions = s.suggest_actions(tavern_context)
    assert(tavern_actions.has("купить хлеб"))
    assert(tavern_actions.has("спросить о прошлом"))
    assert(not tavern_actions.has("попроситься матросом"))

    var look_tavern = s.resolve_action("осмотреться", tavern_context)
    assert(bool(look_tavern["ok"]))
    assert(str(look_tavern["message"]).find("трактир") >= 0)

    var buy = s.resolve_action("купить хлеб", tavern_context)
    assert(bool(buy["ok"]))
    assert(s.action_events.size() >= 2)
    var village_reaction = s.npc_world_line("villager", {})
    assert(village_reaction.find("хлеб") >= 0)

    s.tick(1, 18.5, {})
    var dock_context = {
        "near_npc": "",
        "coins": 8,
        "hour": 18.5,
        "location": "dock",
        "near_dock": true,
        "near_tracks": false,
        "tracks_found": false,
        "near_campfire": false,
        "campfire_lit": false,
    }
    var dock_actions = s.suggest_actions(dock_context)
    assert(dock_actions.has("попроситься матросом"))
    assert(dock_actions.has("пробраться на корабль"))

    var sailor = s.resolve_action("попроситься матросом", dock_context)
    assert(bool(sailor["ok"]))
    assert(s.sailor_offer)
    var ship_news = s.npc_world_line("bard", {})
    assert(ship_news.find("корабль") >= 0)
    var sailor_reaction = s.npc_world_line("bard", {})
    assert(sailor_reaction.find("работу") >= 0)

    var theft_context = tavern_context.duplicate(true)
    theft_context["hour"] = 12.0
    var theft = s.resolve_action("украсть хлеб", theft_context)
    assert(not bool(theft["ok"]))
    assert(s.heat >= 1)
    assert(str(s.action_events[s.action_events.size() - 1]["action"]).find("украсть") >= 0)
    var heat_warning = s.npc_world_line("guard", {})
    assert(heat_warning.find("шум") >= 0 or heat_warning.find("выходка") >= 0)
    var theft_reaction = s.npc_world_line("guard", {})
    assert(theft_reaction.find("воров") >= 0)

    var p = Prototype.new()
    assert(p.systems.has_method("suggest_actions"))
    p.player = Vector2(720, 535)
    var live_tavern_context = p._action_context()
    assert(str(live_tavern_context["location"]) == "tavern")
    assert(str(live_tavern_context["near_npc"]) == "innkeeper")

    p.systems.tick(1, 19.0, {})
    p.player = Vector2(350, 900)
    var live_dock_context = p._action_context()
    assert(str(live_dock_context["location"]) == "dock")
    assert(bool(live_dock_context["near_dock"]))
    assert(p.systems.suggest_actions(live_dock_context).has("попроситься матросом"))

    print("PROTOTYPE_V04_CONTEXT_SMOKE_OK")
    quit(0)
