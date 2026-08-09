extends "res://scripts/game_v11.gd"

const PlayerFactionSystem=preload("res://scripts/player_faction_system.gd")
var player_factions=PlayerFactionSystem.new()
var player_faction_event_cursor:=0

func _process(delta):
    super._process(delta)
    _drain_player_faction_events()

func _do_location_npc_action(n:Dictionary,action:int):
    var id=str(n.get("id",""))
    super._do_location_npc_action(n,action)
    match id:
        "king","queen","chancellor":
            if action==0:player_factions.change("crown",4.0,day,hour,"Двор заметил твою полезность.")
            elif action==1:player_factions.change("crown",1.5,day,hour,"Ты лучше понял придворные интересы.")
        "captain_guard":
            if action==0:player_factions.change("guard",4.0,day,hour,"Стража стала доверять тебе больше.")
        "priest":
            if action==0:player_factions.change("temple",4.0,day,hour,"Храм считает тебя благонадёжным.")
            elif action==1 and occult_member:player_factions.change("temple",-2.5,day,hour,"Жрец почувствовал, что ты что-то скрываешь.")
        "cult_leader","vampire":
            if action==0:player_factions.change("occult",5.0,day,hour,"Ты приблизился к тайному кругу.")
            if player_factions.reputation.get("temple",0)>35:player_factions.change("temple",-1.5,day,hour,"Связи с тайным кругом вызывают подозрение храма.")
        "smuggler":
            if action==0:player_factions.change("underworld",5.0,day,hour,"Подполье стало считать тебя своим человеком.")
        "marek":
            if action==0:player_factions.change("merchants",3.0,day,hour,"Торговцы знают, что на тебя можно положиться.")

func _drain_player_faction_events():
    while player_faction_event_cursor<player_factions.events.size():
        var e=player_factions.events[player_faction_event_cursor]
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),"player_faction",str(e.get("text","Изменилось отношение фракции.")),{"social":0.2})
        _notify(str(e.get("text","Изменилось отношение фракции.")))
        player_faction_event_cursor+=1

func _access_state()->Dictionary:
    var state:Dictionary=super._access_state()
    state["influence"]=influence+int(player_factions.reputation.get("crown",0)/20.0)
    state["guard_trust"]=guard_trust+int(player_factions.reputation.get("guard",0)/20.0)
    state["temple_trust"]=temple_trust+int(player_factions.reputation.get("temple",0)/20.0)
    state["occult_member"]=occult_member or player_factions.can_access("occult",20.0)
    return state

func _record_faction_event(e:Dictionary):
    super._record_faction_event(e)
    var winner=str(e.get("winner",""));var target=str(e.get("target",""))
    var dominant=player_factions.dominant_faction()
    if winner==dominant and float(player_factions.reputation.get(dominant,0))>20:
        influence+=1
        history.record(day,hour,"political_gain","Победа союзной фракции усилила твоё положение в %s."%target,{"social":0.25})

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var dom=player_factions.dominant_faction()
    var title=str(player_factions.titles.get(dom,"без статуса"))
    draw_rect(Rect2(710,206,555,32),Color(0.02,0.04,0.05,.82))
    draw_string(ThemeDB.fallback_font,Vector2(722,227),"Твоя сторона: %s · %s · репутация %.0f"%[dom,title,float(player_factions.reputation.get(dom,0))],0,530,12,Color("#c9d8ef"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["player_factions"]=player_factions.serialize()
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var pf=data.get("player_factions",{})
    if typeof(pf)==TYPE_DICTIONARY:player_factions.restore(pf)
