extends Node2D

const WORLD_SIZE = Vector2(1800, 1100)
const PLAYER_SPEED = 175.0

var player = Vector2(650, 600)
var hour = 17.5
var day = 1
var coins = 12
var held_item = ""
var message = "Подойди к людям и нажми ДЕЙСТВИЕ."
var message_time = 6.0
var touch_dir = Vector2.ZERO
var move_touch_id = -1
var rumor_heard = false
var dog_friend = false
var campfire_lit = false
var tavern_brawl = false

var npcs = [
    {"id":"innkeeper","name":"Мирон","role":"трактирщик","pos":Vector2(720,535),"home":Vector2(720,535),"target":Vector2(720,535),"speed":35.0,"mood":"занят"},
    {"id":"bard","name":"Радован","role":"бард","pos":Vector2(785,555),"home":Vector2(785,555),"target":Vector2(785,555),"speed":25.0,"mood":"поёт"},
    {"id":"guard","name":"Борислав","role":"стражник","pos":Vector2(960,410),"home":Vector2(960,410),"target":Vector2(960,410),"speed":48.0,"mood":"бдителен"},
    {"id":"hunter","name":"Остромир","role":"охотник","pos":Vector2(1180,690),"home":Vector2(1180,690),"target":Vector2(1180,690),"speed":52.0,"mood":"насторожен"},
    {"id":"volkhv","name":"Веда","role":"волхв","pos":Vector2(1370,360),"home":Vector2(1370,360),"target":Vector2(1370,360),"speed":32.0,"mood":"молчит"},
    {"id":"villager","name":"Любава","role":"жительница","pos":Vector2(555,665),"home":Vector2(555,665),"target":Vector2(555,665),"speed":42.0,"mood":"спешит"}
]

var dog = {"name":"Серко","pos":Vector2(520,720),"target":Vector2(520,720),"bond":0.0}
var bottle = {"pos":Vector2(755,585),"taken":false,"broken":false}
var camp = {"pos":Vector2(1260,785)}
var hunter_tracks = {"pos":Vector2(1440,745),"found":false}

func _ready():
    queue_redraw()

func _process(delta):
    var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if touch_dir.length() > 0.1:
        dir = touch_dir
    if dir.length() > 1.0:
        dir = dir.normalized()
    player += dir * PLAYER_SPEED * delta
    player.x = clampf(player.x, 30.0, WORLD_SIZE.x - 30.0)
    player.y = clampf(player.y, 30.0, WORLD_SIZE.y - 30.0)
    hour += delta * 0.08
    if hour >= 24.0:
        hour -= 24.0
        day += 1
    _update_npcs(delta)
    _update_dog(delta)
    message_time = maxf(0.0, message_time - delta)
    queue_redraw()

func _update_npcs(delta):
    for n in npcs:
        if randf() < delta * 0.18 and str(n["id"]) not in ["innkeeper", "bard"]:
            n["target"] = n["home"] + Vector2(randf_range(-90.0,90.0), randf_range(-70.0,70.0))
        if n["pos"].distance_to(n["target"]) > 5.0:
            n["pos"] = n["pos"].move_toward(n["target"], float(n["speed"]) * delta)

func _update_dog(delta):
    if dog_friend:
        dog["pos"] = dog["pos"].move_toward(player + Vector2(-34,24), 115.0 * delta)
    else:
        if randf() < delta * 0.12:
            dog["target"] = Vector2(520,720) + Vector2(randf_range(-80.0,80.0), randf_range(-60.0,60.0))
        dog["pos"] = dog["pos"].move_toward(dog["target"], 28.0 * delta)

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_E:
            interact()
        elif event.keycode == KEY_F:
            action()
    if event is InputEventScreenTouch:
        var size = get_viewport_rect().size
        if event.pressed:
            if event.position.x < size.x * 0.46 and event.position.y > size.y * 0.55:
                move_touch_id = event.index
                _set_touch_dir(event.position)
            elif Rect2(size.x-180,size.y-120,155,80).has_point(event.position):
                interact()
            elif Rect2(size.x-350,size.y-120,150,80).has_point(event.position):
                action()
        elif event.index == move_touch_id:
            move_touch_id = -1
            touch_dir = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == move_touch_id:
        _set_touch_dir(event.position)

func _set_touch_dir(pos):
    var size = get_viewport_rect().size
    var center = Vector2(125, size.y-125)
    touch_dir = (pos-center) / 70.0
    if touch_dir.length() > 1.0:
        touch_dir = touch_dir.normalized()

