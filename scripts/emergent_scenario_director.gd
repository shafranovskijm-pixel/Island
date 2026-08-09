extends RefCounted

var events:Array=[]
var cooldowns:Dictionary={}
var last_slot:=-1

func tick(ctx:Dictionary)->Array:
    var day=int(ctx.get("day",0));var hour=float(ctx.get("hour",0));var slot=day*6+int(hour/4.0)
    if slot==last_slot:return []
    last_slot=slot
    _decay_cooldowns()
    var candidates:Array=[]
    _collect_household(ctx,candidates)
    _collect_economy(ctx,candidates)
    _collect_crime(ctx,candidates)
    _collect_social(ctx,candidates)
    _collect_occult(ctx,candidates)
    _collect_sea(ctx,candidates)
    _collect_politics(ctx,candidates)
    if candidates.is_empty():return []
    candidates.sort_custom(func(a,b):return float(a.get("weight",1.0))>float(b.get("weight",1.0)))
    var limit=2 if randf()<0.28 else 1
    for i in mini(limit,candidates.size()):
        var c:Dictionary=candidates[i]
        if _ready(str(c["id"])) and randf()<=float(c.get("chance",0.5)):
            var ev=_execute(c,ctx)
            if not ev.is_empty():events.append(ev);cooldowns[c["id"]]=int(c.get("cooldown",4))
    return drain()

func _collect_household(ctx:Dictionary,out:Array):
    var estate:Dictionary=ctx.get("estate",{});var residents:Array=estate.get("residents",[]) if not estate.is_empty() else []
    var staff:Array=estate.get("staff",[]) if not estate.is_empty() else []
    if estate.is_empty():return
    if float(estate.get("treasury",0))>45 and staff.size()>0:_add(out,"servant_theft",.16,6,4,{})
    if float(estate.get("treasury",0))<5 and staff.size()>0:_add(out,"servant_demands_pay",.48,4,8,{})
    if residents.size()>=2:_add(out,"resident_quarrel",.28,3,5,{})
    if residents.size()>=3:_add(out,"jealous_triangle",.16,7,4,{})
    if residents.size()>=2 and float(estate.get("food_store",0))>=12:_add(out,"private_feast",.14,6,2,{})
    if int(ctx.get("castle_level",0))>=2:_add(out,"noble_guest",.15,8,2,{})
    if int(ctx.get("locked_doors",0))==0 and float(ctx.get("crime",0))>45:_add(out,"house_intruder",.30,4,7,{})
    if int(ctx.get("guards",0))>=1 and float(ctx.get("crime",0))>55:_add(out,"guard_catches_thief",.22,5,5,{})
    if staff.size()>=2:_add(out,"staff_friendship",.18,4,2,{})
    if staff.size()>=2 and float(estate.get("treasury",0))<3:_add(out,"staff_walkout",.18,7,5,{})

func _collect_economy(ctx:Dictionary,out:Array):
    var hunger=float(ctx.get("hunger",0));var prosperity=float(ctx.get("prosperity",50));var builders=int(ctx.get("builders",0));var farmers=int(ctx.get("farmers",0))
    if hunger>45:_add(out,"bread_riot",.30,5,9,{})
    if hunger>60:_add(out,"food_smuggling",.38,4,10,{})
    if farmers<=1:_add(out,"farmer_shortage",.45,6,8,{})
    if builders==0:_add(out,"builder_shortage",.35,6,6,{})
    if prosperity>70:_add(out,"merchant_boom",.16,7,2,{})
    if prosperity<25:_add(out,"shop_bankruptcy",.24,6,5,{})
    if float(ctx.get("tool_shortage",0))>3:_add(out,"tool_black_market",.30,5,6,{})
    if float(ctx.get("food_market",0))<5:_add(out,"market_food_panic",.36,4,7,{})

