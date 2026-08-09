extends "res://prototype/prototype_v04.gd"

const VISUAL_PROFILE = "island_painterly_mobile_v2"
const WORLD_ART_CHUNKS = [
    "res://prototype/art/runtime/world_webp_00.b64",
    "res://prototype/art/runtime/world_webp_01.b64",
    "res://prototype/art/runtime/world_webp_02.b64",
    "res://prototype/art/runtime/world_webp_03.b64",
    "res://prototype/art/runtime/world_webp_04.b64",
]
const PLAYER_ART_CHUNKS = [
    "res://prototype/art/runtime/player_png_00.b64",
]

var world_art: Texture2D
var player_art: Texture2D
var visual_time := 0.0
var last_art_error := ""

func _ready():
    super._ready()
    world_art = _load_embedded_texture(WORLD_ART_CHUNKS, "webp")
    player_art = _load_embedded_texture(PLAYER_ART_CHUNKS, "png")
    _align_gameplay_to_art()
    _style_mobile_ui()
    _layout_free_action_ui()
    systemic_message = "Это уже игровой арт-проход: двигайся джойстиком, говори с людьми и используй УДАР / ДЕЙСТВИЕ."
    systemic_message_time = 10.0
    queue_redraw()

func _process(delta):
    visual_time += delta
    super._process(delta)
    player.x = clampf(player.x, 135.0, 1145.0)
    player.y = clampf(player.y, 110.0, 545.0)
    queue_redraw()

func _update_npcs(_delta):
    # В этом art vertical slice персонажи стоят там, где они нарисованы на фоне.
    # Механика взаимодействий остаётся реальной, но визуальные двойники не появляются.
    pass

func _update_dog(_delta):
    pass

func _camera():
    return Vector2.ZERO

func _align_gameplay_to_art():
    player = Vector2(641, 342)
    hour = 20.9
    coins = 12

    var positions = {
        "innkeeper": Vector2(291, 232),
        "bard": Vector2(470, 202),
        "guard": Vector2(585, 174),
        "hunter": Vector2(470, 324),
        "volkhv": Vector2(836, 126),
        "villager": Vector2(214, 318),
    }
    for n in npcs:
        var id = str(n["id"])
        if positions.has(id):
            n["pos"] = positions[id]
            n["home"] = positions[id]
            n["target"] = positions[id]
            n["mood"] = ""

    camp["pos"] = Vector2(858, 482)
    hunter_tracks["pos"] = Vector2(1010, 440)
    dog["pos"] = Vector2(-400, -400)
    dog["target"] = dog["pos"]
    bottle["pos"] = Vector2(-400, -400)

func _load_embedded_texture(paths, codec):
    var encoded := ""
    for path in paths:
        if not FileAccess.file_exists(path):
            last_art_error = "Нет файла: %s" % path
            return null
        encoded += FileAccess.get_file_as_string(path).strip_edges()

    var bytes = Marshalls.base64_to_raw(encoded)
    if bytes.is_empty():
        last_art_error = "Не удалось декодировать art asset"
        return null

    var image = Image.new()
    var err = ERR_INVALID_DATA
    if codec == "webp":
        err = image.load_webp_from_buffer(bytes)
    elif codec == "png":
        err = image.load_png_from_buffer(bytes)
    else:
        last_art_error = "Неизвестный формат: %s" % codec
        return null

    if err != OK:
        last_art_error = "Ошибка загрузки %s: %s" % [codec, err]
        return null
    return ImageTexture.create_from_image(image)

func _draw_world(_cam):
    var s = get_viewport_rect().size
    if world_art != null:
        draw_texture_rect(world_art, Rect2(Vector2.ZERO, s), false)
    else:
        super._draw_world(Vector2.ZERO)
        _draw_world_tag(Vector2(420, 120), "ART ASSET ERROR: %s" % last_art_error, Color("#ffb7a0"))

    _draw_live_campfire()
    _draw_live_player()
    _draw_time_tint(s)

func _draw_live_player():
    var shadow_center = player + Vector2(0, 25)
    _draw_ellipse(shadow_center, Vector2(20, 7), Color(0.01, 0.015, 0.01, 0.42))
    draw_arc(player + Vector2(0, 8), 24.0 + sin(visual_time * 3.0) * 1.4, 0.0, TAU, 36, Color(0.95, 0.70, 0.29, 0.60), 2.0)

    if player_art != null:
        var target = Rect2(player - Vector2(21, 52), Vector2(42, 77))
        draw_texture_rect(player_art, target, false)
    else:
        _draw_person(player, "герой", "", true)

    if held_item != "":
        _draw_world_tag(player + Vector2(24, 24), held_item, Color("#f0d59e"))

