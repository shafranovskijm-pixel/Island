extends "res://scripts/game_v39.gd"
const PlayerNeeds=preload("res://scripts/player_needs_system.gd")
const AnimalEcology=preload("res://scripts/animal_ecology_system.gd")
var needs=PlayerNeeds.new()
var animals=AnimalEcology.new()
var life_menu_open:=false
func _ready():super._ready();animals.setup()
func _process(delta):
    super._process(delta);needs.tick(delta,hour,world_variety.weather,bool(vampire.state.get("is_vampire",false)));animals.tick(delta,day,player)
    for ev in needs.drain():history.record(day,hour,str(ev.get("type","need")),str(ev.get("text","Быт.")),{})
    for ev in animals.drain():history.record(day,hour,str(ev.get("type","animal")),str(ev.get("text","Животное.")),{"hunter":0.1})
func eat_from_inventory():
    for i in inventory.size():
        var item=inventory[i]
        if str(item.get("kind","")) in ["food","resource"] and (str(item.get("resource","")) in ["food","fish"] or str(item.get("kind",""))=="food"):
            needs.eat(float(item.get("hunger",25)));var q=float(item.get("quantity",1));if q>1:inventory[i]["quantity"]=q-1
            else:inventory.remove_at(i);_notify("Ты поел.");return
    _notify("Подходящей еды нет.")
func drink_water():needs.drink(45);_notify("Ты выпил воды.")
func sleep_here():
    var quality=.55
    if not estate.player_estate().is_empty():quality=1.0
    needs.sleep(day,quality);energy=minf(100,energy+55*quality);_notify("Сон восстановил силы.")
func wash_here():needs.wash();_notify("Ты умылся и привёл себя в порядок.")
func tame_nearby_animal():
    var has_food=_inventory_resource_qty("food")>=1;var r=animals.tame_near(player,has_food,int(skills.get("charm",0)))
    if not bool(r.get("ok",false)):_notify(str(r.get("reason","Не получилось.")));return
    if bool(r.get("success",false)):_consume_resource_from_inventory("food",1);_notify("Животное теперь следует за тобой.")
    else:_notify("Животное пока не доверяет тебе.")
func hunt_nearby_animal():
    var r=animals.hunt_near(player,int(learning.effective_bonus("foraging")))
    if not bool(r.get("ok",false)):_notify(str(r.get("reason","Нет добычи.")));return
    if bool(r.get("success",false)):
        inventory.append({"id":"meat_%d"%Time.get_ticks_usec(),"name":"мясо","kind":"resource","resource":"food","quantity":float(r.get("meat",1)),"value":2});learning.practice("foraging",1.0,day,hour);_notify("Охота удалась.")
    else:_notify("Добыча ушла.")
func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(s.x-155,120,135,44).has_point(event.position):life_menu_open=not life_menu_open;return
        if life_menu_open and _handle_life_touch(event.position):return
    super._unhandled_input(event)
func _handle_life_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(s.x-330,170,310,300);if not panel.has_point(pos):return false
    var actions=["eat","drink","sleep","wash","tame","hunt"];var y=panel.position.y+48
    for i in actions.size():
        var r=Rect2(panel.position.x+14,y+i*39,panel.size.x-28,32);if not r.has_point(pos):continue
        match actions[i]:
            "eat":eat_from_inventory()
            "drink":drink_water()
            "sleep":sleep_here()
            "wash":wash_here()
            "tame":tame_nearby_animal()
            "hunt":hunt_nearby_animal()
        return true
    return true
func _draw_hud(s:Vector2):
    super._draw_hud(s);var b=Rect2(s.x-155,120,135,44);draw_rect(b,Color("#435649"));draw_string(ThemeDB.fallback_font,b.position+Vector2(23,28),"БЫТ / ЗВЕРИ",0,100,11,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(20,82),"Голод %.0f · жажда %.0f · усталость %.0f · настроение %.0f"%[needs.state["hunger"],needs.state["thirst"],needs.state["fatigue"],needs.state["mood"]],0,480,11,Color("#d5dfcf"))
    if life_menu_open:_draw_life_panel(s)
func _draw_life_panel(s:Vector2):
    var panel=Rect2(s.x-330,170,310,300);draw_rect(panel,Color(0.025,0.04,0.03,.97));draw_rect(panel,Color("#637d69"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,28),"Повседневная жизнь",0,280,17,Color.WHITE)
    var labels=["ПОЕСТЬ","ВЫПИТЬ ВОДЫ","ПОСПАТЬ","УМЫТЬСЯ","ПРИРУЧИТЬ ЖИВОТНОЕ","ОХОТИТЬСЯ"];var y=panel.position.y+48
    for i in labels.size():
        var r=Rect2(panel.position.x+14,y+i*39,panel.size.x-28,32);draw_rect(r,Color("#4b6653"));draw_string(ThemeDB.fallback_font,r.position+Vector2(9,21),labels[i],0,r.size.x-18,10,Color.WHITE)
func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    for a in animals.animals:
        if not bool(a.get("alive",true)):continue
        var p:Vector2=a["pos"]-cam;var col=Color("#8b765d")
        if str(a["species"])=="dog":col=Color("#b09b7b")
        elif str(a["species"])=="rat":col=Color("#77706b")
        elif str(a["species"])=="horse":col=Color("#7b5940")
        draw_circle(p,7 if str(a["species"])!="horse" else 11,col);draw_string(ThemeDB.fallback_font,p+Vector2(-22,-12),str(a["name"]),0,70,8,Color.WHITE)
func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["player_needs"]=needs.serialize();data["animal_ecology"]=animals.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var n=data.get("player_needs",{});if typeof(n)==TYPE_DICTIONARY:needs.restore(n);var a=data.get("animal_ecology",{});if typeof(a)==TYPE_DICTIONARY:animals.restore(a)
