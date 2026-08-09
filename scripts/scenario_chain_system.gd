extends RefCounted

var chains:Array=[]
var events:Array=[]
var next_id:=1

func ingest(event:Dictionary,day:int):
    var id=str(event.get("id",""))
    match id:
        "servant_sees_vampire":_start("vampire_secret",day,["servant_confides","rumor_reaches_temple","temple_investigation","hunter_arrives"])
        "servant_theft":_start("stolen_treasury",day,["missing_money_noticed","servant_spends_money","suspicion_grows","confrontation"])
        "bread_riot":_start("food_crisis",day,["guard_market_patrol","smugglers_profit","merchant_pressure","crown_response"])
        "court_conspiracy":_start("court_plot",day,["secret_meeting","bribe_attempt","betrayal_risk","political_move"])
        "boat_damage":_start("damaged_boat",day,["repair_needed","shipwright_offer","parts_shortage"])
        "house_intruder":_start("intruder_story",day,["tracks_found","underworld_rumor","second_attempt"])

func tick(day:int,npcs:Array)->Array:
    for ci in range(chains.size()-1,-1,-1):
        var c=chains[ci]
        if int(c.get("next_day",99999))>day:continue
        var steps:Array=c.get("steps",[]);var index=int(c.get("index",0))
        if index>=steps.size():chains.remove_at(ci);continue
        var step=str(steps[index]);var ev=_step_event(str(c["kind"]),step,npcs,day)
        if not ev.is_empty():events.append(ev)
        c["index"]=index+1;c["next_day"]=day+randi_range(1,3);chains[ci]=c
    return drain()

func _start(kind:String,day:int,steps:Array):
    for c in chains:
        if str(c.get("kind",""))==kind:return
    chains.append({"id":"chain_%d"%next_id,"kind":kind,"steps":steps,"index":0,"next_day":day+randi_range(1,2)});next_id+=1

func _step_event(kind:String,step:String,npcs:Array,day:int)->Dictionary:
    var texts={
        "servant_confides":"Один из жителей дома не выдерживает и делится увиденным с близким человеком.",
        "rumor_reaches_temple":"До храмовых служителей доходит странный слух о хозяине частного владения.",
        "temple_investigation":"Храм начинает осторожно расспрашивать людей о ночной жизни героя.",
        "hunter_arrives":"На остров прибывает молчаливый чужак, слишком хорошо разбирающийся в нечисти.",
        "missing_money_noticed":"В домашней казне обнаруживается недостача.",
        "servant_spends_money":"Один из слуг неожиданно начинает тратить больше обычного.",
        "suspicion_grows":"В доме начинают подозревать, что деньги пропали не случайно.",
        "confrontation":"Домашний конфликт из-за пропавших денег становится неизбежным.",
        "guard_market_patrol":"После беспорядков стража усиливает патрули возле рынка.",
        "smugglers_profit":"Контрабандисты богатеют на дефиците продовольствия.",
        "merchant_pressure":"Крупные торговцы требуют от власти обеспечить поставки еды.",
        "crown_response":"Двор вынужден публично реагировать на продовольственный кризис.",
        "secret_meeting":"Несколько влиятельных людей проводят закрытую встречу.",
        "bribe_attempt":"Кому-то из участников заговора предлагают деньги за молчание.",
        "betrayal_risk":"В заговоре появляется человек, готовый продать остальных.",
        "political_move":"Придворная интрига переходит от разговоров к реальному действию.",
        "repair_needed":"Повреждённое судно начинает заметно хуже слушаться руля.",
        "shipwright_offer":"Кто-то из портовых мастеров узнаёт о проблеме с судном и предлагает помощь.",
        "parts_shortage":"Для полного ремонта судна неожиданно не хватает материалов.",
        "tracks_found":"У владения находят следы ночного незваного гостя.",
        "underworld_rumor":"В преступной среде обсуждают богатый дом и его охрану.",
        "second_attempt":"Тот, кто интересовался владением, возможно, готовится попробовать снова."
    }
    return {"id":step,"type":"scenario_chain","chain":kind,"day":day,"text":str(texts.get(step,step)),"approach_npc_id":"","effects":{}}

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"chains":chains,"next_id":next_id}
func restore(data:Dictionary):
    var c=data.get("chains",[]);if typeof(c)==TYPE_ARRAY:chains=c
    next_id=int(data.get("next_id",next_id))