func _draw_live_campfire():
    if not campfire_lit:
        return
    var cp = camp["pos"]
    var pulse = 1.0 + sin(visual_time * 6.0) * 0.08
    draw_circle(cp, 44.0 * pulse, Color(1.0, 0.45, 0.12, 0.10))
    draw_circle(cp - Vector2(0, 4), 12.0 * pulse, Color(0.94, 0.33, 0.10, 0.82))
    draw_circle(cp - Vector2(0, 10), 7.0 * pulse, Color(1.0, 0.72, 0.24, 0.92))

func _draw_time_tint(s):
    var alpha := 0.0
    if hour >= 22.0:
        alpha = clampf((hour - 22.0) / 8.0, 0.0, 0.16)
    elif hour < 5.0:
        alpha = clampf((5.0 - hour) / 5.0, 0.0, 0.14)
    if alpha > 0.0:
        draw_rect(Rect2(Vector2.ZERO, s), Color(0.02, 0.04, 0.10, alpha))

func _draw_hud(s):
    _draw_live_status_panels(s)
    _draw_live_message(s)
    _draw_joystick_feedback(s)

func _draw_live_status_panels(s):
    var day_panel = Rect2(300, 8, 330, 66)
    draw_rect(day_panel, Color(0.025, 0.025, 0.022, 0.90))
    draw_rect(day_panel, Color("#8d7658"), false, 1.0)
    draw_string(ThemeDB.fallback_font, day_panel.position + Vector2(14, 24), "День %d  ·  %02d:%02d  ·  монеты: %d" % [day, int(hour), int(fmod(hour, 1.0) * 60.0), coins], HORIZONTAL_ALIGNMENT_LEFT, 300, 14, Color("#f2e1bd"))
    draw_string(ThemeDB.fallback_font, day_panel.position + Vector2(14, 48), "В руках: %s" % (held_item if held_item != "" else "ничего"), HORIZONTAL_ALIGNMENT_LEFT, 300, 11, Color("#d8cdb7"))

    var world_panel = Rect2(s.x - 305, 72, 285, 128)
    draw_rect(world_panel, Color(0.025, 0.028, 0.025, 0.91))
    draw_rect(world_panel, Color("#6e806f"), false, 1.0)
    draw_string(ThemeDB.fallback_font, world_panel.position + Vector2(12, 22), "Мир реагирует на тебя", HORIZONTAL_ALIGNMENT_LEFT, 255, 13, Color.WHITE)
    draw_string(ThemeDB.fallback_font, world_panel.position + Vector2(12, 45), "Стража %d · деревня %d · докеры %d" % [int(systems.factions["guard"]), int(systems.factions["village"]), int(systems.factions["dockers"])], HORIZONTAL_ALIGNMENT_LEFT, 255, 10, Color("#d2d9d2"))
    draw_string(ThemeDB.fallback_font, world_panel.position + Vector2(12, 65), "Розыск %d · скрытность %d · море %d" % [systems.heat, int(systems.skills["sneak"]), int(systems.skills["seamanship"])], HORIZONTAL_ALIGNMENT_LEFT, 255, 10, Color("#d2d9d2"))
    draw_string(ThemeDB.fallback_font, world_panel.position + Vector2(12, 85), "Сумка: хлеб %d · пиво %d" % [int(systems.inventory.get("bread", 0)), int(systems.inventory.get("beer", 0))], HORIZONTAL_ALIGNMENT_LEFT, 255, 10, Color("#e4cc9c"))
    var ship_text = "корабль у причала" if systems.ship_arrived else "корабль ещё не пришёл"
    draw_string(ThemeDB.fallback_font, world_panel.position + Vector2(12, 107), ship_text, HORIZONTAL_ALIGNMENT_LEFT, 255, 10, Color("#a9c3cc"))

func _draw_live_message(s):
    var live_message := ""
    if systemic_message_time > 0.0 and systemic_message != "":
        live_message = systemic_message
    elif message_time > 0.0 and message != "":
        live_message = message
    if live_message == "":
        return

    var panel = Rect2(355, s.y - 145, 480, 70)
    draw_rect(panel, Color(0.035, 0.03, 0.022, 0.92))
    draw_rect(panel, Color("#8a7658"), false, 1.0)
    var lines = _wrap_message(live_message, 62)
    for i in range(mini(lines.size(), 3)):
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 21 + i * 19), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 24.0, 10, Color("#f0dfbd"))

