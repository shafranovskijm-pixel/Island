extends "res://scripts/game_v33.gd"

const EmergentScenarioDirector=preload("res://scripts/emergent_scenario_director.gd")
var scenario_director=EmergentScenarioDirector.new()
var scenario_history:Array=[]

func _process(delta):
    super._process(delta)
    var generated=scenario_director.tick(_scenario_context())
    for ev in generated:
        _apply_scenario(ev)

func _scenario_context()->Dictionary:
    var e=estate.player_estate()
    var castle_stats={"castle_level":0}
    if not e.is_empty():castle_stats=castle_builder.stats(str(e.get("id","")))
    var locked:=0
    for d in castle_security.door_locks.values():
        if bool(d.get("locked",false)):locked+=1
    var guards:=0
    if not e.is_empty():
        for s in e.get("staff",[]):
            if str(s.get("role","")) in ["guard","captain"]:guards+=1
    var tool_shortage:=0
    for n in npcs:
        if int(n.get("tool_shortage_days",0))>0:tool_shortage+=1
    var boat=player_boats.player_boat()
    var social_class="poor"
    if coins>=220:social_class="wealthy"
    elif coins>=70:social_class="comfortable"
    elif coins>=15:social_class="worker"
    return {
        "day":day,"hour":hour,"player_pos":player,"location":current_location_id,"npcs":npcs,"estate":e,
        "castle_level":int(castle_stats.get("castle_level",0)),"locked_doors":locked,"guards":guards,
        "hunger":float(production.hunger_pressure),"unrest":float(production.unrest),"crime":float(production.crime_pressure),"prosperity":float(production.prosperity),
        "builders":int(production.jobs.get("builder",0)),"farmers":int(production.jobs.get("farmer",0)),"tool_shortage":tool_shortage,
        "food_market":trade_network.district_stock("market","food"),"food_port":trade_network.district_stock("port","food"),
        "wanted":wanted,"influence":influence,"reputation":reputation,"player_class":social_class,
        "secrets":locations.secrets,"is_vampire":bool(vampire.state.get("is_vampire",false)),"blood":float(vampire.state.get("blood",100)),
        "bat_form":bool(vampire.state.get("bat_form",false)),"temple_rep":0,
        "has_boat":not boat.is_empty(),"sailing":int(learning.effective_bonus("sailing"))
    }

func _apply_scenario(ev:Dictionary):
    scenario_history.append(ev.duplicate(true))
    if scenario_history.size()>120:scenario_history.pop_front()
    var text=str(ev.get("text","Событие на острове."))
    history.record(int(ev.get("day",day)),float(ev.get("hour",hour)),"emergent_scenario",text,{"social":0.08})
    var approach=str(ev.get("approach_npc_id",""))
    if approach!="":
        var idx=_find_npc(approach)
        if idx>=0:
            npcs[idx]["target"]=player
            npcs[idx]["scenario_reason"]=str(ev.get("id",""))
            npcs[idx]["scenario_target_day"]=day
    _apply_scenario_effects(ev.get("effects",{}))
    if _scenario_is_visible(ev):_notify(text)

func _apply_scenario_effects(effects:Dictionary):
    if effects.is_empty():return
    if effects.has("unrest"):production.unrest=clampf(float(production.unrest)+float(effects["unrest"]),0,100)
    if effects.has("crime"):production.crime_pressure=clampf(float(production.crime_pressure)+float(effects["crime"]),0,100)
    if effects.has("prosperity"):production.prosperity=clampf(float(production.prosperity)+float(effects["prosperity"]),0,100)
    if effects.has("food_port"):
        trade_network.market_warehouses["port"]["food"]=float(trade_network.market_warehouses["port"].get("food",0))+float(effects["food_port"])
    if effects.has("food_slums"):
        trade_network.market_warehouses["slums"]["food"]=float(trade_network.market_warehouses["slums"].get("food",0))+float(effects["food_slums"])
    if effects.has("boat_damage"):
        for i in player_boats.boats.size():
            if str(player_boats.boats[i].get("owner",""))=="player":
                player_boats.boats[i]["condition"]=maxf(0,float(player_boats.boats[i].get("condition",100))-float(effects["boat_damage"]))
                break
    if bool(effects.get("blood_hunger",false)):
        energy=maxf(0,energy-5)
    if bool(effects.get("brawl",false)):
        for n in npcs:
            if player.distance_to(n.get("pos",Vector2.ZERO))<180:n["stress"]=minf(100,float(n.get("stress",0))+4)

func _scenario_is_visible(ev:Dictionary)->bool:
    var id=str(ev.get("id",""))
    if str(ev.get("approach_npc_id",""))!="":return false
    if id in ["servant_theft","house_intruder","kidnap_plot","court_conspiracy","servant_sees_vampire"]:return false
    return true

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    draw_rect(Rect2(710,380,555,28),Color(0.02,0.04,0.05,.78))
    draw_string(ThemeDB.fallback_font,Vector2(722,399),"Историй мира: %d · директор не выдаёт квесты"%scenario_history.size(),0,530,11,Color("#c6b8d3"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["scenario_director"]=scenario_director.serialize()
    data["scenario_history"]=scenario_history
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var sd=data.get("scenario_director",{})
    if typeof(sd)==TYPE_DICTIONARY:scenario_director.restore(sd)
    var sh=data.get("scenario_history",[])
    if typeof(sh)==TYPE_ARRAY:scenario_history=sh
