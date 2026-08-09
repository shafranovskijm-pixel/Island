extends "res://prototype/prototype_v04.gd"

const WORLD_ART = preload("res://prototype/art/coastal_village.svg")
const VISUAL_PROFILE = "coastal_painterly_v1"

var visual_time := 0.0

func _ready():
    super._ready()
    _style_mobile_ui()
    systemic_message = "Ты в Бухте Трёх Волн. Мир живёт сам по себе: люди работают, корабли приходят по времени, а действия имеют последствия."
    systemic_message_time = 12.0
    queue_redraw()

func _process(delta):
    visual_time += delta
    super._process(delta)

func _draw_world(cam):
    if WORLD_ART != null:
        draw_texture_rect(WORLD_ART, Rect2(-cam, WORLD_SIZE), false)
    else:
        super._draw_world(cam)
        return

    _draw_water_life(cam)
    _draw_dynamic_ship(cam)
    _draw_world_entities(cam)
    _draw_location_atmosphere(cam)

func _draw_water_life(cam):
    var phase = visual_time * 1.15
    for i in range(9):
        var y = 800.0 + float(i) * 31.0
        var x = 78.0 + fmod(float(i * 83) + phase * 28.0, 390.0)
        var p = Vector2(x, y) - cam
        draw_arc(p, 18.0 + float(i % 3) * 5.0, 0.15, 2.85, 14, Color(0.76, 0.91, 0.90, 0.25), 2.0)

func _draw_dynamic_ship(cam):
    if not systems.ship_arrived:
        return
    var p = Vector2(365, 958) - cam
    draw_ellipse_shadow(p + Vector2(0, 22), Vector2(112, 30), Color(0.01, 0.03, 0.04, 0.34))
    var hull = PackedVector2Array([
        p + Vector2(-110, -3), p + Vector2(-78, 34), p + Vector2(73, 34), p + Vector2(112, -3), p + Vector2(77, 17), p + Vector2(-72, 17)
    ])
    draw_colored_polygon(hull, Color("#3b2922"))
    draw_polyline(PackedVector2Array([p + Vector2(-108, -3), p + Vector2(110, -3), p + Vector2(76, 34), p + Vector2(-78, 34), p + Vector2(-108, -3)]), Color("#a0784f"), 4.0)
    draw_line(p + Vector2(2, -10), p + Vector2(2, -112), Color("#2b2420"), 7.0)
    var sail = PackedVector2Array([p + Vector2(7, -105), p + Vector2(78, -46), p + Vector2(7, -48)])
    draw_colored_polygon(sail, Color(0.78, 0.73, 0.62, 0.88))
    draw_polyline(PackedVector2Array([p + Vector2(7, -105), p + Vector2(78, -46), p + Vector2(7, -48), p + Vector2(7, -105)]), Color("#6d5943"), 2.0)
    _draw_world_tag(p + Vector2(-80, 56), "ТОРГОВЫЙ КОРАБЛЬ", Color("#d8c49b"))

func _draw_world_entities(cam):
    for n in npcs:
        var p = n["pos"] - cam
        draw_circle(p + Vector2(5, 18), 13.0, Color(0.03, 0.04, 0.03, 0.33))
        _draw_person(p, str(n["role"]), str(n["mood"]), false)
        _draw_nameplate(p + Vector2(-38, -38), str(n["name"]), str(n["role"]))

    _draw_relationship_marks(cam)
    _draw_dog(dog["pos"] - cam)
    if dog_friend:
        draw_arc(dog["pos"] - cam, 18.0, 0.0, TAU, 24, Color(0.73, 0.84, 0.55, 0.75), 2.0)

    if not bottle["taken"]:
        var bp = bottle["pos"] - cam
        draw_circle(bp + Vector2(0, 7), 8.0, Color(0.02, 0.03, 0.02, 0.3))
        draw_rect(Rect2(bp - Vector2(4, 8), Vector2(8, 15)), Color("#739a83"))
        draw_line(bp - Vector2(2, 9), bp + Vector2(2, -9), Color("#b9d1bd"), 2.0)

    _draw_campfire(cam)

    if rumor_heard:
        var tp = hunter_tracks["pos"] - cam
        draw_arc(tp, 26.0, 0.0, TAU, 32, Color(0.79, 0.63, 0.39, 0.45), 2.0)
        draw_circle(tp + Vector2(-7, -2), 5.0, Color("#5b4839"))
        draw_circle(tp + Vector2(8, 6), 5.0, Color("#5b4839"))
        if hunter_tracks["found"]:
            _draw_world_tag(tp + Vector2(-42, 35), "СЛЕДЫ", Color("#d9bf8f"))

    var player_p = player - cam
    draw_circle(player_p + Vector2(4, 19), 16.0, Color(0.02, 0.03, 0.02, 0.38))
    draw_arc(player_p, 21.0 + sin(visual_time * 3.0) * 1.5, 0.0, TAU, 32, Color(0.95, 0.72, 0.31, 0.42), 2.0)
    _draw_person(player_p, "герой", "", true)
    if held_item != "":
        _draw_world_tag(player_p + Vector2(17, 27), held_item, Color("#f0d59e"))

