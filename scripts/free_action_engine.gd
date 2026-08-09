extends RefCounted

var verbs:={
    "взять":"take","поднять":"take","бросить":"throw","сломать":"break","разбить":"break","сжечь":"burn","поджечь":"burn",
    "спрятать":"hide","спрятаться":"hide","украсть":"steal","обокрасть":"steal","взломать":"pick_lock","залезть":"climb","взобраться":"climb",
    "убедить":"persuade","уговорить":"persuade","обмануть":"deceive","соврать":"deceive","угрожать":"threaten","запугать":"threaten",
    "отрезать":"sever","отрубить":"sever","искать":"search","обыскать":"search","пробраться":"sneak","красться":"sneak"
}
var allowed=["take","throw","break","burn","hide","steal","pick_lock","climb","persuade","deceive","threaten","sever","search","sneak"]

func parse_local(text:String,world:Dictionary)->Dictionary:
    var low=text.to_lower().strip_edges();var verb=""
    for token in verbs.keys():
        if token in low:verb=verbs[token];break
    if verb=="":return {"ok":false,"needs_ai":true,"reason":"Не удалось свести действие к известным примитивам."}
    var target=_find_target(low,world)
    var tool=_find_tool(low,world)
    return {"ok":true,"needs_ai":false,"verb":verb,"target":target,"tool":tool,"raw":text,"uncertain":verb not in ["take"],"stakes":1}

func validate(action:Dictionary,world:Dictionary)->Dictionary:
    var verb=str(action.get("verb",""))
    if verb not in allowed:return {"ok":false,"reason":"Такого действия пока нет в правилах мира."}
    var target=action.get("target",{})
    if verb in ["break","burn","steal","sever","pick_lock","climb","persuade","deceive","threaten"] and (typeof(target)!=TYPE_DICTIONARY or target.is_empty()):
        return {"ok":false,"reason":"Неясно, с чем или с кем ты хочешь это сделать."}
    if verb=="sever":
        if str(target.get("kind",""))!="corpse":return {"ok":false,"reason":"Отделить часть тела можно только от доступного тела/трупа в текущей системной версии."}
        if not _has_cutting_tool(world):return {"ok":false,"reason":"Нужен режущий инструмент."}
    if verb=="burn" and not bool(world.get("has_fire_source",false)):return {"ok":false,"reason":"У тебя нет доступного источника огня."}
    return {"ok":true,"action":action}

func _find_target(text:String,world:Dictionary)->Dictionary:
    var candidates:Array=[]
    candidates.append_array(world.get("nearby_objects",[]));candidates.append_array(world.get("nearby_npcs",[]));candidates.append_array(world.get("nearby_corpses",[]))
    for c in candidates:
        var name=str(c.get("name","")).to_lower()
        if name!="" and name in text:return c
        for alias in c.get("aliases",[]):
            if str(alias).to_lower() in text:return c
    if "голов" in text:
        for c in world.get("nearby_corpses",[]):return c
    if candidates.size()==1:return candidates[0]
    return {}

func _find_tool(text:String,world:Dictionary)->Dictionary:
    for item in world.get("inventory",[]):
        var name=str(item.get("name","")).to_lower()
        if name!="" and name in text:return item
    return {}

func _has_cutting_tool(world:Dictionary)->bool:
    for item in world.get("inventory",[]):
        if str(item.get("tool_type","")) in ["knife","axe","blade"]:return true
        var n=str(item.get("name","")).to_lower()
        if "нож" in n or "топор" in n or "клин" in n:return true
    return false
