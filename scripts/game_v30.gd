extends "res://scripts/game_v29.gd"

const PlayerTradeSystem=preload("res://scripts/player_trade_system.gd")
var player_trade=PlayerTradeSystem.new()
var trade_menu_open:=false
var trade_resource_index:=0
var trade_resources=["food","wood","stone","cloth","tools","medicine"]

func _process(delta):
    super._process(delta)
    for e in player_trade.drain():
        history.record(day,hour,str(e.get("type","player_trade")),str(e.get("text","Торговая операция.")),{"merchant":0.25})
        if str(e.get("type",""))=="smuggling" and bool(e.get("detected",false)):
            wanted+=1
            reputation-=2
            player_factions.adjust("guard",-2,"контрабанда",day,hour)
            player_factions.adjust("underworld",2,"контрабанда",day,hour)

func _trade_district()->String:
    if current_location_id=="port":return "port"
    if current_location_id=="slums":return "slums"
    return "market"

func _trade_here()->bool:
    return current_location_id in ["market","port","slums"]

func _selected_trade_resource()->String:
    return str(trade_resources[clampi(trade_resource_index,0,trade_resources.size()-1)])

func buy_selected(qty:float=1.0):
    if not _trade_here():_notify("Торговать можно на рынке, в порту или Нижних улицах.");return
    var result=player_trade.buy(_selected_trade_resource(),_trade_district(),qty,coins,trade_network,production)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Покупка не удалась.")));return
    coins=int(result["coins"]);learning.practice("trade",0.65,day,hour)
    _notify("Куплено: %s x%.0f"%[_selected_trade_resource(),qty]);saves.save_game(_capture_save())

func sell_selected(qty:float=1.0):
    if not _trade_here():_notify("Торговать можно на рынке, в порту или Нижних улицах.");return
    var result=player_trade.sell(_selected_trade_resource(),_trade_district(),qty,coins,trade_network,production)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Продажа не удалась.")));return
    coins=int(result["coins"]);learning.practice("trade",0.85,day,hour)
    _notify("Продано: %s x%.0f"%[_selected_trade_resource(),qty]);saves.save_game(_capture_save())

func smuggle_selected(qty:float=1.0):
    if current_location_id not in ["port","slums"]:_notify("Для контрабанды нужен порт или Нижние улицы.");return
    var result=player_trade.smuggle(_selected_trade_resource(),_trade_district(),qty,coins,trade_network,production,int(skills.get("stealth",0)),wanted)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Сделка не состоялась.")));return
    coins=int(result["coins"]);learning.practice("trade",1.0,day,hour);learning.practice("stealth",0.5,day,hour)
    _notify("Контрабанда: %s"%("тебя заметили" if bool(result.get("detected",false)) else "прошла тихо"));saves.save_game(_capture_save())

func rent_trade_warehouse():
    if current_location_id!="port":_notify("Склад можно арендовать в порту.");return
    var result=player_trade.rent_warehouse(day,coins)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не удалось арендовать склад.")));return
    coins=int(result["coins"]);_notify("Склад арендован на 7 дней.");saves.save_game(_capture_save())

func store_selected(qty:float=1.0):
    if current_location_id!="port":_notify("Товарный склад находится в порту.");return
    var result=player_trade.store(_selected_trade_resource(),qty,day)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не удалось положить товар.")));return
    _notify("Товар отправлен на склад.");saves.save_game(_capture_save())

func withdraw_selected(qty:float=1.0):
    if current_location_id!="port":_notify("Товарный склад находится в порту.");return
    var result=player_trade.withdraw(_selected_trade_resource(),qty,day)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не удалось забрать товар.")));return
    _notify("Товар забран со склада.");saves.save_game(_capture_save())

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(s.x-520,s.y-145,160,50).has_point(event.position):
            trade_menu_open=not trade_menu_open;return
        if trade_menu_open and _handle_trade_touch(event.position):return
    super._unhandled_input(event)

