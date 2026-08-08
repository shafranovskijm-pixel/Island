extends RefCounted

const SAVE_PATH := "user://island_save_v1.json"

func save_game(state:Dictionary) -> bool:
    var file:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if file==null:
        return false
    file.store_string(JSON.stringify(_encode(state)))
    return true

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file==null:
        return {}
    var parsed=JSON.parse_string(file.get_as_text())
    if typeof(parsed)!=TYPE_DICTIONARY:
        return {}
    return _decode(parsed)

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func clear_save():
    if has_save():
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _encode(value):
    var t:=typeof(value)
    if t==TYPE_VECTOR2:
        return {"__type":"Vector2","x":value.x,"y":value.y}
    if t==TYPE_COLOR:
        return {"__type":"Color","r":value.r,"g":value.g,"b":value.b,"a":value.a}
    if t==TYPE_ARRAY:
        var out:Array=[]
        for item in value:
            out.append(_encode(item))
        return out
    if t==TYPE_DICTIONARY:
        var out:Dictionary={}
        for key in value.keys():
            out[str(key)]=_encode(value[key])
        return out
    return value

func _decode(value):
    var t:=typeof(value)
    if t==TYPE_ARRAY:
        var out:Array=[]
        for item in value:
            out.append(_decode(item))
        return out
    if t==TYPE_DICTIONARY:
        if value.get("__type","")=="Vector2":
            return Vector2(float(value.get("x",0)),float(value.get("y",0)))
        if value.get("__type","")=="Color":
            return Color(float(value.get("r",1)),float(value.get("g",1)),float(value.get("b",1)),float(value.get("a",1)))
        var out:Dictionary={}
        for key in value.keys():
            out[key]=_decode(value[key])
        return out
    return value
