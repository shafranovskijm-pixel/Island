extends "res://prototype/prototype_v03.gd"

const SliceSystemsV04 = preload("res://prototype/prototype_systems_v04.gd")
const V04_DOCK_AREA = Rect2(150, 820, 460, 260)
const TAVERN_AREA = Rect2(600, 450, 290, 210)
const FOREST_AREA = Rect2(1050, 590, 590, 390)
const GRAVEYARD_AREA = Rect2(1290, 225, 270, 210)
const CASTLE_AREA = Rect2(880, 230, 300, 200)

var quick_action_buttons = []
var last_context_signature = ""

func _init():
    systems = SliceSystemsV04.new()

func _ready():
    super._ready()
    _build_quick_action_ui()
    _refresh_quick_actions(true)
    systemic_message = "Действия теперь привязаны к реальному месту: подойди к человеку или месту. Быстрые кнопки показывают только то, что имеет смысл здесь."
    systemic_message_time = 12.0
    queue_redraw()

func _process(delta):
    super._process(delta)
    _layout_quick_action_ui()
    _refresh_quick_actions(false)

func attempt_free_action(text):
    systems.tick(day, hour, _world_flags())
    var context = _action_context()
    var result = systems.resolve_action(text, context)
    coins = maxi(0, coins + int(result.get("coin_delta", 0)))
    systemic_message = str(result.get("message", ""))
    systemic_message_time = 10.0
    if free_action_input != null:
        free_action_input.text = ""
    _refresh_quick_actions(true)
    queue_redraw()
    return result

func _action_context():
    var near_index = _nearest_npc(115.0)
    var near_npc = ""
    if near_index >= 0:
        near_npc = str(npcs[near_index]["id"])

    return {
        "coins": coins,
        "hour": hour,
        "day": day,
        "near_npc": near_npc,
        "near_dock": V04_DOCK_AREA.grow(65.0).has_point(player),
        "near_tracks": rumor_heard and player.distance_to(hunter_tracks["pos"]) < 105.0,
        "tracks_found": bool(hunter_tracks["found"]),
        "near_campfire": player.distance_to(camp["pos"]) < 105.0,
        "campfire_lit": campfire_lit,
        "near_dog": player.distance_to(dog["pos"]) < 95.0,
        "dog_friend": dog_friend,
        "brawl": tavern_brawl,
        "held_item": held_item,
        "location": _current_location(),
    }

func _current_location():
    if TAVERN_AREA.has_point(player):
        return "tavern"
    if V04_DOCK_AREA.has_point(player):
        return "dock"
    if FOREST_AREA.has_point(player):
        return "forest"
    if GRAVEYARD_AREA.has_point(player):
        return "graveyard"
    if CASTLE_AREA.has_point(player):
        return "castle"
    return "village"

func _build_quick_action_ui():
    for i in range(3):
        var button = Button.new()
        button.text = ""
        button.visible = false
        button.focus_mode = Control.FOCUS_NONE
        button.pressed.connect(_on_quick_action_pressed.bind(i))
        quick_action_buttons.append(button)
        add_child(button)
    _layout_quick_action_ui()

func _layout_quick_action_ui():
    if quick_action_buttons.is_empty():
        return
    var s = get_viewport_rect().size
    var start_x = 215.0
    var available = maxf(300.0, s.x - 430.0)
    var button_width = minf(180.0, (available - 16.0) / 3.0)
    var y = s.y - 110.0
    for i in range(quick_action_buttons.size()):
        var button = quick_action_buttons[i]
        button.position = Vector2(start_x + i * (button_width + 8.0), y)
        button.size = Vector2(button_width, 44.0)

func _refresh_quick_actions(force):
    if quick_action_buttons.is_empty():
        return
    var context = _action_context()
    var signature = "%s|%s|%s|%d|%s" % [
        str(context.get("location", "")),
        str(context.get("near_npc", "")),
        str(systems.ship_arrived),
        int(systems.heat),
        str(context.get("near_tracks", false)),
    ]
    if not force and signature == last_context_signature:
        return
    last_context_signature = signature
    var suggestions = systems.suggest_actions(context)
    for i in range(quick_action_buttons.size()):
        var button = quick_action_buttons[i]
        if i < suggestions.size():
            button.text = str(suggestions[i])
            button.visible = true
        else:
            button.text = ""
            button.visible = false

func _on_quick_action_pressed(index):
    if index < 0 or index >= quick_action_buttons.size():
        return
    var button = quick_action_buttons[index]
    if not button.visible or button.text == "":
        return
    attempt_free_action(button.text)