func _handle_trade_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size
    var panel=Rect2(s.x*.50,s.y*.14,s.x*.46,s.y*.66)
    if not panel.has_point(pos):return false
    var left=Rect2(panel.position+Vector2(18,48),Vector2(45,34));var right=Rect2(panel.end.x-63,panel.position.y+48,45,34)
    if left.has_point(pos):trade_resource_index=(trade_resource_index-1+trade_resources.size())%trade_resources.size();return true
    if right.has_point(pos):trade_resource_index=(trade_resource_index+1)%trade_resources.size();return true
    var y=panel.position.y+118
    var buttons=["buy","sell","smuggle","rent","store","withdraw"]
    for i in buttons.size():
        var r=Rect2(panel.position.x+18,y+i*44,panel.size.x-36,36)
        if not r.has_point(pos):continue
        match buttons[i]:
            "buy":buy_selected(1.0)
            "sell":sell_selected(1.0)
            "smuggle":smuggle_selected(1.0)
            "rent":rent_trade_warehouse()
            "store":store_selected(1.0)
            "withdraw":withdraw_selected(1.0)
        return true
    return true

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var b=Rect2(s.x-520,s.y-145,160,50);draw_rect(b,Color("#705734"));draw_string(ThemeDB.fallback_font,b.position+Vector2(28,31),"ТОРГОВЛЯ",0,115,14,Color.WHITE)
    if trade_menu_open:_draw_trade_panel(s)

func _draw_trade_panel(s:Vector2):
    var panel=Rect2(s.x*.50,s.y*.14,s.x*.46,s.y*.66);draw_rect(panel,Color(0.035,0.03,0.02,.96));draw_rect(panel,Color("#947442"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(18,29),"Торговля героя",0,panel.size.x-36,20,Color("#f0e0bd"))
    draw_rect(Rect2(panel.position+Vector2(18,48),Vector2(45,34)),Color("#5e4d34"));draw_string(ThemeDB.fallback_font,panel.position+Vector2(33,71),"‹",0,20,20,Color.WHITE)
    draw_rect(Rect2(panel.end.x-63,panel.position.y+48,45,34),Color("#5e4d34"));draw_string(ThemeDB.fallback_font,Vector2(panel.end.x-48,panel.position.y+71),"›",0,20,20,Color.WHITE)
    var res=_selected_trade_resource();var district=_trade_district()
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(78,70),"%s · %s"%[res,district],0,panel.size.x-156,16,Color.WHITE)
    var buy_p=trade_network._district_price(res,district,production,true);var sell_p=trade_network._district_price(res,district,production,false)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(18,102),"Цена покупки %.1f · продажи %.1f · груз %.1f"%[buy_p,sell_p,float(player_trade.cargo.get(res,0.0))],0,panel.size.x-36,12,Color("#d7c99c"))
    var labels=["КУПИТЬ 1","ПРОДАТЬ 1","КОНТРАБАНДА 1","АРЕНДОВАТЬ СКЛАД","НА СКЛАД 1","ЗАБРАТЬ 1"]
    var y=panel.position.y+118
    for i in labels.size():
        var r=Rect2(panel.position.x+18,y+i*44,panel.size.x-36,36);draw_rect(r,Color("#5c503d"));draw_string(ThemeDB.fallback_font,r.position+Vector2(14,24),labels[i],0,r.size.x-28,13,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+18,panel.end.y-22),"Прибыль %.1f · жара контрабанды %.0f · аренда до дня %d"%[player_trade.trade_profit,player_trade.contraband_heat,player_trade.warehouse_rent_paid_until],0,panel.size.x-36,11,Color("#d0b58d"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["player_trade"]=player_trade.serialize();return data

func _apply_save(data:Dictionary):
    super._apply_save(data);var t=data.get("player_trade",{});if typeof(t)==TYPE_DICTIONARY:player_trade.restore(t)
