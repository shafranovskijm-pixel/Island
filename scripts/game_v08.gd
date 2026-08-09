extends "res://scripts/game_v07.gd"

const InteriorSystem=preload("res://scripts/interior_system.gd")
const PowerSystem=preload("res://scripts/power_system.gd")

var interiors=InteriorSystem.new()
var power=PowerSystem.new()
var current_interior_id:=""
var royal_invitation:=false
var royal_access:=false
var room_rented:=false
var prisoner:=false
var guard_trust:=0
var temple_trust:=0
var occult_member:=false
var influence:=0
var power_event_cursor:=0

func _ready():
    super._ready()
    _restore_location_roles()

func _process(delta):
    super._process(delta)
    npcs=power.tick(npcs,day,hour)
    _drain_power_events()

func _restore_location_roles():
    var role_data={
        "king":["сохранить власть и династию","crown","castle",85],
        "queen":["усилить влияние своей семьи","crown","castle",72],
        "chancellor":["стать незаменимым при дворе","crown","castle",80],
        "captain_guard":["удержать порядок любой ценой","guard","guard_barracks",62],
        "priest":["искоренить запретную магию","temple","temple",58],
        "vampire":["питать тайную кровь острова и не раскрыться","occult","crypt",76],
        "cult_leader":["вернуть Ордену утраченную силу","occult","occult_lodge",69],
        "smuggler":["подчинить чёрный рынок","underworld","slums",44]
    }
    for i in npcs.size():
        var id=str(npcs[i].get("id",""))
        if role_data.has(id):
            var d=role_data[id]
            npcs[i]["goal"]=d[0];npcs[i]["faction"]=d[1];npcs[i]["home_location"]=d[2];npcs[i]["influence"]=d[3]

func _drain_power_events():
    while power_event_cursor<power.crises.size():
        var e=power.crises[power_event_cursor]
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),"power",str(e.get("text","Политический кризис.")),{"social":0.3})
        _notify(str(e.get("text","Политический кризис.")))
        power_event_cursor+=1

func _try_interact():
    # Contextual entrances to interiors.
    var chosen=_interior_near_player()
    if chosen!="":
        var result=interiors.can_enter(chosen,_access_state())
        if bool(result.get("ok",false)):
            current_interior_id=chosen
            history.record(day,hour,"interior","Вошёл: %s."%interiors.name_of(chosen),{})
            _notify("Внутри: %s"%interiors.name_of(chosen))
            _apply_interior_effect(chosen)
            return
        elif str(result.get("reason",""))!="":
            _notify(str(result["reason"]))
            return
    super._try_interact()

func _interior_near_player()->String:
    if current_location_id=="castle" and player.distance_to(locations.locations["castle"]["center"])<100:
        return "castle_hall"
    if current_location_id=="guard_barracks" and player.distance_to(locations.locations["guard_barracks"]["center"])<80:
        return "barracks_jail"
    if current_location_id=="tavern" and player.distance_to(locations.locations["tavern"]["center"])<70:
        return "tavern_common"
    if current_location_id=="crypt":
        return "crypt_lower" if locations.secrets["vampires"] else "crypt_upper"
    if current_location_id=="temple" and player.distance_to(locations.locations["temple"]["center"])<70:
        return "temple_nave"
    if current_location_id=="occult_lodge": return "occult_chamber"
    return ""

func _access_state()->Dictionary:
    return {
        "wanted":wanted,"stealth":int(skills.get("stealth",0)),"politics":int(skills.get("politics",0)),
        "magic":int(skills.get("magic",0)),"influence":influence,"royal_invitation":royal_invitation,
        "royal_access":royal_access,"room_rented":room_rented,"prisoner":prisoner,"guard_trust":guard_trust,
        "temple_trust":temple_trust,"occult_member":occult_member,"crypt_known":bool(locations.secrets["crypt_entrance"])
    }

func _apply_interior_effect(id:String):
    match id:
        "tavern_common":
            if coins>=3 and not room_rented:
                coins-=3;room_rented=true;history.record(day,hour,"home","Снял дешёвую комнату над таверной.",{"homeless":-0.4})
        "crypt_upper":
            if not locations.secrets["vampires"] and hour>=20.0:
                locations.discover("vampires");history.record(day,hour,"secret","В склепе нашёл следы существ, которым не место среди живых.",{"mage":0.4})
        "crypt_lower":
            if int(skills.get("magic",0))>=3 and not occult_member:
                occult_member=true;history.record(day,hour,"occult","Был допущен к более глубоким тайнам под кладбищем.",{"mage":0.8})
        "temple_nave":
            temple_trust+=1
        "castle_hall":
            influence+=1

func _do_location_npc_action(n:Dictionary,action:int):
    var id=str(n.get("id",""))
    super._do_location_npc_action(n,action)
    match id:
        "king":
            if action==0:
                royal_invitation=true;influence+=1
            elif action==1:
                influence+=1
        "queen":
            if action==0: influence+=1
        "chancellor":
            if action==0 and int(skills.get("politics",0))>=3:
                royal_access=true;influence+=1
        "captain_guard":
            if action==0: guard_trust+=1
        "priest":
            if action==0: temple_trust+=1
        "cult_leader":
            if action==0 and int(skills.get("magic",0))>=2: occult_member=true
        "smuggler":
            if action==0: influence+=1

func simulate_death(npc_id:String,cause:String):
    var idx=_find_npc(npc_id)
    if idx<0:return
    npcs[idx]["alive"]=false
    history.record(day,hour,"death","%s погиб: %s."%[npcs[idx]["name"],cause],{})
    if npc_id==power.ruler_id:
        power.crisis_for("смерть правителя",npc_id,"трон",day,hour)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    if current_interior_id!="":
        draw_rect(Rect2(18,170,340,32),Color(0.02,0.03,0.04,.84))
        draw_string(ThemeDB.fallback_font,Vector2(30,191),"Внутри: %s"%interiors.name_of(current_interior_id),0,315,13,Color("#d8c8e8"))
    draw_rect(Rect2(370,132,330,34),Color(0.02,0.04,0.05,.82))
    draw_string(ThemeDB.fallback_font,Vector2(382,154),"Власть: %s · влияние %d"%[power.ruler_id if power.ruler_id!="" else "вакантно",influence],0,310,13,Color("#efd89a"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["current_interior_id"]=current_interior_id
    data["royal_invitation"]=royal_invitation;data["royal_access"]=royal_access;data["room_rented"]=room_rented
    data["prisoner"]=prisoner;data["guard_trust"]=guard_trust;data["temple_trust"]=temple_trust;data["occult_member"]=occult_member
    data["influence"]=influence;data["ruler_id"]=power.ruler_id;data["location_control"]=power.location_control
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    current_interior_id=str(data.get("current_interior_id",""))
    royal_invitation=bool(data.get("royal_invitation",false));royal_access=bool(data.get("royal_access",false));room_rented=bool(data.get("room_rented",false))
    prisoner=bool(data.get("prisoner",false));guard_trust=int(data.get("guard_trust",0));temple_trust=int(data.get("temple_trust",0));occult_member=bool(data.get("occult_member",false))
    influence=int(data.get("influence",0));power.ruler_id=str(data.get("ruler_id",power.ruler_id))
    var lc=data.get("location_control",{})
    if typeof(lc)==TYPE_DICTIONARY:power.location_control=lc
