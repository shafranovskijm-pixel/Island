extends "res://scripts/game_v41.gd"
const SocialContracts=preload("res://scripts/social_contract_system.gd")
const DiseaseCult=preload("res://scripts/disease_cult_system.gd")
var contracts=SocialContracts.new()
var disease_cult=DiseaseCult.new()
var contracts_menu_open:=false
var last_contract_day:=-1
func _process(delta):
    super._process(delta)
    if day!=last_contract_day and hour>=7:
        last_contract_day=day;contracts.tick(day,npcs);disease_cult.tick(day,npcs,{"hunger":production.hunger_pressure,"rats":world_variety.wildlife.get("rats",0),"vampire_rumors":bool(locations.secrets.get("vampires",false))})
    for ev in contracts.drain():
        history.record(day,hour,str(ev.get("type","contract")),str(ev.get("text","Обязательство изменилось.")),{"social":0.08})
        if str(ev.get("type","")) in ["promise_broken","debt_overdue","betrayal"]:_notify(str(ev.get("text","Последствия обязательства.")))
    for ev in disease_cult.drain():
        history.record(day,hour,str(ev.get("type","disease")),str(ev.get("text","Болезнь или культ.")),{"medicine":0.08})
        if str(ev.get("type","")) in ["disease","recovery"]:_notify(str(ev.get("text","Состояние здоровья изменилось.")))
func borrow_money(amount:float=20.0):
    var idx=_nearest_npc();if idx<0:_notify("Рядом нет человека, у которого можно просить деньги.");return
    if int(npcs[idx].get("money",0))<amount:_notify("У этого человека нет таких денег.");return
    npcs[idx]["money"]=int(npcs[idx].get("money",0))-int(amount);coins+=int(amount);contracts.add_debt("player",str(npcs[idx]["id"]),amount,day+7,.12);_notify("Ты занял %.0f монет у %s."%[amount,npcs[idx].get("name","кредитора")])
func promise_nearest():
    var idx=_nearest_npc();if idx<0:_notify("Рядом никого нет.");return
    contracts.make_promise("player",str(npcs[idx]["id"]),"помочь в трудный момент",day+5,0);_notify("Ты дал обещание %s."%npcs[idx].get("name","человеку"))
func take_nearest_apprentice():
    var idx=_nearest_npc();if idx<0:_notify("Рядом никого нет.");return
    if int(npcs[idx].get("rel",0))<2:_notify("Для ученичества нужно больше доверия.");return
    contracts.take_apprentice(str(npcs[idx]["id"]),"building",day);_notify("%s стал твоим учеником."%npcs[idx].get("name","Житель"))
func recruit_nearest_to_cult(cult:String):
    var idx=_nearest_npc();if idx<0:_notify("Рядом никого нет.");return
    var r=disease_cult.recruit(npcs[idx],cult);_notify(str(r.get("reason","Не удалось завербовать.")) if not bool(r.get("ok",false)) else "%s вступил в %s."%[npcs[idx].get("name","Житель"),cult])
func swear_nearest_oath():
    var idx=_nearest_npc();if idx<0:_notify("Рядом никого нет.");return
    contracts.swear_oath(str(npcs[idx]["id"]),"player_house","верность дому");_notify("%s поклялся в верности дому."%npcs[idx].get("name","Житель"))
func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(s.x-155,220,135,44).has_point(event.position):contracts_menu_open=not contracts_menu_open;return
        if contracts_menu_open and _handle_contract_touch(event.position):return
    super._unhandled_input(event)
func _handle_contract_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(s.x-330,270,310,300);if not panel.has_point(pos):return false
    var actions=["borrow","promise","apprentice","oath","temple","occult"];var y=panel.position.y+48
    for i in actions.size():
        var r=Rect2(panel.position.x+14,y+i*39,panel.size.x-28,32);if not r.has_point(pos):continue
        match actions[i]:
            "borrow":borrow_money()
            "promise":promise_nearest()
            "apprentice":take_nearest_apprentice()
            "oath":swear_nearest_oath()
            "temple":recruit_nearest_to_cult("temple")
            "occult":recruit_nearest_to_cult("occult_order")
        return true
    return true
func _draw_hud(s:Vector2):
    super._draw_hud(s);var b=Rect2(s.x-155,220,135,44);draw_rect(b,Color("#51445e"));draw_string(ThemeDB.fallback_font,b.position+Vector2(20,28),"СВЯЗИ / ДОЛГИ",0,105,10,Color.WHITE)
    if contracts_menu_open:_draw_contract_panel(s)
func _draw_contract_panel(s:Vector2):
    var panel=Rect2(s.x-330,270,310,300);draw_rect(panel,Color(0.035,0.025,0.045,.97));draw_rect(panel,Color("#725f82"),false,2);draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,28),"Обязательства и влияние",0,280,17,Color.WHITE)
    var labels=["ЗАНЯТЬ 20 МОНЕТ","ДАТЬ ОБЕЩАНИЕ","ВЗЯТЬ УЧЕНИКА","ПРИНЯТЬ КЛЯТВУ","ПОЗВАТЬ В ХРАМ","ЗАВЕРБОВАТЬ В ОРДЕН"];var y=panel.position.y+48
    for i in labels.size():var r=Rect2(panel.position.x+14,y+i*39,panel.size.x-28,32);draw_rect(r,Color("#5d4c6b"));draw_string(ThemeDB.fallback_font,r.position+Vector2(8,21),labels[i],0,r.size.x-16,10,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+14,panel.end.y-14),"Долги %d · обещания %d · ученики %d · больных %d"%[contracts.debts.size(),contracts.promises.size(),contracts.apprentices.size(),disease_cult.diseases.size()],0,280,9,Color("#d0c6d5"))
func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["social_contracts"]=contracts.serialize();data["disease_cult"]=disease_cult.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var c=data.get("social_contracts",{});if typeof(c)==TYPE_DICTIONARY:contracts.restore(c);var d=data.get("disease_cult",{});if typeof(d)==TYPE_DICTIONARY:disease_cult.restore(d)
