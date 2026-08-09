extends "res://scripts/game_v06.gd"

const LocationSystem=preload("res://scripts/location_system.gd")
const LocationPopulation=preload("res://scripts/location_population.gd")

var locations=LocationSystem.new()
var population=LocationPopulation.new()
var current_location_id:="wilderness"
var last_location_id:=""
var location_message_timer:=0.0

func _ready():
    super._ready()
    var existing:Dictionary={}
    for n in npcs: existing[str(n["id"])]=true
    for n in population.extra_npcs(locations.spawn_points()):
        if not existing.has(str(n["id"])): npcs.append(n)
    npc_sim.setup(npcs)
    social.setup(npcs)
    player_social.setup(npcs)
    _update_location(true)

func _process(delta):
    super._process(delta)
    _update_location(false)
    if location_message_timer>0: location_message_timer-=delta

func _advance_world(delta):
    super._advance_world(delta)
    _location_behaviors(delta)

func _update_location(force:bool):
    current_location_id=locations.current_location(player)
    if force or current_location_id!=last_location_id:
        last_location_id=current_location_id
        _notify("Локация: %s"%locations.location_name(current_location_id))
        history.record(day,hour,"location","Пришёл в локацию: %s."%locations.location_name(current_location_id),{})

func _location_behaviors(delta:float):
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)): continue
        var home_id=str(n.get("home_location",""))
        if home_id!="" and locations.locations.has(home_id):
            # Important location NPCs return home outside social/economic excursions.
            if hour<7.0 or hour>21.5:
                n["target"]=locations.locations[home_id]["center"]
        if str(n.get("id",""))=="vampire":
            n["hidden"]=hour>=6.0 and hour<20.0
            if not n["hidden"] and locations.secrets["vampires"]:
                n["target"]=locations.locations["graveyard"]["center"]
        npcs[i]=n

func _nearest_npc()->int:
    var best=-1;var d0=INF
    for i in npcs.size():
        var n=npcs[i]
        if bool(n.get("hidden",false)): continue
        if not bool(n.get("alive",true)): continue
        var d=player.distance_to(n["pos"])
        if d<TALK_RANGE and d<d0: d0=d;best=i
    return best

func _try_interact():
    # Secret discovery is contextual rather than a quest marker.
    if current_location_id=="graveyard" and hour>=21.0:
        if int(skills.get("magic",0))>=1 or int(skills.get("stealth",0))>=2:
            if not locations.secrets["crypt_entrance"]:
                locations.discover("crypt_entrance")
                history.record(day,hour,"secret","На кладбище обнаружил скрытый вход в древний склеп.",{"mage":0.25,"thief":0.15})
                _notify("Между могилами найден скрытый спуск в склеп.")
                return
    super._try_interact()

func _do_action(action:int):
    if selected_npc>=0 and selected_npc<npcs.size():
        var n=npcs[selected_npc]
        var id=str(n.get("id",""))
        if id in ["king","queen","chancellor","captain_guard","priest","undertaker","vampire","cult_leader","beggar","smuggler","archmage"]:
            _do_location_npc_action(n,action)
            return
    super._do_action(action)

