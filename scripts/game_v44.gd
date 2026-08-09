extends "res://scripts/game_v43.gd"
const SlavicMythology=preload("res://scripts/slavic_mythology_system.gd")
var slavic=SlavicMythology.new()
var myth_menu_open:=false
var myth_index:=0
func _ready():
    super._ready()
    # The player begins with only fragmentary folk knowledge, not the full pantheon.
    slavic.discover_deity("perun")
    slavic.discover_spirit("domovoi")
    knowledge_ui.discover("factions","old_faith",{"name":"Старая вера","note":"На острове сохранились разные, иногда противоречащие друг другу традиции."})
func _process(delta):
    super._process(delta)
    slavic.tick(day,world_variety.weather,{"wealth":coins,"estate":not estate.player_estate().is_empty(),"forest":current_location_id in ["wilderness","graveyard"],"near_water":current_location_id in ["port","fisher_cove"]})
    for ev in slavic.drain():
        history.record(day,hour,str(ev.get("type","myth")),str(ev.get("text","Знак старой веры.")),{"magic":0.1})
        var type=str(ev.get("type",""))
        if type in ["myth_discovery","spirit_discovery","omen","spirit_event"]:
            knowledge_ui.add_journal(day,hour,"Старая вера",str(ev.get("text","")),["myth","spirit"])
        if ev.has("god"):
            var gid=str(ev["god"]);if slavic.gods.has(gid):knowledge_ui.discover("factions","god_%s"%gid,{"name":slavic.gods[gid]["name"],"kind":"deity"})
        if type in ["omen","myth_discovery"]:_notify(str(ev.get("text","Знак.")))
func _current_known_god_ids()->Array:
    var ids:Array=[]
    for id in slavic.gods.keys():
        if bool(slavic.gods[id].get("known",false)):ids.append(id)
    return ids
func _current_god_id()->String:
    var ids=_current_known_god_ids();if ids.is_empty():return ""
    myth_index=clampi(myth_index,0,ids.size()-1);return str(ids[myth_index])
func discover_old_faith_at_location():
    var map={"castle":"perun","market":"dazhbog","fisher_cove":"stribog","wilderness":"veles","graveyard":"veles","library":"mokosh"}
    if map.has(current_location_id):
        var gid=str(map[current_location_id]);var was=bool(slavic.gods[gid]["known"]);slavic.discover_deity(gid)
        if not was:knowledge_ui.add_journal(day,hour,"Новый культ","Ты узнал имя %s и связанные с ним предания."%slavic.gods[gid]["name"],["myth"])
        else:_notify("Здесь уже знакомая тебе традиция старой веры.")
func build_current_shrine():
    var gid=_current_god_id();if gid=="":_notify("Ты пока не знаешь ни одного имени для святилища.");return
    if _inventory_resource_qty("wood")<4 and _inventory_resource_qty("stone")<4:_notify("Для небольшого святилища нужно 4 дерева или 4 камня.");return
    if _inventory_resource_qty("wood")>=4:_consume_resource_from_inventory("wood",4)
    else:_consume_resource_from_inventory("stone",4)
    var r=slavic.build_shrine(gid,player+Vector2(45,20));_notify("Поставлено святилище %s."%slavic.gods[gid]["name"] if bool(r.get("ok",false)) else str(r.get("reason","Не получилось.")))
func make_current_offering():
    var gid=_current_god_id();if gid=="":return
    var kind="gift";var value=0.0
    if coins>=5:coins-=5;kind="coin";value=5
    elif _inventory_resource_qty("food")>=2:_consume_resource_from_inventory("food",2);kind="food";value=3
    elif _inventory_resource_qty("fish")>=2:_consume_resource_from_inventory("fish",2);kind="fish";value=3
    else:_notify("Нечего принести в дар.");return
    var r=slavic.offer(gid,value,kind,day);_notify("Подношение %s. Благосклонность %.1f."%[slavic.gods[gid]["name"],float(r.get("favor",0))])
func swear_current_divine_oath():
    var gid=_current_god_id();if gid=="":return
    var r=slavic.swear_oath(gid,"Не предавать данное слово",day);_notify("Клятва дана именем %s."%slavic.gods[gid]["name"] if bool(r.get("ok",false)) else str(r.get("reason","Не получилось.")))
func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(175,18,125,44).has_point(event.position):myth_menu_open=not myth_menu_open;return
        if myth_menu_open and _handle_myth_touch(event.position):return
    super._unhandled_input(event)
func _handle_myth_touch(pos:Vector2)->bool:
    var panel=Rect2(310,70,360,300);if not panel.has_point(pos):return false
    var actions=["prev","next","discover","shrine","offer","oath"];var y=panel.position.y+52
    for i in actions.size():
        var r=Rect2(panel.position.x+14,y+i*38,panel.size.x-28,31);if not r.has_point(pos):continue
        match actions[i]:
            "prev":myth_index=maxi(0,myth_index-1)
            "next":myth_index+=1
            "discover":discover_old_faith_at_location()
            "shrine":build_current_shrine()
            "offer":make_current_offering()
            "oath":swear_current_divine_oath()
        return true
    return true
func _draw_hud(s:Vector2):
    super._draw_hud(s);var b=Rect2(175,18,125,44);draw_rect(b,Color("#554937"));draw_string(ThemeDB.fallback_font,b.position+Vector2(18,28),"СТАРАЯ ВЕРА",0,95,11,Color.WHITE)
    if myth_menu_open:_draw_myth_panel()
func _draw_myth_panel():
    var panel=Rect2(310,70,360,300);draw_rect(panel,Color(0.035,0.028,0.018,.98));draw_rect(panel,Color("#85704e"),false,2)
    var gid=_current_god_id();var title="Неизвестные предания" if gid=="" else "%s · благосклонность %.1f"%[slavic.gods[gid]["name"],slavic.gods[gid]["favor"]]
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,29),title,0,330,16,Color("#eee1c0"))
    var labels=["ПРЕДЫДУЩИЙ БОГ","СЛЕДУЮЩИЙ БОГ","ИСКАТЬ МЕСТНЫЕ ПРЕДАНИЯ","ПОСТАВИТЬ СВЯТИЛИЩЕ","СДЕЛАТЬ ПОДНОШЕНИЕ","ДАТЬ КЛЯТВУ"]
    var y=panel.position.y+52
    for i in labels.size():var r=Rect2(panel.position.x+14,y+i*38,panel.size.x-28,31);draw_rect(r,Color("#66563d"));draw_string(ThemeDB.fallback_font,r.position+Vector2(9,21),labels[i],0,r.size.x-18,10,Color.WHITE)
func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    for sh in slavic.shrines:
        var p:Vector2=sh["pos"]-cam;draw_circle(p,10,Color("#85704e"));draw_line(p+Vector2(0,-14),p+Vector2(0,14),Color("#d6c08a"),3);draw_string(ThemeDB.fallback_font,p+Vector2(-28,-18),slavic.gods[str(sh["god"])]["name"],0,70,8,Color("#f0dfb4"))
func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["slavic_mythology"]=slavic.serialize();data["myth_index"]=myth_index;return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var m=data.get("slavic_mythology",{});if typeof(m)==TYPE_DICTIONARY:slavic.restore(m);myth_index=int(data.get("myth_index",0))
