extends "res://scripts/game_v32.gd"

const CastleRoomSecurity=preload("res://scripts/castle_room_security.gd")
var castle_security=CastleRoomSecurity.new()
var security_menu_open:=false

func _process(delta):
    super._process(delta)
    var e=estate.player_estate()
    castle_security.tick(npcs,e,castle_builder.placed,day,hour,float(production.crime_pressure))
    for ev in castle_security.drain():
        var type=str(ev.get("type","castle_security"));history.record(day,hour,type,str(ev.get("text","Событие в замке.")),{"social":0.05})
        if type in ["intrusion","intruder_caught","burglary"]:_notify(str(ev.get("text","Ночное событие.")))

func assign_room_to_nearest():
    var idx=_nearest_npc();if idx<0:_notify("Рядом никого нет.");return
    var e=estate.player_estate();if e.is_empty():_notify("Нет собственного владения.");return
    castle_security.rebuild_from_castle(e,castle_builder.placed)
    var result=castle_security.assign_bedroom(str(npcs[idx].get("id","")))
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Нет комнаты.")));return
    npcs[idx]["private_room_id"]=str(result["room"].get("id",""));npcs[idx]["target"]=result["room"].get("pos",npcs[idx].get("pos",Vector2.ZERO))
    _notify("%s получил личную спальню."%npcs[idx].get("name","Житель"))

func install_door_lock():
    var result=castle_security.create_key_for_nearest_door(player,castle_builder.placed)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не удалось установить замок.")));return
    var key:Dictionary=result["key"].duplicate(true);key["kind"]="key";key["key_id"]=key["id"];inventory.append(key)
    _notify("Дверь заперта. Ключ добавлен в инвентарь.")

func toggle_door_lock():
    var result=castle_security.toggle_nearest_door_lock(player,castle_builder.placed,inventory)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не удалось изменить замок.")));return
    _notify("Дверь %s."%("заперта" if bool(result.get("locked",false)) else "отперта"))

func assign_nearest_guard_post():
    var idx=_nearest_npc();if idx<0:_notify("Рядом нет охранника.");return
    var n=npcs[idx]
    var role=str(n.get("household_role",n.get("role",""))).to_lower()
    if "guard" not in role and "охран" not in role and "страж" not in role:
        _notify("Сначала найми этого человека охранником.");return
    var result=castle_security.add_guard_post(player+Vector2(64,0),str(n.get("id","")))
    if bool(result.get("ok",false)):
        n["target"]=result["post"].get("pos",n.get("pos",Vector2.ZERO));npcs[idx]=n;_notify("Охраннику назначен пост у этой точки.")

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(365,s.y-145,160,50).has_point(event.position):security_menu_open=not security_menu_open;return
        if security_menu_open and _handle_security_touch(event.position):return
    super._unhandled_input(event)

func _handle_security_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(s.x-360,s.y*.20,340,s.y*.56)
    if not panel.has_point(pos):return false
    var actions=["room","lock","toggle","guard"]
    var y=panel.position.y+58
    for i in actions.size():
        var r=Rect2(panel.position.x+15,y+i*48,panel.size.x-30,38)
        if not r.has_point(pos):continue
        match actions[i]:
            "room":assign_room_to_nearest()
            "lock":install_door_lock()
            "toggle":toggle_door_lock()
            "guard":assign_nearest_guard_post()
        return true
    return true

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var b=Rect2(365,s.y-145,160,50);draw_rect(b,Color("#4c5866"));draw_string(ThemeDB.fallback_font,b.position+Vector2(27,31),"ЗАМОК",0,110,14,Color.WHITE)
    if security_menu_open:_draw_security_panel(s)

func _draw_security_panel(s:Vector2):
    var panel=Rect2(s.x-360,s.y*.20,340,s.y*.56);draw_rect(panel,Color(0.025,0.03,0.038,.97));draw_rect(panel,Color("#6c7b8c"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(15,30),"Комнаты и безопасность",0,305,18,Color.WHITE)
    var labels=["НАЗНАЧИТЬ СПАЛЬНЮ БЛИЖНЕМУ","УСТАНОВИТЬ ЗАМОК НА ДВЕРЬ","ЗАПЕРЕТЬ / ОТПЕРЕТЬ ДВЕРЬ","ПОСТ ОХРАНЫ ДЛЯ БЛИЖНЕГО"]
    var y=panel.position.y+58
    for i in labels.size():
        var r=Rect2(panel.position.x+15,y+i*48,panel.size.x-30,38);draw_rect(r,Color("#4b5966"));draw_string(ThemeDB.fallback_font,r.position+Vector2(10,25),labels[i],0,r.size.x-20,11,Color.WHITE)
    var e=estate.player_estate();castle_security.rebuild_from_castle(e,castle_builder.placed)
    var locked=0
    for d in castle_security.door_locks.values():
        if bool(d.get("locked",false)):locked+=1
    draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+15,panel.end.y-18),"Комнат %d · запертых дверей %d · постов %d"%[castle_security.rooms.size(),locked,castle_security.guard_posts.size()],0,305,10,Color("#c9d2dc"))

func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    for post in castle_security.guard_posts:
        var p:Vector2=post.get("pos",Vector2.ZERO)-cam;draw_circle(p,7,Color("#87a6c2"));draw_string(ThemeDB.fallback_font,p+Vector2(-18,-12),"ПОСТ",0,50,8,Color.WHITE)
    for room in castle_security.rooms:
        var rp:Vector2=room.get("pos",Vector2.ZERO)-cam;draw_string(ThemeDB.fallback_font,rp+Vector2(-28,28),str(room.get("name","комната")),0,95,8,Color("#d5d0c4"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["castle_room_security"]=castle_security.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var cs=data.get("castle_room_security",{});if typeof(cs)==TYPE_DICTIONARY:castle_security.restore(cs)
