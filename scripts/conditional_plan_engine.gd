extends RefCounted

func parse(text:String,free_actions,world:Dictionary)->Dictionary:
    var low=text.to_lower().strip_edges()
    if "если" not in low:
        return {"ok":false,"reason":"Нет условной конструкции."}
    var else_split:=low.split("иначе",false,1)
    var first:=else_split[0]
    var fallback_text:="" if else_split.size()<2 else else_split[1].strip_edges()
    var parts:=first.split(",",false,1)
    if parts.size()<2:
        parts=first.split("то",false,1)
    if parts.size()<2:return {"ok":false,"reason":"Не удалось отделить условие от действия."}
    var condition_text=parts[0].replace("если","").strip_edges()
    var action_text=parts[1].strip_edges()
    var condition=_parse_condition(condition_text,world)
    var success_action=free_actions.parse_local(action_text,world)
    var fallback_action={} if fallback_text=="" else free_actions.parse_local(fallback_text,world)
    return {"ok":bool(condition.get("ok",false)) and bool(success_action.get("ok",false)),"condition":condition,"then":success_action,"else":fallback_action,"raw":text}

func evaluate(condition:Dictionary,world:Dictionary)->bool:
    match str(condition.get("type","")):
        "guard_not_looking":
            for n in world.get("nearby_npcs",[]):
                if "страж" in str(n.get("name","")).to_lower() or "страж" in str(n.get("role","")).to_lower():
                    return not bool(n.get("watching_player",true))
            return true
        "guard_absent":
            for n in world.get("nearby_npcs",[]):
                if "страж" in str(n.get("name","")).to_lower() or "страж" in str(n.get("role","")).to_lower():return false
            return true
        "night":return bool(world.get("night",false))
        "has_item":
            var needle=str(condition.get("item","")).to_lower()
            for i in world.get("inventory",[]):
                if needle in str(i.get("name","")).to_lower():return true
            return false
        "target_near":return bool(condition.get("value",false))
    return false

func _parse_condition(text:String,world:Dictionary)->Dictionary:
    if "страж" in text and ("отверн" in text or "не смотр" in text):return {"ok":true,"type":"guard_not_looking"}
    if "страж" in text and ("нет" in text or "уйдет" in text or "уйдёт" in text):return {"ok":true,"type":"guard_absent"}
    if "ноч" in text:return {"ok":true,"type":"night"}
    if "есть" in text and ("нож" in text or "факел" in text or "ключ" in text):
        var item="нож" if "нож" in text else ("факел" if "факел" in text else "ключ")
        return {"ok":true,"type":"has_item","item":item}
    return {"ok":false,"type":"unknown","raw":text}
