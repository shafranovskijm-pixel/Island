extends RefCounted

var plots:Array=[]
var events:Array=[]
var rng:=RandomNumberGenerator.new()
var next_plot_day:=2

func setup(): rng.randomize()

func tick(npcs:Array,day:int,hour:float,faction_relations:Dictionary)->Array:
    if day<next_plot_day or hour<12.0:return npcs
    next_plot_day=day+rng.randi_range(1,3)
    var actors:Array=[]
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)):continue
        if int(n.get("influence",0))>=35 or float(n.get("traits",{}).get("ambition",0))>0.7:
            actors.append(i)
    if actors.is_empty():return npcs
    var ai:int=actors[rng.randi_range(0,actors.size()-1)]
    var actor=npcs[ai]
    var action:=_choose_action(actor)
    var result:=_execute(action,ai,npcs,day,hour,faction_relations)
    return result

func _choose_action(actor:Dictionary)->String:
    var greed=float(actor.get("traits",{}).get("greed",0))
    var ambition=float(actor.get("traits",{}).get("ambition",0))
    var law=float(actor.get("traits",{}).get("lawfulness",0.5))
    if ambition>0.78 and rng.randf()<0.45:return "plot_power"
    if greed>0.72:return "bribe"
    if law<0.35 and rng.randf()<0.5:return "betray"
    return "spread_rumor"

func _execute(action:String,actor_idx:int,npcs:Array,day:int,hour:float,faction_relations:Dictionary)->Array:
    var actor=npcs[actor_idx]
    var target_idx:=_pick_target(actor_idx,npcs)
    if target_idx<0:return npcs
    var target=npcs[target_idx]
    match action:
        "bribe":
            var amount:=min(4,int(actor.get("money",0)))
            if amount>0:
                actor["money"]=int(actor.get("money",0))-amount
                target["money"]=int(target.get("money",0))+amount
                target["corruption"]=float(target.get("corruption",0))+amount*0.15
                _log(day,hour,"%s подкупил %s."%[actor["name"],target["name"]],action,actor,target)
        "betray":
            target["stress"]=float(target.get("stress",0))+20.0
            actor["influence"]=int(actor.get("influence",0))+2
            _log(day,hour,"%s предал %s ради собственной выгоды."%[actor["name"],target["name"]],action,actor,target)
        "plot_power":
            actor["influence"]=int(actor.get("influence",0))+1
            actor["plotting"]=true
            target["suspicion"]=int(target.get("suspicion",0))+1
            _log(day,hour,"%s начал интригу против %s."%[actor["name"],target["name"]],action,actor,target)
        "spread_rumor":
            var memory={"type":"rumor","about":str(target["id"]),"day":day,"hour":hour,"text":"сомнительные слухи"}
            actor["memory"].append(memory)
            _log(day,hour,"%s распустил слух о %s."%[actor["name"],target["name"]],action,actor,target)
    npcs[actor_idx]=actor;npcs[target_idx]=target
    return npcs

func _pick_target(actor_idx:int,npcs:Array)->int:
    var choices:Array=[]
    for i in npcs.size():
        if i==actor_idx:continue
        if not bool(npcs[i].get("alive",true)):continue
        choices.append(i)
    if choices.is_empty():return -1
    return int(choices[rng.randi_range(0,choices.size()-1)])

func _log(day:int,hour:float,text:String,type:String,actor:Dictionary,target:Dictionary):
    var e={"day":day,"hour":hour,"type":type,"actor":str(actor["id"]),"target":str(target["id"]),"text":text}
    events.append(e);plots.append(e)
    if events.size()>80:events.pop_front()
