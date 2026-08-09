extends SceneTree

const InheritanceSystem=preload("res://scripts/inheritance_system.gd")

func _init():
    var sys=InheritanceSystem.new()
    var npcs=[
        {"id":"dead","name":"Старый фермер","alive":false,"money":50,"spouse_id":"wife","employment_property":"farm1","role":"крестьянин"},
        {"id":"wife","name":"Жена","alive":true,"money":5,"spouse_id":"dead"}
    ]
    var props=[{"id":"farm1","name":"Ферма","owner":"dead","workers":["dead"],"active":true}]
    var result=sys.process_death(npcs,"dead",props,null,3,12.0)
    var out_npcs=result["npcs"];var out_props=result["properties"]
    assert(str(out_props[0]["owner"])=="wife")
    assert(not ("dead" in out_props[0]["workers"]))
    assert(float(out_npcs[1]["money"])>=55.0)
    print("SMOKE_V23_OK")
    quit()
