extends SceneTree
const Security=preload("res://scripts/castle_room_security.gd")
func _init():
    var sec=Security.new()
    var estate={"id":"estate_1","owner":"player","security":10.0,"treasury":20.0}
    var placed=[
        {"id":"bed_1","estate_id":"estate_1","piece":"simple_bed","pos":Vector2(64,64)},
        {"id":"door_1","estate_id":"estate_1","piece":"wooden_door","pos":Vector2(96,64)},
        {"id":"table_1","estate_id":"estate_1","piece":"wood_table","pos":Vector2(128,64)}
    ]
    sec.rebuild_from_castle(estate,placed)
    assert(sec.rooms.size()>=2)
    var room=sec.assign_bedroom("resident_1");assert(bool(room.get("ok",false)))
    assert(str(sec.private_room_for("resident_1").get("type",""))=="bedroom")
    var lock=sec.create_key_for_nearest_door(Vector2(96,64),placed);assert(bool(lock.get("ok",false)))
    var key=lock["key"].duplicate(true);key["key_id"]=key["id"]
    var inv=[key]
    var toggle=sec.toggle_nearest_door_lock(Vector2(96,64),placed,inv);assert(bool(toggle.get("ok",false)))
    var npcs=[{"id":"guard_1","alive":true,"pos":Vector2.ZERO,"target":Vector2.ZERO}]
    assert(bool(sec.add_guard_post(Vector2(100,80),"guard_1").get("ok",false)))
    sec.tick(npcs,estate,placed,1,2.0,80.0)
    assert(sec.guard_posts.size()==1)
    assert(bool(npcs[0].get("guarding_estate",false)))
    print("SMOKE_V33_CASTLE_SECURITY_OK")
    quit(0)
