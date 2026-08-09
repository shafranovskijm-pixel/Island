extends RefCounted

# AI is optional. The simulation remains authoritative and fully playable offline.
# The model may suggest intentions or dialogue, but it never mutates world state directly.

var enabled := false
var provider := "none"
var endpoint := ""
var api_key := ""

func configure(p_provider: String, p_endpoint: String, p_api_key: String):
    provider = p_provider
    endpoint = p_endpoint
    api_key = p_api_key
    enabled = endpoint != "" and api_key != ""

func npc_snapshot(npc: Dictionary, npcs: Array, day: int, hour: float) -> Dictionary:
    var known: Array = []
    for other in npcs:
        if other.get("id", "") == npc.get("id", ""):
            continue
        var social_map: Dictionary = npc.get("social", {})
        if social_map.has(other.get("id", "")):
            var relation: Dictionary = social_map[other["id"]]
            known.append({
                "id": other["id"],
                "name": other["name"],
                "friendship": relation.get("friendship", 0),
                "trust": relation.get("trust", 0),
                "love": relation.get("love", 0),
                "resentment": relation.get("resentment", 0),
                "fear": relation.get("fear", 0),
                "debt": relation.get("debt", 0)
            })
    var memories: Array = npc.get("memory", [])
    var memory_start := maxi(0, memories.size() - 8)
    return {
        "day": day,
        "hour": hour,
        "id": npc.get("id", ""),
        "name": npc.get("name", ""),
        "role": npc.get("role", ""),
        "goal": npc.get("goal", ""),
        "vice": npc.get("vice", ""),
        "faction": npc.get("faction", ""),
        "money": npc.get("money", 0),
        "stress": npc.get("stress", 0),
        "traits": npc.get("traits", {}),
        "relationships": known,
        "memories": memories.slice(memory_start)
    }

func local_intention(npc: Dictionary) -> Dictionary:
    var stress := float(npc.get("stress", 0.0))
    var traits: Dictionary = npc.get("traits", {})
    if npc.get("vice", "") == "алкоголь" and stress > 55.0:
        return {"action": "seek_drink", "reason": "stress_and_addiction"}
    if float(traits.get("ambition", 0.0)) > 0.75 and float(npc.get("influence", 0.0)) < 50.0:
        return {"action": "seek_influence", "reason": "ambition"}
    if float(traits.get("greed", 0.0)) > 0.78 and int(npc.get("money", 0)) < 4:
        return {"action": "seek_money", "reason": "greed_and_poverty"}
    return {"action": "continue_goal", "reason": npc.get("goal", "daily_life")}

func validate_proposal(proposal: Dictionary) -> Dictionary:
    var allowed := [
        "talk", "seek_person", "seek_job", "seek_money", "seek_drink", "seek_food",
        "seek_influence", "spread_rumor", "court", "apologize", "threaten", "steal",
        "trade", "rest", "continue_goal"
    ]
    var action := str(proposal.get("action", ""))
    if action not in allowed:
        return {"ok": false, "action": "continue_goal", "reason": "invalid_ai_action"}
    return {
        "ok": true,
        "action": action,
        "target": proposal.get("target", ""),
        "reason": proposal.get("reason", "")
    }

func build_dialogue_context(npc: Dictionary, player_history: String, world_events: Array) -> Dictionary:
    return {
        "instruction": "Speak only from facts this NPC knows. You may lie only when personality or motive supports it. Never invent completed world actions.",
        "npc": {
            "name": npc.get("name", ""),
            "role": npc.get("role", ""),
            "goal": npc.get("goal", ""),
            "vice": npc.get("vice", ""),
            "traits": npc.get("traits", {}),
            "memories": npc.get("memory", [])
        },
        "player_history": player_history,
        "recent_world_events": world_events
    }
