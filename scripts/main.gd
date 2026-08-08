extends Node2D

const WORLD := Vector2(1800, 1200)
const SPEED := 240.0
const TALK_RANGE := 90.0

var player := Vector2(900, 650)
var coins := 3
var hunger := 20.0
var energy := 85.0
var day := 1
var hour := 8.0
var joy := Vector2.ZERO
var joy_id := -1
var interaction_open := false
var selected_npc := -1
var message := ""
var message_timer := 0.0

var skills := {
    "begging": 0,
    "trade": 0,
    "stealth": 0,
    "sailing": 0,
    "magic": 0,
    "drinking": 0
}

var npcs = [
    {"name":"Марек","role":"торговец","pos":Vector2(650,520),"color":Color("#d6a84c"),"rel":0},
    {"name":"Лисса","role":"воровка","pos":Vector2(1120,420),"color":Color("#8f74c9"),"rel":0},
    {"name":"Кракен","role":"старый пират","pos":Vector2(1440,680),"color":Color("#687985"),"rel":0},
    {"name":"Томас","role":"рыбак","pos":Vector2(430,830),"color":Color("#67a99b"),"rel":0},
    {"name":"Эндар","role":"отшельник","pos":Vector2(930,260),"color":Color("#6d92e3"),"rel":0}
]

func _ready():
    queue_redraw()

func _process(delta):
    if not interaction_open:
        _update_world(delta)
    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0:
            message = ""
    queue_redraw()

func _update_world(delta):
    hour += delta * 0.10
    hunger = min(100.0, hunger + delta * 0.45)
    energy = max(0.0, energy - delta * 0.18)
    if hour >= 24.0:
        hour -= 24.0
        day += 1
    var kb := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var dir := kb + joy
    if dir.length() > 1.0:
        dir = dir.normalized()
    var speed := SPEED if energy >= 20.0 else SPEED * 0.65
    player += dir * speed * delta
    player.x = clamp(player.x, 120.0, WORLD.x - 120.0)
    player.y = clamp(player.y, 120.0, WORLD.y - 120.0)
    if Input.is_action_just_pressed("interact"):
        _try_interact()

func _nearest_npc() -> int:
    var best := -1
    var dist := INF
    for i in npcs.size():
        var d: float = player.distance_to(npcs[i]["pos"])
        if d < TALK_RANGE and d < dist:
            best = i
            dist = d
    return best

func _try_interact():
    var idx := _nearest_npc()
    if idx >= 0:
        selected_npc = idx
        interaction_open = true
        return
    if player.distance_to(Vector2(1500,860)) < 120.0:
        selected_npc = -2
        interaction_open = true
        return
    _notify("Рядом не с чем взаимодействовать.")

func _notify(text: String):
    message = text
    message_timer = 3.0

func _do_action(action: int):
    if selected_npc == -2:
        if action == 0:
            if coins >= 2:
                coins -= 2
                hunger = max(0.0, hunger - 20.0)
                energy = min(100.0, energy + 8.0)
                _notify("Ты поел в дешёвой таверне.")
            else:
                _notify("Не хватает денег.")
        elif action == 1:
            if coins >= 1:
                coins -= 1
                skills["drinking"] += 1
                energy = max(0.0, energy - 8.0)
                _notify("Пиво тёплое. Навык выпивки растёт.")
            else:
                _notify("Даже на пиво не хватает.")
        _close_dialog()
        return

    var npc = npcs[selected_npc]
    match selected_npc:
        0:
            if action == 0:
                skills["trade"] += 1
                coins += 2
                npc["rel"] += 1
                _notify("Разгрузил ящики. +2 монеты, торговля растёт.")
            else:
                skills["begging"] += 1
                if randi() % 2 == 0:
                    coins += 1
                    _notify("Марек дал тебе монету.")
                else:
                    _notify("Марек отказал, но попрошайничество растёт.")
        1:
            if action == 0:
                skills["stealth"] += 1
                npc["rel"] += 1
                _notify("Лисса показала, как двигаться тише.")
            else:
                skills["begging"] += 1
                _notify("Лисса посоветовала просить у богатых.")
        2:
            if action == 0 and coins >= 1:
                coins -= 1
                skills["drinking"] += 1
                skills["sailing"] += 1
                npc["rel"] += 1
                _notify("За кружкой Кракен рассказал про море.")
            elif action == 1:
                skills["sailing"] += 1
                _notify("Ты начал понимать морской жаргон.")
            else:
                _notify("Нечем угостить.")
        3:
            if action == 0:
                skills["sailing"] += 1
                coins += 1
                npc["rel"] += 1
                _notify("Починил сеть. +1 монета, море растёт.")
            else:
                hunger = max(0.0, hunger - 12.0)
                _notify("Томас поделился рыбой.")
        4:
            if action == 0:
                skills["magic"] += 1
                npc["rel"] += 1
                _notify("Эндар показал странный символ.")
            else:
                _notify("Эндар молчит. Иногда молчание тоже ответ.")
    npcs[selected_npc] = npc
    _close_dialog()

