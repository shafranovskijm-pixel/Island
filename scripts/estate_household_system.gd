extends RefCounted

var estates:Array=[]
var events:Array=[]
var next_id:=1
var last_day:=-1

func create_estate(owner:String,pos:Vector2,name:String="Усадьба героя")->Dictionary:
    var e={"id":"estate_%d"%next_id,"owner":owner,"name":name,"pos":pos,"pieces":[],"staff":[],"residents":[],"treasury":0.0,"food_store":0.0,"comfort":5.0,"security":0.0,"prestige":0.0,"rooms":{"bedroom":0,"kitchen":0,"hall":0,"tower":0,"cellar":0},"active":true}
    next_id+=1;estates.append(e);events.append({"type":"estate","text":"Основано владение: %s."%name});return e

func player_estate()->Dictionary:
    for e in estates:
        if str(e.get("owner",""))=="player":return e
    return {}

func add_piece(estate_id:String,piece:String)->Dictionary:
    var idx=_estate_index(estate_id);if idx<0:return {"ok":false,"reason":"Владение не найдено."}
    var e=estates[idx];e["pieces"].append(piece)
    match piece:
        "stone_wall":e["security"]+=2;e["prestige"]+=1
        "wood_wall":e["security"]+=1
        "wooden_door":e["security"]+=1
        "simple_bed":e["comfort"]+=2;e["rooms"]["bedroom"]+=1
        "wood_table","wood_chair":e["comfort"]+=0.5
        "occult_altar":e["prestige"]+=1
    estates[idx]=e;events.append({"type":"estate_build","text":"Во владении построено: %s."%piece});return {"ok":true,"estate":e}

func hire(npc:Dictionary,role:String,wage:float)->Dictionary:
    var idx=_player_estate_index();if idx<0:return {"ok":false,"reason":"Сначала нужно основать владение."}
    if not bool(npc.get("alive",true)):return {"ok":false,"reason":"Этот человек недоступен."}
    if float(npc.get("rel",0))<-1:return {"ok":false,"reason":"Он тебе не доверяет."}
    var e=estates[idx];var id=str(npc.get("id",""))
    for s in e["staff"]:
        if str(s.get("npc_id",""))==id:return {"ok":false,"reason":"Этот человек уже служит у тебя."}
    e["staff"].append({"npc_id":id,"role":role,"wage":wage,"loyalty":clampf(45.0+float(npc.get("rel",0))*5.0,5.0,95.0)})
    if id not in e["residents"]:e["residents"].append(id)
    estates[idx]=e
    npc["household_role"]=role;npc["home_location"]="player_estate";npc["target"]=e["pos"]
    events.append({"type":"hire","text":"%s нанят: %s."%[npc.get("name","Житель"),role]})
    return {"ok":true,"estate":e}

func invite_resident(npc:Dictionary)->Dictionary:
    var idx=_player_estate_index();if idx<0:return {"ok":false,"reason":"Нет собственного дома."}
    if int(npc.get("rel",0))<2:return {"ok":false,"reason":"Для совместной жизни нужны более близкие отношения."}
    var e=estates[idx];var id=str(npc.get("id",""));if id not in e["residents"]:e["residents"].append(id)
    npc["home_location"]="player_estate";npc["target"]=e["pos"];estates[idx]=e
    events.append({"type":"resident","text":"%s поселился во владении героя."%npc.get("name","Житель")});return {"ok":true}

func tick(npcs:Array,day:int,hour:float):
    if day==last_day or hour<8.0:return
    last_day=day
    for ei in estates.size():
        var e=estates[ei];if not bool(e.get("active",true)):continue
        var wage_bill:=0.0;var service:=0.0
        var kept:Array=[]
        for s in e["staff"]:
            var ni=_npc_index(npcs,str(s["npc_id"]));if ni<0 or not bool(npcs[ni].get("alive",true)):continue
            kept.append(s);wage_bill+=float(s["wage"]);service+=float(s.get("loyalty",40))/100.0
            npcs[ni]["target"]=e["pos"]+Vector2(randf_range(-80,80),randf_range(-60,60))
        e["staff"]=kept
        if float(e["treasury"])>=wage_bill:
            e["treasury"]-=wage_bill
            for s in e["staff"]:
                var ni=_npc_index(npcs,str(s["npc_id"]));if ni>=0:npcs[ni]["money"]=int(npcs[ni].get("money",0))+int(round(float(s["wage"])))
        elif wage_bill>0:
            for s in e["staff"]:s["loyalty"]=maxf(0,float(s.get("loyalty",40))-8)
            events.append({"type":"household_debt","text":"Слугам во владении задерживают жалование."})
        e["comfort"]=clampf(float(e["comfort"])+service*.05,0,100)
        e["security"]=clampf(float(e["security"])+_guards(e)*.03,0,100)
        estates[ei]=e

func deposit_coins(amount:float)->Dictionary:
    var idx=_player_estate_index();if idx<0:return {"ok":false,"reason":"Нет владения."}
    estates[idx]["treasury"]=float(estates[idx].get("treasury",0))+amount;return {"ok":true}

func _guards(e:Dictionary)->int:
    var c=0
    for s in e["staff"]:
        if str(s.get("role","")) in ["guard","captain"]:c+=1
    return c

func _player_estate_index()->int:
    for i in estates.size():
        if str(estates[i].get("owner",""))=="player":return i
    return -1
func _estate_index(id:String)->int:
    for i in estates.size():
        if str(estates[i].get("id",""))==id:return i
    return -1
func _npc_index(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"estates":estates,"next_id":next_id,"last_day":last_day}
func restore(data:Dictionary):
    var e=data.get("estates",[]);if typeof(e)==TYPE_ARRAY:estates=e
    next_id=int(data.get("next_id",next_id));last_day=int(data.get("last_day",last_day))
