extends RefCounted

var spawned_objects:Array=[]
var mutations:Array=[]
var next_id:=1

func apply(action:Dictionary,result:Dictionary,world:Dictionary)->Dictionary:
    if not bool(result.get("success",false)):return _failure(action,result)
    var verb=str(action.get("verb",""));var target:Dictionary=action.get("target",{})
    match verb:
        "sever":return _sever(target,result)
        "break":return _break(target,result)
        "burn":return _burn(target,result)
        "steal","take":return {"ok":true,"text":"Ты забираешь %s."%target.get("name","предмет"),"mutation":{"type":"take","target":target.get("id","")}}
        "hide","sneak":return {"ok":true,"text":"Тебе удаётся скрыть свои действия от большинства наблюдателей.","mutation":{"type":"hidden_action"}}
        "climb":return {"ok":true,"text":"Ты успешно добираешься туда, куда пытался залезть.","mutation":{"type":"position_opportunity"}}
        "pick_lock":return _unlock(target)
        "burn":return _burn(target,result)
        "persuade","deceive","threaten":return {"ok":true,"text":"Твои слова производят эффект на %s."%target.get("name","собеседника"),"mutation":{"type":"social","verb":verb,"target":target.get("id","")}}
        "search":return {"ok":true,"text":"Поиск оказался результативным.","mutation":{"type":"search_success"}}
        "throw":return {"ok":true,"text":"Бросок получился.","mutation":{"type":"throw"}}
    return {"ok":true,"text":"Действие удалось.","mutation":{"type":verb}}

func _sever(target:Dictionary,result:Dictionary)->Dictionary:
    var obj={"id":"spawned_%d"%next_id,"name":"голова %s"%target.get("name","неизвестного"),"kind":"body_part","part":"head","former_person":target.get("person_id",target.get("id","")),"recognizable":true,"decay":0.0,"bloody":true,"value":0}
    next_id+=1;spawned_objects.append(obj);mutations.append({"type":"body_part_removed","target":target.get("id",""),"part":"head"})
    return {"ok":true,"text":"Тебе удаётся отделить голову. Теперь это физический предмет мира.","spawn":obj,"mutation":mutations.back()}

func _break(target:Dictionary,result:Dictionary)->Dictionary:
    var m={"type":"broken","target":target.get("id","")};mutations.append(m)
    return {"ok":true,"text":"%s теперь сломан(а)."%target.get("name","Объект"),"mutation":m}

func _burn(target:Dictionary,result:Dictionary)->Dictionary:
    var m={"type":"burning","target":target.get("id","")};mutations.append(m)
    return {"ok":true,"text":"%s загорается. Это может привлечь людей и повредить имущество."%target.get("name","Объект"),"mutation":m}

func _unlock(target:Dictionary)->Dictionary:
    var m={"type":"unlocked","target":target.get("id","")};mutations.append(m)
    return {"ok":true,"text":"Замок поддаётся.","mutation":m}

func _failure(action:Dictionary,result:Dictionary)->Dictionary:
    var verb=str(action.get("verb","action"));var text="Не получилось."
    if bool(result.get("fumble",false)):text="Критический провал: попытка приводит к неприятным последствиям."
    elif int(result.get("margin",0))<=-5:text="Попытка провалилась заметно и шумно."
    return {"ok":false,"text":text,"mutation":{"type":"failed","verb":verb,"severity":abs(int(result.get("margin",0)))}}
