extends "res://scripts/game_v21.gd"

const HousingSystem=preload("res://scripts/housing_system.gd")
const HealthLifecycle=preload("res://scripts/health_lifecycle.gd")
var housing=HousingSystem.new()
var lifecycle=HealthLifecycle.new()
var player_home_id:=""

func _ready():
    super._ready()
    housing.setup()

func _process(delta):
    super._process(delta)
    npcs=housing.tick(npcs,day,hour)
    for e in housing.drain():history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","housing")),str(e.get("text","Изменение жилья.")),{})
    npcs=lifecycle.tick(npcs,production,day,hour)
    for e in lifecycle.drain():
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","health")),str(e.get("text","Событие здоровья.")),{})
        if str(e.get("type",""))=="death":
            var id=str(e.get("npc_id",""));if id!="":_register_system_death(id,str(e.get("text","умер")))

func _register_system_death(npc_id:String,cause:String):
    var idx=_find_npc(npc_id);if idx<0:return
    recent_dead_name=str(npcs[idx].get("name",npc_id))
    if npc_id==power.ruler_id:power.crisis_for("смерть правителя",npc_id,"трон",day,hour)

func claim_built_property_as_home(kind:String):
    if owned_property=="":return
    var loc="slums" if kind=="hut" else ("market" if kind in ["house","shop"] else "castle")
    var name={"hut":"Хижина героя","house":"Дом героя","mansion":"Особняк героя","shop":"Дом при лавке"}.get(kind,"Жильё героя")
    var h=housing.add_player_home(kind,name,loc,player);player_home_id=str(h["id"])
    history.record(day,hour,"home","Получил собственное жильё: %s."%name,{"homeless":-1.0,"merchant":0.15})

func request_construction(kind:String):
    var before=owned_property
    super.request_construction(kind)
    if owned_property!=before and owned_property==kind and kind in ["hut","house","mansion","shop"]:claim_built_property_as_home(kind)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var homeless:=0;var sick:=0
    for n in npcs:
        if bool(n.get("homeless",false)):homeless+=1
        if bool(n.get("sick",false)):sick+=1
    draw_rect(Rect2(710,278,555,30),Color(0.02,0.04,0.05,.80))
    draw_string(ThemeDB.fallback_font,Vector2(722,298),"Без жилья %d · больных %d · жилых мест %d"%[homeless,sick,housing.homes.size()],0,530,12,Color("#d8c9c0"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["housing"]=housing.serialize();data["player_home_id"]=player_home_id;return data

func _apply_save(data:Dictionary):
    super._apply_save(data);var h=data.get("housing",{});if typeof(h)==TYPE_DICTIONARY:housing.restore(h);player_home_id=str(data.get("player_home_id",""))
