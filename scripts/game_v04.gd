extends Node2D

const HistorySystem = preload("res://scripts/history_system.gd")
const NPCSimulation = preload("res://scripts/npc_simulation.gd")
const SocialSystem = preload("res://scripts/social_system.gd")
const AIBridge = preload("res://scripts/ai_bridge.gd")

const WORLD := Vector2(1900, 1250)
const SPEED := 235.0
const TALK_RANGE := 92.0
const ITEM_RANGE := 72.0
const WITNESS_RANGE := 250.0

var history = HistorySystem.new()
var npc_sim = NPCSimulation.new()
var social = SocialSystem.new()
var ai = AIBridge.new()

var player := Vector2(900, 670)
var joy := Vector2.ZERO
var joy_id := -1
var day := 1
var hour := 8.0
var hunger := 18.0
var energy := 90.0
var hygiene := 55.0
var coins := 3
var wanted := 0
var reputation := 0
var inventory:Array = []
var message := ""
var message_timer := 0.0
var panel := ""
var selected_npc := -1
var interaction_open := false
var sim_event_cursor := 0
var social_event_cursor := 0

var skills := {
    "begging":0,"trade":0,"stealth":0,"sailing":0,"magic":0,
    "drinking":0,"theft":0,"labor":0,"politics":0,"charm":0
}

var npcs:Array = [
    {"id":"marek","name":"Марек","role":"торговец","pos":Vector2(650,520),"color":Color("#d6a84c"),"rel":0,"memory":[],"suspicion":0},
    {"id":"lissa","name":"Лисса","role":"воровка","pos":Vector2(1120,430),"color":Color("#8f74c9"),"rel":0,"memory":[],"suspicion":0},
    {"id":"kraken","name":"Кракен","role":"старый пират","pos":Vector2(1460,675),"color":Color("#687985"),"rel":0,"memory":[],"suspicion":0},
    {"id":"thomas","name":"Томас","role":"рыбак","pos":Vector2(430,845),"color":Color("#67a99b"),"rel":0,"memory":[],"suspicion":0},
    {"id":"endar","name":"Эндар","role":"отшельник","pos":Vector2(930,265),"color":Color("#6d92e3"),"rel":0,"memory":[],"suspicion":0},
    {"id":"ira","name":"Ира","role":"трактирщица","pos":Vector2(1500,850),"color":Color("#c57973"),"rel":0,"memory":[],"suspicion":0},
    {"id":"brann","name":"Бранн","role":"стражник","pos":Vector2(1260,650),"color":Color("#7187a4"),"rel":0,"memory":[],"suspicion":0},
    {"id":"voss","name":"Восс","role":"советник","pos":Vector2(820,580),"color":Color("#b4935b"),"rel":0,"memory":[],"suspicion":0}
]

var items:Array = [
    {"id":"apple","name":"яблоко","pos":Vector2(690,545),"owner":"marek","value":1,"color":Color("#d95c52"),"taken":false},
    {"id":"bread","name":"хлеб","pos":Vector2(620,555),"owner":"marek","value":2,"color":Color("#c89a62"),"taken":false},
    {"id":"pouch","name":"кошель","pos":Vector2(675,495),"owner":"marek","value":6,"color":Color("#e7c558"),"taken":false},
    {"id":"rope","name":"верёвка","pos":Vector2(1515,650),"owner":"kraken","value":3,"color":Color("#c7b28a"),"taken":false},
    {"id":"fish","name":"рыба","pos":Vector2(470,850),"owner":"thomas","value":2,"color":Color("#8ec6d0"),"taken":false},
    {"id":"herb","name":"синяя трава","pos":Vector2(1010,295),"owner":"","value":1,"color":Color("#6f9deb"),"taken":false}
]

func _ready():
    randomize()
    npc_sim.setup(npcs)
    social.setup(npcs)
    if history.events.is_empty():
        history.record(day,hour,"arrival","Прибыл на остров никем — с тремя монетами и без связей.",{"homeless":1.0})
    queue_redraw()

