extends RefCounted

var cases:Array=[]
var next_id:=1
var events:Array=[]

func report_crime(kind:String,pos:Vector2,victim_id:String,suspect_id:String,day:int,hour:float,evidence:Array=[])->Dictionary:
    var c={"id":"case_%d"%next_id,"kind":kind,"pos":pos,"victim_id":victim_id,"suspects":{},"witnesses":[],"evidence":evidence.duplicate(true),"status":"open","day":day,"hour":hour,"heat":0.0,"assigned_guard":""}
    next_id+=1
    if suspect_id!="":c["suspects"][suspect_id]=1.0
    cases.append(c);events.append({"type":"crime_report","text":"Зафиксировано преступление: %s."%kind,"case_id":c["id"]});return c

func add_witness(case_id:String,npc:Dictionary,saw_suspect:String,confidence:float=.7):
    var i=_idx(case_id);if i<0:return
    var testimony={"npc_id":npc.get("id",""),"suspect_id":saw_suspect,"confidence":confidence,"reliability":clampf(1.0-float(npc.get("stress",0))/160.0,.25,1.0)}
    cases[i]["witnesses"].append(testimony)
    if saw_suspect!="":cases[i]["suspects"][saw_suspect]=float(cases[i]["suspects"].get(saw_suspect,0))+confidence*float(testimony["reliability"])

func add_evidence(case_id:String,evidence:Dictionary):
    var i=_idx(case_id);if i<0:return
    cases[i]["evidence"].append(evidence)
    var suspect=str(evidence.get("suspect_id",evidence.get("actor","")))
    if suspect!="":cases[i]["suspects"][suspect]=float(cases[i]["suspects"].get(suspect,0))+float(evidence.get("weight",.6))

func scan_scene(case_id:String,physical_objects:Array,corpses:Array,npcs:Array):
    var i=_idx(case_id);if i<0:return
    var c=cases[i];var pos:Vector2=c["pos"]
    for o in physical_objects:
        if pos.distance_to(o.get("pos",Vector2.ZERO))>130:continue
        for e in o.get("evidence",[]):
            var ev=e.duplicate(true);ev["source_object"]=o.get("id","");ev["weight"]=.75;add_evidence(case_id,ev)
    for corpse in corpses:
        if pos.distance_to(corpse.get("pos",Vector2.ZERO))<=130:add_evidence(case_id,{"type":"body","victim":corpse.get("person_id",corpse.get("id","")),"weight":.4})
    for n in npcs:
        if pos.distance_to(n.get("pos",Vector2.ZERO))<=160:
            for m in n.get("memory",[]):
                if str(m.get("type",""))=="attacked_by_player":add_witness(case_id,n,"player",.85)
    cases[i]["heat"]=minf(100,float(cases[i].get("heat",0))+8)

func assign_guard(case_id:String,npcs:Array)->Dictionary:
    var i=_idx(case_id);if i<0:return {}
    for n in npcs:
        var role=str(n.get("role","")).to_lower()
        if ("guard" in role or "страж" in role) and bool(n.get("alive",true)):
            cases[i]["assigned_guard"]=str(n.get("id",""));n["target"]=cases[i]["pos"];events.append({"type":"investigation","text":"%s отправлен осмотреть место преступления."%n.get("name","Стражник")});return n
    return {}

func tick(npcs:Array,day:int,hour:float):
    for i in cases.size():
        var c=cases[i];if str(c.get("status",""))!="open":continue
        c["heat"]=maxf(0,float(c.get("heat",0))-.08)
        if str(c.get("assigned_guard",""))=="" and randf()<.04:assign_guard(str(c["id"]),npcs)
        var best_id="";var best=0.0
        for sid in c["suspects"].keys():
            var score=float(c["suspects"][sid])
            if score>best:best=score;best_id=str(sid)
        if best>=2.1:
            c["status"]="suspect_identified";c["primary_suspect"]=best_id;events.append({"type":"suspect_identified","text":"Следствие определило главного подозреваемого.","suspect_id":best_id,"case_id":c["id"]})
        elif day-int(c.get("day",day))>12 and best<.8:
            c["status"]="cold";events.append({"type":"cold_case","text":"Расследование зашло в тупик."})
        cases[i]=c

func open_cases()->Array:
    var out:Array=[]
    for c in cases:
        if str(c.get("status","")) in ["open","suspect_identified"]:out.append(c)
    return out

func _idx(id:String)->int:
    for i in cases.size():
        if str(cases[i].get("id",""))==id:return i
    return -1
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"cases":cases,"next_id":next_id}
func restore(data:Dictionary):
    var c=data.get("cases",[]);if typeof(c)==TYPE_ARRAY:cases=c
    next_id=int(data.get("next_id",next_id))
