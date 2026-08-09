extends SceneTree

const Investigation=preload("res://scripts/crime_investigation_system.gd")

func _init():
    seed(42)
    var system=Investigation.new()
    var scene=Vector2(100,100)
    var victim={"id":"victim","name":"Пострадавший","alive":true,"pos":scene,"stress":10.0,"memory":[]}
    var witness_a={"id":"w1","name":"Свидетель А","alive":true,"pos":scene+Vector2(30,0),"stress":0.0,"role":"merchant","memory":[]}
    var witness_b={"id":"w2","name":"Свидетель Б","alive":true,"pos":scene+Vector2(-25,0),"stress":0.0,"role":"worker","memory":[]}
    var guard={"id":"guard","name":"Стражник","alive":true,"pos":scene,"stress":0.0,"role":"стражник","memory":[]}
    var npcs=[victim,witness_a,witness_b,guard]
    var c=system.report_crime("assault",scene,"victim","player",3,12.0,[{"type":"weapon_trace","source_object":"shard","suspect_id":"player","weight":.8}])
    var case_id=str(c["id"])
    assert(system.cases.size()==1)
    assert(system.public_cases().is_empty())
    # A second blow in the same fight must update the incident rather than spam another case.
    system.report_crime("assault",scene,"victim","player",3,12.4,[])
    assert(system.cases.size()==1)
    system.add_witness(case_id,npcs[1],"player",.9)
    system.add_witness(case_id,npcs[2],"player",.9)
    # Duplicate testimony must not create duplicate witnesses.
    system.add_witness(case_id,npcs[1],"player",.7)
    assert(system.cases[0]["witnesses"].size()==2)
    system.report_case(case_id,"w1")
    assert(system.public_cases().size()==1)
    var assigned=system.assign_guard(case_id,npcs)
    assert(not assigned.is_empty())
    assert(str(system.cases[0].get("assigned_guard",""))=="guard")
    var objects=[{"id":"shard","name":"окровавленный осколок","pos":scene,"evidence":[{"type":"created","actor":"player"},{"type":"blood","person":"victim"}]}]
    system.process_guard_arrivals(npcs,objects,[])
    assert(bool(system.cases[0].get("scene_scanned",false)))
    var evidence_count=system.cases[0]["evidence"].size()
    system.process_guard_arrivals(npcs,objects,[])
    assert(system.cases[0]["evidence"].size()==evidence_count)
    system.tick(npcs,3,13.0)
    assert(str(system.cases[0].get("status",""))=="suspect_identified")
    assert(str(system.cases[0].get("primary_suspect",""))=="player")
    var saved=system.serialize();var restored=Investigation.new();restored.restore(saved)
    assert(restored.cases.size()==1)
    print("SMOKE_V38_INVESTIGATION_OK")
    quit(0)
