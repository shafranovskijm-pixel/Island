extends "res://scripts/game_v34.gd"

const WorldVarietySystem=preload("res://scripts/world_variety_system.gd")
const ScenarioChainSystem=preload("res://scripts/scenario_chain_system.gd")
var world_variety=WorldVarietySystem.new()
var scenario_chains=ScenarioChainSystem.new()

func _process(delta):
    super._process(delta)
    world_variety.tick(day,hour,{"hunger":production.hunger_pressure,"unrest":production.unrest,"crime":production.crime_pressure,"prosperity":production.prosperity,"vampire_rumors":bool(locations.secrets.get("vampires",false)),"foreigners":0,"fishing_pressure":0})
    for ev in world_variety.drain():
        history.record(day,hour,str(ev.get("type","ambient")),str(ev.get("text","Что-то изменилось на острове.")),{})
        if str(ev.get("type","")) in ["weather","festival"]:_notify(str(ev.get("text","Событие.")))
    for ev in scenario_chains.tick(day,npcs):_apply_chain_event(ev)

func _apply_scenario(ev:Dictionary):
    super._apply_scenario(ev)
    scenario_chains.ingest(ev,day)
    var id=str(ev.get("id",""))
    if id in ["vampire_rumor","servant_sees_vampire","court_conspiracy","bread_riot","foreign_ship"]:
        world_variety.add_rumor(str(ev.get("text","Слух")),id,.75)

func _apply_chain_event(ev:Dictionary):
    scenario_history.append(ev.duplicate(true));if scenario_history.size()>150:scenario_history.pop_front()
    history.record(day,hour,"scenario_chain",str(ev.get("text","История развивается.")),{"social":0.08})
    # Chain steps remain mostly diegetic; only events likely visible to the player are surfaced.
    var id=str(ev.get("id",""))
    if id in ["repair_needed","shipwright_offer","tracks_found","missing_money_noticed","hunter_arrives","guard_market_patrol"]:_notify(str(ev.get("text","История развивается.")))

func fish_from_boat():
    if current_location_id not in ["port","fisher_cove"]:_notify("Для рыбалки нужно выйти к воде.");return
    var result=player_boats.fish(learning,day,hour)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не получилось рыбачить.")));return
    var qty=float(result.get("quantity",0))*world_variety.fishing_multiplier()
    inventory.append({"id":"boat_fish_%d"%Time.get_ticks_usec(),"name":"свежая рыба","kind":"resource","resource":"fish","quantity":qty,"value":2})
    _notify("Поймано %.1f рыбы. Погода: %s."%[qty,world_variety.weather])

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    draw_rect(Rect2(710,412,555,28),Color(0.02,0.04,0.05,.78))
    draw_string(ThemeDB.fallback_font,Vector2(722,431),"Погода %s · рыба %.0f · страх %.0f · слухов %d · цепочек %d"%[world_variety.weather,world_variety.wildlife.get("fish",0),world_variety.public_mood.get("fear",0),world_variety.rumors.size(),scenario_chains.chains.size()],0,530,11,Color("#b9d0d1"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["world_variety"]=world_variety.serialize();data["scenario_chains"]=scenario_chains.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data)
    var w=data.get("world_variety",{});if typeof(w)==TYPE_DICTIONARY:world_variety.restore(w)
    var c=data.get("scenario_chains",{});if typeof(c)==TYPE_DICTIONARY:scenario_chains.restore(c)
