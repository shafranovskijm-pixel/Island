extends "res://scripts/game_v13.gd"

const PropertyEconomy=preload("res://scripts/property_economy.gd")
var property_economy=PropertyEconomy.new()
var property_event_cursor:=0

func _ready():
    super._ready()
    property_economy.setup()

func _process(delta):
    super._process(delta)
    property_economy.tick(npcs,production,day,hour)
    _drain_property_events()

func _drain_property_events():
    while property_event_cursor<property_economy.events.size():
        var e=property_economy.events[property_event_cursor]
        history.record(day,hour,"property_economy",str(e.get("text","Изменение собственности.")),{})
        property_event_cursor+=1

func request_construction(kind:String):
    var result=production.can_build(kind)
    if not bool(result.get("ok",false)):
        _notify(str(result.get("reason","Строительство невозможно.")));return
    var cost=int(result.get("cost",0))
    if coins<cost:_notify("Не хватает денег на строительство.");return
    coins-=cost;production.build(kind);owned_property=kind
    var actual_kind=kind
    if kind=="house":actual_kind="mansion" if coins>250 else "shop"
    var newp=property_economy.create_property(actual_kind,"Владение игрока", "player", player+Vector2(80,40))
    history.record(day,hour,"property","Построил владение: %s."%str(newp.get("name",kind)),{"merchant":0.6})
    _notify("Строительство завершено: теперь это часть экономики острова.")

func _do_location_npc_action(n:Dictionary,action:int):
    var role=str(n.get("role","")).to_lower()
    if action==0 and ("строитель" in role) and property_economy.ownership_summary("player").is_empty() and coins>=25:
        request_construction("hut")
        return
    super._do_location_npc_action(n,action)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var owned=property_economy.ownership_summary("player")
    draw_rect(Rect2(545,206,360,62),Color(0.02,0.04,0.05,.86))
    draw_string(ThemeDB.fallback_font,Vector2(557,228),"Владения: %d · предприятия: %d"%[owned.size(),property_economy.properties.size()],0,335,13,Color("#d6e0b0"))
    if not owned.is_empty():
        var p=owned[0]
        draw_string(ThemeDB.fallback_font,Vector2(557,250),"%s · работники %d/%d · прибыль %.1f"%[p["name"],p["workers"].size(),p["worker_slots"],p["profit"]],0,335,13,Color("#d6e0b0"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["properties"]=property_economy.properties
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var props=data.get("properties",[])
    if typeof(props)==TYPE_ARRAY:property_economy.properties=props