func _close_dialog():
    interaction_open = false
    selected_npc = -1

func _unhandled_input(event):
    var size := get_viewport_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < 260 and event.position.y > size.y - 260:
                joy_id = event.index
                _update_joy(event.position)
            elif event.position.x > size.x - 220 and event.position.y > size.y - 220 and not interaction_open:
                _try_interact()
            elif interaction_open:
                _dialog_touch(event.position)
        elif event.index == joy_id:
            joy_id = -1
            joy = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == joy_id:
        _update_joy(event.position)

func _update_joy(pos: Vector2):
    var center := Vector2(115, get_viewport_rect().size.y - 115)
    var delta := pos - center
    if delta.length() > 70.0:
        delta = delta.normalized() * 70.0
    joy = delta / 70.0

func _dialog_touch(pos: Vector2):
    var size := get_viewport_rect().size
    var box := Rect2(size.x * 0.08, size.y * 0.50, size.x * 0.84, size.y * 0.40)
    var y0 := box.position.y + 105.0
    for i in 3:
        var r := Rect2(box.position.x + 30, y0 + i * 58, box.size.x - 60, 44)
        if r.has_point(pos):
            if i == 2:
                _close_dialog()
            else:
                _do_action(i)

func _draw():
    var size := get_viewport_rect().size
    var cam := player - size / 2.0
    cam.x = clamp(cam.x, 0.0, WORLD.x - size.x)
    cam.y = clamp(cam.y, 0.0, WORLD.y - size.y)
    _draw_world(cam, size)
    _draw_hud(size)
    if interaction_open:
        _draw_dialog(size)