func interact():
    var nearest = _nearest_npc(95.0)
    if nearest >= 0:
        _talk(npcs[nearest])
        return
    if player.distance_to(dog["pos"]) < 90.0:
        if not dog_friend:
            dog_friend = true
            dog["bond"] = 25.0
            _say("Ты поделился едой с Серко. Пёс решил идти за тобой.")
        else:
            dog["bond"] = minf(100.0, float(dog["bond"])+2.0)
            _say("Серко виляет хвостом. Привязанность: %.0f" % dog["bond"])
        return
    if player.distance_to(bottle["pos"]) < 75.0 and not bottle["taken"]:
        bottle["taken"] = true
        held_item = "бутылка"
        _say("Ты поднял бутылку. УДАР использует предмет в руке.")
        return
    if player.distance_to(camp["pos"]) < 90.0:
        campfire_lit = not campfire_lit
        if campfire_lit:
            _say("Ты развёл костёр.")
        else:
            _say("Ты затушил костёр.")
        return
    if rumor_heard and player.distance_to(hunter_tracks["pos"]) < 85.0 and not hunter_tracks["found"]:
        hunter_tracks["found"] = true
        _say("В грязи следы сапог и волочения. Они уходят к старой роще.")
        return
    _say("Здесь ничего очевидного. Осмотрись дальше.")

func action():
    var nearest = _nearest_npc(78.0)
    if nearest < 0:
        if held_item == "бутылка" and not bottle["broken"]:
            bottle["broken"] = true
            held_item = "осколок"
            _say("Ты разбил бутылку. В руке остался острый осколок.")
        else:
            _say("Рядом нет цели.")
        return
    var n = npcs[nearest]
    tavern_brawl = true
    var dmg = 4
    if held_item == "бутылка":
        dmg = 7
    elif held_item == "осколок":
        dmg = 10
    n["mood"] = "в ярости"
    n["target"] = player + Vector2(randf_range(-40.0,40.0),randf_range(-40.0,40.0))
    _say("Ты ударил %s. Урон %d. Свидетели это запомнят." % [n["name"],dmg])
    for g in npcs:
        if str(g["id"]) == "guard" and str(n["id"]) != "guard":
            g["target"] = player
            g["mood"] = "идёт на шум"

func _talk(n):
    match str(n["id"]):
        "innkeeper":
            if tavern_brawl:
                _say("Мирон: Ещё один удар — и стража тебя вышвырнет!")
            else:
                _say("Мирон: Пиво — 2 монеты. Ночью в лес лучше не ходи.")
        "bard":
            rumor_heard = true
            _say("Радован: Третий охотник не вернулся из старой рощи. Шепчут про лешего.")
        "guard":
            _say("Борислав: Замок принимает работников. Сначала заслужи имя.")
        "hunter":
            _say("Остромир: У костра на востоке видел свежие следы. Не звериные.")
        "volkhv":
            _say("Веда: Не всякий шорох — дух. Но и не всякий дух хочет быть увиденным.")
        _:
            _say("Любава: На рынке дорожает хлеб. Корабль задержало ветром.")

func _nearest_npc(max_dist):
    var best = -1
    var best_d = max_dist
    for i in range(npcs.size()):
        var d = player.distance_to(npcs[i]["pos"])
        if d < best_d:
            best = i
            best_d = d
    return best

func _say(text):
    message = text
    message_time = 6.0

func _camera():
    var s = get_viewport_rect().size
    return Vector2(clampf(player.x-s.x*0.5,0.0,maxf(0.0,WORLD_SIZE.x-s.x)),clampf(player.y-s.y*0.5,0.0,maxf(0.0,WORLD_SIZE.y-s.y)))

func _draw():
    var s = get_viewport_rect().size
    var cam = _camera()
    draw_rect(Rect2(Vector2.ZERO,s),Color("#314b35"))
    _draw_world(cam)
    _draw_hud(s)

