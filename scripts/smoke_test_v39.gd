extends SceneTree

const Justice=preload("res://scripts/justice_system.gd")
const Evidence=preload("res://scripts/evidence_manipulation_system.gd")

func _init():
    var justice=Justice.new()
    var strong_case={"id":"case_strong","kind":"robbery","evidence":[{"type":"weapon","suspect_id":"player","weight":1.0},{"type":"blood_trace","actor":"player","weight":.8}],"witnesses":[{"npc_id":"w1","suspect_id":"player","confidence":.8,"reliability":.9}]}
    var scores=justice.case_scores(strong_case,"player")
    assert(float(scores["evidence"])>1.7)
    assert(float(scores["witness"])>.7)
    var arrest=justice.arrest(strong_case);assert(bool(arrest.get("ok",false)));assert(int(justice.state["fine_due"])==24)
    var verdict=justice.resolve_trial(strong_case,0,0,0);assert(bool(verdict.get("ok",false)));assert(bool(verdict.get("guilty",false)));assert(int(verdict.get("jail_days",0))==4)

    var justice2=Justice.new();var evidence=Evidence.new()
    var weak_case={"id":"case_weak","kind":"assault","evidence":[{"type":"object","suspect_id":"player","weight":.85}],"witnesses":[{"npc_id":"w2","suspect_id":"player","confidence":.45,"reliability":.55}]}
    var ally={"id":"ally","name":"Союзник","rel":5,"stress":0}
    var alibi=evidence.create_alibi("case_weak",ally,2,14.0);assert(bool(alibi.get("ok",false)))
    assert(evidence.defense_modifier("case_weak")>.6)
    var destroy=evidence.destroy_evidence(weak_case,0);assert(bool(destroy.get("ok",false)))
    var weak_scores=justice2.case_scores(weak_case,"player")
    var trial_copy=weak_case.duplicate(true);trial_copy["evidence_score"]=maxf(0,float(weak_scores["evidence"])-evidence.defense_modifier("case_weak"));trial_copy["witness_score"]=float(weak_scores["witness"])
    assert(bool(justice2.arrest(weak_case).get("ok",false)))
    var weak_verdict=justice2.resolve_trial(trial_copy,0,0,0);assert(bool(weak_verdict.get("ok",false)));assert(not bool(weak_verdict.get("guilty",true)))
    print("SMOKE_V39_JUSTICE_OK")
    quit(0)