func _draw_world(cam: Vector2, size: Vector2):
    draw_rect(Rect2(Vector2.ZERO, size), Color("#1b5865"))
    var center := Vector2(900,600) - cam
    draw_circle(center, 520, Color("#d7bd78"))
    draw_circle(center, 470, Color("#6c9d59"))
    draw_line(Vector2(350,650)-cam, Vector2(1450,650)-cam, Color("#b89a63"), 34)
    draw_line(Vector2(900,650)-cam, Vector2(930,250)-cam, Color("#b89a63"), 28)
    draw_circle(Vector2(1500,860)-cam, 65, Color("#7d4f2d"))
    draw_string(ThemeDB.fallback_font, Vector2(1445,790)-cam, "ТАВЕРНА", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    draw_rect(Rect2(Vector2(1540,600)-cam, Vector2(210,100)), Color("#795233"))
    draw_string(ThemeDB.fallback_font, Vector2(1580,585)-cam, "ПОРТ", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    for npc in npcs:
        var p: Vector2 = npc["pos"] - cam
        draw_circle(p, 20, npc["color"])
        draw_string(ThemeDB.fallback_font, p + Vector2(-35,-28), npc["role"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
        if player.distance_to(npc["pos"]) < TALK_RANGE:
            draw_arc(p, 30, 0, TAU, 40, Color.WHITE, 2)
    var pp := player - cam
    draw_circle(pp, 18, Color("#f0eee5"))
    draw_string(ThemeDB.fallback_font, pp + Vector2(-10,-25), "ТЫ", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#17252a"))

func _draw_hud(size: Vector2):
    draw_rect(Rect2(14,14,390,92), Color(0.02,0.05,0.06,0.78))
    var time_text := "%02d:%02d" % [int(hour), int((hour-int(hour))*60)]
    draw_string(ThemeDB.fallback_font, Vector2(28,38), "День %d   %s" % [day,time_text], HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(28,62), "Монеты: %d   Голод: %d   Энергия: %d" % [coins,int(hunger),int(energy)], HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(28,86), "Торг %d  Попрош. %d  Скрыт. %d  Море %d  Магия %d" % [skills.trade,skills.begging,skills.stealth,skills.sailing,skills.magic], HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#dce9e8"))
    var jc := Vector2(115, size.y - 115)
    draw_circle(jc, 78, Color(1,1,1,0.10))
    draw_arc(jc, 78, 0, TAU, 40, Color(1,1,1,0.22), 2)
    draw_circle(jc + joy * 52, 30, Color(1,1,1,0.35))
    var ac := Vector2(size.x - 105, size.y - 105)
    draw_circle(ac, 58, Color("#d7a13d"))
    draw_string(ThemeDB.fallback_font, ac + Vector2(-39,6), "ДЕЙСТВИЕ", HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#17252a"))
    if message != "":
        draw_rect(Rect2(size.x*0.18,120,size.x*0.64,54),Color(0.01,0.03,0.04,0.88))
        draw_string(ThemeDB.fallback_font, Vector2(size.x*0.20,153), message, HORIZONTAL_ALIGNMENT_LEFT,size.x*0.60,15,Color.WHITE)

func _draw_dialog(size: Vector2):
    draw_rect(Rect2(0,0,size.x,size.y), Color(0,0,0,0.30))
    var box := Rect2(size.x*0.08,size.y*0.50,size.x*0.84,size.y*0.40)
    draw_rect(box,Color("#0a1b20"))
    draw_rect(box,Color("#6f8790"),false,2)
    var title := ""
    var desc := ""
    var a0 := ""
    var a1 := ""
    if selected_npc == -2:
        title = "Таверна «Сломанный Маяк»"
        desc = "Здесь можно поесть, выпить или просто переждать день."
        a0 = "Поесть — 2 монеты"
        a1 = "Выпить пива — 1 монета"
    else:
        var npc = npcs[selected_npc]
        title = "%s — %s" % [npc["name"],npc["role"]]
        desc = "Отношение: %d. Действия постепенно меняют персонажа." % npc["rel"]
        match selected_npc:
            0: a0="Помочь разгрузить товар"; a1="Попросить милостыню"
            1: a0="Учиться двигаться тише"; a1="Попросить монету"
            2: a0="Угостить пивом и слушать"; a1="Расспросить о море"
            3: a0="Помочь с сетью"; a1="Попросить еды"
            4: a0="Попросить показать знак"; a1="Просто поговорить"
    draw_string(ThemeDB.fallback_font, box.position+Vector2(30,34), title, HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
    draw_string(ThemeDB.fallback_font, box.position+Vector2(30,68), desc, HORIZONTAL_ALIGNMENT_LEFT,box.size.x-60,15,Color("#d6e3e4"))
    var options := [a0,a1,"Уйти"]
    for i in 3:
        var r := Rect2(box.position.x+30,box.position.y+105+i*58,box.size.x-60,44)
        draw_rect(r,Color("#245765"))
        draw_string(ThemeDB.fallback_font,r.position+Vector2(15,28),options[i],HORIZONTAL_ALIGNMENT_LEFT,r.size.x-30,15,Color.WHITE)