func _process(delta):
    if not interaction_open and panel == "":
        _advance_world(delta)
    _drain_world_events()
    if message_timer > 0:
        message_timer -= delta
        if message_timer <= 0: message = ""
    queue_redraw()

func _advance_world(delta):
    hour += delta * 0.10
    hunger = minf(100.0,hunger + delta*0.42)
    energy = maxf(0.0,energy - delta*0.16)
    hygiene = maxf(0.0,hygiene - delta*0.055)
    if hour >= 24.0:
        hour -= 24.0; day += 1
        if hygiene < 18.0: history.record(day,hour,"condition","Проснулся грязным и запущенным.",{"homeless":0.35})
    var kb := Input.get_vector("move_left","move_right","move_up","move_down")
    var dir := kb + joy
    if dir.length() > 1: dir = dir.normalized()
    var speed := SPEED
    if energy < 20: speed *= 0.62
    player += dir * speed * delta
    player.x = clampf(player.x,120,WORLD.x-120)
    player.y = clampf(player.y,120,WORLD.y-120)
    npcs = npc_sim.tick(npcs,delta,hour,day)
    npcs = social.tick(npcs,day,hour,delta)
    if Input.is_action_just_pressed("interact"): _try_interact()

func _drain_world_events():
    var sim_events:Array = npc_sim.world_events
    while sim_event_cursor < sim_events.size():
        var e = sim_events[sim_event_cursor]
        history.record(int(e["day"]),float(e["hour"]),"world",str(e["text"]),{})
        sim_event_cursor += 1
    var social_events:Array = social.events
    while social_event_cursor < social_events.size():
        var e = social_events[social_event_cursor]
        history.record(int(e["day"]),float(e["hour"]),"social",str(e["text"]),{})
        social_event_cursor += 1

func _nearest_npc() -> int:
    var best=-1; var d0=INF
    for i in npcs.size():
        var d=player.distance_to(npcs[i]["pos"])
        if d<TALK_RANGE and d<d0: d0=d; best=i
    return best

func _nearest_item() -> int:
    var best=-1; var d0=INF
    for i in items.size():
        if items[i]["taken"]: continue
        var d=player.distance_to(items[i]["pos"])
        if d<ITEM_RANGE and d<d0: d0=d; best=i
    return best

func _try_interact():
    var ii=_nearest_item()
    if ii>=0: _take_item(ii); return
    var ni=_nearest_npc()
    if ni>=0: selected_npc=ni; interaction_open=true; return
    if player.distance_to(Vector2(1500,850))<115: selected_npc=-2; interaction_open=true; return
    _notify("Здесь сейчас нечего делать.")

func _take_item(index:int):
    var item=items[index]
    item["taken"]=true; items[index]=item
    inventory.append(item.duplicate(true))
    if item["owner"]=="":
        history.record(day,hour,"found","Нашёл: %s."%item["name"],{})
        _notify("Подобрано: %s"%item["name"]); return
    skills["theft"]+=1
    var witnesses:Array=[]
    for i in npcs.size():
        if player.distance_to(npcs[i]["pos"])<WITNESS_RANGE: witnesses.append(i)
    if witnesses.is_empty():
        skills["stealth"]+=1
        history.record(day,hour,"theft","Незаметно украл %s."%item["name"],{"thief":1.0,"criminal":0.25})
        _notify("Кража удалась незаметно.")
    else:
        wanted+=1; reputation-=1
        for wi in witnesses: _witness_theft(wi,item)
        history.record(day,hour,"crime","Был замечен при краже %s."%item["name"],{"thief":0.8,"criminal":1.0})
        _notify("Тебя заметили. Розыск +1")

func _witness_theft(index:int,item:Dictionary):
    var n=npcs[index]
    n["memory"].append({"type":"theft","item":item["name"],"owner":item["owner"],"day":day,"hour":hour})
    n["suspicion"]+=2; n["rel"]-=2 if n["id"]==item["owner"] else 1
    npcs[index]=n

