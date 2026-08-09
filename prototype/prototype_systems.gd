extends RefCounted

# Compact systemic layer for the mobile vertical slice. It deliberately keeps
# consequences in data instead of hard-coding them into dialogue strings.

var relationships = {
    "innkeeper": 0,
    "bard": 0,
    "guard": 0,
    "hunter": 0,
    "volkhv": 0,
    "villager": 0,
}

var factions = {
    "village": 0,
    "guard": 0,
    "dockers": 0,
    "outlaws": 0,
    "old_faith": 0,
}

var npc_profiles = {
    "innkeeper": {
        "name": "Мирон",
        "faction": "village",
        "past": "Когда-то Мирон ходил матросом на северных каботажниках и до сих пор знает капитанов по именам.",
        "want": "Хочет, чтобы трактир пережил плохой сезон без долгов.",
        "secret": "Иногда прячет контрабандные тюки в погребе за плату.",
    },
    "bard": {
        "name": "Радован",
        "faction": "village",
        "past": "Радован три года странствовал по островам и собирал истории о пропавших поселениях.",
        "want": "Ищет историю, которую будут петь после его смерти.",
        "secret": "Он намеренно приукрашивает слухи, если видит, что слушатель готов действовать.",
    },
    "guard": {
        "name": "Борислав",
        "faction": "guard",
        "past": "Борислав был портовым грузчиком, пока не спас младшего сына старосты во время пожара.",
        "want": "Хочет спокойной смены и уважения, а не крови на улице.",
        "secret": "Долг ростовщику делает его уязвимым для осторожного подкупа.",
    },
    "hunter": {
        "name": "Остромир",
        "faction": "village",
        "past": "Остромир вырос у старой рощи и знает звериные тропы лучше дорог.",
        "want": "Хочет понять, что уводит охотников в рощу.",
        "secret": "Он видел человеческий след среди следов пропавшего охотника и боится сказать это страже.",
    },
    "volkhv": {
        "name": "Веда",
        "faction": "old_faith",
        "past": "Веда пришла на остров ребёнком вместе с общиной старой веры.",
        "want": "Хочет удержать людей от паники вокруг рощи.",
        "secret": "Она считает, что исчезновения связаны не с духом, а с людьми, использующими старые святилища.",
    },
    "villager": {
        "name": "Любава",
        "faction": "village",
        "past": "Любава держит маленький огород и помогает сестре растить двоих детей.",
        "want": "Хочет пережить рост цен на хлеб.",
        "secret": "Она видела ночью лодку без фонаря у старого причала.",
    },
}

var inventory = {}
var skills = {"sneak": 1, "streetwise": 0, "seamanship": 0}
var market = {"bread_base": 3, "beer_base": 2, "bread_stock": 7, "beer_stock": 10}
var talk_counts = {}
var delivered_threads = {}
var begged_keys = {}
var heat = 0
var ship_arrived = false
var sailor_offer = false
var boarded_ship = false
var last_day = 1

func tick(day, hour, flags = {}):
    last_day = int(day)
    # The ship is a world event, not a menu unlock. It physically appears at dusk.
    if int(day) > 1 or float(hour) >= 18.0:
        ship_arrived = true
    if bool(flags.get("brawl", false)):
        heat = maxi(heat, 1)

func current_price(item_id):
    if item_id == "bread":
        var scarcity = 1 if not ship_arrived else 0
        return int(market["bread_base"]) + scarcity
    if item_id == "beer":
        return int(market["beer_base"])
    return 0

func change_relationship(npc_id, amount):
    if not relationships.has(npc_id):
        return
    relationships[npc_id] = clampi(int(relationships[npc_id]) + int(amount), -100, 100)

func change_faction(faction_id, amount):
    if not factions.has(faction_id):
        return
    factions[faction_id] = clampi(int(factions[faction_id]) + int(amount), -100, 100)

func record_talk(npc_id):
    talk_counts[npc_id] = int(talk_counts.get(npc_id, 0)) + 1
    change_relationship(npc_id, 2)
    var profile = npc_profiles.get(npc_id, {})
    if not profile.is_empty():
        change_faction(str(profile.get("faction", "village")), 1)

func biography_line(npc_id):
    var profile = npc_profiles.get(npc_id, {})
    if profile.is_empty():
        return "Ты почти ничего не знаешь об этом человеке."
    var trust = int(relationships.get(npc_id, 0))
    if trust < 6:
        return "%s пока не готов говорить о себе." % str(profile.get("name", "Собеседник"))
    if trust < 14:
        return str(profile.get("past", "Прошлое пока неясно."))
    if trust < 24:
        return "%s %s" % [str(profile.get("past", "")), str(profile.get("want", ""))]
    return "%s %s По доверию ты понимаешь ещё кое-что: %s" % [str(profile.get("past", "")), str(profile.get("want", "")), str(profile.get("secret", ""))]

