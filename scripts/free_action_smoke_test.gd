extends SceneTree

const FreeActionEngine=preload("res://scripts/free_action_engine.gd")
const ActionPlanner=preload("res://scripts/action_planner.gd")
const DiceEngine=preload("res://scripts/dice_engine.gd")
const Mutator=preload("res://scripts/world_action_mutator.gd")

func _init():
    var free=FreeActionEngine.new();var planner=ActionPlanner.new();var dice=DiceEngine.new();var mut=Mutator.new()
    var world={"nearby_objects":[{"id":"door","name":"дверь","kind":"object"},{"id":"curtain","name":"штора","kind":"object"}],"nearby_npcs":[],"nearby_corpses":[],"inventory":[{"id":"torch","name":"факел"}],"has_fire_source":true}
    var plan=planner.build_plan("сломать дверь затем поджечь штору",free,world)
    if not bool(plan.get("ok",false)):
        push_error("FREE_ACTION_SMOKE_FAILED: planner");quit(1);return
    if plan["steps"].size()!=2:
        push_error("FREE_ACTION_SMOKE_FAILED: expected 2 steps");quit(1);return
    for action in plan["steps"]:
        var valid=free.validate(action,world)
        if not bool(valid.get("ok",false)):
            push_error("FREE_ACTION_SMOKE_FAILED: invalid step");quit(1);return
        var result={"success":true,"roll":15,"total":18,"dc":10,"critical":false,"fumble":false,"margin":8}
        var outcome=mut.apply(action,result,world)
        if not bool(outcome.get("ok",false)):
            push_error("FREE_ACTION_SMOKE_FAILED: mutation");quit(1);return
    if mut.mutations.size()<2:
        push_error("FREE_ACTION_SMOKE_FAILED: persistent mutations missing");quit(1);return
    print("FREE_ACTION_SMOKE_OK")
    quit(0)
