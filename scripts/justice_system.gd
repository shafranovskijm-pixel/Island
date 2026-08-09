extends RefCounted

var state={"arrested":false,"jailed":false,"jail_days":0,"fine_due":0,"trial_pending":false,"convictions":[],"bribe_attempts":0,"escaped":false}
var events:Array=[]

func arrest(case:Dictionary)->Dictionary:
    if bool(state["arrested"]):return {"ok":false,"reason":"Уже задержан."}
    state["arrested"]=true;state["trial_pending"]=true
    var severity=_severity(_case_crime(case));state["fine_due"]=severity*12
    events.append({"type":"arrest","text":"Стража задерживает героя по делу %s."%case.get("id","")});return {"ok":true}

func case_scores(case:Dictionary,suspect_id:String="player")->Dictionary:
    var evidence_score:=0.0;var witness_score:=0.0
    for e in case.get("evidence",[]):
        var suspect=str(e.get("suspect_id",e.get("actor","")))
        var weight=float(e.get("weight",.4))
        if bool(e.get("destroyed",false)):weight*=.35
        if suspect==suspect_id:evidence_score+=weight
        elif suspect=="" and str(e.get("type","")) in ["body","blood","victim_blood"]:evidence_score+=weight*.18
    for w in case.get("witnesses",[]):
        if str(w.get("suspect_id",""))!=suspect_id:continue
        witness_score+=float(w.get("confidence",0))*float(w.get("reliability",.6))
    return {"evidence":minf(4.0,evidence_score),"witness":minf(3.0,witness_score),"total":minf(7.0,evidence_score+witness_score)}

func resolve_trial(case:Dictionary,reputation:int,influence:int,coins:int)->Dictionary:
    if not bool(state["trial_pending"]):return {"ok":false,"reason":"Суда сейчас нет."}
    var scored=case_scores(case,"player")
    var evidence=float(case.get("evidence_score",scored["evidence"]));var witness=float(case.get("witness_score",scored["witness"]))
    var defense=maxf(0,reputation*.05+influence*.08)
    var prosecution=evidence+witness
    var guilty=prosecution-defense>=1.25
    state["trial_pending"]=false;state["arrested"]=false
    if guilty:
        var crime=_case_crime(case);var severity=_severity(crime);state["jailed"]=true;state["jail_days"]=severity*2;state["convictions"].append({"case":case.get("id",""),"crime":crime,"evidence":evidence,"witness":witness})
        events.append({"type":"conviction","text":"Суд признаёт героя виновным. Назначены штраф и заключение."});return {"ok":true,"guilty":true,"jail_days":state["jail_days"],"fine":state["fine_due"],"evidence_score":evidence,"witness_score":witness}
    state["fine_due"]=0;events.append({"type":"acquittal","text":"Доказательств оказалось недостаточно. Героя отпускают."});return {"ok":true,"guilty":false,"evidence_score":evidence,"witness_score":witness}

func pay_fine(coins:int)->Dictionary:
    var due=int(state["fine_due"]);if due<=0:return {"ok":false,"reason":"Штрафа нет."}
    if coins<due:return {"ok":false,"reason":"Не хватает денег на штраф."}
    state["fine_due"]=0;events.append({"type":"fine_paid","text":"Штраф уплачен."});return {"ok":true,"cost":due}

func attempt_bribe(coins:int,charm:int)->Dictionary:
    var cost=15+int(state["fine_due"]*.4);if coins<cost:return {"ok":false,"reason":"Для взятки не хватает денег."}
    state["bribe_attempts"]=int(state["bribe_attempts"])+1
    var success=randf()<clampf(.18+charm*.04,.1,.72)
    if success:
        state["arrested"]=false;state["trial_pending"]=false;events.append({"type":"bribe_success","text":"Чиновник принимает деньги и дело временно теряет ход."})
    else:events.append({"type":"bribe_failed","text":"Попытка подкупа провалилась и только ухудшила положение."})
    return {"ok":true,"success":success,"cost":cost}

func attempt_escape(stealth:int)->Dictionary:
    if not bool(state["jailed"]):return {"ok":false,"reason":"Ты не в тюрьме."}
    var success=randf()<clampf(.12+stealth*.045,.08,.70)
    if success:state["jailed"]=false;state["escaped"]=true;state["jail_days"]=0;events.append({"type":"jail_escape","text":"Герой сбежал из заключения."})
    else:state["jail_days"]=int(state["jail_days"])+2;events.append({"type":"escape_failed","text":"Побег провален. Срок увеличен."})
    return {"ok":true,"success":success}

func tick_day():
    if bool(state["jailed"]):
        state["jail_days"]=maxi(0,int(state["jail_days"])-1)
        if int(state["jail_days"])==0:state["jailed"]=false;events.append({"type":"released","text":"Срок заключения закончился."})

func _case_crime(case:Dictionary)->String:
    return str(case.get("crime_type",case.get("kind","assault")))
func _severity(crime:String)->int:
    return {"robbery":2,"assault":2,"murder":5,"burglary":2,"arson":3,"kidnap":4}.get(crime,1)
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return state.duplicate(true)
func restore(data:Dictionary):
    for k in state.keys():
        if data.has(k):state[k]=data[k]
