extends RefCounted

var alibis:Array=[]
var tampering:Array=[]
var events:Array=[]

func create_alibi(case_id:String,npc:Dictionary,day:int,hour:float)->Dictionary:
    if int(npc.get("rel",0))<2:return {"ok":false,"reason":"Этот человек не станет подтверждать твою версию."}
    var reliability=clampf(.35+float(npc.get("rel",0))*.08-float(npc.get("stress",0))*.003,.2,.9)
    var a={"case_id":case_id,"npc_id":npc.get("id",""),"reliability":reliability,"day":day,"hour":hour};alibis.append(a);events.append({"type":"alibi","text":"%s готов подтвердить алиби героя."%npc.get("name","Свидетель")});return {"ok":true,"alibi":a}

func pressure_witness(case:Dictionary,witness_id:String,npcs:Array,charm:int,threat:bool=false)->Dictionary:
    for w in case.get("witnesses",[]):
        if str(w.get("npc_id",""))!=witness_id:continue
        var chance=clampf(.18+charm*.04+(.18 if threat else 0),.1,.78);var success=randf()<chance
        if success:w["confidence"]=maxf(.05,float(w.get("confidence",.5))-(.45 if threat else .25));events.append({"type":"witness_pressure","text":"Свидетель начинает сомневаться в своих показаниях."})
        else:events.append({"type":"witness_pressure_failed","text":"Свидетель запомнил попытку давления."})
        return {"ok":true,"success":success}
    return {"ok":false,"reason":"Такого свидетеля в деле нет."}

func destroy_evidence(case:Dictionary,evidence_index:int)->Dictionary:
    var evidence:Array=case.get("evidence",[]);if evidence_index<0 or evidence_index>=evidence.size():return {"ok":false,"reason":"Улика не найдена."}
    var e=evidence[evidence_index];e["destroyed"]=true;e["weight"]=float(e.get("weight",0))*.15;evidence[evidence_index]=e;case["evidence"]=evidence
    tampering.append({"case":case.get("id",""),"type":"destroy","evidence":evidence_index});events.append({"type":"evidence_destroyed","text":"Одна из улик серьёзно повреждена или уничтожена."});return {"ok":true}

func plant_evidence(case:Dictionary,target_id:String,object:Dictionary)->Dictionary:
    case["evidence"].append({"type":"planted_object","suspect_id":target_id,"source_object":object.get("id",""),"weight":.75,"planted":true})
    tampering.append({"case":case.get("id",""),"type":"plant","target":target_id});events.append({"type":"evidence_planted","text":"Улика подброшена так, чтобы указать на другого человека."});return {"ok":true}

func defense_modifier(case_id:String)->float:
    var total=0.0
    for a in alibis:
        if str(a.get("case_id",""))==case_id:total+=float(a.get("reliability",0))
    return minf(1.5,total)

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"alibis":alibis,"tampering":tampering}
func restore(data:Dictionary):
    var a=data.get("alibis",[]);if typeof(a)==TYPE_ARRAY:alibis=a
    var t=data.get("tampering",[]);if typeof(t)==TYPE_ARRAY:tampering=t
