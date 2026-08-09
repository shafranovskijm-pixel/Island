extends RefCounted

var factions := {
    "crown":{"name":"Корона","power":70.0,"aggression":0.35,"wealth":80.0,"targets":["castle","port"]},
    "guard":{"name":"Стража","power":58.0,"aggression":0.55,"wealth":48.0,"targets":["guard_barracks","port","slums"]},
    "temple":{"name":"Храм Рассвета","power":52.0,"aggression":0.45,"wealth":55.0,"targets":["temple","graveyard","occult_lodge"]},
    "occult":{"name":"Орден Пепельной Луны","power":44.0,"aggression":0.50,"wealth":32.0,"targets":["crypt","occult_lodge","graveyard"]},
    "underworld":{"name":"Преступный мир","power":49.0,"aggression":0.62,"wealth":51.0,"targets":["slums","port","market"]},
    "merchants":{"name":"Гильдия торговцев","power":57.0,"aggression":0.22,"wealth":88.0,"targets":["market","port"]}
}

var relations := {}
var incidents:Array=[]
var rng:=RandomNumberGenerator.new()
var next_tick_day:=1
var next_tick_hour:=18.0

func setup():
    rng.randomize()
    for a in factions.keys():
        relations[a]={}
        for b in factions.keys():
            if a==b: continue
            relations[a][b]=rng.randf_range(-25.0,20.0)
    relations["temple"]["occult"]=-70.0;relations["occult"]["temple"]=-70.0
    relations["guard"]["underworld"]=-60.0;relations["underworld"]["guard"]=-60.0
    relations["crown"]["guard"]=45.0;relations["guard"]["crown"]=45.0
    relations["merchants"]["underworld"]=-15.0;relations["underworld"]["merchants"]=-10.0

func tick(npcs:Array,location_control:Dictionary,day:int,hour:float)->Dictionary:
    if day<next_tick_day or (day==next_tick_day and hour<next_tick_hour):
        return {"npcs":npcs,"control":location_control,"events":[]}
    next_tick_day=day+1;next_tick_hour=rng.randf_range(17.0,23.0)
    var out_events:Array=[]
    _decay_relations()
    var conflict=_choose_conflict()
    if conflict.is_empty(): return {"npcs":npcs,"control":location_control,"events":out_events}
    var attacker:String=conflict[0];var defender:String=conflict[1]
    var target:=_choose_target(attacker,defender,location_control)
    if target=="": return {"npcs":npcs,"control":location_control,"events":out_events}
    var result:=_resolve(attacker,defender,target,npcs,location_control,day,hour)
    npcs=result["npcs"];location_control=result["control"];out_events.append(result["event"])
    incidents.append(result["event"])
    return {"npcs":npcs,"control":location_control,"events":out_events}

func _decay_relations():
    for a in relations.keys():
        for b in relations[a].keys():
            relations[a][b]=lerpf(float(relations[a][b]),0.0,0.025)

func _choose_conflict()->Array:
    var candidates:Array=[]
    for a in factions.keys():
        for b in factions.keys():
            if a==b: continue
            var hostility=-float(relations[a][b])
            var aggression=float(factions[a]["aggression"])*100.0
            var score=hostility+aggression+rng.randf_range(-20,20)
            if score>65.0:candidates.append({"a":a,"b":b,"score":score})
    if candidates.is_empty(): return []
    candidates.sort_custom(func(x,y): return float(x["score"])>float(y["score"]))
    return [candidates[0]["a"],candidates[0]["b"]]

func _choose_target(attacker:String,defender:String,control:Dictionary)->String:
    var options:Array=[]
    for loc in factions[attacker]["targets"]:
        if str(control.get(loc,""))==defender: options.append(loc)
    if options.is_empty():
        for loc in factions[attacker]["targets"]:
            if control.has(loc) and str(control[loc])!=attacker: options.append(loc)
    if options.is_empty(): return ""
    return str(options[rng.randi_range(0,options.size()-1)])

func _resolve(attacker:String,defender:String,target:String,npcs:Array,control:Dictionary,day:int,hour:float)->Dictionary:
    var attack=float(factions[attacker]["power"])+float(factions[attacker]["wealth"])*0.22+rng.randf_range(-20,20)
    var defense=float(factions[defender]["power"])+float(factions[defender]["wealth"])*0.18+rng.randf_range(-20,20)
    var winner:=attacker if attack>defense else defender
    var loser:=defender if winner==attacker else attacker
    if winner==attacker: control[target]=attacker
    relations[attacker][defender]=maxf(-100.0,float(relations[attacker][defender])-12.0)
    relations[defender][attacker]=maxf(-100.0,float(relations[defender][attacker])-15.0)
    for i in npcs.size():
        var n=npcs[i]
        if str(n.get("faction",""))==winner: n["influence"]=int(n.get("influence",0))+1
        if str(n.get("faction",""))==loser:
            n["stress"]=float(n.get("stress",0))+12.0
            if rng.randf()<0.12: n["injured"]=true
        npcs[i]=n
    var text="%s и %s столкнулись за %s. Победитель: %s."%[factions[attacker]["name"],factions[defender]["name"],target,factions[winner]["name"]]
    return {"npcs":npcs,"control":control,"event":{"day":day,"hour":hour,"type":"faction_conflict","attacker":attacker,"defender":defender,"target":target,"winner":winner,"text":text}}

func add_pressure(source:String,target:String,amount:float):
    if relations.has(source) and relations[source].has(target):
        relations[source][target]=clampf(float(relations[source][target])-amount,-100.0,100.0)

func tension(a:String,b:String)->float:
    if relations.has(a) and relations[a].has(b):
        return clampf(-float(relations[a][b]),0.0,100.0)
    return 0.0

func serialize()->Dictionary:
    return {"factions":factions,"relations":relations,"next_tick_day":next_tick_day,"next_tick_hour":next_tick_hour}

func restore(data:Dictionary):
    if typeof(data.get("relations",{}))==TYPE_DICTIONARY: relations=data["relations"]
    next_tick_day=int(data.get("next_tick_day",next_tick_day));next_tick_hour=float(data.get("next_tick_hour",next_tick_hour))
