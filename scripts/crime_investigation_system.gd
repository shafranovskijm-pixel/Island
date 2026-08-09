extends RefCounted

var cases:Array=[]
var next_id:=1
var events:Array=[]
var last_report_slot:=-1

func report_crime(kind:String,pos:Vector2,victim_id:String,suspect_id:String,day:int,hour:float,evidence:Array=[])->Dictionary:
    var merge_i=_merge_case_index(kind,victim_id,day,hour)
    if merge_i>=0:
        var existing:Dictionary=cases[merge_i]
        if suspect_id!="":existing["suspects"][suspect_id]=float(existing["suspects"].get(suspect_id,0))+0.35
        cases[merge_i]=existing
        for ev in evidence:add_evidence(str(existing["id"]),ev)
        events.append({"type":"crime_updated","text":"Появились новые обстоятельства уже известного происшествия.","case_id":existing["id"]})
        return cases[merge_i]
    var c={"id":"case_%d"%next_id,"kind":kind,"pos":pos,"victim_id":victim_id,"suspects":{},"witnesses":[],"evidence":[],"status":"open","reported":false,"scene_scanned":false,"day":day,"hour":hour,"heat":0.0,"assigned_guard":""}
    next_id+=1
    if suspect_id!="":c["suspects"][suspect_id]=0.45
    cases.append(c)
    for ev in evidence:add_evidence(str(c["id"]),ev)
    events.append({"type":"crime_incident","text":"Произошло преступление, о котором мир пока может не знать.","case_id":c["id"]})
    return cases.back()

func add_witness(case_id:String,npc:Dictionary,saw_suspect:String,confidence:float=.7):
    var i=_idx(case_id);if i<0:return
    var npc_id=str(npc.get("id",""));var reliability=clampf(1.0-float(npc.get("stress",0))/160.0,.25,1.0)
    for wi in cases[i]["witnesses"].size():
        var w:Dictionary=cases[i]["witnesses"][wi]
        if str(w.get("npc_id",""))==npc_id and str(w.get("suspect_id",""))==saw_suspect:
            w["confidence"]=maxf(float(w.get("confidence",0)),confidence);w["reliability"]=maxf(float(w.get("reliability",0)),reliability);cases[i]["witnesses"][wi]=w;return
    var testimony={"npc_id":npc_id,"suspect_id":saw_suspect,"confidence":confidence,"reliability":reliability,"reported":false}
    cases[i]["witnesses"].append(testimony)
    if saw_suspect!="":cases[i]["suspects"][saw_suspect]=float(cases[i]["suspects"].get(saw_suspect,0))+confidence*reliability*.35

func add_evidence(case_id:String,evidence:Dictionary):
    var i=_idx(case_id);if i<0:return
    var key=_evidence_key(evidence)
    for existing in cases[i]["evidence"]:
        if _evidence_key(existing)==key:return
    cases[i]["evidence"].append(evidence.duplicate(true))
    var suspect=str(evidence.get("suspect_id",evidence.get("actor","")))
    if suspect!="":cases[i]["suspects"][suspect]=float(cases[i]["suspects"].get(suspect,0))+float(evidence.get("weight",.6))

func report_case(case_id:String,witness_id:String=""):
    var i=_idx(case_id);if i<0:return
    if bool(cases[i].get("reported",false)):return
    cases[i]["reported"]=true;cases[i]["heat"]=maxf(8.0,float(cases[i].get("heat",0)))
    if witness_id!="":
        for wi in cases[i]["witnesses"].size():
            if str(cases[i]["witnesses"][wi].get("npc_id",""))==witness_id:cases[i]["witnesses"][wi]["reported"]=true
    events.append({"type":"witness_report","text":"Сведения о преступлении дошли до стражи.","case_id":case_id,"npc_id":witness_id})

func scan_scene(case_id:String,physical_objects:Array,corpses:Array,npcs:Array):
    var i=_idx(case_id);if i<0:return
    var c:Dictionary=cases[i];var pos:Vector2=c["pos"]
    for o in physical_objects:
        if pos.distance_to(o.get("pos",Vector2.ZERO))>130:continue
        for e in o.get("evidence",[]):
            var ev=e.duplicate(true);ev["source_object"]=o.get("id","");ev["weight"]=.75;add_evidence(case_id,ev)
    for corpse in corpses:
        if pos.distance_to(corpse.get("pos",Vector2.ZERO))<=130:add_evidence(case_id,{"type":"body","victim":corpse.get("person_id",corpse.get("id","")),"weight":.4})
    for n in npcs:
        if not bool(n.get("alive",true)) or pos.distance_to(n.get("pos",Vector2.ZERO))>160:continue
        for m in n.get("memory",[]):
            if str(m.get("type",""))=="witnessed_crime" and str(m.get("case_id",""))==case_id:
                add_witness(case_id,n,str(m.get("suspect","")),float(m.get("confidence",.65)))
    i=_idx(case_id);if i>=0:
        cases[i]["heat"]=minf(100,float(cases[i].get("heat",0))+8);cases[i]["scene_scanned"]=true