func _collect_crime(ctx:Dictionary,out:Array):
    var crime=float(ctx.get("crime",0));var wanted=int(ctx.get("wanted",0));var location=str(ctx.get("location",""))
    if crime>50 and location in ["tavern","slums","market"]:_add(out,"street_robbery",.30,3,7,{})
    if location=="tavern":_add(out,"tavern_brawl",.24,3,4,{})
    if location=="tavern" and wanted>0:_add(out,"bounty_recognition",.28,5,8,{})
    if wanted>=2:_add(out,"guard_search",.34,3,9,{})
    if crime>65:_add(out,"gang_recruitment",.20,6,5,{})
    if str(ctx.get("player_class",""))=="wealthy" and crime>35:_add(out,"kidnap_plot",.10,10,3,{})

func _collect_social(ctx:Dictionary,out:Array):
    var npcs:Array=ctx.get("npcs",[]);if npcs.is_empty():return
    _add(out,"old_friend_visit",.12,6,2,{})
    _add(out,"public_insult",.12,4,2,{})
    if int(ctx.get("influence",0))>=4:_add(out,"favor_request",.18,5,5,{})
    if int(ctx.get("reputation",0))>=5:_add(out,"stranger_seeks_help",.18,5,4,{})
    if int(ctx.get("reputation",0))<=-4:_add(out,"people_avoid_player",.22,4,4,{})

func _collect_occult(ctx:Dictionary,out:Array):
    var secrets:Dictionary=ctx.get("secrets",{});var is_vampire=bool(ctx.get("is_vampire",false));var hour=float(ctx.get("hour",0));var blood=float(ctx.get("blood",100))
    if bool(secrets.get("occult_order",false)) and hour>=20:_add(out,"occult_invitation",.20,6,5,{})
    if bool(secrets.get("vampires",false)) and not is_vampire:_add(out,"vampire_rumor",.12,7,3,{})
    if is_vampire and blood<30:_add(out,"blood_hunger",.50,2,10,{})
    if is_vampire and int(ctx.get("temple_rep",0))<0:_add(out,"priest_suspicion",.26,4,8,{})
    if is_vampire and int(ctx.get("castle_level",0))>=1:_add(out,"servant_sees_vampire",.14,8,5,{})
    if is_vampire and bool(ctx.get("bat_form",false)):_add(out,"bat_witness",.18,5,5,{})
    if bool(secrets.get("crypt_entrance",false)) and str(ctx.get("location",""))=="graveyard":_add(out,"crypt_whispers",.22,5,3,{})

func _collect_sea(ctx:Dictionary,out:Array):
    var has_boat=bool(ctx.get("has_boat",false));var location=str(ctx.get("location",""))
    if has_boat and location in ["port","fisher_cove"]:_add(out,"rare_fish",.18,4,2,{})
    if has_boat:_add(out,"boat_damage",.10,8,3,{})
    if has_boat and int(ctx.get("sailing",0))>=2:_add(out,"drifting_wreck",.12,8,3,{})
    if location=="port":_add(out,"foreign_ship",.18,5,4,{})
    if location=="port" and float(ctx.get("hunger",0))>40:_add(out,"grain_ship",.22,5,6,{})

func _collect_politics(ctx:Dictionary,out:Array):
    var influence=int(ctx.get("influence",0));var castle=int(ctx.get("castle_level",0));var unrest=float(ctx.get("unrest",0))
    if castle>=2:_add(out,"tax_collector",.18,7,4,{})
    if castle>=2 and influence>=4:_add(out,"royal_envoy",.16,8,4,{})
    if unrest>60:_add(out,"political_agitator",.26,5,7,{})
    if influence>=7:_add(out,"court_conspiracy",.14,9,5,{})
    if int(ctx.get("wanted",0))>=3 and influence>=5:_add(out,"political_protection_offer",.12,9,5,{})

