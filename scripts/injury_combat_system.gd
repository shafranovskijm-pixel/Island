extends RefCounted

var actor_state:Dictionary={}
var events:Array=[]

func ensure(id:String):
    if not actor_state.has(id):actor_state[id]={"hp":100.0,"max_hp":100.0,"stamina":100.0,"bleeding":0.0,"pain":0.0,"unconscious":false,"injuries":[],"armor":0.0}

func attack(attacker:Dictionary,target:Dictionary,weapon:Dictionary,dice,skill:int=0)->Dictionary:
    var aid=str(attacker.get("id","player"));var tid=str(target.get("id",""));ensure(aid);ensure(tid)
    if bool(actor_state[aid]["unconscious"]):return {"ok":false,"reason":"Нападающий без сознания."}
    var attack_bonus=skill+int(attacker.get("combat_bonus",0));var defense=10+int(target.get("defense",0))+int(actor_state[tid].get("armor",0))
    var roll=dice.check(attack_bonus,0,defense,0)
    actor_state[aid]["stamina"]=maxf(0,float(actor_state[aid]["stamina"])-6)
    if not bool(roll.get("success",false)):
        events.append({"type":"combat_miss","text":"Атака не достигает цели."});return {"ok":true,"hit":false,"roll":roll}
    var base=float(weapon.get("damage",3.0));var damage=base+maxf(0,float(roll.get("margin",0))*.35)
    if bool(roll.get("critical",false)):damage*=1.7
    damage=maxf(1,damage-float(actor_state[tid].get("armor",0))*.45)
    actor_state[tid]["hp"]=maxf(0,float(actor_state[tid]["hp"])-damage)
    actor_state[tid]["pain"]=minf(100,float(actor_state[tid]["pain"])+damage*.7)
    var injury=_injury_for(weapon,damage,bool(roll.get("critical",false)))
    if not injury.is_empty():actor_state[tid]["injuries"].append(injury)
    if str(injury.get("type","")) in ["cut","stab","severe_cut"]:actor_state[tid]["bleeding"]=minf(30,float(actor_state[tid]["bleeding"])+damage*.12)
    if float(actor_state[tid]["hp"])<=0 or float(actor_state[tid]["pain"])>=90:actor_state[tid]["unconscious"]=true
    events.append({"type":"combat_hit","text":"%s получает %.1f урона."%[target.get("name","Цель"),damage]})
    return {"ok":true,"hit":true,"damage":damage,"injury":injury,"roll":roll,"unconscious":actor_state[tid]["unconscious"]}

func brawl(attacker:Dictionary,target:Dictionary,dice,skill:int=0)->Dictionary:
    return attack(attacker,target,{"name":"кулак","damage":3.0,"weapon_type":"blunt"},dice,skill)

func tick(delta:float):
    for id in actor_state.keys():
        var s=actor_state[id];var bleed=float(s.get("bleeding",0))
        if bleed>0:
            s["hp"]=maxf(0,float(s["hp"])-bleed*delta*.025);s["bleeding"]=maxf(0,bleed-delta*.006)
            if float(s["hp"])<=0:s["unconscious"]=true
        s["stamina"]=minf(float(s["max_hp"]),float(s["stamina"])+delta*.6);actor_state[id]=s

func bandage(id:String)->Dictionary:
    ensure(id);actor_state[id]["bleeding"]=maxf(0,float(actor_state[id]["bleeding"])-12);events.append({"type":"treatment","text":"Кровотечение перевязано."});return {"ok":true}

func _injury_for(weapon:Dictionary,damage:float,critical:bool)->Dictionary:
    var wt=str(weapon.get("weapon_type",weapon.get("tool_type","blunt")))
    if damage<5 and not critical:return {}
    if wt in ["knife","blade","sword"]:return {"type":"severe_cut" if critical else "cut","severity":damage}
    if wt in ["spear","glass_shard"]:return {"type":"stab","severity":damage}
    return {"type":"bruise" if damage<10 else "fracture","severity":damage}

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"actor_state":actor_state}
func restore(data:Dictionary):
    var a=data.get("actor_state",{});if typeof(a)==TYPE_DICTIONARY:actor_state=a
