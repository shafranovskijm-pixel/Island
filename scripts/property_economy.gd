extends RefCounted

var properties:Array=[]
var events:Array=[]
var last_day:=-1
var next_id:=1

func setup():
    if not properties.is_empty():return
    properties=[
        _property("farm","Старая ферма","crown",Vector2(260,620),3,2.0,{"food":18.0}),
        _property("lumberyard","Лесной двор","merchants",Vector2(1210,920),2,2.5,{"wood":14.0}),
        _property("quarry","Каменоломня","crown",Vector2(1210,300),2,3.0,{"stone":12.0}),
        _property("workshop","Мастерская","marek",Vector2(720,590),2,3.0,{"tools":4.0,"cloth":2.0}),
        _property("inn","Сломанный Маяк","ira",Vector2(1500,850),2,2.5,{}),
        _property("shop","Лавка Марека","marek",Vector2(650,520),1,2.0,{})
    ]

func _property(kind:String,name:String,owner:String,pos:Vector2,slots:int,wage:float,output:Dictionary)->Dictionary:
    var p={"id":"property_%d"%next_id,"kind":kind,"name":name,"owner":owner,"pos":pos,"worker_slots":slots,"workers":[],"wage":wage,"output":output,"condition":100.0,"profit":0.0,"active":true}
    next_id+=1
    return p

func tick(npcs:Array,production,day:int,hour:float):
    if day==last_day or hour<6.0:return
    last_day=day
    _assign_workers(npcs)
    for p in properties:
        if not bool(p.get("active",true)):continue
        var efficiency=_efficiency(p,npcs)
        var output:Dictionary=p.get("output",{})
        for resource in output.keys():production.resources[resource]+=float(output[resource])*efficiency
        var wage_bill=float(p.get("wage",0))*p["workers"].size()
        p["profit"]=maxf(0.0,_gross_value(output,production)*efficiency-wage_bill)
        p["condition"]=maxf(0.0,float(p["condition"])-0.2)
        if float(p["condition"])<30:_log("%s приходит в упадок и работает хуже."%p["name"])

func _assign_workers(npcs:Array):
    var assigned:Dictionary={}
    for p in properties:
        var keep:Array=[]
        for id in p["workers"]:
            if _alive(npcs,str(id)):keep.append(id);assigned[str(id)]=true
        p["workers"]=keep
    for p in properties:
        while p["workers"].size()<int(p["worker_slots"]):
            var idx=_best_worker(npcs,str(p["kind"]),assigned)
            if idx<0:break
            var id=str(npcs[idx]["id"]);p["workers"].append(id);assigned[id]=true
            npcs[idx]["employment_property"]=p["id"]

func _best_worker(npcs:Array,kind:String,assigned:Dictionary)->int:
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)) or assigned.has(str(n["id"])):continue
        var role=str(n.get("role","")).to_lower()
        if kind=="farm" and ("крест" in role or "фермер" in role):return i
        if kind=="lumberyard" and "лес" in role:return i
        if kind=="quarry" and ("камен" in role or "шах" in role):return i
        if kind=="workshop" and ("ремес" in role or "кузне" in role):return i
        if kind in ["inn","shop"] and ("торгов" in role or "тракт" in role):return i
    return -1

func _efficiency(p:Dictionary,npcs:Array)->float:
    var filled=float(p["workers"].size())/maxf(float(p["worker_slots"]),1.0)
    return clampf(filled*(float(p["condition"])/100.0),0.0,1.0)

func _gross_value(output:Dictionary,production)->float:
    var total:=0.0
    for resource in output.keys():total+=float(output[resource])*float(production.prices.get(resource,1.0))
    return total

func create_property(kind:String,name:String,owner:String,pos:Vector2)->Dictionary:
    var presets={
        "farm":[3,2.0,{"food":18.0}],"lumberyard":[2,2.5,{"wood":14.0}],"quarry":[2,3.0,{"stone":12.0}],
        "workshop":[2,3.0,{"tools":4.0,"cloth":2.0}],"shop":[1,2.0,{}],"mansion":[2,4.0,{}]
    }
    if not presets.has(kind):return {}
    var d=presets[kind];var p=_property(kind,name,owner,pos,int(d[0]),float(d[1]),d[2]);properties.append(p);_log("Появилось новое владение: %s."%name);return p

func ownership_summary(owner:String)->Array:
    var out:Array=[]
    for p in properties:
        if str(p["owner"])==owner:out.append(p)
    return out

func _alive(npcs:Array,id:String)->bool:
    for n in npcs:
        if str(n.get("id",""))==id:return bool(n.get("alive",true))
    return false

func _log(text:String):
    events.append({"text":text})
    if events.size()>80:events.pop_front()
