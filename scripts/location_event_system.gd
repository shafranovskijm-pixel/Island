extends RefCounted

var events:Array=[]
var last_event_day:Dictionary={}

func tick(npcs:Array,locations,day:int,hour:float,world_state:Dictionary)->Array:
    if hour>=18.0 and hour<19.0:
        _maybe_royal_feast(npcs,locations,day,hour,world_state)
    if hour>=21.0 and hour<22.0:
        _maybe_occult_ritual(npcs,locations,day,hour,world_state)
    if hour>=10.0 and hour<11.0:
        _maybe_funeral(npcs,locations,day,hour,world_state)
    return npcs

func _once(key:String,day:int)->bool:
    if int(last_event_day.get(key,-999))==day:return false
    last_event_day[key]=day
    return true

func _maybe_royal_feast(npcs:Array,locations,day:int,hour:float,state:Dictionary):
    if day%5!=0 or not _once("royal_feast",day):return
    var center:Vector2=locations.locations["castle"]["center"]
    for i in npcs.size():
        var faction=str(npcs[i].get("faction",""))
        if faction in ["crown","merchants"] or int(npcs[i].get("influence",0))>=55:
            npcs[i]["target"]=center+Vector2((i%4)*18-30,(i%3)*16-20)
    events.append({"day":day,"hour":hour,"type":"royal_feast","text":"В замке начался королевский пир. Влиятельные жители стекаются ко двору."})

func _maybe_occult_ritual(npcs:Array,locations,day:int,hour:float,state:Dictionary):
    if day%3!=0 or not _once("occult_ritual",day):return
    var center:Vector2=locations.locations["occult_lodge"]["center"]
    for i in npcs.size():
        if str(npcs[i].get("faction",""))=="occult":
            npcs[i]["target"]=center+Vector2((i%3)*14-14,(i%2)*14)
    events.append({"day":day,"hour":hour,"type":"ritual","text":"Ночью члены Пепельной Луны собираются в тайном доме."})

func _maybe_funeral(npcs:Array,locations,day:int,hour:float,state:Dictionary):
    var dead_name=str(state.get("recent_dead_name",""))
    if dead_name=="" or not _once("funeral_"+dead_name,day):return
    var center:Vector2=locations.locations["graveyard"]["center"]
    for i in npcs.size():
        if bool(npcs[i].get("alive",true)) and float(npcs[i].get("traits",{}).get("sociability",0))>0.35:
            npcs[i]["target"]=center+Vector2((i%5)*15-30,(i%3)*14-14)
    events.append({"day":day,"hour":hour,"type":"funeral","text":"На Старом кладбище хоронят %s. Жители приходят проститься."%dead_name})

func arrest(npcs:Array,npc_id:String,locations,day:int,hour:float)->Array:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==npc_id:
            npcs[i]["arrested"]=true
            npcs[i]["target"]=locations.locations["guard_barracks"]["center"]
            events.append({"day":day,"hour":hour,"type":"arrest","text":"%s арестован и отправлен в казармы стражи."%npcs[i]["name"]})
            break
    return npcs