func _draw_joystick_feedback(s):
    var center = Vector2(205, s.y - 172)
    if touch_dir.length() > 0.08:
        var knob = center + touch_dir * 34.0
        draw_circle(knob, 18.0, Color(0.82, 0.72, 0.52, 0.38))
        draw_arc(knob, 18.0, 0.0, TAU, 24, Color(0.96, 0.86, 0.66, 0.55), 2.0)

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_E:
            interact()
        elif event.keycode == KEY_F:
            action()

    if event is InputEventScreenTouch:
        var s = get_viewport_rect().size
        if event.pressed:
            if event.position.x < 330.0 and event.position.y > s.y - 265.0:
                move_touch_id = event.index
                _set_touch_dir(event.position)
            elif Rect2(s.x - 450, s.y - 170, 125, 150).has_point(event.position):
                action()
                systemic_message = "УДАР / ЛОМАТЬ"
                systemic_message_time = 1.2
            elif Rect2(s.x - 315, s.y - 170, 125, 150).has_point(event.position):
                systemic_message = "Сумка: хлеб %d, пиво %d. В руках: %s" % [int(systems.inventory.get("bread", 0)), int(systems.inventory.get("beer", 0)), held_item if held_item != "" else "ничего"]
                systemic_message_time = 3.0
            elif Rect2(s.x - 180, s.y - 170, 165, 150).has_point(event.position):
                interact()
        elif event.index == move_touch_id:
            move_touch_id = -1
            touch_dir = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == move_touch_id:
        _set_touch_dir(event.position)

func _set_touch_dir(pos):
    var s = get_viewport_rect().size
    var center = Vector2(205, s.y - 172)
    touch_dir = (pos - center) / 60.0
    if touch_dir.length() > 1.0:
        touch_dir = touch_dir.normalized()

func _layout_free_action_ui():
    if free_action_input == null or free_action_button == null:
        return
    var s = get_viewport_rect().size
    free_action_input.position = Vector2(355.0, s.y - 58.0)
    free_action_input.size = Vector2(465.0, 44.0)
    free_action_button.position = Vector2(828.0, s.y - 58.0)
    free_action_button.size = Vector2(145.0, 44.0)

func _layout_quick_action_ui():
    for button in quick_action_buttons:
        button.visible = false

func _refresh_quick_actions(_force):
    for button in quick_action_buttons:
        button.visible = false

func _style_mobile_ui():
    if free_action_input != null:
        free_action_input.placeholder_text = "Напишите действие..."
        free_action_input.add_theme_font_size_override("font_size", 15)
        free_action_input.add_theme_color_override("font_color", Color("#f2e6cb"))
        free_action_input.add_theme_color_override("font_placeholder_color", Color("#a89f90"))
        free_action_input.add_theme_stylebox_override("normal", _make_box(Color(0.025, 0.025, 0.022, 0.95), Color("#8d7658"), 2, 10))
        free_action_input.add_theme_stylebox_override("focus", _make_box(Color(0.045, 0.04, 0.03, 0.98), Color("#d0aa68"), 2, 10))
    if free_action_button != null:
        free_action_button.text = "СДЕЛАТЬ"
        _style_button(free_action_button, Color("#a6763d"))

func _style_button(button, accent):
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_color_override("font_color", Color("#f4ead5"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _make_box(Color(0.05, 0.05, 0.04, 0.94), accent, 2, 9))
    button.add_theme_stylebox_override("hover", _make_box(Color(0.10, 0.095, 0.075, 0.97), accent.lightened(0.18), 2, 9))
    button.add_theme_stylebox_override("pressed", _make_box(Color(0.15, 0.12, 0.075, 0.98), Color("#d3ad6f"), 2, 9))

func _make_box(bg, border, border_width, radius):
    var box = StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = border
    box.border_width_left = border_width
    box.border_width_right = border_width
    box.border_width_top = border_width
    box.border_width_bottom = border_width
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius
    return box

func _draw_world_tag(pos, text, color):
    var width = maxf(54.0, float(str(text).length()) * 7.0 + 14.0)
    draw_rect(Rect2(pos, Vector2(width, 22)), Color(0.03, 0.03, 0.025, 0.78))
    draw_string(ThemeDB.fallback_font, pos + Vector2(7, 15), str(text), HORIZONTAL_ALIGNMENT_LEFT, width - 14.0, 9, color)

func _draw_ellipse(center, radius, color):
    var points = PackedVector2Array()
    for i in range(25):
        var a = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
    draw_colored_polygon(points, color)
