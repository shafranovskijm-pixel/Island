extends "res://scripts/game_v16.gd"

const ActionPlanner=preload("res://scripts/action_planner.gd")
var planner=ActionPlanner.new()
var active_plan:Array=[]
var active_plan_index:=0
var plan_log:Array=[]

func _submit_free_action():
    var text=free_action_text.strip_edges();free_action_mode=false;free_action_text=""
    if text=="":return
    var world=_action_world_snapshot()
    var plan=planner.build_plan(text,free_actions,world)
    if not bool(plan.get("ok",false)):
        history.record(day,hour,"free_action","План '%s' требует AI-разбора шага: %s"%[text,plan.get("failed_step","")],{})
        _notify("Один из шагов пока требует AI-мастера.")
        return
    active_plan=plan["steps"];active_plan_index=0;plan_log.clear()
    _execute_next_plan_step()

func _execute_next_plan_step():
    if active_plan_index>=active_plan.size():
        var summary="План завершён: "+" → ".join(plan_log)
        history.record(day,hour,"free_plan",summary,{"social":0.08})
        _notify(summary);active_plan.clear();active_plan_index=0;saves.save_game(_capture_save());return
    var world=_action_world_snapshot()
    var recheck=planner.revalidate_remaining(active_plan,active_plan_index,free_actions,world)
    if not bool(recheck.get("ok",false)):
        var msg="План остановился: %s"%recheck.get("reason","условия изменились")
        history.record(day,hour,"free_plan",msg,{})
        _notify(msg);active_plan.clear();return
    var action:Dictionary=active_plan[active_plan_index]
    var valid=free_actions.validate(action,world)
    if not bool(valid.get("ok",false)):
        _notify(str(valid.get("reason","Шаг невозможен.")));active_plan.clear();return
    var verb=str(action["verb"]);var dc=dice.dc_for(verb,_roll_context())
    var result={"success":true,"roll":0,"total":0,"dc":dc,"critical":false,"fumble":false,"margin":0}
    if dice.should_roll(action):result=dice.check(_stat_for(verb),_skill_for(verb),dc,0)
    var outcome=mutator.apply(action,result,world)
    _apply_action_outcome(action,result,outcome)
    plan_log.append(str(action.get("source_text",verb))+": "+("успех" if bool(result.get("success",false)) else "провал"))
    var severe=bool(result.get("fumble",false)) or int(result.get("margin",0))<=-5
    if severe:
        var failmsg="План сорван на шаге %d: %s"%[active_plan_index+1,outcome.get("text","критический провал")]
        history.record(day,hour,"free_plan",failmsg,{})
        _notify(failmsg);active_plan.clear();return
    active_plan_index+=1
    call_deferred("_execute_next_plan_step")

func _apply_action_outcome(action:Dictionary,result:Dictionary,outcome:Dictionary):
    super._apply_action_outcome(action,result,outcome)
    # Every successful mutation changes the next step context immediately.
    var mutation:Dictionary=outcome.get("mutation",{})
    var mtype=str(mutation.get("type",""))
    if mtype=="burning":
        production.unrest=clampf(production.unrest+8,0,100)
        for i in npcs.size():
            if player.distance_to(npcs[i].get("pos",Vector2.ZERO))<260:npcs[i]["target"]=player+Vector2(randf_range(-80,80),randf_range(-80,80))
    elif mtype=="broken":
        production.crime_pressure=clampf(production.crime_pressure+2,0,100)
    elif mtype=="social" and str(mutation.get("verb",""))=="threaten":
        wanted+=1

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    if not active_plan.is_empty():
        draw_rect(Rect2(s.x*.23,s.y-142,s.x*.54,44),Color(0.03,0.035,0.06,.90))
        draw_string(ThemeDB.fallback_font,Vector2(s.x*.25,s.y-115),"План: шаг %d/%d"%[active_plan_index+1,active_plan.size()],0,s.x*.50,14,Color("#dfd1ef"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["active_plan"]=active_plan;data["active_plan_index"]=active_plan_index;data["plan_log"]=plan_log;return data

func _apply_save(data:Dictionary):
    super._apply_save(data);active_plan=data.get("active_plan",[]);active_plan_index=int(data.get("active_plan_index",0));plan_log=data.get("plan_log",[])
