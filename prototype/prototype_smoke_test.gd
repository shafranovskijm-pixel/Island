extends SceneTree

const Prototype = preload("res://prototype/prototype_v02.gd")
const CI_MARKER = "PROTOTYPE_V02_SMOKE_OK"

func _init():
    var p = Prototype.new()
    assert(p.npcs.size() >= 6)
    assert(str(p.dog["name"]) == "Серко")
    assert(not p.rumor_heard)
    p.player = Vector2(785,555)
    p.interact()
    assert(p.rumor_heard)
    p.player = Vector2(500,745)
    p.interact()
    assert(p.dog_friend)
    p.player = Vector2(1260,785)
    p.interact()
    assert(p.campfire_lit)
    p.player = Vector2(725,635)
    p.interact()
    assert(str(p.held_item) == "бутылка")
    p.player = Vector2(100,100)
    p.action()
    assert(str(p.held_item) == "осколок")
    p.free()
    _mark_success(CI_MARKER)
    quit(0)

func _mark_success(marker):
    var marker_path = "res://.ci_%s.ok" % marker
    var file = FileAccess.open(marker_path, FileAccess.WRITE)
    assert(file != null)
    file.store_string(marker)
    file.close()
    print(marker)
