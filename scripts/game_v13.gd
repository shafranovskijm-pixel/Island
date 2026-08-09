extends "res://scripts/game_v12.gd"

const ProductionEconomy=preload("res://scripts/production_economy.gd")
const CivilianPopulation=preload("res://scripts/civilian_population.gd")
var production=ProductionEconomy.new()
var civilians=CivilianPopulation.new()
var production_event_cursor:=0
var owned_property:=""

func _ready():
    super._ready()
    var existing:Dictionary={}
    for n in npcs:existing[str(n["id"])]=true
    for n in civilians.setup():
        if not existing.has(str(n["id"])):npcs.append(n)
    npc_sim.setup(npcs);social.setup(npcs);player_social.setup(npcs)
    _restore_location_roles()
    production.setup(npcs)

func _process(delta):
    super._process(delta)
    production.tick(npcs,ship_system.ships,day,hour)
    _apply_economic_pressure(delta)
    _drain_production_events()

func _apply_economic_pressure(delta:float):
    var snap=production.snapshot()
    var hunger_p=float(snap["hunger_pressure"])
    var crime_p=float(snap["crime_pressure"])
    if hunger_p>35:
        for i in npcs.size():
            if not bool(npcs[i].get("alive",true)):continue
            npcs[i]["stress"]=clampf(float(npcs[i].get("stress",0))+delta*hunger_p*.003,0,100)
    # High scarcity can turn ordinary unemployed civilians toward opportunistic crime.
    if crime_p>58 and randi()%900==0:
        var candidates:Array=[]
        for i in npcs.size():
            if str(npcs[i].get("job",""))=="" and int(npcs[i].get("money",0))<3 and bool(npcs[i].get("alive",true)):candidates.append(i)
        if not candidates.is_empty():
            var idx=int(candidates.pick_random());npcs[idx]["vice"]="мелкие кражи";npcs[idx]["stress"]=minf(100,float(npcs[idx].get("stress",0))+12)
            history.record(day,hour,"economy_crime","%s из-за нужды начал промышлять кражами."%npcs[idx]["name"],{})

func _drain_production_events():
    while production_event_cursor<production.events.size():
        var e=production.events[production_event_cursor]
        history.record(day,hour,"economy",str(e.get("text","Экономическое событие.")),{})
        production_event_cursor+=1

func request_construction(kind:String):
    var result=production.can_build(kind)
    if not bool(result.get("ok",false)):
        _notify(str(result.get("reason","Строительство невозможно.")));return
    var cost=int(result.get("cost",0))
    if coins<cost:_notify("Не хватает денег на строительство.");return
    coins-=cost;production.build(kind);owned_property=kind
    history.record(day,hour,"property","Заказал строительство: %s."%kind,{"merchant":0.5})
    _notify("Строительство заказано. Ресурсы и рабочие заняты.")

func _do_location_npc_action(n:Dictionary,action:int):
    var id=str(n.get("id",""))
    if id.begins_with("civilian_"):
        if action==0:
            n["rel"]+=1
            var role=str(n.get("role","житель"))
            history.record(day,hour,"civilian","Поговорил с жителем (%s) о его работе."%role,{"social":0.1})
            if role=="строитель" and owned_property=="" and coins>=25:
                request_construction("hut")
        else:
            if coins>0:coins-=1;n["money"]=int(n.get("money",0))+1;n["rel"]+=1
        var idx=_find_npc(id);if idx>=0:npcs[idx]=n
        _close_dialog();return
    super._do_location_npc_action(n,action)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var snap=production.snapshot()
    draw_rect(Rect2(18,206,520,62),Color(0.02,0.04,0.05,.86))
    draw_string(ThemeDB.fallback_font,Vector2(30,228),"Еда %.0f · дерево %.0f · камень %.0f · строители %d"%[production.resources["food"],production.resources["wood"],production.resources["stone"],production.jobs["builder"]],0,495,13,Color("#e8deb5"))
    draw_string(ThemeDB.fallback_font,Vector2(30,250),"Голод %.0f%% · беспорядки %.0f%% · преступность %.0f%% · благополучие %.0f%%"%[snap["hunger_pressure"],snap["unrest"],snap["crime_pressure"],snap["prosperity"]],0,495,13,Color("#e6c0b2"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["production_resources"]=production.resources;data["production_prices"]=production.prices;data["owned_property"]=owned_property
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var r=data.get("production_resources",{});if typeof(r)==TYPE_DICTIONARY:production.resources=r
    var p=data.get("production_prices",{});if typeof(p)==TYPE_DICTIONARY:production.prices=p
    owned_property=str(data.get("owned_property",""))