func npc_world_line(npc_id, flags = {}):
    # Hidden director: it never says "quest" or "AI". Opportunities leak into the
    # world only through believable people who currently know something useful.
    if ship_arrived and not bool(delivered_threads.get("ship_arrival", false)) and npc_id in ["innkeeper", "bard", "guard"]:
        delivered_threads["ship_arrival"] = true
        return "У старого причала только что встал торговый корабль. Капитан ищет пару рук до утра."
    if bool(flags.get("tracks_found", false)) and not bool(delivered_threads.get("human_tracks", false)) and npc_id in ["hunter", "volkhv"]:
        delivered_threads["human_tracks"] = true
        return "Следы слишком ровные для зверя. Кто-то тащил груз или человека к старому святилищу."
    if bool(flags.get("dog_friend", false)) and not bool(delivered_threads.get("dog_notice", false)) and npc_id == "hunter":
        delivered_threads["dog_notice"] = true
        return "Серко знает запах пропавшего охотника. Если он занервничает в роще — смотри под ноги."
    if heat > 0 and npc_id == "guard" and not bool(delivered_threads.get("heat_warning", false)):
        delivered_threads["heat_warning"] = true
        return "Я запомнил шум у трактира. Ещё одна выходка — и разговор будет уже в караулке."
    return ""

