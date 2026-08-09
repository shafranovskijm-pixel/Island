extends "res://scripts/game_v15.gd"

const EvidenceSystem=preload("res://scripts/evidence_system.gd")
const ConsequenceSystem=preload("res://scripts/consequence_system.gd")
var evidence=EvidenceSystem.new();var consequences=ConsequenceSystem.new()
var evidence_scan_timer:=0.0
var evidence_event_cursor:=0
var consequence_event_cursor:=0

func _process(delta):
    super._process(delta)
    evidence_scan_timer+=delta
    if evidence_scan_timer>=1.5:
        evidence_scan_timer=0.0
        _scan_visible_evidence()
    _drain_evidence_events();_drain_consequence_events()

func _scan_visible_evidence():
    var reactions=evidence.inspect_player_inventory(npcs,inventory,player,day,hour)
    if reactions.is_empty():return
    var resolved=consequences.process_reactions(reactions,npcs,power,player_factions,day,hour)
    wanted+=int(resolved.get("wanted_delta",0));reputation+=int(resolved.get("reputation_delta",0))
    for r in reactions:
        var text=str(r.get("text",""))
        if text!="":_notify(text)
    # Severe evidence triggers a local guard response instead of global omniscience.
    if int(resolved.get("alarm_level",0))>=5:
        _call_nearby_guard()

func _call_nearby_guard():
    var best=-1;var d0=INF
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)):continue
        if str(n.get("faction",""))!="guard":continue
        var d=player.distance_to(n.get("pos",Vector2.ZERO))
        if d<d0:d0=d;best=i
    if best>=0:
        npcs[best]["target"]=player
        npcs[best]["state"]="responding_to_crime"
        npcs[best]["stress"]=minf(100,float(npcs[best].get("stress",0))+10)

func _apply_action_outcome(action:Dictionary,result:Dictionary,outcome:Dictionary):
    super._apply_action_outcome(action,result,outcome)
    var mutation:Dictionary=outcome.get("mutation",{})
    if not mutation.is_empty():
        var c=consequences.react_to_mutation(mutation,current_location_id,npcs,day,hour)
        wanted+=int(c.get("crime",0))
        if bool(c.get("fire",false)):_apply_fire_pressure(mutation)

func _apply_fire_pressure(mutation:Dictionary):
    production.unrest=clampf(production.unrest+8,0,100)
    production.crime_pressure=clampf(production.crime_pressure+3,0,100)
    history.record(day,hour,"fire","Пожар вызывает панику и отвлекает жителей от обычной работы.",{})
    # Nearby civilians temporarily abandon normal targets to react to fire.
    for i in npcs.size():
        if not bool(npcs[i].get("alive",true)):continue
        if player.distance_to(npcs[i].get("pos",Vector2.ZERO))<260:
            npcs[i]["state"]="fire_response";npcs[i]["target"]=player

func _drain_evidence_events():
    while evidence_event_cursor<evidence.events.size():
        var e=evidence.events[evidence_event_cursor]
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),"evidence",str(e.get("text","Свидетель увидел улику.")),{})
        evidence_event_cursor+=1

func _drain_consequence_events():
    while consequence_event_cursor<consequences.events.size():
        var e=consequences.events[consequence_event_cursor]
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),"consequence",str(e.get("text","Последствие действия.")),{})
        consequence_event_cursor+=1

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    if consequences.alarm_level>0:
        draw_rect(Rect2(s.x-340,84,310,34),Color(.18,.03,.03,.88))
        draw_string(ThemeDB.fallback_font,Vector2(s.x-325,106),"Тревога %d · розыск %d"%[consequences.alarm_level,wanted],0,280,13,Color("#ffd0cc"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["alarm_level"]=consequences.alarm_level;return data

func _apply_save(data:Dictionary):
    super._apply_save(data);consequences.alarm_level=int(data.get("alarm_level",0))
