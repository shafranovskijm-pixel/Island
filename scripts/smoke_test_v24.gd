extends SceneTree

const LearningSystem=preload("res://scripts/learning_system.gd")

func _init():
    var learning=LearningSystem.new()
    var books=learning.available_books("library")
    assert(books.size()>0)
    var result=learning.study_book("building_1","library",1,10.0)
    assert(bool(result.get("ok",false)))
    assert(float(learning.knowledge.get("building",0))>0.0)
    learning.practice("building",2.0,1,12.0)
    assert(float(learning.study_progress.get("building",0))>2.0)
    var saved=learning.serialize()
    var restored=LearningSystem.new();restored.restore(saved)
    assert(float(restored.knowledge.get("building",0))==float(learning.knowledge.get("building",0)))
    print("LEARNING_SMOKE_OK")
    quit()
