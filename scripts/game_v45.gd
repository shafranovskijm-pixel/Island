extends "res://scripts/game_v44.gd"
const RitualPriesthood=preload("res://scripts/ritual_priesthood_system.gd")
var priesthood=RitualPriesthood.new()
var ritual_menu_open:=false
var ritual_god_index:=0
func _process(delta):
    super._process(delta);priesthood.tick(npcs)
    for ev in priesthood.drain():
        history.record(day,hour,str(ev.get("type","ritual")),str(ev.get("text","Обряд.")),{"mystic":0.15});knowledge_ui.add_journal(day,hour,"Старая вера",str(ev.get("text","")),["faith"])
        if str(ev.get("type","")) in ["prophecy","volkhv","conversion"]:_notify(str(ev.get("text","")))
func _ritual_gods()->Array:return ["perun","veles","mokosh","dazhbog","stribog"]
func _ritual_god()->String:return str(_ritual_gods()[ritual_god_index%_ritual_gods().size()])
func consecrate_here():
    var god=_ritual_god();if not slavic_faith.is_known(god):_notify("Ты ещё не знаешь этой традиции.");return
    var r=priesthood.consecrate(god,player);_notify("Священное место создано для %s."%slavic_faith.gods[god]["name"] if bool(r.get("ok",false)) else str(r.get("reason","Не получилось.")))
func appoint_nearest_volkhv():
    var i=_nearest_npc();if i<0:_notify("Рядом никого нет.");return
    var r=priesthood.appoint_volkhv(_ritual_god(),npcs[i]);_notify(str(r.get("reason","Назначен волхв.")) if not bool(r.get("ok",false)) else "%s становится волхвом."%npcs[i].get("name","Житель"))
func hold_ritual(kind:String):
    var god=_ritual_god();if not slavic_faith.is_known(god):_notify("Эта традиция тебе пока неизвестна.");return
    var participants=1
    for n in npcs:
        if player.distance_to(n.get("pos",Vector2.ZERO))<180:participants+=1
    var r=priesthood.ritual(god,kind,participants,slavic_faith);_notify("Обряд завершён. Сила %.1f."%float(r.get("power",0)))
func recruit_nearest_to_faith():
    var i=_nearest_npc();if i<0:_notify("Рядом никого нет.");return
    var r=priesthood.recruit(_ritual_god(),npcs[i]);_notify("Человек принял твою традицию." if bool(r.get("success",false)) else "Он не убеждён.")
func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(175,18,135,44).has_point(event.position):ritual_menu_open=not ritual_menu_open;return
        if ritual_menu_open and _handle_ritual_touch(event.position):return
    super._unhandled_input(event)
func _handle_ritual_touch(pos:Vector2)->bool:
    var panel=Rect2(170,70,330,350);if not panel.has_point(pos):return false
    var actions=["prev","next","site","volkhv","prayer","feast","divination","recruit"];var y=panel.position.y+48
    for i in actions.size():
        var r=Rect2(panel.position.x+14,y+i*37,panel.size.x-28,30);if not r.has_point(pos):continue
        match actions[i]:
            "prev":ritual_god_index=(ritual_god_index-1+_ritual_gods().size())%_ritual_gods().size()
            "next":ritual_god_index=(ritual_god_index+1)%_ritual_gods().size()
            "site":consecrate_here()
            "volkhv":appoint_nearest_volkhv()
            "prayer":hold_ritual("prayer")
            "feast":hold_ritual("feast")
            "divination":hold_ritual("divination")
            "recruit":recruit_nearest_to_faith()
        return true
    return true
func _draw_hud(s:Vector2):
    super._draw_hud(s);var b=Rect2(175,18,135,44);draw_rect(b,Color("#66553b"));draw_string(ThemeDB.fallback_font,b.position+Vector2(26,28),"ОБРЯДЫ",0,90,11,Color.WHITE)
    if ritual_menu_open:_draw_ritual_panel()
func _draw_ritual_panel():
    var panel=Rect2(170,70,330,350);draw_rect(panel,Color(0.04,0.032,0.018,.98));draw_rect(panel,Color("#8b754e"),false,2);var god=_ritual_god();draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,28),"Обряды · %s"%slavic_faith.gods[god]["name"],0,300,17,Color.WHITE)
    var labels=["‹ ПРЕДЫДУЩИЙ БОГ","СЛЕДУЮЩИЙ БОГ ›","ОСВЯТИТЬ МЕСТО","НАЗНАЧИТЬ ВОЛХВА","МОЛИТВА","ОБЩИЙ ПИР","ГАДАНИЕ / ПРОРОЧЕСТВО","ПРИВЛЕЧЬ БЛИЖАЙШЕГО NPC"];var y=panel.position.y+48
    for i in labels.size():var r=Rect2(panel.position.x+14,y+i*37,panel.size.x-28,30);draw_rect(r,Color("#66583e"));draw_string(ThemeDB.fallback_font,r.position+Vector2(8,20),labels[i],0,r.size.x-16,10,Color.WHITE)
    var p=priesthood.priesthoods[god];draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+14,panel.end.y-12),"Последователи %d · влияние %.1f · пророчеств %d"%[p["followers"],p["influence"],priesthood.prophecies.size()],0,300,9,Color("#ddd0ad"))
func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["ritual_priesthood"]=priesthood.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var p=data.get("ritual_priesthood",{});if typeof(p)==TYPE_DICTIONARY:priesthood.restore(p)
