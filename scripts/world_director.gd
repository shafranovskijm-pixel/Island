extends RefCounted

var rng:=RandomNumberGenerator.new()
var events:Array=[]
var tension:=15.0
var last_event_day:=0

func setup():
    rng.randomize()

func tick(day:int,hour:float,npcs:Array,economy,ships,social,delta:float) -> Dictionary:
    tension=clampf(tension+delta*0.02,0.0,100.0)
    if day==last_event_day:
        return {"npcs":npcs}
    if hour<10.0 or hour>18.0:
        return {"npcs":npcs}
    var chance:=0.003+float(tension)*0.00008
    if rng.randf()>chance*delta*60.0:
        return {"npcs":npcs}
    last_event_day=day
    var options=["storm","shortage","festival","fight","fire","arrest","discovery"]
    var event:String=options[rng.randi_range(0,options.size()-1)]
    match event:
        "storm":
            tension=maxf(0.0,tension-4.0)
            _log(day,hour,"Шторм задержал суда и испортил часть запасов.")
            economy.consume("food",4,day,hour)
            economy.consume("fish",3,day,hour)
        "shortage":
            tension+=6.0
            economy.consume("food",6,day,hour)
            _log(day,hour,"На рынке начался дефицит еды.")
        "festival":
            tension=maxf(0.0,tension-12.0)
            economy.consume("ale",4,day,hour)
            for i in npcs.size():
                npcs[i]["stress"]=maxf(0.0,float(npcs[i].get("stress",0))-8.0)
            _log(day,hour,"На площади начался стихийный праздник.")
        "fight":
            tension+=8.0
            var pair=_pick_pair(npcs)
            if pair.size()==2:
                var a:int=pair[0];var b:int=pair[1]
                npcs[a]["stress"]+=12.0;npcs[b]["stress"]+=12.0
                social.alter_relation(npcs,npcs[a]["id"],npcs[b]["id"],"resentment",12.0)
                social.alter_relation(npcs,npcs[b]["id"],npcs[a]["id"],"resentment",12.0)
                _log(day,hour,"%s и %s подрались."%[npcs[a]["name"],npcs[b]["name"]])
                if rng.randf()<0.45:
                    ships.create_vacancy(day,hour,"один из матросов оказался под арестом после драки")
        "fire":
            tension+=10.0
            economy.consume("cloth",2,day,hour)
            economy.consume("food",2,day,hour)
            _log(day,hour,"На складе вспыхнул пожар. Часть товаров уничтожена.")
        "arrest":
            var criminal=_pick_high_stress(npcs)
            if criminal>=0:
                npcs[criminal]["stress"]+=18.0
                _log(day,hour,"Стража задержала %s после жалоб жителей."%npcs[criminal]["name"])
                ships.create_vacancy(day,hour,"задержание сорвало выход одного члена команды")
        "discovery":
            tension=maxf(0.0,tension-3.0)
            _log(day,hour,"В джунглях нашли странные древние следы. По острову пошли слухи.")
    return {"npcs":npcs,"event":event}

func _pick_pair(npcs:Array)->Array:
    if npcs.size()<2:return []
    var a:=rng.randi_range(0,npcs.size()-1)
    var b:=rng.randi_range(0,npcs.size()-1)
    var guard:=0
    while b==a and guard<10:
        b=rng.randi_range(0,npcs.size()-1);guard+=1
    if a==b:return []
    return [a,b]

func _pick_high_stress(npcs:Array)->int:
    var best:=-1;var score:=55.0
    for i in npcs.size():
        var s=float(npcs[i].get("stress",0))
        if s>score:score=s;best=i
    return best

func _log(day:int,hour:float,text:String):
    if events.size()>100:events.pop_front()
    events.append({"day":day,"hour":hour,"text":text})
