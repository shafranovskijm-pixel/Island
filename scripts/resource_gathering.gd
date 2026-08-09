extends RefCounted

var nodes:Array=[]
var events:Array=[]
var next_id:=1
var last_regen_day:=-1

func setup():
    if not nodes.is_empty(): return
    nodes=[
        _node("branches","Сухой валежник",Vector2(1080,860),"wood",26.0,1.4,"","foraging"),
        _node("tree","Сосновая роща",Vector2(1180,930),"wood",55.0,4.0,"axe","woodcutting"),
        _node("loose_stone","Каменная осыпь",Vector2(1110,360),"stone",24.0,1.2,"","foraging"),
        _node("quarry","Каменистый склон",Vector2(1190,315),"stone",48.0,3.0,"pickaxe","mining"),
        _node("herbs","Луговые травы",Vector2(860,370),"herbs",36.0,2.0,"","foraging"),
        _node("fish","Рыбное место",Vector2(390,825),"fish",45.0,3.0,"fishing_rod","fishing"),
        _node("wild_food","Дикие коренья",Vector2(520,700),"food",30.0,2.0,"","foraging")
    ]

func _node(kind:String,name:String,pos:Vector2,resource:String,amount:float,yield_base:float,tool:String,skill:String)->Dictionary:
    var n={"id":"resource_%d"%next_id,"kind":kind,"name":name,"pos":pos,"resource":resource,"amount":amount,"max_amount":amount,"yield":yield_base,"tool":tool,"skill":skill,"last_day":0}
    next_id+=1
    return n

func tick(day:int):
    if day==last_regen_day:return
    last_regen_day=day
    for n in nodes:
        var regen=float(n["max_amount"])*0.04
        if n["kind"] in ["herbs","fish","wild_food","branches","loose_stone"]:regen=float(n["max_amount"])*0.12
        n["amount"]=minf(float(n["max_amount"]),float(n["amount"])+regen)

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
    if needed!="" and not _has_tool(inventory,needed):return {"ok":false,"reason":"Нужен инструмент: %s."%needed}
    var skill=str(node.get("skill",""));var learned=int(knowledge.skill_level(skill)) if knowledge!=null else int(skills.get(skill,0))
    return {"ok":true,"skill":skill,"level":learned}

func gather(node_id:String,inventory:Array,knowledge,skills:Dictionary,day:int,hour:float)->Dictionary:
    var idx=_find(node_id);if idx<0:return {"ok":false,"reason":"Источник не найден."}
    var n:Dictionary=nodes[idx];var chk=can_gather(n,inventory,knowledge,skills)
    if not bool(chk.get("ok",false)):return chk
    var lvl=int(chk.get("level",0));var amount=minf(float(n["amount"]),float(n["yield"])*(1.0+lvl*0.16))
    n["amount"]-=amount;n["last_day"]=day;nodes[idx]=n
    var item={"id":"gathered_%s_%d"%[n["resource"],Time.get_ticks_msec()],"name":_resource_name(str(n["resource"])),"kind":"resource","resource":n["resource"],"quantity":amount,"value":1}
    inventory.append(item)
    if knowledge!=null:knowledge.practice(str(n["skill"]),1.0+amount*.1,"gathering")
    events.append({"day":day,"hour":hour,"type":"gather","text":"Добыто: %s x%.1f."%[item["name"],amount]})
    return {"ok":true,"item":item,"amount":amount,"node":n}

func _has_tool(inventory:Array,tool:String)->bool:
    for item in inventory:
        var tt=str(item.get("tool_type",""))
        if tt==tool:return true
        if tool=="fishing_rod" and tt in ["fishing_rod","fishing"]:return true
        var n=str(item.get("name","")).to_lower()
        if tool=="axe" and "топор" in n:return true
        if tool=="pickaxe" and ("кирк" in n or "кайло" in n):return true
        if tool=="fishing_rod" and "удоч" in n:return true
    return false

func _find(id:String)->int:
    for i in nodes.size():
        if str(nodes[i].get("id",""))==id:return i
    return -1

func _resource_name(id:String)->String:
    return {"wood":"древесина","stone":"камень","herbs":"лечебные травы","fish":"рыба","food":"съедобные коренья"}.get(id,id)

func serialize()->Dictionary:return {"nodes":nodes,"next_id":next_id,"last_regen_day":last_regen_day}
func restore(data:Dictionary):
    var n=data.get("nodes",[]);if typeof(n)==TYPE_ARRAY:nodes=n
    next_id=int(data.get("next_id",next_id));last_regen_day=int(data.get("last_regen_day",last_regen_day))

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