func _do_action(action:int):
    if selected_npc==-2:
        if action==0:
            if coins>=2:
                coins-=2; hunger=maxf(0,hunger-28); hygiene=minf(100,hygiene+3)
                history.record(day,hour,"meal","Поел в таверне.",{"social":0.15})
            else: _notify("Не хватает монет.")
        elif action==1:
            if coins>=1:
                coins-=1; skills["drinking"]+=1; energy=maxf(0,energy-5)
                history.record(day,hour,"drink","Выпил пива в таверне.",{"drunk":0.8,"social":0.2})
            else: _notify("Даже на пиво не хватает.")
        _close_dialog(); return
    var n=npcs[selected_npc]
    if action==0:
        match n["id"]:
            "marek": coins+=2; skills["labor"]+=1; skills["trade"]+=1; n["rel"]+=1; history.record(day,hour,"work","Разгружал товар у Марека.",{"worker":0.8,"merchant":0.25})
            "lissa": skills["stealth"]+=1; n["rel"]+=1; history.record(day,hour,"training","Учился скрытности у Лиссы.",{"thief":0.55})
            "kraken": skills["sailing"]+=1; n["rel"]+=1; history.record(day,hour,"sea","Слушал морские уроки Кракена.",{"sailor":0.7})
            "thomas": coins+=1; skills["labor"]+=1; skills["sailing"]+=1; n["rel"]+=1; history.record(day,hour,"work","Чинил сети с Томасом.",{"worker":0.5,"sailor":0.25})
            "endar": skills["magic"]+=1; n["rel"]+=1; history.record(day,hour,"magic","Изучал странный знак у Эндара.",{"mage":0.8})
            "ira": skills["charm"]+=1; n["rel"]+=1; history.record(day,hour,"social","Помогал Ире в таверне и знакомился с людьми.",{"social":0.7,"worker":0.2})
            "brann": wanted=maxi(0,wanted-1); n["rel"]+=1; history.record(day,hour,"law","Помог стражнику с поручением.",{"worker":0.3})
            "voss": skills["politics"]+=1; n["rel"]+=1; history.record(day,hour,"politics","Слушал разговоры о власти у советника Восса.",{"social":0.3})
    else:
        skills["begging"]+=1
        if randi()%3==0: coins+=1; history.record(day,hour,"begging","Выпросил монету у %s."%n["name"],{"homeless":0.55})
        else: history.record(day,hour,"begging","Просил милостыню у %s, но получил отказ."%n["name"],{"homeless":0.35})
    npcs[selected_npc]=n; _close_dialog()

func _notify(t:String): message=t; message_timer=3.0
func _close_dialog(): interaction_open=false; selected_npc=-1

func _unhandled_input(event):
    var s=get_viewport_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if panel!="": _panel_touch(event.position); return
            if interaction_open: _dialog_touch(event.position); return
            if event.position.x<250 and event.position.y>s.y-250:
                joy_id=event.index; _update_joy(event.position)
            elif event.position.x>s.x-210 and event.position.y>s.y-210: _try_interact()
            elif Rect2(s.x-210,18,190,54).has_point(event.position): panel="bio"
            elif Rect2(s.x-410,18,190,54).has_point(event.position): panel="world"
        elif event.index==joy_id: joy_id=-1; joy=Vector2.ZERO
    elif event is InputEventScreenDrag and event.index==joy_id: _update_joy(event.position)

func _update_joy(pos:Vector2):
    var c=Vector2(112,get_viewport_rect().size.y-112); var d=pos-c
    if d.length()>70:d=d.normalized()*70
    joy=d/70.0

func _dialog_touch(pos:Vector2):
    var s=get_viewport_rect().size; var box=Rect2(s.x*.08,s.y*.50,s.x*.84,s.y*.40)
    for i in 3:
        var r=Rect2(box.position.x+30,box.position.y+105+i*58,box.size.x-60,44)
        if r.has_point(pos):
            if i==2:_close_dialog()
            else:_do_action(i)

func _panel_touch(pos:Vector2):
    var s=get_viewport_rect().size
    if Rect2(s.x-180,28,140,50).has_point(pos): panel=""