func _draw_campfire(cam):
    var cp = camp["pos"] - cam
    draw_circle(cp + Vector2(0, 9), 19.0, Color(0.02, 0.02, 0.01, 0.35))
    for i in range(7):
        var a = TAU * float(i) / 7.0
        draw_circle(cp + Vector2(cos(a), sin(a)) * 13.0, 5.0, Color("#6e6557"))
    if campfire_lit:
        var pulse = 1.0 + sin(visual_time * 5.0) * 0.08
        draw_circle(cp, 55.0 * pulse, Color(0.95, 0.48, 0.16, 0.08))
        draw_circle(cp - Vector2(0, 5), 13.0 * pulse, Color("#d75d2b"))
        draw_circle(cp - Vector2(0, 10), 8.0 * pulse, Color("#ffb34f"))
        draw_circle(cp - Vector2(0, 14), 4.0 * pulse, Color("#ffe39a"))
    _draw_world_tag(cp + Vector2(-34, 35), "КОСТЁР", Color("#e2c99b"))

func _draw_location_atmosphere(cam):
    var s = get_viewport_rect().size
    var night_alpha = 0.0
    if hour >= 20.0:
        night_alpha = clampf((hour - 20.0) / 4.0, 0.0, 0.38)
    elif hour < 6.0:
        night_alpha = clampf((6.0 - hour) / 6.0, 0.0, 0.38)
    if night_alpha > 0.0:
        draw_rect(Rect2(Vector2.ZERO, s), Color(0.04, 0.07, 0.14, night_alpha))

    var loc = _current_location()
    var titles = {
        "dock": "СТАРЫЙ ПРИЧАЛ",
        "tavern": "ТРАКТИР «ТРИ ВОЛНЫ»",
        "forest": "СТАРАЯ РОЩА",
        "graveyard": "СТАРОЕ КЛАДБИЩЕ",
        "castle": "ЗАМОК НА СКАЛЕ",
        "village": "БУХТА ТРЁХ ВОЛН",
    }
    var title = str(titles.get(loc, "БУХТА ТРЁХ ВОЛН"))
    var panel = Rect2(22, 18, 245, 44)
    draw_rect(panel, Color(0.035, 0.035, 0.03, 0.82))
    draw_rect(panel, Color("#a48a62"), false, 1.5)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(14, 27), title, HORIZONTAL_ALIGNMENT_LEFT, 215, 15, Color("#f2e1bd"))

func _draw_nameplate(pos, title, subtitle):
    var width = maxf(82.0, float(title.length()) * 8.0 + 22.0)
    var panel = Rect2(pos.x, pos.y, width, 31)
    draw_rect(panel, Color(0.025, 0.028, 0.025, 0.72))
    draw_rect(panel, Color(0.65, 0.55, 0.4, 0.55), false, 1.0)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(7, 13), title, HORIZONTAL_ALIGNMENT_LEFT, width - 14.0, 10, Color.WHITE)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(7, 25), subtitle, HORIZONTAL_ALIGNMENT_LEFT, width - 14.0, 8, Color("#c9c1ad"))

func _draw_world_tag(pos, text, color):
    var width = maxf(54.0, float(str(text).length()) * 7.0 + 14.0)
    draw_rect(Rect2(pos, Vector2(width, 22)), Color(0.03, 0.03, 0.025, 0.72))
    draw_string(ThemeDB.fallback_font, pos + Vector2(7, 15), str(text), HORIZONTAL_ALIGNMENT_LEFT, width - 14.0, 9, color)

func draw_ellipse_shadow(center, radius, color):
    var points = PackedVector2Array()
    for i in range(25):
        var a = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
    draw_colored_polygon(points, color)

func _style_mobile_ui():
    if free_action_input != null:
        free_action_input.add_theme_font_size_override("font_size", 16)
        free_action_input.add_theme_color_override("font_color", Color("#f2e6cb"))
        free_action_input.add_theme_color_override("font_placeholder_color", Color("#a89f90"))
        free_action_input.add_theme_stylebox_override("normal", _make_box(Color(0.035, 0.035, 0.03, 0.94), Color("#8d7658"), 2, 10))
        free_action_input.add_theme_stylebox_override("focus", _make_box(Color(0.05, 0.045, 0.035, 0.98), Color("#d0aa68"), 2, 10))
    if free_action_button != null:
        _style_button(free_action_button, Color("#a6763d"))
        free_action_button.text = "СДЕЛАТЬ"
    for button in quick_action_buttons:
        _style_button(button, Color("#5e7059"))
        button.add_theme_font_size_override("font_size", 14)

func _style_button(button, accent):
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", Color("#f4ead5"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _make_box(Color(0.05, 0.05, 0.04, 0.93), accent, 2, 9))
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
