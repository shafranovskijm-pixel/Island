extends RefCounted

var carried_body:=""
var bound:Dictionary={}
var searched:Dictionary={}
var events:Array=[]

func can_interact(npc:Dictionary,combat)->bool:
    var id=str(npc.get("id",""));combat.ensure(id)
    return bool(combat.actor_state[id].get("unconscious",false)) or not bool(npc.get("alive",true))

func search_body(npc:Dictionary,combat,player_inventory:Array)->Dictionary:
    if not can_interact(npc,combat):return {"ok":false,"reason":"Человек в сознании и не позволит себя обыскивать."}
    var id=str(npc.get("id",""));if bool(searched.get(id,false)):return {"ok":false,"reason":"Ты уже тщательно его обыскал."}
    searched[id]=true
    var found:Array=[]
    var money=int(npc.get("money",0));if money>0:
        var take=mini(money,randi_range(1,maxi(1,money)));npc["money"]=money-take;found.append({"kind":"coins","amount":take})
    var gear:Array=npc.get("equipment",[])
    if not gear.is_empty():
        var item=gear.pop_back();player_inventory.append(item);npc["equipment"]=gear;found.append(item)
    events.append({"type":"body_search","text":"Герой обыскал %s."%npc.get("name","человека")});return {"ok":true,"found":found}

func bind_body(npc:Dictionary,combat,inventory:Array)->Dictionary:
    if not can_interact(npc,combat):return {"ok":false,"reason":"Сначала нужно обездвижить человека."}
    var rope_idx=_rope_index(inventory);if rope_idx<0:return {"ok":false,"reason":"Нужна верёвка."}
    _consume_one(inventory,rope_idx);var id=str(npc.get("id",""));bound[id]=true;npc["bound"]=true
    events.append({"type":"body_bind","text":"%s связан."%npc.get("name","Человек")});return {"ok":true}

func carry(npc:Dictionary,combat)->Dictionary:
    if carried_body!="":return {"ok":false,"reason":"Ты уже кого-то несёшь."}
    if not can_interact(npc,combat):return {"ok":false,"reason":"Нельзя просто поднять человека, пока он сопротивляется."}
    carried_body=str(npc.get("id",""));npc["carried_by"]="player";events.append({"type":"body_carry","text":"Герой поднял %s."%npc.get("name","человека")});return {"ok":true}

func drop(npcs:Array,pos:Vector2)->Dictionary:
    if carried_body=="":return {"ok":false,"reason":"Ты никого не несёшь."}
    for n in npcs:
        if str(n.get("id",""))==carried_body:n["pos"]=pos;n["carried_by"]="";break
    var id=carried_body;carried_body="";events.append({"type":"body_drop","text":"Тело опущено на землю."});return {"ok":true,"npc_id":id}

func stabilize(npc:Dictionary,combat,inventory:Array)->Dictionary:
    var id=str(npc.get("id",""));combat.ensure(id);var state=combat.actor_state[id]
    if float(state.get("bleeding",0))<=0:return {"ok":false,"reason":"Сильного кровотечения нет."}
    var bandage=_bandage_index(inventory);if bandage<0:return {"ok":false,"reason":"Нужна повязка."}
    _consume_one(inventory,bandage);combat.bandage(id);state=combat.actor_state[id];state["pain"]=maxf(0,float(state["pain"])-5);combat.actor_state[id]=state
    events.append({"type":"rescue","text":"Герой остановил кровотечение у %s."%npc.get("name","раненого")});return {"ok":true}

func update_carried(npcs:Array,player_pos:Vector2):
    if carried_body=="":return
    for n in npcs:
        if str(n.get("id",""))==carried_body:n["pos"]=player_pos+Vector2(-20,18);return

func _rope_index(inventory:Array)->int:
    for i in inventory.size():
        if str(inventory[i].get("resource",""))=="rope" or "верёв" in str(inventory[i].get("name","")).to_lower():return i
    return -1
func _bandage_index(inventory:Array)->int:
    for i in inventory.size():
        if str(inventory[i].get("subtype",""))=="bandage" or "повяз" in str(inventory[i].get("name","")).to_lower():return i
    return -1
func _consume_one(inventory:Array,i:int):
    var q=float(inventory[i].get("quantity",1));if q>1:inventory[i]["quantity"]=q-1
    else:inventory.remove_at(i)
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"carried_body":carried_body,"bound":bound,"searched":searched}
func restore(data:Dictionary):
    carried_body=str(data.get("carried_body",""));var b=data.get("bound",{});if typeof(b)==TYPE_DICTIONARY:bound=b
    var s=data.get("searched",{});if typeof(s)==TYPE_DICTIONARY:searched=s
