extends "res://scripts/game_v20.gd"

const LaborMarket=preload("res://scripts/labor_market.gd")
var labor_market=LaborMarket.new()

func _process(delta):
    super._process(delta)
    npcs=labor_market.tick(npcs,property_economy.properties,production,day,hour)
    for e in labor_market.drain():
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","labor")),str(e.get("text","Изменение на рынке труда.")),{})

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var employed:=0;var poor:=0
    for n in npcs:
        if str(n.get("employment_property",""))!="":employed+=1
        if str(n.get("social_class","poor"))=="poor":poor+=1
    draw_rect(Rect2(710,244,555,30),Color(0.02,0.04,0.05,.80))
    draw_string(ThemeDB.fallback_font,Vector2(722,264),"Заняты %d/%d · бедных %d · предприятий %d"%[employed,npcs.size(),poor,property_economy.properties.size()],0,530,12,Color("#d5e0c2"))