func assign_guard(case_id:String,npcs:Array)->Dictionary:
    var i=_idx(case_id);if i<0 or not bool(cases[i].get("reported",false)):return {}
    for ni in npcs.size():
        var n:Dictionary=npcs[ni];var role=str(n.get("role","")).to_lower()
        if ("guard" in role or "страж" in role) and bool(n.get("alive",true)):
            cases[i]["assigned_guard"]=str(n.get("id",""));n["target"]=cases[i]["pos"];n["investigating_case_id"]=case_id;npcs[ni]=n
            events.append({"type":"investigation","text":"%s отправлен осмотреть место преступления."%n.get("name","Стражник"),"case_id":case_id});return n
    return {}

func process_guard_arrivals(npcs:Array,physical_objects:Array,corpses:Array):
    for i in cases.size():
        var c:Dictionary=cases[i]
        if str(c.get("assigned_guard",""))=="" or bool(c.get("scene_scanned",false)):continue
        var gi=_npc_idx(npcs,str(c.get("assigned_guard","")));if gi<0:continue
        if Vector2(npcs[gi].get("pos",Vector2.ZERO)).distance_to(c.get("pos",Vector2.ZERO))>75:continue
        scan_scene(str(c["id"]),physical_objects,corpses,npcs)
        events.append({"type":"scene_scanned","text":"Стража осмотрела место происшествия и собрала доступные улики.","case_id":c["id"]})

func tick(npcs:Array,day:int,hour:float):
    var slot=day*24+int(hour)
    if slot!=last_report_slot:
        last_report_slot=slot;_advance_witness_reports(npcs)
    for i in cases.size():
        var c:Dictionary=cases[i];var status=str(c.get("status",""));if status not in ["open","suspect_identified"]:continue
        c["heat"]=maxf(0,float(c.get("heat",0))-.08)
        if bool(c.get("reported",false)) and str(c.get("assigned_guard",""))=="" and randf()<.12:assign_guard(str(c["id"]),npcs)
        if status=="open" and bool(c.get("reported",false)):
            var best_id="";var best=0.0
            for sid in c["suspects"].keys():
                var score=float(c["suspects"][sid])
                if score>best:best=score;best_id=str(sid)
            if best>=2.1:
                c["status"]="suspect_identified";c["primary_suspect"]=best_id;events.append({"type":"suspect_identified","text":"Следствие определило главного подозреваемого.","suspect_id":best_id,"case_id":c["id"]})
            elif day-int(c.get("day",day))>12 and best<.8:
                c["status"]="cold";events.append({"type":"cold_case","text":"Расследование зашло в тупик.","case_id":c["id"]})
        cases[i]=c

func _advance_witness_reports(npcs:Array):
    for ci in cases.size():
        var c:Dictionary=cases[ci];if bool(c.get("reported",false)) or str(c.get("status",""))!="open":continue
        for w in c.get("witnesses",[]):
            var ni=_npc_idx(npcs,str(w.get("npc_id","")));if ni<0:continue
            var n:Dictionary=npcs[ni];var role=str(n.get("role","")).to_lower();var underworld=("банд" in role or "контраб" in role or "вор" in role)
            var chance=float(w.get("reliability",.5))*.45
            if underworld:chance*=.2
            if randf()<chance:report_case(str(c["id"]),str(w.get("npc_id","")));break

func open_cases()->Array:
    var out:Array=[]
    for c in cases:
        if str(c.get("status","")) in ["open","suspect_identified"]:out.append(c)
    return out

func public_cases()->Array:
    var out:Array=[]
    for c in cases:
        if bool(c.get("reported",false)) and str(c.get("status","")) in ["open","suspect_identified"]:out.append(c)
    return out

func _merge_case_index(kind:String,victim_id:String,day:int,hour:float)->int:
    for i in cases.size():
        var c:Dictionary=cases[i]
        if str(c.get("kind",""))==kind and str(c.get("victim_id",""))==victim_id and int(c.get("day",-99))==day and absf(float(c.get("hour",0))-hour)<=1.5 and str(c.get("status","")) in ["open","suspect_identified"]:return i
    return -1

func _evidence_key(e:Dictionary)->String:
    return "%s|%s|%s|%s|%s"%[str(e.get("type","")),str(e.get("source_object","")),str(e.get("suspect_id",e.get("actor",""))),str(e.get("person","")),str(e.get("victim",""))]

func _idx(id:String)->int:
    for i in cases.size():
        if str(cases[i].get("id",""))==id:return i
    return -1
func _npc_idx(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"cases":cases,"next_id":next_id,"last_report_slot":last_report_slot}
func restore(data:Dictionary):
    var c=data.get("cases",[]);if typeof(c)==TYPE_ARRAY:cases=c
    next_id=int(data.get("next_id",next_id));last_report_slot=int(data.get("last_report_slot",last_report_slot))
