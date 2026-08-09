extends "res://scripts/game_v18.gd"

const HiddenGMDirector=preload("res://scripts/hidden_gm_director.gd")
const ApproachSystem=preload("res://scripts/approach_system.gd")

var hidden_gm=HiddenGMDirector.new()
var approach=ApproachSystem.new()
var approaching_npc_id:=""
var approach_reason:=""

func _process(delta):
    super._process(delta)
    hidden_gm.tick(npcs,_gm_world_state(),day,hour)
    _tick_approach(delta)

func _tick_approach(delta:float):
    if interaction_open or free_action_mode:return
    if approaching_npc_id=="":
        var a=approach.tick(delta,player,npcs,{"location":current_location_id,"wanted":wanted,"faction_rep":player_factions.reputation})
        if not a.is_empty():
            approaching_npc_id=str(a.get("npc_id",""));approach_reason=str(a.get("reason","conversation"))
            var idx=_find_npc(approaching_npc_id)
            if idx>=0:npcs[idx]["target"]=player
        return
    var idx=_find_npc(approaching_npc_id)
    if idx<0 or not bool(npcs[idx].get("alive",true)):
        approaching_npc_id="";approach_reason="";return
    # NPC keeps walking toward the current player position rather than teleporting.
    npcs[idx]["target"]=player
    var d=player.distance_to(npcs[idx].get("pos",Vector2.ZERO))
    if d<72:
        _complete_approach(idx)
    elif d>700 and approach_reason!="law":
        approaching_npc_id="";approach_reason=""

func _complete_approach(idx:int):
    var n=npcs[idx]
    var id=str(n.get("id",""))
    selected_npc=idx;interaction_open=true
    var hint=hidden_gm.npc_hint(id,current_location_id)
    if not hint.is_empty():
        n["memory"].append({"day":day,"hour":hour,"type":"told_player","text":hint.get("hint","")})
        history.record(day,hour,"rumor","%s сам подошёл и рассказал: %s"%[n.get("name","Кто-то"),hint.get("hint","")],{"social":0.1})
        _notify("%s подходит к тебе: «%s»"%[n.get("name","Кто-то"),hint.get("hint","")])
    else:
        match approach_reason:
            "law":_notify("%s подходит к тебе по делу стражи."%n.get("name","Стражник"))
            "beg":_notify("%s подходит и просит монету."%n.get("name","Нищий"))
            "trade":_notify("%s замечает тебя и сам начинает разговор о делах."%n.get("name","Торговец"))
            "underworld":_notify("%s подходит так, чтобы разговор не слышали лишние уши."%n.get("name","Незнакомец"))
            "relationship":_notify("%s сам ищет встречи с тобой."%n.get("name","Знакомый"))
            _:_notify("%s подходит поговорить."%n.get("name","Кто-то"))
    npcs[idx]=n
    approaching_npc_id="";approach_reason=""

func _gm_world_state()->Dictionary:
    return {
        "crypt_known":bool(locations.secrets.get("crypt_entrance",false)),
        "food_scarcity":int(production.hunger_pressure),
        "crime_pressure":int(production.crime_pressure),
        "occult_tension":int(faction_conflicts.tension("temple","occult")) if faction_conflicts.has_method("tension") else 0,
        "court_tension":int(faction_conflicts.tension("crown","underworld")) if faction_conflicts.has_method("tension") else 0
    }

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["gm_opportunities"]=hidden_gm.opportunities
    data["approaching_npc_id"]=approaching_npc_id
    data["approach_reason"]=approach_reason
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    hidden_gm.opportunities=data.get("gm_opportunities",[])
    approaching_npc_id=str(data.get("approaching_npc_id",""))
    approach_reason=str(data.get("approach_reason",""))
