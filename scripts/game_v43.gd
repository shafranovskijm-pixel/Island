extends "res://scripts/game_v42.gd"
const KnowledgeInterface=preload("res://scripts/knowledge_interface_system.gd")
const GenerationSystem=preload("res://scripts/generation_system.gd")
var knowledge_ui=KnowledgeInterface.new()
var generations=GenerationSystem.new()
var journal_open:=false
var journal_tab:=0
func _ready():
    super._ready();generations.ensure_npcs(npcs);knowledge_ui.discover("places",current_location_id,{"name":locations.location_name(current_location_id)});knowledge_ui.learn_mechanic("movement","опыт","Ты понял, что по острову можно свободно ходить и взаимодействовать с людьми и предметами.")
func _process(delta):
    super._process(delta);generations.tick(npcs,day)
    for ev in generations.drain():history.record(day,hour,str(ev.get("type","generation")),str(ev.get("text","Семейное событие.")),{"social":0.05});knowledge_ui.add_journal(day,hour,"Семья",str(ev.get("text","")),["family"])
    for ev in knowledge_ui.drain():_notify(str(ev.get("text","Новое знание.")))
    _discover_nearby()
func _discover_nearby():
    knowledge_ui.discover("places",current_location_id,{"name":locations.location_name(current_location_id)})
    for n in npcs:
        if player.distance_to(n.get("pos",Vector2.ZERO))<95:knowledge_ui.discover("people",str(n.get("id","")),{"name":n.get("name","Незнакомец"),"role":n.get("role","неизвестно")})
    for a in animals.animals:
        if player.distance_to(a.get("pos",Vector2.ZERO))<90:knowledge_ui.discover("creatures",str(a.get("species","")),{"name":a.get("name","животное")})
func _deliver_npc_knowledge(npc:Dictionary):
    var before=heard_opportunities.size();super._deliver_npc_knowledge(npc)
    if heard_opportunities.size()>before:
        var o=heard_opportunities.back();knowledge_ui.discover("rumors",str(o.get("id","rumor")),{"text":o.get("text",""),"source":npc.get("name","")});knowledge_ui.add_journal(day,hour,"Слух от %s"%npc.get("name","кого-то"),str(o.get("text","")),["rumor"])
func study_first_book():
    var before=learning.knowledge.duplicate(true);super.study_first_book()
    if learning.knowledge!=before:knowledge_ui.learn_mechanic("study_books","библиотекарь","Книги дают теорию, но мастерство требует практики.")
func craft_item(recipe_id:String):
    super.craft_item(recipe_id);knowledge_ui.learn_mechanic("crafting","практика","Рецепты требуют знаний, ресурсов, инструментов и иногда рабочей станции.")
func attack_nearest():
    super.attack_nearest();knowledge_ui.learn_mechanic("combat","драка","Удары зависят от навыка и броска; раны могут кровоточить и привести к потере сознания.")
func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(18,18,145,44).has_point(event.position):journal_open=not journal_open;return
        if journal_open and _handle_journal_touch(event.position):return
    super._unhandled_input(event)
func _handle_journal_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(20,70,s.x*.62,s.y*.76);if not panel.has_point(pos):return false
    for i in 4:
        var r=Rect2(panel.position.x+15+i*120,panel.position.y+42,110,34);if r.has_point(pos):journal_tab=i;return true
    return true
func _draw_hud(s:Vector2):
    super._draw_hud(s);var b=Rect2(18,18,145,44);draw_rect(b,Color("#3e4850"));draw_string(ThemeDB.fallback_font,b.position+Vector2(22,28),"ДНЕВНИК / МИР",0,110,11,Color.WHITE)
    if journal_open:_draw_journal(s)
func _draw_journal(s:Vector2):
    var panel=Rect2(20,70,s.x*.62,s.y*.76);draw_rect(panel,Color(0.025,0.03,0.035,.98));draw_rect(panel,Color("#65727b"),false,2);draw_string(ThemeDB.fallback_font,panel.position+Vector2(15,28),"Что герой действительно знает",0,panel.size.x-30,18,Color.WHITE)
    var tabs=["ДНЕВНИК","ЛЮДИ","МЕСТА","ЗНАНИЯ"]
    for i in tabs.size():var r=Rect2(panel.position.x+15+i*120,panel.position.y+42,110,34);draw_rect(r,Color("#596771") if journal_tab==i else Color("#3e484f"));draw_string(ThemeDB.fallback_font,r.position+Vector2(10,22),tabs[i],0,90,10,Color.WHITE)
    var lines:Array=[]
    if journal_tab==0:
        for i in range(maxi(0,knowledge_ui.journal.size()-12),knowledge_ui.journal.size()):var j=knowledge_ui.journal[i];lines.append("Д%d · %s — %s"%[j["day"],j["title"],j["text"]])
    elif journal_tab==1:
        for id in knowledge_ui.discoveries["people"].keys():var p=knowledge_ui.discoveries["people"][id];lines.append("%s · %s"%[p.get("name",id),p.get("role","?")])
    elif journal_tab==2:
        for id in knowledge_ui.discoveries["places"].keys():lines.append(str(knowledge_ui.discoveries["places"][id].get("name",id)))
    else:
        for id in knowledge_ui.discoveries["mechanics"].keys():var m=knowledge_ui.discoveries["mechanics"][id];lines.append("%s: %s"%[m.get("source","опыт"),m.get("text",id)])
    var y=panel.position.y+100
    for line in lines:draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+18,y),str(line),0,panel.size.x-36,10,Color("#d5ddd9"));y+=27
func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["knowledge_interface"]=knowledge_ui.serialize();data["generations"]=generations.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var k=data.get("knowledge_interface",{});if typeof(k)==TYPE_DICTIONARY:knowledge_ui.restore(k);var g=data.get("generations",{});if typeof(g)==TYPE_DICTIONARY:generations.restore(g)