func _draw():
    var s=get_viewport_rect().size; var cam=player-s/2
    cam.x=clampf(cam.x,0,WORLD.x-s.x); cam.y=clampf(cam.y,0,WORLD.y-s.y)
    _draw_world(cam,s); _draw_hud(s)
    if interaction_open:_draw_dialog(s)
    if panel!="":_draw_panel(s)

func _draw_world(cam:Vector2,s:Vector2):
    draw_rect(Rect2(Vector2.ZERO,s),Color("#185563"))
    var c=Vector2(950,620)-cam
    draw_circle(c,555,Color("#d7bd78")); draw_circle(c,505,Color("#6c9d59"))
    draw_line(Vector2(350,650)-cam,Vector2(1540,650)-cam,Color("#b89a63"),34)
    draw_line(Vector2(900,650)-cam,Vector2(930,245)-cam,Color("#b89a63"),28)
    draw_circle(Vector2(1500,850)-cam,68,Color("#7d4f2d")); draw_string(ThemeDB.fallback_font,Vector2(1452,780)-cam,"ТАВЕРНА",0,-1,17,Color.WHITE)
    draw_rect(Rect2(Vector2(1550,595)-cam,Vector2(220,105)),Color("#795233")); draw_string(ThemeDB.fallback_font,Vector2(1600,580)-cam,"ПОРТ",0,-1,17,Color.WHITE)
    for item in items:
        if item["taken"]:continue
        var p=item["pos"]-cam; draw_circle(p,10,item["color"])
        if player.distance_to(item["pos"])<ITEM_RANGE: draw_arc(p,18,0,TAU,30,Color.WHITE,2)
    for n in npcs:
        var p=n["pos"]-cam; draw_circle(p,20,n["color"])
        var label=str(n["name"])+" · "+str(n.get("state",""))
        if n.get("partner","")!="":label+=" ♥"
        if n.get("suspicion",0)>0:label+=" !"
        draw_string(ThemeDB.fallback_font,p+Vector2(-48,-28),label,0,-1,12,Color.WHITE)
    _draw_player(player-cam)

func _draw_player(p:Vector2):
    var v:Dictionary=history.visual_profile()
    var clothes=[Color("#8d806d"),Color("#5f6f72"),Color("#485d74"),Color("#604d75")][int(v["clothes_tier"])]
    draw_circle(p,19,clothes)
    if float(v["dirt"])>.28: draw_circle(p+Vector2(-7,5),4,Color("#594631"))
    if float(v["beard"])>.25: draw_line(p+Vector2(-8,10),p+Vector2(8,10),Color("#382b25"),5)
    if float(v["thief"])>.35: draw_arc(p,23,PI,TAU,20,Color("#272330"),6)
    if float(v["sailor"])>.35: draw_line(p+Vector2(-13,-13),p+Vector2(13,-13),Color("#d9c26f"),4)
    if float(v["magic"])>.35: draw_arc(p,28,0,TAU,32,Color(0.45,0.6,1,0.65),2)
    if float(v["drunk"])>.35: draw_circle(p+Vector2(-6,-3),2,Color("#b64040")); draw_circle(p+Vector2(6,-3),2,Color("#b64040"))

func _draw_hud(s:Vector2):
    draw_rect(Rect2(14,14,500,118),Color(0.02,0.05,0.06,.84))
    var time="%02d:%02d"%[int(hour),int((hour-int(hour))*60)]
    draw_string(ThemeDB.fallback_font,Vector2(28,38),"День %d · %s · %s"%[day,time,history.title()],0,-1,17,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(28,62),"Монеты %d · Голод %d · Энергия %d · Чистота %d"%[coins,int(hunger),int(energy),int(hygiene)],0,-1,14,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(28,84),"Розыск %d · Репутация %d · Вещей %d"%[wanted,reputation,inventory.size()],0,-1,13,Color("#f0d9b5"))
    draw_string(ThemeDB.fallback_font,Vector2(28,106),"Вор %d · Море %d · Магия %d · Политика %d"%[skills.theft,skills.sailing,skills.magic,skills.politics],0,-1,13,Color("#dce9e8"))
    _button(Rect2(s.x-210,18,190,54),"БИОГРАФИЯ")
    _button(Rect2(s.x-410,18,190,54),"МИР")
    var jc=Vector2(112,s.y-112); draw_circle(jc,78,Color(1,1,1,.10)); draw_arc(jc,78,0,TAU,40,Color(1,1,1,.25),2); draw_circle(jc+joy*52,30,Color(1,1,1,.35))
    var ac=Vector2(s.x-105,s.y-105); draw_circle(ac,59,Color("#d7a13d")); draw_string(ThemeDB.fallback_font,ac+Vector2(-39,6),"ДЕЙСТВИЕ",0,-1,14,Color("#17252a"))
    if message!="": draw_rect(Rect2(s.x*.18,145,s.x*.64,55),Color(0.01,0.03,0.04,.9)); draw_string(ThemeDB.fallback_font,Vector2(s.x*.20,178),message,0,s.x*.60,14,Color.WHITE)

