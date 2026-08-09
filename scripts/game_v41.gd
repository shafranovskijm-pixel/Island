extends "res://scripts/game_v40.gd"
const Livestock=preload("res://scripts/livestock_system.gd")
const VisualTheme=preload("res://scripts/visual_theme_system.gd")
var livestock=Livestock.new()
var visuals=VisualTheme.new()
var mounted:=false
var farm_menu_open:=false
var last_livestock_day:=-1
func _process(delta):
    super._process(delta)
    if day!=last_livestock_day and hour>=6:
        last_livestock_day=day;var e=estate.player_estate();var food=float(e.get("food_store",0)) if not e.is_empty() else 0.0;food=livestock.tick(day,food);if not e.is_empty():e["food_store"]=food
    for ev in livestock.drain():history.record(day,hour,str(ev.get("type","livestock")),str(ev.get("text","Хозяйство.")),{"farmer":0.1})
func buy_livestock(species:String):
    var prices={"chicken":6,"goat":18,"cow":35,"horse":45};var price=int(prices.get(species,999));if coins<price:_notify("Не хватает денег.");return
    if estate.player_estate().is_empty():_notify("Для скота сначала нужно собственное владение.");return
    var r=livestock.buy(species);if bool(r.get("ok",false)):coins-=price;_notify("Куплено животное: %s."%r["animal"]["name"])
func collect_livestock_products():
    var p=livestock.collect_products(day);var total=float(p.get("egg",0))+float(p.get("milk",0));if total<=0:_notify("Сегодня собирать пока нечего.");return
    if float(p.get("egg",0))>0:inventory.append({"id":"eggs_%d"%Time.get_ticks_usec(),"name":"яйца","kind":"food","subtype":"egg","quantity":p["egg"],"hunger":8,"value":2})
    if float(p.get("milk",0))>0:inventory.append({"id":"milk_%d"%Time.get_ticks_usec(),"name":"молоко","kind":"food","subtype":"milk","quantity":p["milk"],"hunger":14,"value":3});_notify("Продукты хозяйства собраны.")
func toggle_mount():
    var h=livestock.first_horse();if h.is_empty():_notify("У тебя нет здоровой лошади.");return
    mounted=not mounted;_notify("Ты сел на лошадь." if mounted else "Ты спешился.")
func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(s.x-155,170,135,44).has_point(event.position):farm_menu_open=not farm_menu_open;return
        if farm_menu_open and _handle_farm_touch(event.position):return
    super._unhandled_input(event)
func _handle_farm_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(s.x-330,220,310,290);if not panel.has_point(pos):return false
    var actions=["chicken","goat","cow","horse","collect","mount"];var y=panel.position.y+48
    for i in actions.size():
        var r=Rect2(panel.position.x+14,y+i*38,panel.size.x-28,31);if not r.has_point(pos):continue
        if actions[i] in ["chicken","goat","cow","horse"]:buy_livestock(actions[i])
        elif actions[i]=="collect":collect_livestock_products()
        else:toggle_mount()
        return true
    return true
func _draw_hud(s:Vector2):
    super._draw_hud(s);var b=Rect2(s.x-155,170,135,44);draw_rect(b,Color("#67563f"));draw_string(ThemeDB.fallback_font,b.position+Vector2(25,28),"ХОЗЯЙСТВО",0,95,11,Color.WHITE)
    if mounted:draw_string(ThemeDB.fallback_font,Vector2(20,100),"Верхом",0,80,11,Color("#e2c795"))
    if farm_menu_open:_draw_farm_panel(s)
func _draw_farm_panel(s:Vector2):
    var panel=Rect2(s.x-330,220,310,290);draw_rect(panel,Color(0.04,0.032,0.022,.97));draw_rect(panel,Color("#8a7453"),false,2);draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,28),"Поместье и животные",0,280,17,Color.WHITE)
    var labels=["КУПИТЬ КУРИЦУ · 6","КУПИТЬ КОЗУ · 18","КУПИТЬ КОРОВУ · 35","КУПИТЬ ЛОШАДЬ · 45","СОБРАТЬ МОЛОКО / ЯЙЦА","СЕСТЬ НА ЛОШАДЬ"];var y=panel.position.y+48
    for i in labels.size():var r=Rect2(panel.position.x+14,y+i*38,panel.size.x-28,31);draw_rect(r,Color("#69583f"));draw_string(ThemeDB.fallback_font,r.position+Vector2(8,21),labels[i],0,r.size.x-16,10,Color.WHITE)
func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    for a in livestock.livestock:
        var base=estate.player_estate();if base.is_empty():continue
        var seed=int(str(a["id"]).hash());var p:Vector2=base["pos"]+Vector2((seed%140)-70,((seed/7)%100)-50)-cam;visuals.draw_animal(self,p,str(a["species"]));draw_string(ThemeDB.fallback_font,p+Vector2(-18,-12),str(a["name"]),0,60,8,Color.WHITE)
func _draw_player(cam:Vector2):
    if mounted:
        var p=player-cam;visuals.draw_animal(self,p+Vector2(0,7),"horse");visuals.draw_person(self,p+Vector2(0,-7),"",bool(vampire.state.get("is_vampire",false)));return
    if not bool(vampire.state.get("bat_form",false)):visuals.draw_person(self,player-cam,"",bool(vampire.state.get("is_vampire",false)));return
    super._draw_player(cam)
func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["livestock"]=livestock.serialize();data["mounted"]=mounted;return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var l=data.get("livestock",{});if typeof(l)==TYPE_DICTIONARY:livestock.restore(l);mounted=bool(data.get("mounted",false))
