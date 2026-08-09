extends "res://scripts/game_v14.gd"

const DiceEngine=preload("res://scripts/dice_engine.gd")
const FreeActionEngine=preload("res://scripts/free_action_engine.gd")
const WorldActionMutator=preload("res://scripts/world_action_mutator.gd")
var dice=DiceEngine.new();var free_actions=FreeActionEngine.new();var mutator=WorldActionMutator.new()
var free_action_mode:=false
var free_action_text:=""
var last_roll:Dictionary={}
var corpses:Array=[]

func _unhandled_input(event):
    if free_action_mode:
        if event is InputEventKey and event.pressed:
            if event.keycode==KEY_ENTER:_submit_free_action();return
            if event.keycode==KEY_ESCAPE:free_action_mode=false;free_action_text="";return
            if event.keycode==KEY_BACKSPACE:free_action_text=free_action_text.left(maxi(0,free_action_text.length()-1));return
            var u=event.unicode
            if u>0:free_action_text+=char(u)
        return
    var s=get_viewport_rect().size
    if event is InputEventScreenTouch and event.pressed and Rect2(s.x-610,s.y-82,240,54).has_point(event.position):
        free_action_mode=true;free_action_text="";_notify("Опиши своё действие и нажми Enter. Голосовой ввод телефона тоже можно использовать.");return
    super._unhandled_input(event)

func _submit_free_action():
    var text=free_action_text.strip_edges();free_action_mode=false;free_action_text=""
    if text=="":return
    var world=_action_world_snapshot()
    var action=free_actions.parse_local(text,world)
    if not bool(action.get("ok",false)):
        history.record(day,hour,"free_action","Попытался: %s. Действие требует разбора AI-мастером."%text,{})
        _notify("Пока не понял действие локально. Оно будет передаваться AI-мастеру после подключения модели.");return
    var valid=free_actions.validate(action,world)
    if not bool(valid.get("ok",false)):_notify(str(valid.get("reason","Действие невозможно.")));return
    var verb=str(action["verb"]);var stat=_stat_for(verb);var skill=_skill_for(verb);var dc=dice.dc_for(verb,_roll_context())
    var result={"success":true,"roll":0,"total":0,"dc":dc,"critical":false,"fumble":false,"margin":0}
    if dice.should_roll(action):result=dice.check(stat,skill,dc,0)
    last_roll=result
    var outcome=mutator.apply(action,result,world)
    _apply_action_outcome(action,result,outcome)

func _action_world_snapshot()->Dictionary:
    var nearby_npcs:Array=[];var nearby_objects:Array=[];var nearby_corpses:Array=[]
    for n in npcs:
        if bool(n.get("alive",true)) and player.distance_to(n.get("pos",Vector2.ZERO))<140:nearby_npcs.append({"id":n["id"],"name":n["name"],"kind":"npc","aliases":[n.get("role","")]})
    for item in items:
        if not bool(item.get("taken",false)) and player.distance_to(item.get("pos",Vector2.ZERO))<120:nearby_objects.append({"id":item["id"],"name":item["name"],"kind":"item"})
    for c in corpses:
        if player.distance_to(c.get("pos",Vector2.ZERO))<140:nearby_corpses.append(c)
    return {"nearby_npcs":nearby_npcs,"nearby_objects":nearby_objects,"nearby_corpses":nearby_corpses,"inventory":inventory,"has_fire_source":_inventory_has_fire()}

func _inventory_has_fire()->bool:
    for i in inventory:
        var n=str(i.get("name","")).to_lower()
        if "факел" in n or "огниво" in n or "спички" in n:return true
    return false

func _stat_for(verb:String)->int:
    if verb in ["break","sever","climb"]:return int(skills.get("labor",0)/2)
    if verb in ["steal","hide","sneak","pick_lock","throw"]:return int(skills.get("stealth",0)/2)
    if verb in ["persuade","deceive","threaten"]:return int(skills.get("charm",0)/2)
    if verb in ["search"]:return int(skills.get("magic",0)/3)
    return 0

func _skill_for(verb:String)->int:
    if verb=="steal":return int(skills.get("theft",0))
    if verb in ["hide","sneak","pick_lock"]:return int(skills.get("stealth",0))
    if verb in ["persuade","deceive"]:return int(skills.get("charm",0))
    if verb=="climb":return int(skills.get("labor",0))
    return 0

func _roll_context()->Dictionary:
    return {"dark":hour>=21 or hour<6,"rain":false,"guarded":current_location_id in ["castle","guard_barracks"]}

func _apply_action_outcome(action:Dictionary,result:Dictionary,outcome:Dictionary):
    var roll_text=""
    if int(result.get("roll",0))>0:roll_text=" 🎲 %d + бонусы = %d против DC %d"%[result["roll"],result["total"],result["dc"]]
    var text=str(outcome.get("text",""))+roll_text
    history.record(day,hour,"free_action","%s"%text,{"social":0.05})
    var spawn=outcome.get("spawn",{})
    if typeof(spawn)==TYPE_DICTIONARY and not spawn.is_empty():inventory.append(spawn)
    var mutation:Dictionary=outcome.get("mutation",{})
    if mutation.get("type","")=="social":
        var idx=_find_npc(str(mutation.get("target","")))
        if idx>=0:
            var verb=str(mutation.get("verb",""));player_social.interact(npcs[idx],"help" if verb=="persuade" else "threaten",int(skills.get("charm",0)))
    _notify(text);saves.save_game(_capture_save())

func simulate_death(npc_id:String,cause:String):
    var idx=_find_npc(npc_id)
    if idx>=0:
        var n=npcs[idx]
        corpses.append({"id":"corpse_"+npc_id,"person_id":npc_id,"name":str(n.get("name",npc_id)),"kind":"corpse","pos":n.get("pos",Vector2.ZERO),"aliases":["труп","тело"],"head_attached":true})
    super.simulate_death(npc_id,cause)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var r=Rect2(s.x-610,s.y-82,240,54);draw_rect(r,Color("#55446d"));draw_string(ThemeDB.fallback_font,r.position+Vector2(22,33),"✦ СВОЁ ДЕЙСТВИЕ",0,205,15,Color.WHITE)
    if free_action_mode:
        draw_rect(Rect2(s.x*.08,s.y*.34,s.x*.84,105),Color(0.02,0.025,0.04,.96))
        draw_string(ThemeDB.fallback_font,Vector2(s.x*.10,s.y*.38),"Что ты хочешь сделать?",0,s.x*.75,18,Color("#eadcf4"))
        draw_string(ThemeDB.fallback_font,Vector2(s.x*.10,s.y*.43),free_action_text+"▌",0,s.x*.75,16,Color.WHITE)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["corpses"]=corpses;data["world_mutations"]=mutator.mutations;data["spawned_objects"]=mutator.spawned_objects;return data

func _apply_save(data:Dictionary):
    super._apply_save(data);corpses=data.get("corpses",[]);mutator.mutations=data.get("world_mutations",[]);mutator.spawned_objects=data.get("spawned_objects",[])
