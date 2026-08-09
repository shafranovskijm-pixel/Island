extends "res://scripts/game_v31.gd"

const CastleBuilder=preload("res://scripts/castle_builder.gd")
const HouseholdSocial=preload("res://scripts/household_social_system.gd")
var castle_builder=CastleBuilder.new()
var household_social=HouseholdSocial.new()
var build_mode:=false
var build_piece_index:=0
var build_pieces=["stone_wall","wood_wall","wooden_door","simple_bed","wood_table","wood_chair","occult_altar"]

func _process(delta):
    super._process(delta)
    var e=estate.player_estate()
    household_social.tick(npcs,e,day,hour)
    for ev in household_social.drain():
        history.record(day,hour,str(ev.get("type","household")),str(ev.get("text","Домашнее событие.")),{"social":0.2})
        if str(ev.get("type","")) in ["jealousy","guest"]:_notify(str(ev.get("text","Кто-то пришёл в дом.")))
    for ev in castle_builder.drain():history.record(day,hour,str(ev.get("type","castle_build")),str(ev.get("text","Строительство.")),{"worker":0.15})

func _current_build_piece()->String:
    return str(build_pieces[clampi(build_piece_index,0,build_pieces.size()-1)])

func place_selected_castle_piece():
    var e=estate.player_estate()
    if e.is_empty():_notify("Сначала основай собственное владение.");return
    var piece=_current_build_piece()
    var inv_idx=_find_piece_in_inventory(piece)
    if inv_idx<0:_notify("Сначала изготовь: %s."%piece);return
    var pos=player+Vector2(64,0)
    if pos.distance_to(e["pos"])>420:_notify("Строить замок можно в пределах своей земли.");return
    var result=castle_builder.place(piece,pos,str(e["id"]))
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не удалось построить.")));return
    _consume_inventory_piece(inv_idx)
    estate.add_piece(str(e["id"]),piece)
    var stats=castle_builder.stats(str(e["id"]))
    _notify("Построено: %s · уровень замка %d"%[piece,int(stats["castle_level"])])
    saves.save_game(_capture_save())

func dismantle_nearby_castle_piece():
    var result=castle_builder.remove_near(player+Vector2(40,0),70)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Нечего разбирать.")));return
    var piece=str(result["piece"].get("piece",""))
    inventory.append({"id":"recovered_%d"%Time.get_ticks_usec(),"name":piece,"kind":"structure","recipe_id":piece,"placeable":true,"quantity":1.0})
    _notify("Разобрано и возвращено: %s"%piece)

func stock_house_food(qty:float=5.0):
    var e=estate.player_estate();if e.is_empty():_notify("Нет собственного владения.");return
    var available=_inventory_resource_qty("food")
    if available<qty:_notify("Нужно %.0f единиц еды в инвентаре."%qty);return
    _consume_resource_from_inventory("food",qty)
    e["food_store"]=float(e.get("food_store",0))+qty
    _replace_player_estate(e);_notify("Еда перенесена в кладовую дома.")

func host_feast():
    var e=estate.player_estate();var result=household_social.feast(npcs,e)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Пир невозможен.")));return
    _replace_player_estate(e);_notify("В доме начался пир. Жители и близкие проводят вечер вместе.")

func fund_household(amount:int=20):
    var e=estate.player_estate();if e.is_empty():_notify("Нет собственного владения.");return
    if coins<amount:_notify("Не хватает монет.");return
    coins-=amount;estate.deposit_coins(amount);_notify("В казну дома внесено %d монет."%amount)

func _replace_player_estate(updated:Dictionary):
    for i in estate.estates.size():
        if str(estate.estates[i].get("owner",""))=="player":estate.estates[i]=updated;return

func _find_piece_in_inventory(piece:String)->int:
    for i in inventory.size():
        var item:Dictionary=inventory[i]
        if str(item.get("recipe_id",""))==piece:return i
        var type=str(item.get("structure_type",item.get("station_type","")))
        if type==piece:return i
        if str(item.get("name","")).to_lower()==piece.to_lower():return i
    return -1

func _consume_inventory_piece(idx:int):
    if idx<0 or idx>=inventory.size():return
    var qty=float(inventory[idx].get("quantity",1.0))
    if qty>1.0:inventory[idx]["quantity"]=qty-1.0
    else:inventory.remove_at(idx)

