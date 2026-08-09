extends RefCounted

var opportunities:Array=[]
var last_seed_day:=-1
var rng:=RandomNumberGenerator.new()

func _init():
    rng.randomize()

func tick(npcs:Array,world:Dictionary,day:int,hour:float)->Array:
    if day!=last_seed_day and hour>=8.0:
        last_seed_day=day
        _seed_opportunity(npcs,world,day,hour)
    _refresh_states(npcs,world,day,hour)
    return opportunities

func _seed_opportunity(npcs:Array,world:Dictionary,day:int,hour:float):
    var candidates:Array=[]
    if bool(world.get("crypt_known",false))==false:
        candidates.append({"kind":"rumor","topic":"graveyard_whispers","source_role":"могильщик","location":"graveyard","hint":"Ночью на кладбище кто-то слышал шаги под землёй."})
    if int(world.get("food_scarcity",0))>45:
        candidates.append({"kind":"job","topic":"food_shortage","source_role":"торговец","location":"market","hint":"Торговцам срочно нужны люди для разгрузки продовольствия и поиска поставщиков."})
    if int(world.get("crime_pressure",0))>50:
        candidates.append({"kind":"rumor","topic":"guard_weakness","source_role":"стражник","location":"guard_barracks","hint":"Стража перегружена. Ночные обходы стали короче."})
    if int(world.get("occult_tension",0))>35:
        candidates.append({"kind":"secret","topic":"occult_contact","source_role":"контрабандистка","location":"slums","hint":"Сайра знает человека, который покупает запрещённые реликвии."})
    if int(world.get("court_tension",0))>35:
        candidates.append({"kind":"politics","topic":"court_intrigue","source_role":"канцлер","location":"castle","hint":"При дворе ищут человека, которому можно поручить дело без официальной печати."})
    if candidates.is_empty():return
    var chosen:Dictionary=candidates[rng.randi_range(0,candidates.size()-1)]
    var source=_find_source(npcs,str(chosen["source_role"]))
    if source=="":return
    chosen["id"]="opp_%d_%d"%[day,opportunities.size()+1]
    chosen["source_npc"]=source
    chosen["created_day"]=day
    chosen["created_hour"]=hour
    chosen["heard_by_player"]=false
    chosen["resolved"]=false
    opportunities.append(chosen)

func _find_source(npcs:Array,role_hint:String)->String:
    var low=role_hint.to_lower()
    for n in npcs:
        if not bool(n.get("alive",true)):continue
        if low in str(n.get("role","")).to_lower():return str(n.get("id",""))
    return ""

func _refresh_states(npcs:Array,world:Dictionary,day:int,hour:float):
    for i in opportunities.size():
        var o=opportunities[i]
        if bool(o.get("resolved",false)):continue
        if day-int(o.get("created_day",day))>7:
            o["resolved"]=true
            o["expired"]=true
        opportunities[i]=o

func npc_hint(npc_id:String,player_location:String)->Dictionary:
    for i in opportunities.size():
        var o=opportunities[i]
        if bool(o.get("resolved",false)) or bool(o.get("heard_by_player",false)):continue
        if str(o.get("source_npc",""))!=npc_id:continue
        # The player must physically meet the source NPC. No remote quest delivery.
        o["heard_by_player"]=true
        opportunities[i]=o
        return o
    return {}

func mark_resolved(topic:String):
    for i in opportunities.size():
        if str(opportunities[i].get("topic",""))==topic:
            opportunities[i]["resolved"]=true

func visible_to_player()->Array:
    # Intentionally returns only already-heard facts, never hidden GM opportunities.
    var out:Array=[]
    for o in opportunities:
        if bool(o.get("heard_by_player",false)) and not bool(o.get("resolved",false)):
            out.append({"topic":o.get("topic",""),"hint":o.get("hint",""),"location":o.get("location","")})
    return out
