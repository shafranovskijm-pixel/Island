extends RefCounted

var delivered:Dictionary={}
var events:Array=[]

func collect_for_npc(npc:Dictionary,world:Dictionary)->Array:
    var offers:Array=[];var id=str(npc.get("id",""));var role=str(npc.get("role","")).to_lower()
    if float(world.get("hunger_pressure",0))>35 and ("торгов" in role or id=="marek"):
        offers.append(_offer("food_shortage",id,"Еды становится мало. В порту платят тем, кто помогает с поставками.","port"))
    if bool(world.get("vampires_known",false)) and ("жрец" in role or id=="undertaker"):
        offers.append(_offer("graveyard_fear",id,"По ночам на кладбище снова видели движение между могилами.","graveyard"))
    if int(world.get("wanted",0))>0 and ("страж" in role or id=="captain_guard"):
        offers.append(_offer("law_attention",id,"Стража ищет человека с твоими приметами. Лучше объясниться или исчезнуть.","guard_barracks"))
    if str(world.get("location",""))=="slums" and id=="smuggler":
        offers.append(_offer("smuggler_route",id,"Сегодня ночью один из складских проходов в порту почти не охраняют.","port"))
    if int(world.get("influence",0))>=3 and id in ["chancellor","queen"]:
        offers.append(_offer("court_need",id,"При дворе сейчас ищут людей, которые умеют решать вопросы без лишнего шума.","castle"))
    var out:Array=[]
    for o in offers:
        var key=str(o["id"])+":"+id
        if not delivered.has(key):out.append(o)
    return out

func mark_delivered(offer:Dictionary,npc_id:String):
    delivered[str(offer["id"])+":"+npc_id]=true
    events.append({"type":"opportunity_delivered","npc":npc_id,"offer":offer})

func _offer(id:String,source:String,text:String,location:String)->Dictionary:
    return {"id":id,"source":source,"text":text,"location":location}

func serialize()->Dictionary:return {"delivered":delivered}
func restore(data:Dictionary):
    var d=data.get("delivered",{});if typeof(d)==TYPE_DICTIONARY:delivered=d
