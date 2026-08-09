extends "res://scripts/game_v30.gd"

const EstateHouseholdSystem=preload("res://scripts/estate_household_system.gd")
const PlayerBoatSystem=preload("res://scripts/player_boat_system.gd")
const VampireSystem=preload("res://scripts/vampire_system.gd")
var estate=EstateHouseholdSystem.new()
var player_boats=PlayerBoatSystem.new()
var vampire=VampireSystem.new()
var lifestyle_menu_open:=false

func _process(delta):
    super._process(delta)
    estate.tick(npcs,day,hour)
    var vamp=vampire.tick(hour,delta)
    if float(vamp.get("sun_damage",0))>0:
        energy=maxf(0,energy-float(vamp["sun_damage"])*8.0)
    for e in estate.drain():history.record(day,hour,str(e.get("type","estate")),str(e.get("text","Изменение владения.")),{"merchant":0.1})
    for e in player_boats.drain():history.record(day,hour,str(e.get("type","boat")),str(e.get("text","Морская жизнь.")),{"sailor":0.25})
    for e in vampire.drain():history.record(day,hour,str(e.get("type","vampire")),str(e.get("text","Вампирское событие.")),{"mage":0.5})

func found_estate():
    if not estate.player_estate().is_empty():_notify("У тебя уже есть собственное владение.");return
    if coins<40:_notify("Для оформления земли и первых работ нужно 40 монет.");return
    coins-=40;estate.create_estate("player",player+Vector2(120,80),"Владение героя");_notify("Ты основал собственное владение. Теперь его можно превращать в замок.")

func hire_nearest_servant(role:String="servant"):
    var idx=_nearest_npc();if idx<0:_notify("Рядом нет человека, которому можно предложить работу.");return
    var n=npcs[idx];var wage=3.0 if role=="servant" else 5.0
    var result=estate.hire(n,role,wage)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не удалось нанять.")));return
    npcs[idx]=n;_notify("%s теперь служит в твоём доме."%n.get("name","Житель"))

func invite_nearest_to_live():
    var idx=_nearest_npc();if idx<0:_notify("Рядом никого нет.");return
    var n=npcs[idx];var result=estate.invite_resident(n)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не согласился.")));return
    npcs[idx]=n;_notify("%s согласился жить с тобой."%n.get("name","Житель"))

func buy_simple_boat():
    if not player_boats.player_boat().is_empty():_notify("У тебя уже есть судно.");return
    if current_location_id not in ["port","fisher_cove"]:_notify("Лодку нужно искать у воды.");return
    if coins<25:_notify("Простая лодка стоит 25 монет.");return
    coins-=25;player_boats.build_boat("dinghy");_notify("Теперь у тебя есть собственная лодка.")

func fish_from_boat():
    if current_location_id not in ["port","fisher_cove"]:_notify("Для рыбалки нужно выйти к воде.");return
    var result=player_boats.fish(learning,day,hour)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не получилось рыбачить.")));return
    var qty=float(result.get("quantity",0));inventory.append({"id":"boat_fish_%d"%Time.get_ticks_usec(),"name":"свежая рыба","kind":"resource","resource":"fish","quantity":qty,"value":2})
    _notify("Поймано %.1f рыбы."%qty)

func ask_vampire_turning():
    var idx=_find_npc("vampire");if idx<0:_notify("Ты не знаешь никого, кто способен на такое.");return
    if player.distance_to(npcs[idx].get("pos",Vector2.ZERO))>150:_notify("Для этого нужно лично найти Леди Весперу.");return
    var result=vampire.turn(npcs[idx],locations.secrets)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Обращение невозможно.")));return
    _notify("Твоя прежняя жизнь закончилась. Ты стал вампиром.")

func toggle_bat_form():
    var result=vampire.toggle_bat();if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не получилось.")));return
    _notify("Летучая мышь" if bool(result.get("bat_form",false)) else "Человеческий облик")