func _execute(c:Dictionary,ctx:Dictionary)->Dictionary:
    var id=str(c["id"]);var npcs:Array=ctx.get("npcs",[]);var estate:Dictionary=ctx.get("estate",{})
    var ev={"id":id,"type":"scenario","text":"","approach_npc_id":"","effects":{},"day":ctx.get("day",0),"hour":ctx.get("hour",0)}
    match id:
        "servant_theft":
            var s=_staff_npc(estate,npcs);if s.is_empty():return {}
            var stolen=minf(12.0,float(estate.get("treasury",0)));estate["treasury"]-=stolen;s["money"]=int(s.get("money",0))+int(stolen);s["suspicion"]=int(s.get("suspicion",0))+1
            ev["text"]="Из домашней казны пропали монеты. Один из слуг ведёт себя необычно.";ev["effects"]={"treasury":-stolen}
        "servant_demands_pay":
            var s=_staff_npc(estate,npcs);if s.is_empty():return {};ev["approach_npc_id"]=s["id"];ev["text"]="%s идёт к хозяину поговорить о задержке жалования."%s["name"]
        "resident_quarrel":ev["text"]=_pair_event(npcs,estate,"В доме вспыхнула ссора между %s и %s.",-1,6)
        "jealous_triangle":ev["text"]=_pair_event(npcs,estate,"Ревность портит отношения между %s и %s.",-2,9)
        "private_feast":estate["food_store"]=maxf(0,float(estate.get("food_store",0))-5);ev["text"]="Жители дома сами устроили поздний ужин и засиделись вместе."
        "noble_guest":
            var n=_pick_nonresident(npcs,estate,2);if n.is_empty():return {};n["target"]=estate.get("pos",n.get("pos",Vector2.ZERO));ev["approach_npc_id"]=n["id"];ev["text"]="%s направляется во владение с частным визитом."%n["name"]
        "house_intruder":ev["text"]="Ночью кто-то проверяет окна и незапертые двери владения.";ev["effects"]={"intrusion":true}
        "guard_catches_thief":ev["text"]="Охрана замечает подозрительного человека возле владения.";ev["effects"]={"guard_success":true}
        "staff_friendship":ev["text"]=_pair_event(npcs,estate,"Двое слуг, %s и %s, заметно сблизились.",1,-3)
        "staff_walkout":
            var s=_staff_npc(estate,npcs);if s.is_empty():return {};_remove_staff(estate,str(s["id"]));s["household_role"]="";ev["text"]="%s уходит со службы из-за долгов по жалованию."%s["name"]
        "bread_riot":ev["text"]="У рынка собирается раздражённая толпа: цены на еду стали невыносимыми.";ev["effects"]={"unrest":8,"crime":3,"location":"market"}
        "food_smuggling":ev["text"]="По Нижним улицам расходится слух о тайной партии дешёвого зерна.";ev["effects"]={"underworld":2,"food_slums":5}
        "farmer_shortage":ev["text"]="Землевладельцы ищут людей для работы на полях: рабочих рук почти не осталось.";ev["effects"]={"job":"farmer"}
        "builder_shortage":ev["text"]="Стройки острова встают: свободных мастеров почти нет.";ev["effects"]={"construction_delay":true}
        "merchant_boom":ev["text"]="Рынок оживлён: торговцы богатеют и начинают скупать новые дома.";ev["effects"]={"prosperity":3}
        "shop_bankruptcy":ev["text"]="Одна из лавок закрывается. Хозяин распродаёт остатки почти за бесценок.";ev["effects"]={"sale":true}
        "tool_black_market":ev["text"]="В трущобах начинают перепродавать рабочие инструменты втридорога.";ev["effects"]={"underworld":1}
        "market_food_panic":ev["text"]="На рынке почти не осталось еды; покупатели начинают хватать последние запасы.";ev["effects"]={"unrest":4}
        "street_robbery":
            var n=_pick_npc(npcs,0);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="%s начинает следить за героем, выжидая удобный момент."%n["name"]
        "tavern_brawl":ev["text"]="В таверне спор за соседним столом быстро перерастает в драку.";ev["effects"]={"brawl":true}
        "bounty_recognition":
            var n=_pick_npc(npcs,0);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="Кажется, %s узнал героя по описанию розыска."%n["name"]
        "guard_search":
            var g=_pick_role(npcs,["страж","guard"]);if g.is_empty():return {};ev["approach_npc_id"]=g["id"];ev["text"]="Стража получила свежие приметы разыскиваемого и начинает поиски."
        "gang_recruitment":
            var n=_pick_role(npcs,["контраб","банд","вор"]);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="%s хочет поговорить с героем о выгодном грязном деле."%n["name"]
        "kidnap_plot":ev["text"]="Кто-то слишком долго расспрашивает слуг о распорядке богатого хозяина.";ev["effects"]={"threat":true}
        "old_friend_visit":
            var n=_pick_relation(npcs,2);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="%s сам разыскивает героя, чтобы поговорить."%n["name"]
        "public_insult":
            var n=_pick_relation(npcs,-1);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="%s явно настроен на неприятный разговор."%n["name"]
        "favor_request":
            var n=_pick_relation(npcs,1);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="%s идёт просить героя об услуге."%n["name"]
        "stranger_seeks_help":
            var n=_pick_relation(npcs,0);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="Незнакомый житель решает обратиться к герою за помощью."
        "people_avoid_player":ev["text"]="Люди замечают героя и стараются перейти на другую сторону улицы.";ev["effects"]={"social_fear":true}
        "occult_invitation":
            var n=_pick_role(npcs,["орден","occult"]);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="Кто-то из Ордена ищет встречи с героем после заката."
        "vampire_rumor":ev["text"]="В разговорах снова всплывает история о дворянке, которую никто не видел при солнечном свете."
        "blood_hunger":ev["text"]="Запах живой крови вокруг становится почти невыносимым.";ev["effects"]={"blood_hunger":true}
        "priest_suspicion":
            var p=_pick_role(npcs,["жрец","priest"]);if p.is_empty():return {};p["target"]=ctx.get("player_pos",p.get("pos",Vector2.ZERO));ev["approach_npc_id"]=p["id"];ev["text"]="Служитель храма хочет лично увидеть героя при дневном свете."
        "servant_sees_vampire":
            var s=_staff_npc(estate,npcs);if s.is_empty():return {};s["memory"].append({"type":"saw_vampire_master","day":ctx.get("day",0)});s["stress"]=minf(100,float(s.get("stress",0))+18);ev["text"]="Один из слуг замечает нечто невозможное и теперь знает тайну хозяина."
        "bat_witness":
            var n=_pick_npc(npcs,0);if n.is_empty():return {};n["memory"].append({"type":"saw_player_bat","day":ctx.get("day",0)});ev["text"]="%s замечает превращение героя в летучую мышь."%n["name"]
        "crypt_whispers":ev["text"]="Из глубины склепа слышится тихий голос, называющий имя героя.";ev["effects"]={"occult_interest":1}
        "rare_fish":ev["text"]="Рыбаки говорят о редкой крупной рыбе у дальних камней.";ev["effects"]={"rare_fish":true}
        "boat_damage":ev["text"]="После плавания в корпусе лодки обнаруживается течь.";ev["effects"]={"boat_damage":8}
        "drifting_wreck":ev["text"]="Вдали замечены обломки дрейфующего судна. Среди них может быть груз или выжившие.";ev["effects"]={"wreck":true}
        "foreign_ship":ev["text"]="В гавань входит незнакомое судно. На берег сходят новые люди и товары.";ev["effects"]={"migration":true}
        "grain_ship":ev["text"]="В порт приходит корабль с зерном, и цена еды на время падает.";ev["effects"]={"food_port":12}
        "tax_collector":
            var n=_pick_role(npcs,["канцлер","chancellor","страж"]);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="К владению направляется представитель власти с разговором о налогах."
        "royal_envoy":
            var n=_pick_role(npcs,["канцлер","chancellor","страж"]);if n.is_empty():return {};ev["approach_npc_id"]=n["id"];ev["text"]="Королевский посланник едет к герою с предложением двора."
        "political_agitator":ev["text"]="На площади появляется оратор, обвиняющий власть в голоде и беспорядках.";ev["effects"]={"unrest":5}
        "court_conspiracy":ev["text"]="Через знакомых при дворе до героя доходит намёк: против одного из влиятельных людей готовят заговор.";ev["effects"]={"political_secret":true}
        "political_protection_offer":ev["text"]="Кто-то при власти готов прикрыть проблемы героя со стражей — но не бесплатно.";ev["effects"]={"corruption_offer":true}
    return ev

