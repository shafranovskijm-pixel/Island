extends RefCounted

const SAVE_PATH := "user://player_history.json"

var events: Array = []
var lifestyle := {
    "homeless": 0.0,
    "worker": 0.0,
    "thief": 0.0,
    "sailor": 0.0,
    "merchant": 0.0,
    "mage": 0.0,
    "drunk": 0.0,
    "criminal": 0.0,
    "social": 0.0
}

func _init():
    load_history()

func record(day: int, hour: float, event_type: String, text: String, weights: Dictionary = {}):
    if event_type == "arrival" and not events.is_empty():
        return
    events.append({
        "day": day,
        "hour": hour,
        "type": event_type,
        "text": text
    })
    for key in weights.keys():
        if lifestyle.has(key):
            lifestyle[key] += float(weights[key])
    if events.size() > 500:
        events.pop_front()
    save_history()

func save_history():
    var payload := {
        "version": 1,
        "events": events,
        "lifestyle": lifestyle
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(payload))

func load_history():
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var loaded_events = parsed.get("events", [])
    if typeof(loaded_events) == TYPE_ARRAY:
        events = loaded_events
    var loaded_lifestyle = parsed.get("lifestyle", {})
    if typeof(loaded_lifestyle) == TYPE_DICTIONARY:
        for key in lifestyle.keys():
            if loaded_lifestyle.has(key):
                lifestyle[key] = float(loaded_lifestyle[key])

func reset_history():
    events.clear()
    for key in lifestyle.keys():
        lifestyle[key] = 0.0
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func dominant_path() -> String:
    var best_key := "homeless"
    var best_value := -INF
    for key in lifestyle.keys():
        if lifestyle[key] > best_value:
            best_key = key
            best_value = lifestyle[key]
    return best_key

func title() -> String:
    var path := dominant_path()
    var score: float = lifestyle[path]
    if score < 2.0:
        return "Никто"
    match path:
        "homeless": return "Уличный бродяга" if score < 7.0 else "Старожил подворотен"
        "worker": return "Чернорабочий" if score < 7.0 else "Надёжный работник"
        "thief": return "Мелкий вор" if score < 7.0 else "Тень острова"
        "sailor": return "Портовый матрос" if score < 7.0 else "Морской волк"
        "merchant": return "Мелкий торговец" if score < 7.0 else "Дельце"
        "mage": return "Любопытный к тайнам" if score < 7.0 else "Знающий знаки"
        "drunk": return "Завсегдатай таверны" if score < 7.0 else "Пропитая легенда"
        "criminal": return "Подозрительный тип" if score < 7.0 else "Известный преступник"
        "social": return "Знакомое лицо" if score < 7.0 else "Человек связей"
    return "Никто"

func visual_profile() -> Dictionary:
    var wealth := lifestyle["merchant"] + lifestyle["worker"] * 0.4
    var roughness := lifestyle["homeless"] + lifestyle["criminal"] * 0.5
    var drunkenness := lifestyle["drunk"]
    var sailor := lifestyle["sailor"]
    var magic := lifestyle["mage"]
    var thief := lifestyle["thief"]
    return {
        "clothes_tier": clampi(int(wealth / 5.0) - int(roughness / 8.0), 0, 3),
        "dirt": clampf(roughness / 12.0 + lifestyle["homeless"] / 10.0, 0.0, 1.0),
        "beard": clampf((lifestyle["homeless"] + sailor * 0.4) / 10.0, 0.0, 1.0),
        "drunk": clampf(drunkenness / 10.0, 0.0, 1.0),
        "sailor": clampf(sailor / 10.0, 0.0, 1.0),
        "magic": clampf(magic / 10.0, 0.0, 1.0),
        "thief": clampf(thief / 10.0, 0.0, 1.0)
    }

func recent(limit: int = 6) -> Array:
    var result: Array = []
    var start := maxi(0, events.size() - limit)
    for i in range(start, events.size()):
        result.append(events[i])
    return result

func biography_text(limit: int = 8) -> String:
    var lines: Array[String] = []
    lines.append("Текущий образ: %s" % title())
    lines.append("Прожито событий: %d" % events.size())
    lines.append("")
    for event in recent(limit):
        var h := int(event["hour"])
        var m := int((float(event["hour"]) - h) * 60.0)
        lines.append("День %d, %02d:%02d — %s" % [event["day"], h, m, event["text"]])
    return "\n".join(lines)
