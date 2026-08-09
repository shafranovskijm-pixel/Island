extends RefCounted

var state={"is_vampire":false,"blood":0.0,"vampire_xp":0.0,"abilities":[],"bat_form":false,"sun_exposure":0.0,"turned_by":""}
var events:Array=[]

func can_turn(secrets:Dictionary,npc:Dictionary)->Dictionary:
    if bool(state["is_vampire"]):return {"ok":false,"reason":"Ты уже вампир."}
    if not bool(secrets.get("vampires",false)):return {"ok":false,"reason":"Ты ещё не знаешь, что такое возможно."}
    if str(npc.get("id",""))!="vampire":return {"ok":false,"reason":"Этот человек не способен провести обращение."}
    if int(npc.get("rel",0))<3:return {"ok":false,"reason":"Леди Веспера пока не доверяет тебе настолько."}
    return {"ok":true}

func turn(npc:Dictionary,secrets:Dictionary)->Dictionary:
    var c=can_turn(secrets,npc);if not bool(c.get("ok",false)):return c
    state["is_vampire"]=true;state["blood"]=65.0;state["vampire_xp"]=1.0;state["turned_by"]=str(npc.get("id",""));state["abilities"]=["night_sight"]
    events.append({"type":"vampire_turn","text":"Герой пережил обращение и стал вампиром."});return {"ok":true}

func feed(amount:float):
    if not bool(state["is_vampire"]):return
    state["blood"]=clampf(float(state["blood"])+amount,0,100);state["vampire_xp"]=float(state["vampire_xp"])+amount*.04;_unlock()

func tick(hour:float,delta:float)->Dictionary:
    if not bool(state["is_vampire"]):return {"sun_damage":0.0}
    state["blood"]=maxf(0,float(state["blood"])-delta*.025)
    var sun=hour>=7.0 and hour<=18.5
    var damage=0.0
    if sun and bool(state["bat_form"]):damage=delta*.12
    elif sun:damage=delta*.045
    state["sun_exposure"]=maxf(0,float(state["sun_exposure"])+(damage if sun else -delta*.08))
    return {"sun_damage":damage}

func toggle_bat()->Dictionary:
    if not bool(state["is_vampire"]):return {"ok":false,"reason":"Ты не вампир."}
    if "bat_form" not in state["abilities"]:return {"ok":false,"reason":"Ты ещё не освоил превращение в летучую мышь."}
    state["bat_form"]=not bool(state["bat_form"]);events.append({"type":"bat_form","text":"Герой %s."%("превратился в летучую мышь" if state["bat_form"] else "вернул человеческий облик")});return {"ok":true,"bat_form":state["bat_form"]}

func _unlock():
    var xp=float(state["vampire_xp"])
    if xp>=3 and "blood_sense" not in state["abilities"]:state["abilities"].append("blood_sense")
    if xp>=6 and "hypnosis" not in state["abilities"]:state["abilities"].append("hypnosis")
    if xp>=10 and "bat_form" not in state["abilities"]:state["abilities"].append("bat_form")

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return state.duplicate(true)
func restore(data:Dictionary):
    for key in state.keys():
        if data.has(key):state[key]=data[key]
