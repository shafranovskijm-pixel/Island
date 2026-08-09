extends SceneTree
const Body=preload("res://scripts/body_interaction_system.gd")
const Combat=preload("res://scripts/injury_combat_system.gd")
func _init():
    var b=Body.new();var c=Combat.new();c.ensure("npc");c.actor_state["npc"]["unconscious"]=true;c.actor_state["npc"]["bleeding"]=15.0
    var npc={"id":"npc","name":"Раненый","alive":true,"money":8,"equipment":[{"id":"knife","name":"нож"}],"pos":Vector2.ZERO}
    var inv=[{"id":"rope","kind":"resource","resource":"rope","quantity":1.0},{"id":"bandage","kind":"medicine","subtype":"bandage","quantity":1.0}]
    var search=b.search_body(npc,c,inv);assert(bool(search.get("ok",false)));assert(int(npc["money"])<8)
    assert(bool(b.bind_body(npc,c,inv).get("ok",false)));assert(bool(npc.get("bound",false)))
    assert(bool(b.carry(npc,c).get("ok",false)));assert(b.carried_body=="npc")
    var npcs=[npc];assert(bool(b.drop(npcs,Vector2(20,20)).get("ok",false)));assert(b.carried_body=="")
    # Add a fresh bandage after the rope/equipment mutations above.
    inv.append({"id":"bandage2","kind":"medicine","subtype":"bandage","quantity":1.0})
    assert(bool(b.stabilize(npcs[0],c,inv).get("ok",false)));assert(float(c.actor_state["npc"]["bleeding"])<15.0)
    print("SMOKE_V37_BODY_INTERACTIONS_OK")
    quit(0)
