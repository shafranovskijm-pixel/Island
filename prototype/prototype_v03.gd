extends "res://prototype/prototype_v02.gd"

const SliceSystems = preload("res://prototype/prototype_systems.gd")
const DOCK_AREA = Rect2(150, 820, 460, 260)

var systems = SliceSystems.new()
var free_action_input
var free_action_button
var systemic_message = ""
var systemic_message_time = 0.0
var last_schedule_slot = ""

func _ready():
    super._ready()
    systems.tick(day, hour, _world_flags())
    _build_free_action_ui()
    _apply_npc_schedules(true)
    systemic_message = "Можно писать действие своими словами: «купить хлеб», «спросить о прошлом», «попроситься матросом»."
    systemic_message_time = 10.0
    queue_redraw()

func _process(delta):
    systems.tick(day, hour, _world_flags())
    super._process(delta)
    systemic_message_time = maxf(0.0, systemic_message_time - delta)
    _layout_free_action_ui()

func _update_npcs(delta):
    _apply_npc_schedules(false)
    super._update_npcs(delta)

func _apply_npc_schedules(force):
    var slot = _schedule_slot()
    if not force and slot == last_schedule_slot:
        return
    last_schedule_slot = slot
    for n in npcs:
        var id = str(n["id"])
        var destination = _schedule_destination(id, slot)
        n["home"] = destination
        n["target"] = destination
        n["mood"] = _schedule_mood(id, slot)

func _schedule_slot():
    if hour >= 5.0 and hour < 11.0:
        return "morning"
    if hour >= 11.0 and hour < 17.0:
        return "day"
    if hour >= 17.0 and hour < 23.0:
        return "evening"
    return "night"

func _schedule_destination(id, slot):
    var schedule = {
        "innkeeper": {
            "morning": Vector2(690, 520), "day": Vector2(720, 535), "evening": Vector2(720, 535), "night": Vector2(680, 500)
        },
        "bard": {
            "morning": Vector2(565, 650), "day": Vector2(430, 825), "evening": Vector2(785, 555), "night": Vector2(770, 535)
        },
        "guard": {
            "morning": Vector2(960, 410), "day": Vector2(525, 800), "evening": Vector2(875, 520), "night": Vector2(1010, 430)
        },
        "hunter": {
            "morning": Vector2(1180, 690), "day": Vector2(1370, 720), "evening": Vector2(830, 610), "night": Vector2(1080, 670)
        },
        "volkhv": {
            "morning": Vector2(1370, 360), "day": Vector2(1460, 520), "evening": Vector2(1320, 420), "night": Vector2(1430, 330)
        },
        "villager": {
            "morning": Vector2(555, 665), "day": Vector2(600, 760), "evening": Vector2(650, 650), "night": Vector2(510, 640)
        },
    }
    var row = schedule.get(id, {})
    return row.get(slot, Vector2(700, 600))

func _schedule_mood(id, slot):
    if id == "guard":
        return "патрулирует" if slot in ["day", "evening"] else "на посту"
    if id == "hunter":
        return "ищет следы" if slot in ["morning", "day"] else "греется"
    if id == "bard":
        return "поёт" if slot == "evening" else "слушает слухи"
    if id == "innkeeper":
        return "разливает" if slot == "evening" else "считает запасы"
    if id == "volkhv":
        return "наблюдает" if slot == "night" else "собирает травы"
    return "занята делами"

func _talk(n):
    var npc_id = str(n["id"])
    systems.record_talk(npc_id)
    super._talk(n)
    var extra = systems.npc_world_line(npc_id, _world_flags())
    if extra != "":
        systemic_message = extra
        systemic_message_time = 9.0
    queue_redraw()

func attempt_free_action(text):
    systems.tick(day, hour, _world_flags())
    var near_index = _nearest_npc(115.0)
    var near_npc = ""
    if near_index >= 0:
        near_npc = str(npcs[near_index]["id"])
    var context = {
        "coins": coins,
        "hour": hour,
        "near_npc": near_npc,
        "near_dock": DOCK_AREA.grow(65.0).has_point(player),
        "near_tracks": rumor_heard and player.distance_to(hunter_tracks["pos"]) < 105.0,
        "tracks_found": bool(hunter_tracks["found"]),
        "brawl": tavern_brawl,
        "held_item": held_item,
    }
    var result = systems.resolve_action(text, context)
    coins = maxi(0, coins + int(result.get("coin_delta", 0)))
    systemic_message = str(result.get("message", ""))
    systemic_message_time = 10.0
    if free_action_input != null:
        free_action_input.text = ""
    queue_redraw()
    return result

func _world_flags():
    return {
        "brawl": tavern_brawl,
        "tracks_found": bool(hunter_tracks["found"]),
        "dog_friend": dog_friend,
        "campfire_lit": campfire_lit,
    }

func _build_free_action_ui():
    free_action_input = LineEdit.new()
    free_action_input.placeholder_text = "Что ты пытаешься сделать?"
    free_action_input.max_length = 96
    free_action_input.clear_button_enabled = true
    free_action_input.text_submitted.connect(_on_free_action_submitted)
    add_child(free_action_input)

    free_action_button = Button.new()
    free_action_button.text = "ПОПРОБОВАТЬ"
    free_action_button.pressed.connect(_on_free_action_pressed)
    add_child(free_action_button)
    _layout_free_action_ui()

