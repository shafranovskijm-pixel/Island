extends "res://scripts/game_v28.gd"

const NPCTradeNetwork=preload("res://scripts/npc_trade_network.gd")
var trade_network=NPCTradeNetwork.new()

func _process(delta):
    super._process(delta)
    var result=trade_network.tick(npcs,property_economy.properties,production,day,hour)
    npcs=result.get("npcs",npcs)
    for e in trade_network.drain():
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","trade")),str(e.get("text","Торговая сделка.")),{"merchant":0.05})
        if str(e.get("type","")) in ["relief_trade","trade"] and randf()<0.18:_notify(str(e.get("text","Торговцы перемещают товары.")))

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var food_market=trade_network.district_stock("market","food")
    var food_port=trade_network.district_stock("port","food")
    var food_slums=trade_network.district_stock("slums","food")
    draw_rect(Rect2(710,346,555,30),Color(0.02,0.04,0.05,.80))
    draw_string(ThemeDB.fallback_font,Vector2(722,366),"Еда на складах: рынок %.0f · порт %.0f · трущобы %.0f"%[food_market,food_port,food_slums],0,530,12,Color("#d9c7a6"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["npc_trade_network"]=trade_network.serialize();return data

func _apply_save(data:Dictionary):
    super._apply_save(data);var t=data.get("npc_trade_network",{});if typeof(t)==TYPE_DICTIONARY:trade_network.restore(t)