func _do_location_npc_action(n:Dictionary,action:int):
    var id=str(n["id"])
    if action==0:
        match id:
            "king":
                skills["politics"]+=1;n["rel"]+=1;history.record(day,hour,"court","Добился разговора с королём Эдриком.",{"social":0.5})
            "queen":
                skills["charm"]+=1;n["rel"]+=1;history.record(day,hour,"court","Оказал услугу королевскому двору.",{"social":0.6})
            "chancellor":
                skills["politics"]+=1;n["rel"]+=1;history.record(day,hour,"politics","Начал искать покровительство канцлера.",{"social":0.4})
            "captain_guard":
                wanted=maxi(0,wanted-1);n["rel"]+=1;history.record(day,hour,"law","Помог капитану стражи.",{"worker":0.2})
            "priest":
                energy=minf(100,energy+12);n["rel"]+=1;history.record(day,hour,"faith","Получил благословение в храме.",{})
            "undertaker":
                coins+=1;skills["labor"]+=1;n["rel"]+=1;history.record(day,hour,"work","Работал могильщиком среди старых могил.",{"worker":0.5,"homeless":0.1})
            "vampire":
                skills["charm"]+=1;n["rel"]+=1;history.record(day,hour,"occult","Говорил с Леди Весперой в подземном склепе.",{"mage":0.6})
            "cult_leader":
                skills["magic"]+=1;n["rel"]+=1;locations.discover("occult_order");history.record(day,hour,"occult","Приблизился к Ордену Пепельной Луны.",{"mage":0.8})
            "beggar":
                skills["begging"]+=1;n["rel"]+=1;history.record(day,hour,"street","Провёл время среди нищих Нижних улиц.",{"homeless":0.45,"social":0.15})
            "smuggler":
                coins+=2;skills["stealth"]+=1;n["rel"]+=1;history.record(day,hour,"crime","Выполнил мелкую работу для контрабандистки Сайры.",{"criminal":0.45,"thief":0.25})
            "archmage":
                skills["magic"]+=1;n["rel"]+=1;history.record(day,hour,"magic","Помог Талему исследовать руины Звёздного Круга.",{"mage":0.7})
    elif action==1:
        match id:
            "undertaker":
                locations.discover("crypt_entrance");history.record(day,hour,"rumor","Могильщик намекнул на голоса под кладбищем.",{})
            "vampire":
                locations.discover("vampires");history.record(day,hour,"secret","Узнал, что на острове действительно существуют вампиры.",{"mage":0.5})
            "cult_leader":
                locations.discover("occult_order");skills["magic"]+=1;history.record(day,hour,"ritual","Участвовал в тайном ритуале Ордена.",{"mage":1.0})
            "king","queen","chancellor":
                skills["politics"]+=1;history.record(day,hour,"politics","Узнал новые придворные слухи.",{"social":0.2})
            "captain_guard":
                history.record(day,hour,"law","Расспрашивал стражу о преступлениях острова.",{})
            "priest":
                history.record(day,hour,"faith","Говорил со жрецом о запретной магии.",{})
            "beggar":
                if coins>0: coins-=1;n["rel"]+=2;history.record(day,hour,"kindness","Поделился монетой с нищим Нелом.",{"social":0.35})
            "smuggler":
                skills["stealth"]+=1;history.record(day,hour,"underworld","Узнал о тайных путях через порт.",{"thief":0.3})
            "archmage":
                skills["magic"]+=1;history.record(day,hour,"magic","Узнал больше о древней магии острова.",{"mage":0.4})
    var idx=_find_npc(id)
    if idx>=0:npcs[idx]=n
    player_social.interact(n,"help" if action==0 else "talk",int(skills.get("charm",0)))
    _close_dialog();saves.save_game(_capture_save())

func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    _draw_locations(cam)

func _draw_locations(cam:Vector2):
    # Placeholder shapes intentionally make the systemic map testable before final art.
    var castle=locations.locations["castle"]["center"]-cam
    draw_rect(Rect2(castle-Vector2(105,75),Vector2(210,150)),Color("#6f6670"))
    draw_rect(Rect2(castle-Vector2(28,115),Vector2(56,55)),Color("#807786"))
    draw_string(ThemeDB.fallback_font,castle+Vector2(-75,-125),"ЗАМОК ЧЁРНОГО УТЁСА",0,210,14,Color.WHITE)
    var grave=locations.locations["graveyard"]["center"]-cam
    draw_circle(grave,115,Color("#4f6550"))
    for off in [Vector2(-45,-20),Vector2(5,15),Vector2(50,-35),Vector2(-10,-60)]:
        draw_rect(Rect2(grave+off,Vector2(12,25)),Color("#777a76"))
    draw_string(ThemeDB.fallback_font,grave+Vector2(-70,-125),"СТАРОЕ КЛАДБИЩЕ",0,180,14,Color.WHITE)
    var temple=locations.locations["temple"]["center"]-cam
    draw_rect(Rect2(temple-Vector2(60,50),Vector2(120,100)),Color("#c8c2a7"))
    var slums=locations.locations["slums"]["center"]-cam
    for off in [Vector2(-70,-30),Vector2(15,-45),Vector2(-20,30)]: draw_rect(Rect2(slums+off,Vector2(55,38)),Color("#6f543d"))

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    draw_rect(Rect2(18,132,300,34),Color(0.02,0.04,0.05,.82))
    draw_string(ThemeDB.fallback_font,Vector2(30,154),locations.location_name(current_location_id),0,275,14,Color("#e8d8b5"))

func _draw_dialog(s:Vector2):
    super._draw_dialog(s)
    if selected_npc>=0 and selected_npc<npcs.size():
        var id=str(npcs[selected_npc].get("id",""))
        if id in ["king","queen","chancellor","captain_guard","priest","undertaker","vampire","cult_leader","beggar","smuggler","archmage"]:
            var box=Rect2(s.x*.08,s.y*.50,s.x*.84,s.y*.40)
            var opts=population.location_dialogue(npcs[selected_npc],current_location_id)
            for i in 2:
                var r=Rect2(box.position.x+30,box.position.y+105+i*58,box.size.x-60,44)
                draw_rect(r,Color("#354f59"))
                draw_string(ThemeDB.fallback_font,r.position+Vector2(15,28),str(opts[i]),0,r.size.x-30,15,Color.WHITE)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["location_secrets"]=locations.secrets
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var sec=data.get("location_secrets",{})
    if typeof(sec)==TYPE_DICTIONARY:
        for key in locations.secrets.keys():
            if sec.has(key):locations.secrets[key]=bool(sec[key])