func _layout_free_action_ui():
    if free_action_input == null or free_action_button == null:
        return
    var s = get_viewport_rect().size
    var input_x = 215.0
    var input_width = maxf(210.0, s.x - 760.0)
    free_action_input.position = Vector2(input_x, s.y - 58.0)
    free_action_input.size = Vector2(input_width, 44.0)
    free_action_button.position = Vector2(input_x + input_width + 8.0, s.y - 58.0)
    free_action_button.size = Vector2(150.0, 44.0)

func _on_free_action_submitted(text):
    attempt_free_action(text)
    if free_action_input != null:
        free_action_input.release_focus()

func _on_free_action_pressed():
    if free_action_input != null:
        attempt_free_action(free_action_input.text)
        free_action_input.release_focus()

func _draw_world(cam):
    super._draw_world(cam)
    _draw_dock(cam)
    _draw_relationship_marks(cam)

func _draw_dock(cam):
    var water = Rect2(Vector2(80, 900) - cam, Vector2(610, 200))
    draw_rect(water, Color("#365765"))
    for x in range(190, 570, 45):
        draw_rect(Rect2(Vector2(x, 855) - cam, Vector2(32, 120)), Color("#70563d"))
    draw_string(ThemeDB.fallback_font, Vector2(210, 840) - cam, "СТАРЫЙ ПРИЧАЛ", HORIZONTAL_ALIGNMENT_LEFT, 180, 13, Color("#e3d4ad"))
    if systems.ship_arrived:
        var hull = Rect2(Vector2(300, 955) - cam, Vector2(250, 55))
        draw_rect(hull, Color("#49372d"))
        draw_rect(Rect2(Vector2(395, 870) - cam, Vector2(7, 95)), Color("#352b27"))
        draw_line(Vector2(399, 875) - cam, Vector2(480, 945) - cam, Color("#c6b990"), 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(320, 1030) - cam, "торговый корабль", HORIZONTAL_ALIGNMENT_LEFT, 200, 10, Color.WHITE)
    else:
        draw_string(ThemeDB.fallback_font, Vector2(285, 980) - cam, "причал пуст", HORIZONTAL_ALIGNMENT_LEFT, 150, 10, Color("#b9c5c8"))

func _draw_relationship_marks(cam):
    for n in npcs:
        var npc_id = str(n["id"])
        var rel = int(systems.relationships.get(npc_id, 0))
        var p = n["pos"] - cam + Vector2(-20, -31)
        draw_rect(Rect2(p, Vector2(40, 3)), Color(0.08, 0.08, 0.08, 0.7))
        if rel != 0:
            var width = minf(20.0, absf(float(rel)) / 5.0)
            var start_x = 20.0 if rel > 0 else 20.0 - width
            var mark_color = Color("#85b77c") if rel > 0 else Color("#b46d67")
            draw_rect(Rect2(p + Vector2(start_x, 0), Vector2(width, 3)), mark_color)

func _draw_hud(s):
    super._draw_hud(s)
    var panel = Rect2(s.x - 350.0, 50.0, 330.0, 112.0)
    draw_rect(panel, Color(0.035, 0.04, 0.045, 0.90))
    draw_rect(panel, Color("#63736a"), false, 1.0)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 22), "Мир реагирует на тебя", HORIZONTAL_ALIGNMENT_LEFT, 300, 12, Color.WHITE)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 44), "Стража %d · деревня %d · докеры %d" % [int(systems.factions["guard"]), int(systems.factions["village"]), int(systems.factions["dockers"])], HORIZONTAL_ALIGNMENT_LEFT, 305, 10, Color("#d2d9d2"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 64), "Розыск %d · скрытность %d · море %d" % [systems.heat, int(systems.skills["sneak"]), int(systems.skills["seamanship"])], HORIZONTAL_ALIGNMENT_LEFT, 305, 10, Color("#d2d9d2"))
    var bag = "хлеб %d · пиво %d" % [int(systems.inventory.get("bread", 0)), int(systems.inventory.get("beer", 0))]
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 84), "Сумка: %s" % bag, HORIZONTAL_ALIGNMENT_LEFT, 305, 10, Color("#e4cc9c"))
    var ship_text = "корабль у причала" if systems.ship_arrived else "корабль ещё не пришёл"
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 104), ship_text, HORIZONTAL_ALIGNMENT_LEFT, 305, 10, Color("#a9c3cc"))

    if systemic_message_time > 0.0 and systemic_message != "":
        var msg_panel = Rect2(500.0, 14.0, maxf(260.0, s.x - 880.0), 100.0)
        draw_rect(msg_panel, Color(0.04, 0.035, 0.025, 0.92))
        draw_rect(msg_panel, Color("#8a7658"), false, 1.0)
        var lines = _wrap_message(systemic_message, 52)
        for i in range(mini(lines.size(), 4)):
            draw_string(ThemeDB.fallback_font, msg_panel.position + Vector2(12, 22 + i * 19), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, msg_panel.size.x - 24.0, 10, Color("#f0dfbd"))

func _wrap_message(text, max_chars):
    var words = str(text).split(" ")
    var lines = []
    var current = ""
    for word in words:
        var candidate = str(word) if current == "" else current + " " + str(word)
        if candidate.length() > max_chars and current != "":
            lines.append(current)
            current = str(word)
        else:
            current = candidate
    if current != "":
        lines.append(current)
    return lines
