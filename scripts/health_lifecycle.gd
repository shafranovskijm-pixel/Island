extends RefCounted

var events:Array=[]
var last_day:=-1

func tick(npcs:Array,production,day:int,hour:float)->Array:
    if day==last_day or hour<6.5:return npcs
    last_day=day
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)):continue
        var age=float(n.get("age_days",0))+1.0;n["age_days"]=age
        var health=float(n.get("health",100.0));var stress=float(n.get("stress",0));var homeless=bool(n.get("homeless",false))
        var hunger=float(production.hunger_pressure)
        health-=stress*.004+hunger*.006+(0.18 if homeless else 0.0)
        if bool(n.get("injured",false)):health-=0.45
        if bool(n.get("sick",false)):health-=0.55
        if not bool(n.get("sick",false)) and randf()<(0.002+hunger*.00025+(0.004 if homeless else 0.0)):
            n["sick"]=true;events.append({"day":day,"hour":hour,"type":"illness","text":"%s заболел."%n["name"]})
        if bool(n.get("sick",false)) and production.resources.get("medicine",0)>0 and randf()<0.20:
            production.resources["medicine"]=maxf(0,float(production.resources["medicine"])-1);n["sick"]=false;health=minf(100,health+10);events.append({"day":day,"hour":hour,"type":"recovery","text":"%s получил лечение и пошёл на поправку."%n["name"]})
        n["health"]=clampf(health,0,100)
        if health<=0:
            n["alive"]=false;events.append({"day":day,"hour":hour,"type":"death","npc_id":str(n["id"]),"text":"%s умер после ухудшения здоровья."%n["name"]})
        npcs[i]=n
    return npcs

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
