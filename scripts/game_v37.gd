extends "res://scripts/game_v36.gd"

const BodyInteractionSystem=preload("res://scripts/body_interaction_system.gd")
var body_actions=BodyInteractionSystem.new()
var body_menu_open:=false

func _process(delta):
    super._process(delta);body_actions.update_carried(npcs,player)
    for ev in body_actions.drain():history.record(day,hour,str(ev.get("type","body")),str(ev.get("text","Взаимодействие с телом.")),{"social":0.05})
    _sync_combat_deaths()

func _sync_combat_deaths():
    for i in npcs.size():
        var n=npcs[i];var id=str(n.get("id",""));if not bool(n.get("alive",true)):continue
        combat.ensure(id);var state=combat.actor_state[id]
        if float(state.get("hp",100))<=0 and float(state.get("bleeding",0))>0:
            n["death_timer"]=float(n.get("death_timer",0))+0.016
            if float(n["death_timer"])>35.0:
                npcs[i]=n;simulate_death(id,"кровопотеря после ранения");continue
        npcs[i]=n

func _nearest_body_index()->int:
    var best=-1;var d0=INF
    for i in npcs.size():
        var n=npcs[i];var d=player.distance_to(n.get("pos",Vector2.ZERO));if d>105 or d>=d0:continue
        if body_actions.can_interact(n,combat):best=i;d0=d
    return best

func search_nearest_body():
    var i=_nearest_body_index();if i<0:_notify("Рядом нет беспомощного человека или тела.");return
    var before=int(npcs[i].get("money",0));var r=body_actions.search_body(npcs[i],combat,inventory)
    if not bool(r.get("ok",false)):_notify(str(r.get("reason","Обыск не удался.")));return
    coins+=maxi(0,before-int(npcs[i].get("money",0)));wanted+=1;_notify("Ты обыскал %s."%npcs[i].get("name","человека"))

func bind_nearest_body():
    var i=_nearest_body_index();if i<0:_notify("Некого связывать.");return
    var r=body_actions.bind_body(npcs[i],combat,inventory);_notify("%s"%("Человек связан." if bool(r.get("ok",false)) else str(r.get("reason","Не получилось."))))

func carry_or_drop_body():
    if body_actions.carried_body!="":
        var r=body_actions.drop(npcs,player+Vector2(35,0));_notify("Тело опущено." if bool(r.get("ok",false)) else str(r.get("reason","Не получилось.")));return
    var i=_nearest_body_index();if i<0:_notify("Некого нести.");return
    var r=body_actions.carry(npcs[i],combat);_notify("Ты несёшь %s."%npcs[i].get("name","человека") if bool(r.get("ok",false)) else str(r.get("reason","Не получилось.")))

func help_nearest_body():
    var i=_nearest_body_index();if i<0:_notify("Рядом нет раненого, которому можно помочь.");return
    var r=body_actions.stabilize(npcs[i],combat,inventory);_notify("Кровотечение остановлено." if bool(r.get("ok",false)) else str(r.get("reason","Не получилось помочь.")))

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(980,s.y-145,120,50).has_point(event.position):body_menu_open=not body_menu_open;return
        if body_menu_open and _handle_body_touch(event.position):return
    super._unhandled_input(event)

func _handle_body_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(s.x-300,s.y*.30,280,230);if not panel.has_point(pos):return false
    var actions=["search","bind","carry","help"];var y=panel.position.y+48
    for i in actions.size():
        var r=Rect2(panel.position.x+14,y+i*42,panel.size.x-28,34);if not r.has_point(pos):continue
        match actions[i]:
            "search":search_nearest_body()
            "bind":bind_nearest_body()
            "carry":carry_or_drop_body()
            "help":help_nearest_body()
        return true
    return true

func _draw_hud(s:Vector2):
    super._draw_hud(s);var b=Rect2(980,s.y-145,120,50);draw_rect(b,Color("#57464a"));draw_string(ThemeDB.fallback_font,b.position+Vector2(19,31),"ТЕЛО",0,85,12,Color.WHITE)
    if body_menu_open:_draw_body_panel(s)

func _draw_body_panel(s:Vector2):
    var panel=Rect2(s.x-300,s.y*.30,280,230);draw_rect(panel,Color(0.04,0.025,0.03,.97));draw_rect(panel,Color("#7c6269"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,28),"Раненые и тела",0,250,17,Color.WHITE)
    var labels=["ОБЫСКАТЬ","СВЯЗАТЬ","НЕСТИ / ПОЛОЖИТЬ","ОСТАНОВИТЬ КРОВЬ"];var y=panel.position.y+48
    for i in labels.size():
        var r=Rect2(panel.position.x+14,y+i*42,panel.size.x-28,34);draw_rect(r,Color("#5c474d"));draw_string(ThemeDB.fallback_font,r.position+Vector2(10,22),labels[i],0,r.size.x-20,11,Color.WHITE)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["body_actions"]=body_actions.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var b=data.get("body_actions",{});if typeof(b)==TYPE_DICTIONARY:body_actions.restore(b)
