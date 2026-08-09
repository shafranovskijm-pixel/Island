extends "res://scripts/game_v37.gd"

const CrimeInvestigationSystem=preload("res://scripts/crime_investigation_system.gd")
var investigations=CrimeInvestigationSystem.new()
var last_case_id:=""
var cases_menu_open:=false

func _process(delta):
    super._process(delta)
    _sync_held_object_position()
    investigations.tick(npcs,day,hour)
    investigations.process_guard_arrivals(npcs,physical_world.objects,corpses)
    for ev in investigations.drain():
        var type=str(ev.get("type","investigation"))
        history.record(day,hour,type,str(ev.get("text","Следствие.")),{"social":0.05})
        if type=="suspect_identified" and str(ev.get("suspect_id",""))=="player":
            wanted=maxi(wanted,2)
            _notify("Стража считает тебя главным подозреваемым по одному из известных дел.")

func _sync_held_object_position():
    if held_world_object=="":return
    for i in physical_world.objects.size():
        if str(physical_world.objects[i].get("id",""))==held_world_object:
            physical_world.objects[i]["pos"]=player
            return

func attack_nearest():
    var idx=_nearest_npc();if idx<0:_notify("Рядом нет противника.");return
    var target:Dictionary=npcs[idx];var victim_id=str(target.get("id",""));var scene_pos:Vector2=target.get("pos",player)
    combat.ensure(victim_id);var hp_before=float(combat.actor_state[victim_id].get("hp",100))
    super.attack_nearest()
    combat.ensure(victim_id);var hp_after=float(combat.actor_state[victim_id].get("hp",100))
    if hp_after>=hp_before:return
    var evidence:Array=[]
    if held_world_object!="":evidence.append({"type":"weapon_trace","source_object":held_world_object,"suspect_id":"player","weight":.8})
    var c=investigations.report_crime("assault",scene_pos,victim_id,"player",day,hour,evidence)
    last_case_id=str(c["id"])
    _collect_immediate_witnesses(last_case_id,scene_pos,victim_id)

func search_nearest_body():
    var idx=_nearest_body_index();var victim_id="";var pos=player;var was_searched=false
    if idx>=0:
        victim_id=str(npcs[idx].get("id",""));pos=npcs[idx].get("pos",player);was_searched=bool(body_actions.searched.get(victim_id,false))
    super.search_nearest_body()
    if victim_id=="" or was_searched or not bool(body_actions.searched.get(victim_id,false)):return
    var c=investigations.report_crime("robbery",pos,victim_id,"player",day,hour,[])
    last_case_id=str(c["id"])
    _collect_immediate_witnesses(last_case_id,pos,victim_id)

func _collect_immediate_witnesses(case_id:String,pos:Vector2,victim_id:String):
    var max_range=120.0 if world_variety.weather=="fog" else 190.0
    for i in npcs.size():
        var n:Dictionary=npcs[i];var id=str(n.get("id",""));if id==victim_id or not bool(n.get("alive",true)):continue
        combat.ensure(id);if bool(combat.actor_state[id].get("unconscious",false)):continue
        var d=pos.distance_to(n.get("pos",Vector2.ZERO));if d>max_range:continue
        var confidence=clampf(1.0-d/(max_range+60.0),.20,.95)
        if hour>=21 or hour<6:confidence*=.72
        if world_variety.weather in ["rain","storm"]:confidence*=.82
        investigations.add_witness(case_id,n,"player",confidence)
        var mem:Array=n.get("memory",[]);mem.append({"type":"witnessed_crime","case_id":case_id,"suspect":"player","victim_id":victim_id,"day":day,"confidence":confidence});n["memory"]=mem;npcs[i]=n

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(1110,s.y-145,150,50).has_point(event.position):cases_menu_open=not cases_menu_open;return
    super._unhandled_input(event)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var public=investigations.public_cases()
    draw_rect(Rect2(1110,s.y-145,150,50),Color("#384858"))
    draw_string(ThemeDB.fallback_font,Vector2(1123,s.y-114),"ДЕЛА %d"%public.size(),0,120,12,Color.WHITE)
    if cases_menu_open:_draw_cases_panel(s,public)

func _draw_cases_panel(s:Vector2,public:Array):
    var panel=Rect2(s.x-430,65,410,250);draw_rect(panel,Color(0.025,0.032,0.04,.97));draw_rect(panel,Color("#60778b"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(16,29),"Известные расследования",0,370,18,Color.WHITE)
    if public.is_empty():
        draw_string(ThemeDB.fallback_font,panel.position+Vector2(16,60),"Стража не ведёт известных тебе активных дел.",0,370,11,Color("#bfcbd4"));return
    var y=64.0
    for i in mini(4,public.size()):
        var c:Dictionary=public[public.size()-1-i]
        var guard_text=" · стража выехала" if str(c.get("assigned_guard",""))!="" else ""
        var progress=" · следствие продвинулось" if str(c.get("status",""))=="suspect_identified" else ""
        var line="%s · %s%s%s"%[str(c.get("kind","дело")),str(c.get("victim_id","неизвестный")),guard_text,progress]
        draw_string(ThemeDB.fallback_font,panel.position+Vector2(16,y),line,0,370,11,Color("#d7e0e6"));y+=38
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(16,panel.size.y-18),"Скрытые происшествия здесь не показываются.",0,370,10,Color("#8ea0ad"))

func _action_world_snapshot()->Dictionary:
    var world:Dictionary=super._action_world_snapshot();var public:Array=[]
    for c in investigations.public_cases():
        public.append({"id":c.get("id",""),"kind":c.get("kind",""),"victim_id":c.get("victim_id",""),"status":c.get("status",""),"guard_assigned":str(c.get("assigned_guard",""))!=""})
    world["public_investigations"]=public
    return world

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["investigations"]=investigations.serialize();data["last_case_id"]=last_case_id;return data
func _apply_save(data:Dictionary):
    super._apply_save(data)
    var i=data.get("investigations",{});if typeof(i)==TYPE_DICTIONARY:investigations.restore(i)
    last_case_id=str(data.get("last_case_id",""))
