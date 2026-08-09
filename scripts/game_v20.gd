extends "res://scripts/game_v19.gd"

const OpportunityDelivery=preload("res://scripts/opportunity_delivery.gd")
var opportunities=OpportunityDelivery.new()
var heard_opportunities:Array=[]

func _on_approach_arrival(event:Dictionary):
    super._on_approach_arrival(event)
    var id=str(event.get("npc_id",""));var idx=_find_npc(id)
    if idx<0:return
    _deliver_npc_knowledge(npcs[idx])

func _do_location_npc_action(n:Dictionary,action:int):
    super._do_location_npc_action(n,action)
    if action in [0,1]:_deliver_npc_knowledge(n)

func _deliver_npc_knowledge(npc:Dictionary):
    var offers=opportunities.collect_for_npc(npc,_opportunity_world())
    if offers.is_empty():return
    var offer:Dictionary=offers[0]
    opportunities.mark_delivered(offer,str(npc.get("id","")))
    heard_opportunities.append(offer)
    history.record(day,hour,"rumor",str(npc.get("name","Кто-то"))+": "+str(offer["text"]),{})
    _notify(str(npc.get("name","Кто-то"))+": «"+str(offer["text"])+"»")

func _opportunity_world()->Dictionary:
    return {"hunger_pressure":production.hunger_pressure,"vampires_known":locations.secrets.get("vampires",false),"wanted":wanted,"location":current_location_id,"influence":influence}

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["opportunities"]=opportunities.serialize();data["heard_opportunities"]=heard_opportunities;return data

func _apply_save(data:Dictionary):
    super._apply_save(data);var o=data.get("opportunities",{});if typeof(o)==TYPE_DICTIONARY:opportunities.restore(o);heard_opportunities=data.get("heard_opportunities",[])