func _button(r:Rect2,text:String): draw_rect(r,Color("#183b45")); draw_string(ThemeDB.fallback_font,r.position+Vector2(18,33),text,0,r.size.x-30,13,Color.WHITE)

func _draw_dialog(s:Vector2):
    draw_rect(Rect2(Vector2.ZERO,s),Color(0,0,0,.35)); var box=Rect2(s.x*.08,s.y*.50,s.x*.84,s.y*.40); draw_rect(box,Color("#0a1b20")); draw_rect(box,Color("#6f8790"),false,2)
    var title=""; var desc=""; var a0=""; var a1=""
    if selected_npc==-2:
        title="Таверна «Сломанный Маяк»"; desc="Еда, выпивка, слухи и случайные встречи."; a0="Поесть — 2 монеты"; a1="Выпить — 1 монета"
    else:
        var n=npcs[selected_npc]; title="%s — %s"%[n["name"],n["role"]]
        desc="Цель: %s · Порок: %s · Влияние: %d"%[n.get("goal",""),n.get("vice","нет"),int(n.get("influence",0))]
        a0="Провести время / помочь"; a1="Попросить монету"
    draw_string(ThemeDB.fallback_font,box.position+Vector2(30,34),title,0,-1,21,Color.WHITE); draw_string(ThemeDB.fallback_font,box.position+Vector2(30,68),desc,0,box.size.x-60,14,Color("#d6e3e4"))
    var opts=[a0,a1,"Уйти"]
    for i in 3:
        var r=Rect2(box.position.x+30,box.position.y+105+i*58,box.size.x-60,44); draw_rect(r,Color("#245765")); draw_string(ThemeDB.fallback_font,r.position+Vector2(15,28),opts[i],0,r.size.x-30,14,Color.WHITE)

func _draw_panel(s:Vector2):
    draw_rect(Rect2(Vector2.ZERO,s),Color(0,0,0,.72)); var r=Rect2(s.x*.06,s.y*.08,s.x*.88,s.y*.82); draw_rect(r,Color("#0b1b20")); draw_rect(r,Color("#82969b"),false,2); _button(Rect2(s.x-180,28,140,50),"ЗАКРЫТЬ")
    var y=r.position.y+42
    if panel=="bio":
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+30,y),"БИОГРАФИЯ · %s"%history.title(),0,-1,22,Color.WHITE); y+=40
        for e in history.recent(14):
            draw_string(ThemeDB.fallback_font,Vector2(r.position.x+30,y),"День %d · %s"%[e["day"],e["text"]],0,r.size.x-60,14,Color("#dfe8e8")); y+=30
    else:
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+30,y),"ЖИВОЙ ОСТРОВ",0,-1,22,Color.WHITE); y+=38
        for e in social.recent_events(8):
            draw_string(ThemeDB.fallback_font,Vector2(r.position.x+30,y),"• %s"%e["text"],0,r.size.x-60,14,Color("#e7dfca")); y+=27
        y+=12
        for key in social.factions.keys():
            var f=social.factions[key]; draw_string(ThemeDB.fallback_font,Vector2(r.position.x+30,y),"%s · власть %d · поддержка %d"%[f["name"],int(f["power"]),int(f["approval"])],0,-1,14,Color("#c8d8dd")); y+=26
