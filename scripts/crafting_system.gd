extends RefCounted

var recipes:={
    "campfire":{"profession":"survival","theory":"foraging","practice":1.0,"location":["wilderness","fisher_cove","slums"],"inputs":{"wood":3.0},"tools":[],"output":{"kind":"structure","name":"костёр"}},
    "simple_meal":{"profession":"cooking","theory":"foraging","practice":1.0,"location":["tavern","player_home","camp"],"inputs":{"food":2.0},"tools":["knife"],"output":{"kind":"food","name":"простая еда","hunger":25}},
    "wooden_crate":{"profession":"carpentry","theory":"construction","practice":2.0,"location":["workshop","market","player_home"],"inputs":{"wood":6.0},"tools":["hammer"],"output":{"kind":"container","name":"деревянный ящик","capacity":8}},
    "repair_kit":{"profession":"crafting","theory":"construction","practice":2.0,"location":["workshop"],"inputs":{"wood":2.0,"tools":1.0},"tools":["hammer"],"output":{"kind":"tool","name":"ремонтный набор"}},
    "fishing_rod":{"profession":"carpentry","theory":"sailing","practice":2.0,"location":["workshop","fisher_cove"],"inputs":{"wood":4.0,"cloth":1.0},"tools":["knife"],"output":{"kind":"tool","name":"удочка","tool_type":"fishing"}},
    "lockpick":{"profession":"thievery","theory":"locks","practice":3.0,"location":["workshop","slums"],"inputs":{"tools":1.0},"tools":["knife"],"output":{"kind":"tool","name":"отмычка","tool_type":"lockpick"}},
    "healing_draught":{"profession":"medicine","theory":"medicine","practice":3.0,"location":["temple","player_home"],"inputs":{"medicine":2.0,"food":1.0},"tools":[],"output":{"kind":"medicine","name":"лечебный отвар","heal":20}},
    "ritual_chalk":{"profession":"occult","theory":"occult","practice":4.0,"location":["occult_lodge","crypt"],"inputs":{"stone":1.0,"cloth":1.0},"tools":[],"output":{"kind":"ritual","name":"ритуальный мел"}}
}

var known_recipes:Dictionary={}
var crafted_count:Dictionary={}
var events:Array=[]

func unlock_from_knowledge(learning):
    for id in recipes.keys():
        var theory=str(recipes[id].get("theory",""))
        if theory=="" or float(learning.theory.get(theory,0))>=1.0:known_recipes[id]=true

func can_craft(id:String,learning,resources:Dictionary,inventory:Array,location_id:String)->Dictionary:
    if not recipes.has(id):return {"ok":false,"reason":"Неизвестный рецепт."}
    unlock_from_knowledge(learning)
    if not bool(known_recipes.get(id,false)):return {"ok":false,"reason":"Ты ещё не знаешь, как это сделать."}
    var r:Dictionary=recipes[id]
    var allowed:Array=r.get("location",[])
    if not allowed.is_empty() and location_id not in allowed:return {"ok":false,"reason":"Здесь нет подходящих условий для работы."}
    var profession=str(r.get("profession",""));var need=float(r.get("practice",0))
    if float(learning.practice.get(profession,0))<need:return {"ok":false,"reason":"Не хватает практического опыта."}
    for key in r["inputs"].keys():
        if float(resources.get(key,0))<float(r["inputs"][key]):return {"ok":false,"reason":"Не хватает ресурса: %s."%key}
    for tool in r.get("tools",[]):
        if not _has_tool(inventory,str(tool)):return {"ok":false,"reason":"Нужен инструмент: %s."%tool}
    return {"ok":true}

func craft(id:String,learning,resources:Dictionary,inventory:Array,location_id:String)->Dictionary:
    var check=can_craft(id,learning,resources,inventory,location_id)
    if not bool(check.get("ok",false)):return check
    var r:Dictionary=recipes[id]
    for key in r["inputs"].keys():resources[key]=float(resources.get(key,0))-float(r["inputs"][key])
    var item:Dictionary=r["output"].duplicate(true)
    item["id"]="crafted_%s_%d"%[id,int(Time.get_ticks_msec())]
    inventory.append(item)
    crafted_count[id]=int(crafted_count.get(id,0))+1
    learning.practice[str(r["profession"])]=float(learning.practice.get(str(r["profession"]),0))+0.4
    events.append({"type":"craft","text":"Создано: %s."%item.get("name",id),"recipe":id})
    return {"ok":true,"item":item}

func _has_tool(inventory:Array,tool:String)->bool:
    for item in inventory:
        if str(item.get("tool_type",""))==tool:return true
        var n=str(item.get("name","")).to_lower()
        if tool=="knife" and "нож" in n:return true
        if tool=="hammer" and "молот" in n:return true
    return false

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out

func serialize()->Dictionary:return {"known_recipes":known_recipes,"crafted_count":crafted_count}
func restore(data:Dictionary):
    var k=data.get("known_recipes",{});if typeof(k)==TYPE_DICTIONARY:known_recipes=k
    var c=data.get("crafted_count",{});if typeof(c)==TYPE_DICTIONARY:crafted_count=c
