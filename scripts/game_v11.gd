extends "res://scripts/game_v10.gd"

const FamilySystem=preload("res://scripts/family_system.gd")
var families=FamilySystem.new()
var family_event_cursor:=0

func _ready():
    super._ready()
    families.setup(npcs)

func _process(delta):
    super._process(delta)
    npcs=families.tick(npcs,day,hour)
    _drain_family_events()

func _drain_family_events():
    while family_event_cursor<families.events.size():
        var e=families.events[family_event_cursor]
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","family")),str(e.get("text","Семейное событие.")),{"social":0.4})
        _notify(str(e.get("text","Семейное событие.")))
        family_event_cursor+=1

func simulate_death(npc_id:String,cause:String):
    npcs=families.on_death(npcs,npc_id,day,hour)
    super.simulate_death(npc_id,cause)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    draw_rect(Rect2(710,170,555,32),Color(0.02,0.04,0.05,.82))
    draw_string(ThemeDB.fallback_font,Vector2(722,191),"Семьи: %d · Дом короны: %d влияния"%[families.families.size(),int(families.families.get("royal_house",{}).get("influence",0))],0,530,12,Color("#e8c9d5"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["family_system"]=families.serialize()
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var fd=data.get("family_system",{})
    if typeof(fd)==TYPE_DICTIONARY:families.restore(fd)