func _pair_event(npcs:Array,estate:Dictionary,format:String,rel_delta:int,stress_delta:float)->String:
    var ids:Array=estate.get("residents",[]).duplicate();if ids.size()<2:return ""
    ids.shuffle();var a=_npc_by_id(npcs,str(ids[0]));var b=_npc_by_id(npcs,str(ids[1]));if a.is_empty() or b.is_empty():return ""
    a["rel"]=int(a.get("rel",0))+rel_delta;b["rel"]=int(b.get("rel",0))+rel_delta;a["stress"]=clampf(float(a.get("stress",0))+stress_delta,0,100)
    return format%[a.get("name","Житель"),b.get("name","Житель")]

func _staff_npc(estate:Dictionary,npcs:Array)->Dictionary:
    var staff:Array=estate.get("staff",[]);if staff.is_empty():return {}
    return _npc_by_id(npcs,str(staff.pick_random().get("npc_id","")))
func _remove_staff(estate:Dictionary,id:String):
    for i in range(estate.get("staff",[]).size()-1,-1,-1):
        if str(estate["staff"][i].get("npc_id",""))==id:estate["staff"].remove_at(i)
func _pick_nonresident(npcs:Array,estate:Dictionary,min_rel:int)->Dictionary:
    var residents:Dictionary={};for id in estate.get("residents",[]):residents[str(id)]=true
    var a:Array=[];for n in npcs:
        if bool(n.get("alive",true)) and not residents.has(str(n.get("id",""))) and int(n.get("rel",0))>=min_rel:a.append(n)
    return {} if a.is_empty() else a.pick_random()