func resolve_action(raw_text, context):
    var text = str(raw_text).strip_edges().to_lower()
    if text == "":
        return _result(false, "Сформулируй действие: например «купить хлеб», «спросить о прошлом» или «попроситься матросом».")

    var near_npc = str(context.get("near_npc", ""))
    var coins = int(context.get("coins", 0))
    var hour = float(context.get("hour", 12.0))
    var near_dock = bool(context.get("near_dock", false))

    if _contains_any(text, ["купить хлеб", "buy bread"]):
        if near_npc != "innkeeper":
            return _result(false, "Хлеб продают в трактире. Здесь продавца рядом нет.")
        var price = current_price("bread")
        if int(market["bread_stock"]) <= 0:
            return _result(false, "Мирон разводит руками: хлеб закончился до следующей поставки.")
        if coins < price:
            return _result(false, "Хлеб стоит %d монет, а у тебя только %d." % [price, coins])
        market["bread_stock"] = int(market["bread_stock"]) - 1
        _add_item("bread", 1)
        change_relationship("innkeeper", 1)
        return _result(true, "Ты купил хлеб за %d монет." % price, -price)

    if _contains_any(text, ["купить пиво", "купить эль", "buy beer"]):
        if near_npc != "innkeeper":
            return _result(false, "Без трактирщика покупать пиво не у кого.")
        var beer_price = current_price("beer")
        if int(market["beer_stock"]) <= 0:
            return _result(false, "Бочка пуста.")
        if coins < beer_price:
            return _result(false, "Пиво стоит %d монеты." % beer_price)
        market["beer_stock"] = int(market["beer_stock"]) - 1
        _add_item("beer", 1)
        return _result(true, "Мирон наливает кружку. Пиво добавлено в сумку.", -beer_price)

    if _contains_any(text, ["выпить пиво", "выпить эль", "drink beer"]):
        if int(inventory.get("beer", 0)) <= 0:
            return _result(false, "У тебя нет пива.")
        _add_item("beer", -1)
        change_faction("village", 1)
        return _result(true, "Ты выпил пиво. Разговоры вокруг начинают звучать немного проще.")

    if _contains_any(text, ["съесть хлеб", "поесть хлеб", "eat bread"]):
        if int(inventory.get("bread", 0)) <= 0:
            return _result(false, "Хлеба в сумке нет.")
        _add_item("bread", -1)
        return _result(true, "Ты съел хлеб.")

    if _contains_any(text, ["спросить о прошлом", "расспросить о прошлом", "кто ты", "о себе"]):
        if near_npc == "":
            return _result(false, "Рядом нет человека, которого можно расспросить.")
        record_talk(near_npc)
        return _result(true, biography_line(near_npc))

    if _contains_any(text, ["попроситься матросом", "устроиться матросом", "работа на корабле", "наняться на корабль", "sailor job"]):
        if not ship_arrived:
            return _result(false, "Сегодня у причала нет корабля, на который можно наняться.")
        if not near_dock and near_npc not in ["innkeeper", "guard"]:
            return _result(false, "Нужно идти к причалу или спросить кого-то, кто связан с портом.")
        if int(factions["dockers"]) < -10:
            return _result(false, "Докеры уже знают о твоей репутации и не хотят иметь с тобой дела.")
        sailor_offer = true
        skills["seamanship"] = int(skills["seamanship"]) + 1
        change_faction("dockers", 5)
        return _result(true, "Боцман оглядывает тебя: «Руки есть — работа найдётся. До рассвета грузим бочки. Потом решим, брать ли тебя в рейс». ")

    if _contains_any(text, ["пробраться на корабль", "тайно на корабль", "спрятаться на корабле", "sneak aboard"]):
        if not ship_arrived:
            return _result(false, "У причала сейчас нет подходящего корабля.")
        if not near_dock:
            return _result(false, "Сначала нужно добраться до причала.")
        var night_bonus = 2 if hour >= 21.0 or hour < 5.0 else 0
        var score = int(skills["sneak"]) + night_bonus - heat
        skills["sneak"] = int(skills["sneak"]) + 1
        if score >= 2:
            boarded_ship = true
            change_faction("outlaws", 2)
            return _result(true, "Ты дожидаешься, когда грузчики отвернутся, и прячешься между тюками в трюме. Пока тебя никто не заметил.")
        heat += 1
        change_faction("guard", -4)
        return _result(false, "Тебя замечает портовый сторож. Он не арестовывает сразу, но теперь стража знает твоё лицо.")

    if _contains_any(text, ["украсть хлеб", "стащить хлеб", "steal bread"]):
        if near_npc != "innkeeper":
            return _result(false, "Здесь нет хлеба, который можно незаметно стащить.")
        if int(market["bread_stock"]) <= 0:
            return _result(false, "На стойке ничего не осталось.")
        var theft_score = int(skills["sneak"]) + (2 if hour >= 22.0 else 0) - heat
        skills["sneak"] = int(skills["sneak"]) + 1
        if theft_score >= 3:
            market["bread_stock"] = int(market["bread_stock"]) - 1
            _add_item("bread", 1)
            change_faction("outlaws", 1)
            return _result(true, "Когда Мирон отворачивается, буханка исчезает у тебя под плащом.")
        heat += 1
        change_relationship("innkeeper", -12)
        change_faction("village", -6)
        change_faction("guard", -3)
        return _result(false, "Мирон ловит тебя за руку. Теперь в трактире знают, что ты пытался украсть хлеб.")

    if _contains_any(text, ["подкупить страж", "дать взятку", "bribe guard"]):
        if near_npc != "guard":
            return _result(false, "Рядом нет стражника, которому можно это предложить.")
        if heat <= 0:
            return _result(false, "Стража пока тобой не интересуется. Взятка только создаст вопросы.")
        var bribe = 6 + heat * 2
        if coins < bribe:
            return _result(false, "Борислав оценивает риск в %d монет. У тебя столько нет." % bribe)
        heat = maxi(0, heat - 2)
        change_relationship("guard", -2)
        return _result(true, "Монеты исчезают в ладони Борислава. Он обещает забыть часть увиденного.", -bribe)

    if _contains_any(text, ["извиниться", "попросить прощения", "apologize"]):
        if near_npc == "":
            return _result(false, "Извиняться сейчас не перед кем.")
        change_relationship(near_npc, 6)
        if near_npc == "innkeeper":
            change_faction("village", 2)
        return _result(true, "%s выслушивает извинение. Это не стирает случившееся, но напряжение спадает." % str(npc_profiles.get(near_npc, {}).get("name", "Собеседник")))

    if _contains_any(text, ["попросить милостыню", "просить милостыню", "попросить монету", "beg"]):
        if near_npc == "":
            return _result(false, "Просить милостыню не у кого.")
        var key = "%d:%s" % [last_day, near_npc]
        if bool(begged_keys.get(key, false)):
            return _result(false, "Сегодня ты уже просил этого человека о помощи.")
        begged_keys[key] = true
        skills["streetwise"] = int(skills["streetwise"]) + 1
        var sympathy = int(relationships.get(near_npc, 0)) + int(factions["village"])
        if sympathy >= -3 and near_npc != "guard":
            change_relationship(near_npc, -1)
            return _result(true, "%s нехотя даёт тебе одну монету." % str(npc_profiles.get(near_npc, {}).get("name", "Прохожий")), 1)
        return _result(false, "Тебе отказывают.")

    if _contains_any(text, ["искать следы", "осмотреть следы", "идти по следам", "follow tracks"]):
        if not bool(context.get("near_tracks", false)):
            return _result(false, "Здесь нет заметных следов. Нужно сначала найти место, о котором говорили охотники.")
        return _result(true, "Ты сравниваешь отпечатки: один человек шёл сам, второго действительно волокли. След уходит глубже к роще.")

    return _result(false, _contextual_failure(near_npc, near_dock))

func _contextual_failure(near_npc, near_dock):
    if near_npc != "":
        return "Мир допускает это действие, но пока я не умею надёжно разбирать такую формулировку. Попробуй конкретнее: купить, спросить о прошлом, извиниться, украсть или попросить милостыню."
    if near_dock:
        return "У причала можно попробовать наняться матросом или тайно пробраться на корабль — но только если корабль уже пришёл."
    return "Для этого действия сейчас не хватает понятной цели рядом. Подойди к человеку, предмету или месту и сформулируй действие конкретнее."

func _add_item(item_id, amount):
    var next_amount = maxi(0, int(inventory.get(item_id, 0)) + int(amount))
    inventory[item_id] = next_amount

func _contains_any(text, needles):
    for needle in needles:
        if text.find(str(needle)) >= 0:
            return true
    return false

func _result(ok, text, coin_delta = 0):
    return {
        "ok": bool(ok),
        "message": str(text),
        "coin_delta": int(coin_delta),
        "heat": heat,
    }
