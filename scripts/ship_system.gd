extends RefCounted

var rng:=RandomNumberGenerator.new()
var events:Array=[]
var ships:Array=[]
var next_arrival_day:=2
var next_arrival_hour:=9.0
var serial:=0

func setup():
    rng.randomize()

func tick(day:int,hour:float,delta:float) -> Array:
    if day>next_arrival_day or (day==next_arrival_day and hour>=next_arrival_hour):
        _arrive(day,hour)
        next_arrival_day=day+rng.randi_range(1,3)
        next_arrival_hour=rng.randf_range(7.0,19.0)
    for i in range(ships.size()-1,-1,-1):
        var ship=ships[i]
        if ship["status"]=="docked":
            ship["remaining"]-=delta*0.10
            if float(ship["remaining"])<=0.0:
                _log(day,hour,"Корабль «%s» покинул остров."%ship["name"])
                ships.remove_at(i)
                continue
            ships[i]=ship
    return ships

func _arrive(day:int,hour:float):
    serial+=1
    var kinds=["merchant","fishing","pirate","naval","mysterious"]
    var kind:String=kinds[rng.randi_range(0,kinds.size()-1)]
    var prefixes={"merchant":"Золотой","fishing":"Солёный","pirate":"Чёрный","naval":"Королевский","mysterious":"Тихий"}
    var nouns=["Чайка","Кит","Маяк","Ворон","Шторм","Лис"]
    var ship={
        "id":"ship_%d"%serial,
        "name":"%s %s"%[prefixes[kind],nouns[rng.randi_range(0,nouns.size()-1)]],
        "kind":kind,"status":"docked","remaining":rng.randf_range(12.0,36.0),
        "crew":rng.randi_range(4,18),"vacancies":rng.randi_range(0,2),
        "passage_price":rng.randi_range(6,18),"security":rng.randi_range(1,5),
        "cargo":_cargo(kind)
    }
    ships.append(ship)
    _log(day,hour,"В порт прибыл %s корабль «%s»."%[_kind_ru(kind),ship["name"]])

func _cargo(kind:String) -> Dictionary:
    match kind:
        "merchant": return {"food":8,"cloth":5,"ale":4}
        "fishing": return {"fish":12,"rope":2}
        "pirate": return {"ale":8,"rope":4}
        "naval": return {"food":5,"rope":3}
        "mysterious": return {"cloth":1}
    return {}

func escape_options(ship:Dictionary, skills:Dictionary, coins:int, relations:Dictionary={}) -> Array:
    var out:Array=[]
    out.append({"id":"ticket","label":"Купить место","available":coins>=int(ship["passage_price"]),"reason":"нужно %d монет"%ship["passage_price"]})
    out.append({"id":"crew","label":"Устроиться матросом","available":int(ship["vacancies"])>0 and int(skills.get("sailing",0))>=2,"reason":"нужны море 2 и вакансия"})
    out.append({"id":"stowaway","label":"Пробраться в трюм","available":int(skills.get("stealth",0))>=int(ship["security"]),"reason":"скрытность против охраны"})
    out.append({"id":"criminal","label":"Уйти с контрабандистами","available":ship["kind"]=="pirate" and int(skills.get("theft",0))>=2,"reason":"нужны преступные навыки"})
    out.append({"id":"magic","label":"Использовать странный знак","available":ship["kind"]=="mysterious" and int(skills.get("magic",0))>=2,"reason":"магия 2"})
    return out

func create_vacancy(day:int,hour:float,reason:String):
    if ships.is_empty(): return
    ships[0]["vacancies"]=int(ships[0]["vacancies"])+1
    _log(day,hour,"На «%s» появилась вакансия: %s."%[ships[0]["name"],reason])

func _kind_ru(kind:String)->String:
    match kind:
        "merchant": return "торговый"
        "fishing": return "рыбацкий"
        "pirate": return "пиратский"
        "naval": return "военный"
        "mysterious": return "странный"
    return kind

func _log(day:int,hour:float,text:String):
    if events.size()>100: events.pop_front()
    events.append({"day":day,"hour":hour,"text":text})
