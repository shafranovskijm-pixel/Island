extends "res://scripts/game_v04.gd"

const EconomySystem = preload("res://scripts/economy_system.gd")
const ShipSystem = preload("res://scripts/ship_system.gd")
const WorldDirector = preload("res://scripts/world_director.gd")

var economy = EconomySystem.new()
var ship_system = ShipSystem.new()
var director = WorldDirector.new()
var economy_cursor := 0
var ship_cursor := 0
var director_cursor := 0
var escaped := false
var escape_story := ""

func _ready():
    super._ready()
    economy.setup()
    ship_system.setup()
    director.setup()

func _advance_world(delta):
    if escaped:
        return
    super._advance_world(delta)
    npcs = economy.tick(npcs,day,hour,delta)
    ship_system.tick(day,hour,delta)
    var result:Dictionary = director.tick(day,hour,npcs,economy,ship_system,social,delta)
    if result.has("npcs"):
        npcs = result["npcs"]
    _apply_ship_cargo_once()

func _apply_ship_cargo_once():
    for ship in ship_system.ships:
        if ship.get("cargo_unloaded",false):
            continue
        for kind in ship["cargo"].keys():
            economy.supply(kind,float(ship["cargo"][kind]),day,hour)
        ship["cargo_unloaded"] = true

func _drain_world_events():
    super._drain_world_events()
    while economy_cursor < economy.events.size():
        var e=economy.events[economy_cursor]
        history.record(int(e["day"]),float(e["hour"]),"economy",str(e["text"]),{})
        economy_cursor += 1
    while ship_cursor < ship_system.events.size():
        var e=ship_system.events[ship_cursor]
        history.record(int(e["day"]),float(e["hour"]),"ship",str(e["text"]),{"sailor":0.05})
        ship_cursor += 1
    while director_cursor < director.events.size():
        var e=director.events[director_cursor]
        history.record(int(e["day"]),float(e["hour"]),"world_event",str(e["text"]),{})
        director_cursor += 1

func _try_interact():
    if not ship_system.ships.is_empty() and player.distance_to(Vector2(1660,610)) < 145.0:
        selected_npc = -3
        interaction_open = true
        return
    super._try_interact()

func _do_action(action:int):
    if selected_npc != -3:
        super._do_action(action)
        return
    if ship_system.ships.is_empty():
        _notify("Корабль уже ушёл.")
        _close_dialog()
        return
    var ship:Dictionary = ship_system.ships[0]
    var options:Array = ship_system.escape_options(ship,skills,coins)
    if action == 0:
        var ticket:Dictionary = options[0]
        if ticket["available"]:
            coins -= int(ship["passage_price"])
            _escape(ship,"купил билет и покинул остров пассажиром")
        else:
            _notify(str(ticket["reason"]))
    elif action == 1:
        var chosen:Dictionary = {}
        for option in options:
            if option["id"] != "ticket" and option["available"]:
                chosen = option
                break
        if chosen.is_empty():
            _notify("Пока нет другого доступного способа попасть на борт.")
        else:
            match chosen["id"]:
                "crew": _escape(ship,"нанялся матросом")
                "stowaway": _escape(ship,"тайно пробрался в трюм")
                "criminal": _escape(ship,"ушёл с пиратами и контрабандистами")
                "magic": _escape(ship,"использовал магический знак и исчез вместе со странным судном")
    _close_dialog()

func _escape(ship:Dictionary,how:String):
    escaped = true
    escape_story = "На корабле «%s» ты %s." % [ship["name"],how]
    history.record(day,hour,"departure",escape_story,{"sailor":1.0})
    _notify("Ты покинул остров.")

func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    if not ship_system.ships.is_empty():
        var ship:Dictionary = ship_system.ships[0]
        var p:=Vector2(1690,535)-cam
        draw_rect(Rect2(p-Vector2(45,18),Vector2(90,36)),Color("#3d2d24"))
        draw_line(p+Vector2(0,-18),p+Vector2(0,-82),Color("#4b3427"),5)
        draw_colored_polygon(PackedVector2Array([p+Vector2(4,-78),p+Vector2(55,-50),p+Vector2(4,-30)]),Color("#e1d7b8"))
        draw_string(ThemeDB.fallback_font,p+Vector2(-60,58),"«%s»"%ship["name"],0,130,12,Color.WHITE)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var line := "Следующий корабль: день %d" % ship_system.next_arrival_day
    if not ship_system.ships.is_empty():
        var ship:Dictionary=ship_system.ships[0]
        line="В порту: %s · мест %d · билет %d"%[ship["name"],ship["vacancies"],ship["passage_price"]]
    draw_rect(Rect2(14,136,500,34),Color(0.02,0.05,0.06,.82))
    draw_string(ThemeDB.fallback_font,Vector2(28,159),line,0,470,13,Color("#f4e2ad"))
    if escaped:
        draw_rect(Rect2(s.x*.12,s.y*.35,s.x*.76,110),Color(0.02,0.04,0.05,.94))
        draw_string(ThemeDB.fallback_font,Vector2(s.x*.15,s.y*.40),"ГЛАВА ОСТРОВА ЗАВЕРШЕНА",0,s.x*.7,22,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(s.x*.15,s.y*.46),escape_story,0,s.x*.7,15,Color("#e7dfca"))

func _draw_dialog(s:Vector2):
    if selected_npc != -3:
        super._draw_dialog(s)
        return
    draw_rect(Rect2(Vector2.ZERO,s),Color(0,0,0,.35))
    var box:=Rect2(s.x*.08,s.y*.50,s.x*.84,s.y*.40)
    draw_rect(box,Color("#0a1b20"));draw_rect(box,Color("#6f8790"),false,2)
    var ship:Dictionary = ship_system.ships[0] if not ship_system.ships.is_empty() else {}
    var title:="Корабль ушёл"
    var desc:=""
    var a0:="Уйти"
    var a1:="Уйти"
    if not ship.is_empty():
        title="%s · %s"%[ship["name"],ship["kind"]]
        desc="Экипаж %d · вакансий %d · охрана %d · билет %d"%[ship["crew"],ship["vacancies"],ship["security"],ship["passage_price"]]
        a0="Купить билет — %d монет"%ship["passage_price"]
        a1="Попробовать другой путь"
    draw_string(ThemeDB.fallback_font,box.position+Vector2(30,34),title,0,-1,21,Color.WHITE)
    draw_string(ThemeDB.fallback_font,box.position+Vector2(30,68),desc,0,box.size.x-60,14,Color("#d6e3e4"))
    var opts=[a0,a1,"Уйти"]
    for i in 3:
        var r=Rect2(box.position.x+30,box.position.y+105+i*58,box.size.x-60,44)
        draw_rect(r,Color("#245765"));draw_string(ThemeDB.fallback_font,r.position+Vector2(15,28),opts[i],0,r.size.x-30,14,Color.WHITE)

func _draw_panel(s:Vector2):
    super._draw_panel(s)
    if panel != "world":
        return
    var x:=s.x*.55
    var y:=s.y*.38
    draw_string(ThemeDB.fallback_font,Vector2(x,y),"РЫНОК",0,300,17,Color.WHITE)
    y+=28
    for key in economy.market.keys():
        var item:Dictionary=economy.market[key]
        draw_string(ThemeDB.fallback_font,Vector2(x,y),"%s · запас %d · цена %d"%[key,int(item["stock"]),economy.price(key)],0,330,13,Color("#d7dfdf"))
        y+=23
