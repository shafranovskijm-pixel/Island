extends RefCounted

var nodes:Array=[]
var events:Array=[]
var next_id:=1
var last_regen_day:=-1

func setup():
    var defs=[
        ["branches","Сухой валежник",Vector2(1080,860),"wood",26.0,1.4,"","foraging"],
        ["tree","Сосновая роща",Vector2(1180,930),"wood",55.0,4.0,"axe","woodcutting"],
        ["loose_stone","Каменная осыпь",Vector2(1110,360),"stone",24.0,1.2,"","foraging"],
        ["quarry","Каменистый склон",Vector2(1190,315),"stone",48.0,3.0,"pickaxe","mining"],
        ["herbs","Луговые травы",Vector2(860,370),"herbs",36.0,2.0,"","foraging"],
        ["reeds","Заросли тростника",Vector2(560,785),"fiber",42.0,2.2,"","foraging"],
        ["clay_bed","Глинистый берег",Vector2(470,740),"clay",36.0,2.0,"shovel","mining"],
        ["sand_bank","Песчаная отмель",Vector2(300,870),"sand",50.0,2.0,"","foraging"],
        ["coal_seam","Угольный пласт",Vector2(1260,350),"coal",34.0,2.4,"pickaxe","mining"],
        ["iron_vein","Железная жила",Vector2(1325,290),"iron_ore",30.0,2.0,"pickaxe","mining"],
        ["copper_vein","Медная жила",Vector2(1285,245),"copper_ore",32.0,2.2,"pickaxe","mining"],
        ["fish","Рыбное место",Vector2(390,825),"fish",45.0,3.0,"fishing_rod","fishing"],
        ["wild_food","Дикие коренья",Vector2(520,700),"food",30.0,2.0,"","foraging"]
    ]
    for d in defs:
        _ensure_node(str(d[0]),str(d[1]),d[2],str(d[3]),float(d[4]),float(d[5]),str(d[6]),str(d[7]))

func _ensure_node(kind:String,name:String,pos:Vector2,resource:String,amount:float,yield_base:float,tool:String,skill:String):
    for n in nodes:
        if str(n.get("kind",""))==kind:return
    nodes.append(_node(kind,name,pos,resource,amount,yield_base,tool,skill))

func _node(kind:String,name:String,pos:Vector2,resource:String,amount:float,yield_base:float,tool:String,skill:String)->Dictionary:
    var n={"id":"resource_%s_%d"%[kind,next_id],"kind":kind,"name":name,"pos":pos,"resource":resource,"amount":amount,"max_amount":amount,"yield":yield_base,"tool":tool,"skill":skill,"last_day":0}
    next_id+=1
    return n

func tick(day:int):
    if day==last_regen_day:return
    last_regen_day=day
    for n in nodes:
        var kind=str(n.get("kind",""))
        var rate=0.04
        if kind in ["herbs","fish","wild_food","branches","loose_stone","reeds"]:rate=0.12
        elif kind in ["clay_bed","sand_bank"]:rate=0.07
        elif kind in ["coal_seam","iron_vein","copper_vein","quarry"]:rate=0.018
        n["amount"]=minf(float(n["max_amount"]),float(n["amount"])+float(n["max_amount"])*rate)

func nearby(pos:Vector2,range:float=110.0)->Dictionary:
    var best:Dictionary={};var d0:=INF
    for n in nodes:
        if float(n.get("amount",0))<=0:continue
        var d=pos.distance_to(n["pos"])
        if d<=range and d<d0:best=n;d0=d
    return best

func can_gather(node:Dictionary,inventory:Array,knowledge,skills:Dictionary)->Dictionary:
    if node.is_empty():return {"ok":false,"reason":"Рядом нет подходящего ресурса."}
    if float(node.get("amount",0))<=0:return {"ok":false,"reason":"Этот источник пока истощён."}
    var needed=str(node.get("tool",""))
    if needed!="" and _find_tool_index(inventory,needed)<0:return {"ok":false,"reason":"Нужен инструмент: %s."%needed}
    var skill=str(node.get("skill",""));var learned=int(knowledge.effective_bonus(skill)) if knowledge!=null else int(skills.get(skill,0))
    return {"ok":true,"skill":skill,"level":learned,"tool":needed}