func _do_location_npc_action(n:Dictionary,action:int):
    if str(n.get("id",""))=="vampire" and action==1 and bool(locations.secrets.get("vampires",false)):
        ask_vampire_turning();return
    super._do_location_npc_action(n,action)

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(18,s.y-145,170,50).has_point(event.position):lifestyle_menu_open=not lifestyle_menu_open;return
        if lifestyle_menu_open and _handle_lifestyle_touch(event.position):return
    super._unhandled_input(event)

func _handle_lifestyle_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(20,s.y*.20,330,s.y*.62)
    if not panel.has_point(pos):return false
    var actions=["estate","servant","guard","resident","boat","fish","vampire","bat"]
    var y=panel.position.y+55
    for i in actions.size():
        var r=Rect2(panel.position.x+15,y+i*43,panel.size.x-30,35);if not r.has_point(pos):continue
        match actions[i]:
            "estate":found_estate()
            "servant":hire_nearest_servant("servant")
            "guard":hire_nearest_servant("guard")
            "resident":invite_nearest_to_live()
            "boat":buy_simple_boat()
            "fish":fish_from_boat()
            "vampire":ask_vampire_turning()
            "bat":toggle_bat_form()
        return true
    return true

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var b=Rect2(18,s.y-145,170,50);draw_rect(b,Color("#4c3d55"));draw_string(ThemeDB.fallback_font,b.position+Vector2(23,31),"ОБРАЗ ЖИЗНИ",0,130,13,Color.WHITE)
    if lifestyle_menu_open:_draw_lifestyle_panel(s)
    if bool(vampire.state.get("bat_form",false)):
        draw_string(ThemeDB.fallback_font,Vector2(s.x*.45,38),"🦇 ФОРМА ЛЕТУЧЕЙ МЫШИ",0,300,16,Color("#d9b5e8"))

func _draw_lifestyle_panel(s:Vector2):
    var panel=Rect2(20,s.y*.20,330,s.y*.62);draw_rect(panel,Color(0.025,0.02,0.035,.96));draw_rect(panel,Color("#755f80"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(15,30),"Своя жизнь",0,290,19,Color.WHITE)
    var labels=["ОСНОВАТЬ ВЛАДЕНИЕ","НАНЯТЬ СЛУГУ","НАНЯТЬ ОХРАННИКА","ПРИГЛАСИТЬ ЖИТЬ","КУПИТЬ ЛОДКУ","РЫБАЧИТЬ С ЛОДКИ","ПРОСИТЬ ОБРАЩЕНИЕ","ПРЕВРАТИТЬСЯ В МЫШЬ"]
    var y=panel.position.y+55
    for i in labels.size():
        var r=Rect2(panel.position.x+15,y+i*43,panel.size.x-30,35);draw_rect(r,Color("#55475d"));draw_string(ThemeDB.fallback_font,r.position+Vector2(11,23),labels[i],0,r.size.x-22,12,Color.WHITE)
    var e=estate.player_estate();if not e.is_empty():draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+15,panel.end.y-18),"Слуги %d · жители %d · защита %.0f"%[e["staff"].size(),e["residents"].size(),e["security"]],0,295,10,Color("#cbbbd0"))

func _draw_player(cam:Vector2):
    if bool(vampire.state.get("bat_form",false)):
        var p=player-cam;draw_circle(p,8,Color("#25202c"));draw_circle(p+Vector2(-9,0),7,Color("#34293c"));draw_circle(p+Vector2(9,0),7,Color("#34293c"));return
    super._draw_player(cam)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["estate_household"]=estate.serialize();data["player_boats"]=player_boats.serialize();data["vampire_state"]=vampire.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data)
    var e=data.get("estate_household",{});if typeof(e)==TYPE_DICTIONARY:estate.restore(e)
    var b=data.get("player_boats",{});if typeof(b)==TYPE_DICTIONARY:player_boats.restore(b)
    var v=data.get("vampire_state",{});if typeof(v)==TYPE_DICTIONARY:vampire.restore(v)
