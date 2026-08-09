extends "res://scripts/game_v27.gd"

const NPCEquipmentEconomy=preload("res://scripts/npc_equipment_economy.gd")
var npc_equipment=NPCEquipmentEconomy.new()
var npc_equipment_event_cursor:=0

func _ready():
    super._ready()
    var result=npc_equipment.tick(npcs,property_economy.properties,production,day,8.0)
    npcs=result.get("npcs",npcs)

func _process(delta):
    # Let yesterday's equipment state influence this morning's enterprise tick;
    # then refresh purchases/production for the next cycle.
    super._process(delta)
    var result=npc_equipment.tick(npcs,property_economy.properties,production,day,hour)
    npcs=result.get("npcs",npcs)
    _drain_npc_equipment_events()

func _drain_npc_equipment_events():
    var ev=npc_equipment.drain()
    for e in ev:
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","npc_crafting")),str(e.get("text","Изменение снабжения инструментами.")),{})
        var type=str(e.get("type",""))
        if type in ["crafting_shortage","npc_tool_break"] and randf()<0.35:
            _notify(str(e.get("text","Проблема со снабжением.")))

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var without_tools:=0
    for n in npcs:
        if float(n.get("work_tool_factor",1.0))<0.8:without_tools+=1
    var stock_total:=0
    for key in npc_equipment.market_stock.keys():stock_total+=int(npc_equipment.market_stock[key])
    draw_rect(Rect2(710,312,555,30),Color(0.02,0.04,0.05,.80))
    draw_string(ThemeDB.fallback_font,Vector2(722,332),"Инструменты: склад %d · работников с дефицитом %d"%[stock_total,without_tools],0,530,12,Color("#d7d3b0"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["npc_equipment_economy"]=npc_equipment.serialize()
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var eq=data.get("npc_equipment_economy",{})
    if typeof(eq)==TYPE_DICTIONARY:npc_equipment.restore(eq)