func gather(node_id:String,inventory:Array,knowledge,skills:Dictionary,day:int,hour:float)->Dictionary:
    var idx=_find(node_id);if idx<0:return {"ok":false,"reason":"Источник не найден."}
    var n:Dictionary=nodes[idx];var chk=can_gather(n,inventory,knowledge,skills)
    if not bool(chk.get("ok",false)):return chk
    var lvl=int(chk.get("level",0));var amount=minf(float(n["amount"]),float(n["yield"])*(1.0+lvl*0.16))
    n["amount"]-=amount;n["last_day"]=day;nodes[idx]=n
    var item={"id":"gathered_%s_%d"%[n["resource"],Time.get_ticks_usec()],"name":_resource_name(str(n["resource"])),"kind":"resource","resource":n["resource"],"quantity":amount,"value":1}
    _add_resource_stack(inventory,item)
    if knowledge!=null:knowledge.practice(str(n["skill"]),1.0+amount*.1,day,hour)
    var broken=""
    if str(chk.get("tool",""))!="":broken=_damage_tool(inventory,str(chk["tool"]),1.0)
    events.append({"day":day,"hour":hour,"type":"gather","text":"Добыто: %s x%.1f."%[item["name"],amount]})
    if broken!="":events.append({"day":day,"hour":hour,"type":"tool_break","text":"Во время добычи сломался инструмент: %s."%broken})
    return {"ok":true,"item":item,"amount":amount,"node":n,"broken_tool":broken}

func _add_resource_stack(inventory:Array,item:Dictionary):
    for existing in inventory:
        if str(existing.get("kind",""))=="resource" and str(existing.get("resource",""))==str(item.get("resource","")):
            existing["quantity"]=float(existing.get("quantity",1.0))+float(item.get("quantity",1.0))
            return
    inventory.append(item)

func _find_tool_index(inventory:Array,tool:String)->int:
    for i in inventory.size():
        var item:Dictionary=inventory[i]
        if float(item.get("durability",1.0))<=0.0:continue
        var tt=str(item.get("tool_type",""))
        if tt==tool:return i
        if tool=="fishing_rod" and tt in ["fishing_rod","fishing"]:return i
        var n=str(item.get("name","")).to_lower()
        if tool=="axe" and "топор" in n:return i
        if tool=="pickaxe" and ("кирк" in n or "кайло" in n):return i
        if tool=="shovel" and "лопат" in n:return i
        if tool=="fishing_rod" and "удоч" in n:return i
    return -1

func _damage_tool(inventory:Array,tool:String,amount:float)->String:
    var idx=_find_tool_index(inventory,tool)
    if idx<0 or not inventory[idx].has("durability"):return ""
    inventory[idx]["durability"]=float(inventory[idx]["durability"])-amount
    if float(inventory[idx]["durability"])<=0.0:
        var name=str(inventory[idx].get("name",tool));inventory.remove_at(idx);return name
    return ""

func _find(id:String)->int:
    for i in nodes.size():
        if str(nodes[i].get("id",""))==id:return i
    return -1

func _resource_name(id:String)->String:
    return {
        "wood":"древесина","stone":"камень","herbs":"лечебные травы","fiber":"растительное волокно",
        "clay":"глина","sand":"песок","coal":"уголь","iron_ore":"железная руда","copper_ore":"медная руда",
        "fish":"рыба","food":"съедобные коренья"
    }.get(id,id)

func serialize()->Dictionary:return {"nodes":nodes,"next_id":next_id,"last_regen_day":last_regen_day}
func restore(data:Dictionary):
    var n=data.get("nodes",[]);if typeof(n)==TYPE_ARRAY:nodes=n
    next_id=int(data.get("next_id",next_id));last_regen_day=int(data.get("last_regen_day",last_regen_day))

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