func _inventory_resource_qty(resource:String)->float:
    var total:=0.0
    for item in inventory:
        if str(item.get("kind",""))=="resource" and str(item.get("resource",""))==resource:total+=float(item.get("quantity",1.0))
    return total

func _consume_resource_from_inventory(resource:String,amount:float):
    var left=amount
    for i in range(inventory.size()-1,-1,-1):
        if str(inventory[i].get("kind",""))!="resource" or str(inventory[i].get("resource",""))!=resource:continue
        var q=float(inventory[i].get("quantity",1.0));var take=minf(q,left);q-=take;left-=take
        if q<=0.001:inventory.remove_at(i)
        else:inventory[i]["quantity"]=q
        if left<=0.001:return

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(200,s.y-145,150,50).has_point(event.position):build_mode=not build_mode;return
        if build_mode and _handle_build_touch(event.position):return
    super._unhandled_input(event)

func _handle_build_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(365,s.y*.22,340,s.y*.58)
    if not panel.has_point(pos):return false
    var y=panel.position.y+55
    var actions=["prev","next","place","remove","food","fund","feast"]
    for i in actions.size():
        var r=Rect2(panel.position.x+15,y+i*42,panel.size.x-30,34)
        if not r.has_point(pos):continue
        match actions[i]:
            "prev":build_piece_index=(build_piece_index-1+build_pieces.size())%build_pieces.size()
            "next":build_piece_index=(build_piece_index+1)%build_pieces.size()
            "place":place_selected_castle_piece()
            "remove":dismantle_nearby_castle_piece()
            "food":stock_house_food(5)
            "fund":fund_household(20)
            "feast":host_feast()
        return true
    return true

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var b=Rect2(200,s.y-145,150,50);draw_rect(b,Color("#665846"));draw_string(ThemeDB.fallback_font,b.position+Vector2(25,31),"СТРОИТЬ",0,105,14,Color.WHITE)
    if build_mode:_draw_build_panel(s)

func _draw_build_panel(s:Vector2):
    var panel=Rect2(365,s.y*.22,340,s.y*.58);draw_rect(panel,Color(0.03,0.028,0.025,.97));draw_rect(panel,Color("#8b775e"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(15,29),"Строительство владения",0,310,18,Color.WHITE)
    var labels=["‹ ПРЕДЫДУЩИЙ: %s"%_current_build_piece(),"СЛЕДУЮЩИЙ ›","ПОСТАВИТЬ ПЕРЕД ГЕРОЕМ","РАЗОБРАТЬ РЯДОМ","ЕДА В КЛАДОВУЮ +5","КАЗНА ДОМА +20","УСТРОИТЬ ПИР"]
    var y=panel.position.y+55
    for i in labels.size():
        var r=Rect2(panel.position.x+15,y+i*42,panel.size.x-30,34);draw_rect(r,Color("#5a5044"));draw_string(ThemeDB.fallback_font,r.position+Vector2(10,22),labels[i],0,r.size.x-20,11,Color.WHITE)
    var e=estate.player_estate()
    if not e.is_empty():
        var st=castle_builder.stats(str(e["id"]));draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+15,panel.end.y-18),"Замок ур.%d · стены %d · кровати %d · еда %.0f · казна %.0f"%[st["castle_level"],st["walls"],st["beds"],e.get("food_store",0),e.get("treasury",0)],0,310,10,Color("#d4c7aa"))

func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    for p in castle_builder.placed:
        var sp:Vector2=p["pos"]-cam;var type=str(p["piece"]);var col=Color("#77746e")
        if type=="wood_wall":col=Color("#765b40")
        elif type=="wooden_door":col=Color("#5e402c")
        elif type in ["simple_bed","wood_table","wood_chair"]:col=Color("#8a6a4a")
        elif type=="occult_altar":col=Color("#55405f")
        draw_rect(Rect2(sp-Vector2(14,14),Vector2(28,28)),col)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["castle_builder"]=castle_builder.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var cb=data.get("castle_builder",{});if typeof(cb)==TYPE_DICTIONARY:castle_builder.restore(cb)
