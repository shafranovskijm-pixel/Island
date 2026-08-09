extends "res://scripts/game_v37.gd"

const CrimeInvestigationSystem=preload("res://scripts/crime_investigation_system.gd")
var investigations=CrimeInvestigationSystem.new()
var last_case_id:=""

func _process(delta):
    super._process(delta)
    investigations.tick(npcs,day,hour)
    for ev in investigations.drain():
        history.record(day,hour,str(ev.get("type","investigation")),str(ev.get("text","Следствие.")),{"social":0.05})
        if str(ev.get("type",""))=="suspect_identified" and str(ev.get("suspect_id",""))=="player":
            wanted=maxi(wanted,2);_notify("Стража считает тебя главным подозреваемым по одному из дел.")

func attack_nearest():
    var idx=_nearest_npc();if idx<0:_notify("Рядом нет противника.");return
    var target=npcs[idx];var victim_id=str(target.get("id",""));var scene_pos:Vector2=target.get("pos",player)
    super.attack_nearest()
    if idx>=npcs.size():return
    var state=combat.actor_state.get(victim_id,{})
    if not state.is_empty() and (float(state.get("hp",100))<100 or bool(state.get("unconscious",false))):
        var evidence:Array=[]
        if held_world_object!="":evidence.append({"type":"weapon_trace","source_object":held_world_object,"suspect_id":"player","weight":.8})
        var c=investigations.report_crime("assault",scene_pos,victim_id,"player",day,hour,evidence)
        last_case_id=str(c["id"]);_collect_immediate_witnesses(last_case_id,scene_pos,victim_id)

func search_nearest_body():
    var idx=_nearest_body_index();var victim_id="";var pos=player
    if idx>=0:victim_id=str(npcs[idx].get("id",""));pos=npcs[idx].get("pos",player)
    super.search_nearest_body()
    if victim_id!="":
        var c=investigations.report_crime("robbery",pos,victim_id,"player",day,hour,[]);last_case_id=str(c["id"]);_collect_immediate_witnesses(last_case_id,pos,victim_id)

func _collect_immediate_witnesses(case_id:String,pos:Vector2,victim_id:String):
    for n in npcs:
        var id=str(n.get("id",""));if id==victim_id or not bool(n.get("alive",true)):continue
        var d=pos.distance_to(n.get("pos",Vector2.ZERO));if d>190:continue
        var confidence=clampf(1.0-d/250.0,.25,.95)
        if hour>=21 or hour<6:confidence*=.72
        investigations.add_witness(case_id,n,"player",confidence)
        n["memory"].append({"type":"witnessed_crime","case_id":case_id,"suspect":"player","day":day,"confidence":confidence})

func inspect_last_crime_scene():
    if last_case_id=="":_notify("Нет недавнего дела для осмотра.");return
    investigations.scan_scene(last_case_id,physical_world.objects,corpses,npcs)
    _notify("Место происшествия осмотрено. Улики добавлены в дело.")

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    draw_rect(Rect2(1110,s.y-145,150,50),Color("#384858"))
    draw_string(ThemeDB.fallback_font,Vector2(1123,s.y-114),"ДЕЛА %d"%investigations.open_cases().size(),0,120,12,Color.WHITE)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["investigations"]=investigations.serialize();data["last_case_id"]=last_case_id;return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var i=data.get("investigations",{});if typeof(i)==TYPE_DICTIONARY:investigations.restore(i);last_case_id=str(data.get("last_case_id",""))
