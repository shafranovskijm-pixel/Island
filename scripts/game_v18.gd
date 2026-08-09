extends "res://scripts/game_v17.gd"

const ConditionalPlanEngine=preload("res://scripts/conditional_plan_engine.gd")
var conditional_plans=ConditionalPlanEngine.new()
var pending_condition_plan:Dictionary={}

func _submit_free_action():
    var text=free_action_text.strip_edges();free_action_mode=false;free_action_text=""
    if text=="":return
    var world=_action_world_snapshot_extended()
    if "если" in text.to_lower():
        var cp=conditional_plans.parse(text,free_actions,world)
        if bool(cp.get("ok",false)):
            _execute_conditional_plan(cp,world)
            return
    super._submit_free_action_text(text)

func _submit_free_action_text(text:String):
    var world=_action_world_snapshot_extended()
    var action=free_actions.parse_local(text,world)
    if not bool(action.get("ok",false)):
        history.record(day,hour,"free_action","Попытался: %s. Действие требует разбора AI-мастером."%text,{})
        _notify("Пока не понял действие локально. Оно будет передаваться AI-мастеру после подключения модели.")
        return
    var valid=free_actions.validate(action,world)
    if not bool(valid.get("ok",false)):_notify(str(valid.get("reason","Действие невозможно.")));return
    _execute_single_action(action)

func _execute_conditional_plan(plan:Dictionary,world:Dictionary):
    var condition:Dictionary=plan.get("condition",{})
    var passed=conditional_plans.evaluate(condition,world)
    var selected:Dictionary=plan.get("then",{}) if passed else plan.get("else",{})
    var branch="условие выполнено" if passed else "условие не выполнено"
    history.record(day,hour,"conditional_plan","План: %s — %s."%[plan.get("raw",""),branch],{})
    if selected.is_empty():
        pending_condition_plan=plan
        _notify("Условие пока не выполнено. План можно будет повторить позже.")
        return
    var valid=free_actions.validate(selected,world)
    if not bool(valid.get("ok",false)):
        _notify(str(valid.get("reason","Выбранная ветка плана сейчас невозможна.")))
        return
    _execute_single_action(selected)

func _execute_single_action(action:Dictionary):
    var verb=str(action["verb"]);var stat=_stat_for(verb);var skill=_skill_for(verb);var dc=dice.dc_for(verb,_roll_context())
    var result={"success":true,"roll":0,"total":0,"dc":dc,"critical":false,"fumble":false,"margin":0}
    if dice.should_roll(action):result=dice.check(stat,skill,dc,0)
    last_roll=result
    var outcome=mutator.apply(action,result,_action_world_snapshot_extended())
    _apply_action_outcome(action,result,outcome)

func _action_world_snapshot_extended()->Dictionary:
    var world=_action_world_snapshot()
    world["night"]=hour>=21.0 or hour<6.0
    var arr:Array=[]
    for n in npcs:
        if bool(n.get("alive",true)) and player.distance_to(n.get("pos",Vector2.ZERO))<160:
            var copy={"id":n["id"],"name":n["name"],"role":n.get("role",""),"kind":"npc","watching_player":player.distance_to(n.get("pos",Vector2.ZERO))<90}
            arr.append(copy)
    world["nearby_npcs"]=arr
    return world

func _process(delta):
    super._process(delta)
    if not pending_condition_plan.is_empty() and int(Time.get_ticks_msec())%1200<20:
        var world=_action_world_snapshot_extended()
        if conditional_plans.evaluate(pending_condition_plan.get("condition",{}),world):
            var plan=pending_condition_plan.duplicate(true);pending_condition_plan={}
            _notify("Условие твоего плана наступило.")
            _execute_conditional_plan(plan,world)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["pending_condition_plan"]=pending_condition_plan;return data

func _apply_save(data:Dictionary):
    super._apply_save(data);pending_condition_plan=data.get("pending_condition_plan",{})
