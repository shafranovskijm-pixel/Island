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
    var p={
        "id":"property_%d"%next_id,"kind":kind,"name":name,"owner":owner,"pos":pos,
        "worker_slots":slots,"workers":[],"wage":wage,"output":output,"condition":100.0,
        "profit":0.0,"cash":35.0,"active":true,"maintenance_due":0.0,"days_unpaid":0,
        "tool_efficiency":1.0
    }
    next_id+=1
    return p

func tick(npcs:Array,production,day:int,hour:float):
    if day==last_day or hour<6.0:return
    last_day=day
    _assign_workers(npcs)
    for p in properties:
        if not bool(p.get("active",true)):continue
        _operate_property(p,npcs,production)

func _operate_property(p:Dictionary,npcs:Array,production):
    var efficiency=_efficiency(p,npcs,production)
    var output:Dictionary=p.get("output",{})
    for resource in output.keys():production.resources[resource]=float(production.resources.get(resource,0.0))+float(output[resource])*efficiency

    var wage_bill=float(p.get("wage",0))*p["workers"].size()
    var gross=_gross_value(output,production)*efficiency
    if str(p["kind"]) in ["inn","shop"]:gross+=6.0+float(p["workers"].size())*2.0
    p["cash"]=float(p.get("cash",0))+gross

    var paid=_pay_workers(p,npcs,wage_bill)
    var maintenance=maxf(0.5,float(p["worker_slots"])*0.35)
    p["maintenance_due"]=maintenance
    if float(p["cash"])>=maintenance:
        p["cash"]-=maintenance;p["condition"]=minf(100.0,float(p["condition"])+0.15)
    else:p["condition"]=maxf(0.0,float(p["condition"])-1.1)

    p["profit"]=maxf(0.0,gross-paid-maintenance)
    _pay_owner(p,npcs,float(p["profit"])*0.55)

    if float(p.get("tool_efficiency",1.0))<0.6 and str(p["kind"]) in ["farm","lumberyard","quarry","workshop"]:
        _log("%s теряет производительность из-за нехватки исправных инструментов."%p["name"])
    if float(p["condition"])<30:_log("%s приходит в упадок и работает хуже."%p["name"])
    if float(p["condition"])<=5:
        p["active"]=false;_log("%s остановлено: здание почти разрушено."%p["name"])

func _pay_workers(p:Dictionary,npcs:Array,total:float)->float:
    if p["workers"].is_empty():return 0.0
    var each=float(p.get("wage",0));var paid:=0.0
    for id in p["workers"]:
        if float(p["cash"])<each:break
        var idx=_npc_index(npcs,str(id));if idx<0:continue
        p["cash"]-=each;npcs[idx]["money"]=int(npcs[idx].get("money",0))+int(round(each));npcs[idx]["stress"]=maxf(0.0,float(npcs[idx].get("stress",0))-1.5);paid+=each
    if paid+0.01<total:
        p["days_unpaid"]=int(p.get("days_unpaid",0))+1
        for id in p["workers"]:
            var idx=_npc_index(npcs,str(id));if idx>=0:npcs[idx]["stress"]=minf(100.0,float(npcs[idx].get("stress",0))+5.0)
        _log("На %s задерживают зарплату."%p["name"])
    else:p["days_unpaid"]=0
    return paid

func _pay_owner(p:Dictionary,npcs:Array,amount:float):
    if amount<=0:return
    var owner=str(p.get("owner",""));var idx=_npc_index(npcs,owner)
    if idx>=0:
        npcs[idx]["money"]=int(npcs[idx].get("money",0))+int(round(amount));npcs[idx]["influence"]=int(npcs[idx].get("influence",0))+int(amount/30.0)

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
            var id=str(npcs[idx]["id"]);p["workers"].append(id);assigned[id]=true;npcs[idx]["employment_property"]=p["id"]

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
        if kind=="mansion" and "стро" in role:return i
    return -1

func _efficiency(p:Dictionary,npcs:Array,production)->float:
    var filled=float(p["workers"].size())/maxf(float(p["worker_slots"]),1.0)
    var condition=float(p["condition"])/100.0
    var worker_tools=_worker_tool_efficiency(p,npcs)
    p["tool_efficiency"]=worker_tools
    var public_tools_factor:=1.0
    if str(p["kind"]) in ["farm","lumberyard","quarry","workshop"]:
        public_tools_factor=clampf(float(production.resources.get("tools",0))/6.0,0.35,1.0)
        production.resources["tools"]=maxf(0.0,float(production.resources.get("tools",0))-0.08*filled)
    return clampf(filled*condition*worker_tools*public_tools_factor,0.0,1.0)

func _worker_tool_efficiency(p:Dictionary,npcs:Array)->float:
    if p["workers"].is_empty():return 0.0
    var total:=0.0;var count:=0
    for id in p["workers"]:
        var idx=_npc_index(npcs,str(id));if idx<0:continue
        total+=float(npcs[idx].get("work_tool_factor",1.0));count+=1
    return 1.0 if count==0 else clampf(total/count,0.15,1.0)

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

func repair_property(property_id:String,production)->Dictionary:
    for p in properties:
        if str(p["id"])!=property_id:continue
        if production.resources["wood"]<8 or production.resources["stone"]<4:return {"ok":false,"reason":"Не хватает материалов для ремонта."}
        if int(production.jobs["builder"])<1:return {"ok":false,"reason":"Нет доступных строителей."}
        production.resources["wood"]-=8;production.resources["stone"]-=4;p["condition"]=minf(100,float(p["condition"])+30);p["active"]=true
        _log("%s отремонтировано."%p["name"]);return {"ok":true}
    return {"ok":false,"reason":"Владение не найдено."}

func ownership_summary(owner:String)->Array:
    var out:Array=[]
    for p in properties:
        if str(p["owner"])==owner:out.append(p)
    return out

func _alive(npcs:Array,id:String)->bool:
    var idx=_npc_index(npcs,id);return idx>=0 and bool(npcs[idx].get("alive",true))

func _npc_index(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1

func _log(text:String):
    events.append({"text":text})
    if events.size()>80:events.pop_front()
