extends RefCounted

var resources:={"food":160.0,"wood":90.0,"stone":70.0,"cloth":35.0,"medicine":18.0,"tools":22.0}
var prices:={"food":2.0,"wood":3.0,"stone":3.0,"cloth":5.0,"medicine":9.0,"tools":8.0}
var jobs:={"farmer":0,"fisher":0,"builder":0,"lumberjack":0,"miner":0,"artisan":0,"healer":0,"merchant":0,"guard":0,"unemployed":0}
var population:=0
var hunger_pressure:=0.0
var unrest:=5.0
var crime_pressure:=4.0
var prosperity:=45.0
var last_day:=-1
var events:Array=[]

func setup(npcs:Array):
    _count_jobs(npcs)

func tick(npcs:Array,ships:Array,day:int,hour:float)->Dictionary:
    if day==last_day or hour<5.5:return snapshot()
    last_day=day
    _count_jobs(npcs)
    _produce()
    _imports(ships)
    _consume()
    _update_prices()
    _social_pressure(npcs)
    return snapshot()

func _count_jobs(npcs:Array):
    for key in jobs.keys():jobs[key]=0
    population=0
    for n in npcs:
        if not bool(n.get("alive",true)):continue
        population+=1
        var role=str(n.get("role","")).to_lower()
        var job:="unemployed"
        if "рыбак" in role:job="fisher"
        elif "крест" in role or "фермер" in role:job="farmer"
        elif "стро" in role:job="builder"
        elif "лес" in role:job="lumberjack"
        elif "шах" in role or "камен" in role:job="miner"
        elif "кузне" in role or "ремес" in role:job="artisan"
        elif "лекар" in role or "целит" in role:job="healer"
        elif "торгов" in role:job="merchant"
        elif "страж" in role:job="guard"
        jobs[job]+=1

func _produce():
    resources["food"]+=float(jobs["farmer"])*8.0+float(jobs["fisher"])*5.0
    resources["wood"]+=float(jobs["lumberjack"])*7.0
    resources["stone"]+=float(jobs["miner"])*6.0
    resources["cloth"]+=float(jobs["artisan"])*2.0
    resources["tools"]+=minf(float(jobs["artisan"])*1.5,resources["wood"]*.05+resources["stone"]*.03)
    resources["medicine"]+=float(jobs["healer"])*0.8

func _imports(ships:Array):
    for ship in ships:
        if str(ship.get("status",""))!="docked":continue
        var cargo:Dictionary=ship.get("cargo",{})
        resources["food"]+=float(cargo.get("food",0))*0.7
        resources["wood"]+=float(cargo.get("wood",0))*0.5
        resources["cloth"]+=float(cargo.get("cloth",0))*0.5
        resources["medicine"]+=float(cargo.get("medicine",0))*0.5

func _consume():
    var need=float(population)*2.2
    resources["food"]=maxf(0.0,resources["food"]-need)
    hunger_pressure=clampf((need-resources["food"])/maxf(need,1.0)*100.0,0.0,100.0)

func _update_prices():
    var food_target=maxf(40.0,float(population)*8.0)
    prices["food"]=clampf(2.0*(food_target/maxf(resources["food"],8.0)),1.0,18.0)
    prices["wood"]=clampf(3.0*(80.0/maxf(resources["wood"],10.0)),1.5,15.0)
    prices["stone"]=clampf(3.0*(60.0/maxf(resources["stone"],10.0)),1.5,15.0)
    prices["tools"]=clampf(8.0*(20.0/maxf(resources["tools"],3.0)),4.0,35.0)

func _social_pressure(npcs:Array):
    var unemployment=float(jobs["unemployed"])/maxf(float(population),1.0)*100.0
    var guard_ratio=float(jobs["guard"])/maxf(float(population),1.0)*100.0
    unrest=clampf(hunger_pressure*.55+unemployment*.30-guard_ratio*.25,0.0,100.0)
    crime_pressure=clampf(hunger_pressure*.35+unemployment*.40+unrest*.25-guard_ratio*.45,0.0,100.0)
    prosperity=clampf(70.0-hunger_pressure*.5-unemployment*.25+float(jobs["merchant"])*2.0+float(jobs["artisan"])*2.0,0.0,100.0)
    if hunger_pressure>55:_log("На острове начинается нехватка еды. Люди становятся раздражительными.")
    if crime_pressure>60:_log("Голод и безработица толкают жителей к кражам и грабежам.")
    if jobs["builder"]==0:_log("На острове нет свободных строителей. Новое строительство остановлено.")

func can_build(kind:String)->Dictionary:
    var req={
        "hut":{"wood":25.0,"stone":5.0,"builders":1,"cost":25},
        "house":{"wood":55.0,"stone":35.0,"builders":2,"cost":90},
        "mansion":{"wood":120.0,"stone":110.0,"builders":4,"cost":350},
        "shop":{"wood":60.0,"stone":25.0,"builders":2,"cost":120}
    }
    if not req.has(kind):return {"ok":false,"reason":"Неизвестная постройка."}
    var r:Dictionary=req[kind]
    if int(jobs["builder"])<int(r["builders"]):return {"ok":false,"reason":"Недостаточно строителей на острове."}
    if resources["wood"]<float(r["wood"]):return {"ok":false,"reason":"Не хватает древесины."}
    if resources["stone"]<float(r["stone"]):return {"ok":false,"reason":"Не хватает камня."}
    return {"ok":true,"cost":r["cost"],"wood":r["wood"],"stone":r["stone"]}

func build(kind:String):
    var r=can_build(kind)
    if not bool(r.get("ok",false)):return r
    resources["wood"]-=float(r["wood"]);resources["stone"]-=float(r["stone"])
    _log("Строители начали проект: %s."%kind)
    return r

func _log(text:String):
    if events.is_empty() or str(events.back().get("text",""))!=text:events.append({"text":text})
    if events.size()>80:events.pop_front()

func snapshot()->Dictionary:
    return {"resources":resources,"prices":prices,"jobs":jobs,"population":population,"hunger_pressure":hunger_pressure,"unrest":unrest,"crime_pressure":crime_pressure,"prosperity":prosperity}
