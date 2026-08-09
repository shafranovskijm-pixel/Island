extends "res://scripts/game_v23.gd"

const LearningSystem=preload("res://scripts/learning_system.gd")
var learning=LearningSystem.new()
var study_menu_open:=false
var study_books:Array=[]

func _ready():
    super._ready()
    if not skills.has("foraging"):skills["foraging"]=0
    if not skills.has("farming"):skills["farming"]=0
    if not skills.has("building"):skills["building"]=0
    if not skills.has("medicine"):skills["medicine"]=0

func _process(delta):
    super._process(delta)
    for e in learning.drain():
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","learning")),str(e.get("text","Обучение.")),{"worker":0.05})

func _do_location_npc_action(n:Dictionary,action:int):
    var id=str(n.get("id",""))
    if id=="librarian":
        if action==0:
            _open_study_menu("library")
            return
        elif action==1:
            n["rel"]=int(n.get("rel",0))+1
            history.record(day,hour,"knowledge","Библиотекарь рассказал, что редкие книги распределены между храмом, двором и тайными собраниями.",{})
            _notify("Элвин: «Не всё знание лежит на открытых полках. Ищи архивы, наставников и практику.»")
            var idx=_find_npc(id);if idx>=0:npcs[idx]=n
            _close_dialog();return
    super._do_location_npc_action(n,action)
    _practice_from_interaction(n,action)

func _practice_from_interaction(n:Dictionary,action:int):
    if action!=0:return
    var id=str(n.get("id",""));var role=str(n.get("role","")).to_lower()
    if id=="marek":learning.practice("trade",0.8,day,hour)
    elif id=="fisher" or "рыбак" in role:learning.practice("sailing",0.8,day,hour);learning.practice("foraging",0.35,day,hour)
    elif id=="smuggler":learning.practice("stealth",0.8,day,hour)
    elif id=="archmage" or id=="cult_leader":learning.practice("magic",0.7,day,hour)
    elif "стро" in role:learning.practice("building",0.8,day,hour)
    elif "крест" in role or "фермер" in role:learning.practice("farming",0.8,day,hour)
    elif "лекар" in role or id=="priest":learning.practice("medicine",0.7,day,hour)

func _open_study_menu(location_id:String):
    study_books=learning.available_books(location_id)
    if study_books.is_empty():
        _notify("Подходящих книг здесь сейчас нет.");return
    study_menu_open=true;interaction_open=true;selected_npc=-3

func _unhandled_input(event):
    if study_menu_open and event is InputEventScreenTouch and event.pressed:
        _handle_study_touch(event.position);return
    super._unhandled_input(event)

func _handle_study_touch(pos:Vector2):
    var s=get_viewport_rect().size;var box=Rect2(s.x*.10,s.y*.32,s.x*.80,s.y*.52)
    if not box.has_point(pos):return
    var y=box.position.y+85
    for i in mini(study_books.size(),5):
        var r=Rect2(box.position.x+28,y+i*56,box.size.x-56,42)
        if r.has_point(pos):
            var b:Dictionary=study_books[i]
            var result=learning.study_book(str(b["id"]),current_location_id,day,hour)
            if bool(result.get("ok",false)):
                var skill=str(result.get("skill",""));skills[skill]=int(skills.get(skill,0))+maxi(0,learning.effective_bonus(skill)-int(skills.get(skill,0)))
                hour+=1.5;energy=maxf(0,energy-7);_notify("Изучено: %s"%result.get("title","книга"))
            else:_notify(str(result.get("reason","Не удалось учиться.")))
            study_menu_open=false;interaction_open=false;selected_npc=-1
            saves.save_game(_capture_save());return

func ask_mentor_lesson(npc_id:String,skill:String):
    var idx=_find_npc(npc_id);if idx<0:return
    var result=learning.mentor_lesson(npcs[idx],skill,day,hour)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Урок недоступен.")));return
    skills[skill]=int(skills.get(skill,0))+1;hour+=2.0;energy=maxf(0,energy-9)
    _notify("Урок завершён: %s +1"%skill)

func _skill_for(verb:String)->int:
    var base=super._skill_for(verb)
    var map={"steal":"stealth","hide":"stealth","sneak":"stealth","pick_lock":"stealth","persuade":"trade","deceive":"trade","climb":"building","search":"foraging"}
    if map.has(verb):base+=learning.effective_bonus(str(map[verb]))
    return base

func request_construction(kind:String):
    var bonus=learning.effective_bonus("building")
    if bonus>0:history.record(day,hour,"knowledge_use","Знания строительства помогли лучше понять заказ и материалы.",{})
    super.request_construction(kind)

func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    var p=locations.locations["library"]["center"]-cam
    draw_rect(Rect2(p-Vector2(62,42),Vector2(124,84)),Color("#756b57"))
    draw_rect(Rect2(p-Vector2(50,32),Vector2(100,64)),Color("#b2a781"))
    draw_string(ThemeDB.fallback_font,p+Vector2(-45,-50),"БИБЛИОТЕКА",0,120,13,Color.WHITE)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    if study_menu_open:
        var box=Rect2(s.x*.10,s.y*.32,s.x*.80,s.y*.52);draw_rect(box,Color(0.03,0.04,0.05,.97));draw_rect(box,Color("#8f835e"),false,2)
        draw_string(ThemeDB.fallback_font,box.position+Vector2(28,38),"Что изучать?",0,box.size.x-56,20,Color("#eee5ca"))
        var y=box.position.y+85
        for i in mini(study_books.size(),5):
            var b:Dictionary=study_books[i];var r=Rect2(box.position.x+28,y+i*56,box.size.x-56,42)
            draw_rect(r,Color("#3d4f50"));draw_string(ThemeDB.fallback_font,r.position+Vector2(12,26),str(b["title"])+"  →  "+str(b["skill"]),0,r.size.x-24,14,Color.WHITE)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["learning"]=learning.serialize();return data

func _apply_save(data:Dictionary):
    super._apply_save(data);var l=data.get("learning",{});if typeof(l)==TYPE_DICTIONARY:learning.restore(l)
