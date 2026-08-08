extends RefCounted

# AI is optional. The simulation remains authoritative and fully playable offline.
# This bridge prepares compact world snapshots and validates model proposals
# before the game can turn them into real actions.

var enabled := false
var provider := "none"
var endpoint := ""
var api_key := ""
var last_prompt := ""
var last_result := {}

func configure(p_provider:String, p_endpoint:String, p_api_key:String):
    provider = p_provider
    endpoint = p_endpoint
    api_key = p_api_key
    enabled = endpoint != "" and api_key != ""

func npc_snapshot(npc:Dictionary, npcs:Array, day:int, hour:float) -> Dictionary:
    var known:Array=[]
    for other in npcs:
        if other["id"] == npc["id"]: continue
        if npc.get("social",{}).has(other["id"]):
            var r:Dictionary = npc["social"][other["id"]]
            known.append({
                "id":other["id"],"name":other["name"],
                "friendship":r.get("friendship",0),"trust":r.get("trust",0),
                "love":r.get("love",0),"resentment":r.get("resentment",0),
                "fear":r.get("fear",0),"debt":r.get("debt",0)
            })
    return {
        "day":day,"hour":hour,"id":npc["id"],"name":npc["name"],
        "role":npc.get("role",""),"goal":npc.get("goal",""),
        "vice":npc.get("vice",""),"faction":npc.get("faction",""),
        "money":npc.get("money",0),"stress":npc.get("stress",0),
        "traits":npc.get("traits",{}),"relationships":known,
        "memories":npc.get("memory",[]).slice(maxi(0,npc.get("memory",[]).size()-8))
    }

func local_intention(npc:Dictionary) -> Dictionary:
    # Deterministic/offline fallback for important decisions.
    var stress := float(npc.get("stress",0))
    var traits:Dictionary = npc.get("traits",{})
    if npc.get("vice","") == "алкоголь" and stress > 55:
        return {"action":"seek_drink","reason":"stress_and_addiction"}
    if float(traits.get("ambition",0)) > 0.75 and float(npc.get("influence",0)) < 50:
        return {"action":"seek_influence","reason":"ambition"}
    if float(traits.get("greed",0)) > 0.78 and int(npc.get("money",0)) < 4:
        return {"action":"seek_money","reason":"greed_and_poverty"}
    return {"action":"continue_goal","reason":npc.get("goal","daily_life")}

func validate_proposal(proposal:Dictionary) -> Dictionary:
    # The LLM never changes world state directly. Only whitelisted verbs survive.
    var allowed := [
        "talk","seek_person","seek_job","seek_money","seek_drink","seek_food",
        "seek_influence","spread_rumor","court","apologize","threaten","steal",
        "trade","rest","continue_goal"
    ]
    var action := str(proposal.get("action",""))
    if not action in allowed:
        return {"ok":false,"action":"continue_goal","reason":"invalid_ai_action"}
    return {"ok":true,"action":action,"target":proposal.get("target",""),"reason":proposal.get("reason","")}

func build_dialogue_context(npc:Dictionary, player_history:String, world_events:Array) -> Dictionary:
    return {
        "instruction":"Speak only from facts this NPC knows. You may lie only if personality/motive supports it. Never invent completed world actions.",
        "npc":npc_snapshot(npc,[],0,0) if false else {
            "name":npc.get("name",""),"role":npc.get("role",""),"goal":npc.get("goal",""),
            "vice":npc.get("vice",""),"traits":npc.get("traits",{}),"memories":npc.get("memory",[])
        },
        "player_history":player_history,
        "recent_world_events":world_events
    }
