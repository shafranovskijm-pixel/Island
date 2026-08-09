extends "res://prototype/prototype_systems.gd"

# V04 keeps the free-form text box, but adds two systemic pieces that make it
# practical on mobile: context-grounded affordances and a short world memory.
# Nothing here unlocks from a menu alone: suggestions are derived from the same
# physical context that validates the action.

var action_events = []
var npc_seen_event = {}
var next_event_id = 1

func suggest_actions(context):
    var suggestions = []
    var near_npc = str(context.get("near_npc", ""))
    var location = str(context.get("location", "village"))

    if near_npc == "innkeeper":
        _append_unique(suggestions, "купить хлеб")
        _append_unique(suggestions, "спросить о прошлом")
        if int(context.get("coins", 0)) <= 3:
            _append_unique(suggestions, "попросить милостыню")
        elif heat > 0:
            _append_unique(suggestions, "извиниться")
    elif near_npc == "guard":
        _append_unique(suggestions, "спросить о прошлом")
        if heat > 0:
            _append_unique(suggestions, "дать взятку стражнику")
            _append_unique(suggestions, "извиниться")
    elif near_npc != "":
        _append_unique(suggestions, "спросить о прошлом")
        _append_unique(suggestions, "попросить милостыню")

    if location == "dock":
        if ship_arrived:
            _append_unique(suggestions, "попроситься матросом")
            _append_unique(suggestions, "пробраться на корабль")
        else:
            _append_unique(suggestions, "осмотреться")
    elif location == "forest" and bool(context.get("near_tracks", false)):
        _append_unique(suggestions, "искать следы")
    elif location in ["forest", "graveyard", "castle"]:
        _append_unique(suggestions, "осмотреться")

    if suggestions.is_empty():
        suggestions.append("осмотреться")

    while suggestions.size() > 3:
        suggestions.pop_back()
    return suggestions

func resolve_action(raw_text, context):
    var text = str(raw_text).strip_edges().to_lower()
    var before_heat = heat
    var result

    if _contains_any(text, ["осмотреться", "осмотреть местность", "оглядеться", "look around"]):
        result = _result(true, _describe_context(context))
    else:
        result = super.resolve_action(raw_text, context)

    # Successful actions and failed actions that changed legal attention become
    # facts in the world. The director can later surface them through NPC speech.
    if bool(result.get("ok", false)) or heat != before_heat:
        _record_action(raw_text, result, context)
    return result

func npc_world_line(npc_id, flags = {}):
    var inherited_line = super.npc_world_line(npc_id, flags)
    if inherited_line != "":
        return inherited_line
    return _memory_reaction(str(npc_id))

func _describe_context(context):
    var location = str(context.get("location", "village"))
    if bool(context.get("near_campfire", false)):
        if bool(context.get("campfire_lit", false)):
            return "Костёр горит ровно. Рядом вытоптана земля: здесь недавно сидело несколько человек."
        return "В холодной золе видны свежие угли. Костром пользовались совсем недавно."

    match location:
        "tavern":
            return "В трактире пахнет дымом и хлебом. На стойке осталось %d буханок и %d кружек пива." % [int(market.get("bread_stock", 0)), int(market.get("beer_stock", 0))]
        "dock":
            if ship_arrived:
                return "У старого причала стоит торговый корабль. Грузчики носят бочки, у трапа следит портовый сторож."
            return "Причал пуст. Канаты сухие, но на досках свежие следы телеги: здесь ждут судно."
        "forest":
            if bool(context.get("tracks_found", false)):
                return "В роще тихо. Найденная цепочка следов уходит между деревьями к старому святилищу."
            if bool(context.get("near_tracks", false)):
                return "В грязи есть нарушенный рисунок следов. С расстояния непонятно, человек это или зверь."
            return "Старая роща глушит звуки деревни. Подлесок густой; двигаться здесь незаметно легче, но обзор хуже."
        "graveyard":
            return "Кладбище ухожено хуже, чем деревня. У дальней ограды трава примята, будто кто-то ходит там ночью."
        "castle":
            return "У замка дежурит стража. Ворота открыты для работников, но внутренний двор просматривается с башни."
        _:
            return "Ты оглядываешь деревню: трактир, дорога к замку, старая роща и причал связаны одной живой дорогой людей и слухов."

func _record_action(raw_text, result, context):
    var event = {
        "id": next_event_id,
        "day": last_day,
        "action": str(raw_text).strip_edges().to_lower(),
        "ok": bool(result.get("ok", false)),
        "location": str(context.get("location", "village")),
        "near_npc": str(context.get("near_npc", "")),
        "heat": heat,
    }
    next_event_id += 1
    action_events.append(event)
    while action_events.size() > 24:
        action_events.pop_front()

func _memory_reaction(npc_id):
    if action_events.is_empty():
        return ""
    var seen = int(npc_seen_event.get(npc_id, 0))
    var newest = int(action_events[action_events.size() - 1].get("id", 0))

    for i in range(action_events.size() - 1, -1, -1):
        var event = action_events[i]
        var event_id = int(event.get("id", 0))
        if event_id <= seen:
            break
        var line = _reaction_for_event(npc_id, event)
        if line != "":
            npc_seen_event[npc_id] = event_id
            return line

    if newest > seen:
        npc_seen_event[npc_id] = newest
    return ""

func _reaction_for_event(npc_id, event):
    var action = str(event.get("action", ""))
    var ok = bool(event.get("ok", false))

    if _contains_any(action, ["украсть хлеб", "стащить хлеб", "steal bread"]):
        if npc_id == "innkeeper":
            return "Мирон смотрит на твои руки внимательнее обычного. Он помнит историю с хлебом."
        if npc_id == "guard" and not ok:
            return "Борислав уже слышал, что в трактире кого-то поймали на воровстве."

    if _contains_any(action, ["попроситься матросом", "устроиться матросом", "наняться на корабль", "sailor job"]):
        if npc_id == "bard":
            return "Радован усмехается: «Говорят, ты уже нашёл работу у причала. Море быстро проверяет людей»."
        if npc_id == "innkeeper":
            return "Мирон кивает на твою одежду: «Если боцман оставит тебя до утра — значит, шанс у тебя есть»."

    if _contains_any(action, ["попросить милостыню", "просить милостыню", "попросить монету", "beg"]):
        if npc_id == "innkeeper":
            return "Мирон замечает, что ты ищешь любую монету: «Работа лучше жалости. К вечеру спроси у причала»."

    if _contains_any(action, ["дать взятку", "подкупить страж", "bribe guard"]):
        if npc_id == "bard":
            return "Радован понижает голос: «На острове монеты иногда бегут быстрее слухов. Но слухи всё равно догоняют»."

    if _contains_any(action, ["пробраться на корабль", "тайно на корабль", "спрятаться на корабле", "sneak aboard"]):
        if npc_id == "guard" and not ok:
            return "Борислав щурится: «Портовый сторож описал человека, слишком похожего на тебя»."

    if _contains_any(action, ["купить хлеб", "buy bread"]):
        if npc_id == "villager" and not ship_arrived:
            return "Любава смотрит на буханку: «До прихода корабля хлеб опять дорожает. Береги его»."

    return ""

func _append_unique(items, value):
    if not items.has(value):
        items.append(value)