func _pick_npc(npcs:Array,min_rel:int)->Dictionary:
    var a:Array=[];for n in npcs:
        if bool(n.get("alive",true)) and int(n.get("rel",0))>=min_rel:a.append(n)
    return {} if a.is_empty() else a.pick_random()
func _pick_relation(npcs:Array,min_rel:int)->Dictionary:
    return _pick_npc(npcs,min_rel)
func _pick_role(npcs:Array,parts:Array)->Dictionary:
    var a:Array=[];for n in npcs:
        var role=(str(n.get("role",""))+" "+str(n.get("id",""))).to_lower();var ok=false
        for p in parts:
            if str(p).to_lower() in role:ok=true;break
        if ok and bool(n.get("alive",true)):a.append(n)
    return {} if a.is_empty() else a.pick_random()
func _npc_by_id(npcs:Array,id:String)->Dictionary:
    for n in npcs:
        if str(n.get("id",""))==id:return n
    return {}
func _add(out:Array,id:String,chance:float,cooldown:int,weight:float,data:Dictionary):
    if _ready(id):out.append({"id":id,"chance":chance,"cooldown":cooldown,"weight":weight,"data":data})
func _ready(id:String)->bool:return int(cooldowns.get(id,0))<=0
func _decay_cooldowns():
    for key in cooldowns.keys():cooldowns[key]=maxi(0,int(cooldowns[key])-1)
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"cooldowns":cooldowns,"last_slot":last_slot}
func restore(data:Dictionary):
    var c=data.get("cooldowns",{});if typeof(c)==TYPE_DICTIONARY:cooldowns=c
    last_slot=int(data.get("last_slot",last_slot))
