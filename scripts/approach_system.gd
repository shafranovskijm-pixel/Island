extends RefCounted

var idle_seconds:=0.0
var last_player_pos:=Vector2.ZERO
var cooldown:=0.0
var rng:=RandomNumberGenerator.new()

func _init():
    rng.randomize()

func tick(delta:float,player_pos:Vector2,npcs:Array,context:Dictionary)->Dictionary:
    if cooldown>0.0:
        cooldown=maxf(0.0,cooldown-delta)
    if last_player_pos==Vector2.ZERO:
        last_player_pos=player_pos
    if player_pos.distance_to(last_player_pos)<3.0:
        idle_seconds+=delta
    else:
        idle_seconds=0.0
        last_player_pos=player_pos
    if idle_seconds<18.0 or cooldown>0.0:
        return {}
    var candidate=_choose_candidate(player_pos,npcs,context)
    if candidate.is_empty():
        idle_seconds=0.0
        cooldown=8.0
        return {}
    idle_seconds=0.0
    cooldown=35.0
    return candidate

func _choose_candidate(player_pos:Vector2,npcs:Array,context:Dictionary)->Dictionary:
    var scored:Array=[]
    var location=str(context.get("location",""))
    var wanted=int(context.get("wanted",0))
    var faction_rep:Dictionary=context.get("faction_rep",{})
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)) or bool(n.get("hidden",false)):continue
        var d=player_pos.distance_to(n.get("pos",Vector2.ZERO))
        if d<90 or d>520:continue
        var score=0.0
        var role=str(n.get("role","")).to_lower()
        var rel=int(n.get("rel",0))
        score+=maxf(0.0,40.0-d/18.0)
        score+=rel*4.0
        if wanted>0 and "страж" in role:score+=35.0
        if location=="market" and "торгов" in role:score+=15.0
        if location=="slums" and ("нищий" in role or "контраб" in role):score+=18.0
        if location=="graveyard" and ("могиль" in role or "жрец" in role):score+=14.0
        if location=="castle" and ("страж" in role or "канцлер" in role):score+=14.0
        if int(n.get("money",0))<2 and "нищий" in role:score+=10.0
        if score>5.0:scored.append({"index":i,"score":score})
    if scored.is_empty():return {}
    scored.sort_custom(func(a,b):return float(a["score"])>float(b["score"]))
    var pick=scored[0] if scored.size()==1 or rng.randf()<0.7 else scored[min(1,scored.size()-1)]
    var idx=int(pick["index"])
    var npc=npcs[idx]
    return {"npc_index":idx,"npc_id":npc.get("id",""),"reason":_reason(npc,context)}

func _reason(npc:Dictionary,context:Dictionary)->String:
    var role=str(npc.get("role","")).to_lower()
    if int(context.get("wanted",0))>0 and "страж" in role:return "law"
    if "нищий" in role:return "beg"
    if "торгов" in role:return "trade"
    if "контраб" in role:return "underworld"
    if "жрец" in role:return "faith"
    if int(npc.get("rel",0))>=3:return "relationship"
    return "conversation"
