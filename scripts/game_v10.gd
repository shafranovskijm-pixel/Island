extends "res://scripts/game_v09.gd"

const FactionConflictSystem=preload("res://scripts/faction_conflict_system.gd")
const IntrigueSystem=preload("res://scripts/intrigue_system.gd")

var faction_conflicts=FactionConflictSystem.new()
var intrigue=IntrigueSystem.new()
var faction_event_cursor:=0
var intrigue_event_cursor:=0

func _ready():
    super._ready()
    faction_conflicts.setup()
    intrigue.setup()

func _process(delta):
    super._process(delta)
    var conflict_result=faction_conflicts.tick(npcs,power.location_control,day,hour)
    npcs=conflict_result.get("npcs",npcs)
    power.location_control=conflict_result.get("control",power.location_control)
    for e in conflict_result.get("events",[]):
        _record_faction_event(e)
    npcs=intrigue.tick(npcs,day,hour,faction_conflicts.relations)
    _drain_intrigue_events()
    _derive_cross_faction_pressure()

func _record_faction_event(e:Dictionary):
    history.record(int(e.get("day",day)),float(e.get("hour",hour)),"faction_conflict",str(e.get("text","Фракции вступили в конфликт.")),{"social":0.4})
    _notify(str(e.get("text","Фракции вступили в конфликт.")))
    var target=str(e.get("target",""))
    var winner=str(e.get("winner",""))
    if target=="occult_lodge" and winner=="temple":
        _raid_occult_lodge()
    elif target=="slums" and winner=="guard":
        _guard_crackdown()
    elif target=="port" and winner=="underworld":
        economy.tax_rate=maxf(0.0,economy.tax_rate-0.02)
    elif target=="market" and winner=="merchants":
        economy.tax_rate=maxf(0.0,economy.tax_rate-0.01)

func _derive_cross_faction_pressure():
    # World facts create pressure; this does not fire scripted quests.
    if locations.secrets.get("vampires",false):
        faction_conflicts.add_pressure("temple","occult",0.012)
    if wanted>=3:
        faction_conflicts.add_pressure("guard","underworld",0.01)
    if occult_member:
        faction_conflicts.add_pressure("temple","occult",0.008)
    if influence>=5:
        faction_conflicts.relations["crown"]["merchants"]=clampf(float(faction_conflicts.relations["crown"]["merchants"])+0.003,-100,100)

func _raid_occult_lodge():
    var arrests:Array=[]
    for i in npcs.size():
        var n=npcs[i]
        if str(n.get("faction",""))=="occult" and bool(n.get("alive",true)):
            n["stress"]=float(n.get("stress",0))+25.0
            if randf()<0.35:
                n["arrested"]=true
                n["target"]=locations.locations["guard_barracks"]["center"]
                arrests.append(str(n["name"]))
            else:
                n["target"]=locations.locations["crypt"]["center"]
            npcs[i]=n
    history.record(day,hour,"raid","Стража и храм провели рейд против Ордена. Арестованы: %s."%", ".join(arrests),{})

func _guard_crackdown():
    for i in npcs.size():
        var n=npcs[i]
        if str(n.get("faction",""))=="underworld":
            n["stress"]=float(n.get("stress",0))+18.0
            n["target"]=locations.locations["slums"]["center"]
            npcs[i]=n
    history.record(day,hour,"crackdown","Стража усилила давление на Нижние улицы.",{})

func _drain_intrigue_events():
    while intrigue_event_cursor<intrigue.events.size():
        var e=intrigue.events[intrigue_event_cursor]
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","intrigue")),str(e.get("text","Интрига.")),{"social":0.25})
        _notify(str(e.get("text","Интрига.")))
        _apply_intrigue_consequence(e)
        intrigue_event_cursor+=1

func _apply_intrigue_consequence(e:Dictionary):
    var actor_id=str(e.get("actor",""));var target_id=str(e.get("target",""));var type=str(e.get("type",""))
    var ai=_find_npc(actor_id);var ti=_find_npc(target_id)
    if ai<0 or ti<0:return
    if type=="bribe":
        var af=str(npcs[ai].get("faction",""));var tf=str(npcs[ti].get("faction",""))
        if af!="" and tf!="" and faction_conflicts.relations.has(af) and faction_conflicts.relations[af].has(tf):
            faction_conflicts.relations[af][tf]=clampf(float(faction_conflicts.relations[af][tf])+4.0,-100,100)
    elif type=="betray":
        player_social.interact(npcs[ti],"threaten",0)
    elif type=="plot_power":
        if target_id==power.ruler_id and int(npcs[ai].get("influence",0))>70:
            power.crisis_for("дворцовый заговор",actor_id,"трон",day,hour)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    draw_rect(Rect2(710,132,555,34),Color(0.02,0.04,0.05,.82))
    var control=str(power.location_control.get(current_location_id,"нет"))
    draw_string(ThemeDB.fallback_font,Vector2(722,154),"Контроль: %s · Корона/Храм %.0f · Стража/подполье %.0f"%[control,float(faction_conflicts.relations["crown"]["temple"]),float(faction_conflicts.relations["guard"]["underworld"])],0,530,12,Color("#dfcbb0"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["faction_conflicts"]=faction_conflicts.serialize()
    data["intrigue_plots"]=intrigue.plots
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var fc=data.get("faction_conflicts",{})
    if typeof(fc)==TYPE_DICTIONARY:faction_conflicts.restore(fc)
    var plots=data.get("intrigue_plots",[])
    if typeof(plots)==TYPE_ARRAY:intrigue.plots=plots
