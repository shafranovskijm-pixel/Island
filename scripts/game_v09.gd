extends "res://scripts/game_v08.gd"

const LocationEventSystem=preload("res://scripts/location_event_system.gd")
var location_events=LocationEventSystem.new()
var location_event_cursor:=0
var recent_dead_name:=""

func _process(delta):
    super._process(delta)
    npcs=location_events.tick(npcs,locations,day,hour,{"recent_dead_name":recent_dead_name})
    _drain_location_events()

func _drain_location_events():
    while location_event_cursor<location_events.events.size():
        var e=location_events.events[location_event_cursor]
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","location_event")),str(e.get("text","Событие в локации.")),{})
        _notify(str(e.get("text","Событие в локации.")))
        location_event_cursor+=1

func simulate_death(npc_id:String,cause:String):
    var idx=_find_npc(npc_id)
    if idx<0:return
    recent_dead_name=str(npcs[idx].get("name",npc_id))
    super.simulate_death(npc_id,cause)

func arrest_npc(npc_id:String):
    npcs=location_events.arrest(npcs,npc_id,locations,day,hour)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["recent_dead_name"]=recent_dead_name
    data["location_event_days"]=location_events.last_event_day
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    recent_dead_name=str(data.get("recent_dead_name",""))
    var led=data.get("location_event_days",{})
    if typeof(led)==TYPE_DICTIONARY:location_events.last_event_day=led
