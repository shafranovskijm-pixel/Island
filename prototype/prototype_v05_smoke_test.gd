extends SceneTree

const Prototype = preload("res://prototype/prototype_v05.gd")
const PrototypeScene = preload("res://prototype/prototype_v05.tscn")
const WorldArt = preload("res://prototype/art/coastal_village.svg")

func _init():
    assert(WorldArt != null)
    assert(WorldArt.get_width() >= 1700)
    assert(WorldArt.get_height() >= 1000)

    var p = Prototype.new()
    assert(p.has_method("_draw_world"))
    assert(p.has_method("_style_mobile_ui"))
    assert(p.systems.has_method("suggest_actions"))

    p.player = Vector2(720, 535)
    assert(str(p._current_location()) == "tavern")
    p.player = Vector2(350, 900)
    assert(str(p._current_location()) == "dock")
    p.player = Vector2(1370, 720)
    assert(str(p._current_location()) == "forest")

    var scene_instance = PrototypeScene.instantiate()
    assert(scene_instance is Node2D)
    assert(scene_instance.get_script() == Prototype)
    scene_instance.free()
    p.free()

    print("PROTOTYPE_V05_VISUAL_SMOKE_OK")
    quit(0)