func _draw_world(cam):
    var tavern = Rect2(Vector2(620,470)-cam,Vector2(245,165))
    var castle = Rect2(Vector2(900,250)-cam,Vector2(260,160))
    var graveyard = Rect2(Vector2(1310,245)-cam,Vector2(230,170))
    var forest = Rect2(Vector2(1080,610)-cam,Vector2(540,350))
    draw_rect(Rect2(Vector2(0,820)-cam,Vector2(1800,280)),Color("#8d7a55"))
    draw_rect(forest,Color("#203c29"))
    draw_rect(tavern,Color("#73543d"))
    draw_rect(tavern.grow(-10),Color("#49372d"))
    draw_rect(castle,Color("#666b6c"))
    draw_rect(castle.grow(-12),Color("#45494b"))
    draw_rect(graveyard,Color("#3f493f"))
    draw_string(ThemeDB.fallback_font,Vector2(640,455)-cam,"ТРАКТИР «ТРИ ВОЛНЫ»",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#f1ddae"))
    draw_string(ThemeDB.fallback_font,Vector2(935,235)-cam,"ЗАМОК",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(1350,230)-cam,"КЛАДБИЩЕ",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#d1d6cf"))
    draw_string(ThemeDB.fallback_font,Vector2(1180,600)-cam,"СТАРАЯ РОЩА",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#b6c8a8"))
    for x in range(1100,1600,80):
        for y in range(645,930,75):
            var offset = (int(y / 75) % 2) * 25
            var p = Vector2(x+offset,y)-cam
            draw_circle(p,18,Color("#18301f"))
            draw_rect(Rect2(p+Vector2(-3,12),Vector2(6,20)),Color("#4b3828"))
    for n in npcs:
        _draw_person(n["pos"]-cam,str(n["role"]),str(n["mood"]),false)
        draw_string(ThemeDB.fallback_font,n["pos"]-cam+Vector2(-32,-20),str(n["name"]),HORIZONTAL_ALIGNMENT_LEFT,70,9,Color.WHITE)
    _draw_dog(dog["pos"]-cam)
    if not bottle["taken"]:
        draw_rect(Rect2(bottle["pos"]-cam-Vector2(5,8),Vector2(10,16)),Color("#7b9b86"))
    var cp = camp["pos"]-cam
    draw_circle(cp,15,Color("#4b3d31"))
    if campfire_lit:
        draw_circle(cp-Vector2(0,7),9,Color("#e57a39"))
        draw_circle(cp-Vector2(0,11),5,Color("#ffd36b"))
    draw_string(ThemeDB.fallback_font,cp+Vector2(-30,30),"КОСТЁР",HORIZONTAL_ALIGNMENT_LEFT,70,9,Color("#e0c69d"))
    if rumor_heard:
        var tp = hunter_tracks["pos"]-cam
        draw_circle(tp,5,Color("#7b6250"))
        draw_circle(tp+Vector2(12,7),5,Color("#7b6250"))
    _draw_person(player-cam,"герой","",true)
    if held_item != "":
        draw_string(ThemeDB.fallback_font,player-cam+Vector2(13,4),held_item,HORIZONTAL_ALIGNMENT_LEFT,80,8,Color("#f2e0b0"))

func _draw_person(p,role,mood,is_player):
    var body = Color("#657a75")
    if "страж" in role:
        body = Color("#68788c")
    elif "бард" in role:
        body = Color("#815a72")
    elif "волхв" in role:
        body = Color("#6d6250")
    elif "охот" in role:
        body = Color("#596b48")
    if is_player:
        body = Color("#d0a65d")
    draw_circle(p+Vector2(3,7),11,Color(0,0,0,.22))
    draw_rect(Rect2(p+Vector2(-7,-1),Vector2(14,20)),body)
    draw_circle(p+Vector2(0,-8),7,Color("#d2a67f"))
    if mood in ["в ярости","идёт на шум"]:
        draw_line(p+Vector2(-5,-13),p+Vector2(5,-13),Color("#b2463f"),2)

func _draw_dog(p):
    draw_rect(Rect2(p-Vector2(10,5),Vector2(19,10)),Color("#a98662"))
    draw_circle(p+Vector2(11,-3),6,Color("#a98662"))
    if dog_friend:
        draw_circle(p+Vector2(0,-14),3,Color("#e8c46b"))

func _draw_hud(s):
    draw_rect(Rect2(12,12,470,92),Color(0.03,0.04,0.035,.86))
    draw_string(ThemeDB.fallback_font,Vector2(24,36),"День %d · %02d:%02d · монеты %d" % [day,int(hour),int((hour-int(hour))*60),coins],HORIZONTAL_ALIGNMENT_LEFT,440,13,Color.WHITE)
    var hand_text = held_item
    if hand_text == "":
        hand_text = "ничего"
    var dog_text = "нет"
    if dog_friend:
        dog_text = "Серко"
    draw_string(ThemeDB.fallback_font,Vector2(24,58),"В руках: %s · пёс: %s" % [hand_text,dog_text],HORIZONTAL_ALIGNMENT_LEFT,440,11,Color("#d4d8cb"))
    if message_time > 0:
        draw_string(ThemeDB.fallback_font,Vector2(24,84),message,HORIZONTAL_ALIGNMENT_LEFT,440,11,Color("#f0d9a9"))
    draw_circle(Vector2(125,s.y-125),68,Color(1,1,1,.08))
    draw_circle(Vector2(125,s.y-125)+touch_dir*52,24,Color(1,1,1,.24))
    var action_rect = Rect2(s.x-350,s.y-120,150,80)
    var interact_rect = Rect2(s.x-180,s.y-120,155,80)
    draw_rect(action_rect,Color("#704840"))
    draw_rect(interact_rect,Color("#47624f"))
    draw_string(ThemeDB.fallback_font,action_rect.position+Vector2(24,48),"УДАР / ЛОМАТЬ",HORIZONTAL_ALIGNMENT_LEFT,125,12,Color.WHITE)
    draw_string(ThemeDB.fallback_font,interact_rect.position+Vector2(35,48),"ДЕЙСТВИЕ",HORIZONTAL_ALIGNMENT_LEFT,110,13,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(s.x-360,35),"ПК: WASD · E действие · F удар",HORIZONTAL_ALIGNMENT_LEFT,340,10,Color("#c8d1c6"))
