extends RefCounted

var rooms:Array=[]
var door_locks:Dictionary={}
var keys:Dictionary={}
var guard_posts:Array=[]
var intruders:Array=[]
var events:Array=[]
var next_room_id:=1
var next_key_id:=1
var last_intrusion_day:=-1

func rebuild_from_castle(estate:Dictionary,placed:Array):
    if estate.is_empty():return
    var estate_id=str(estate.get("id",""))
    var beds:Array=[];var doors:Array=[];var tables:Array=[];var altars:Array=[]
    for p in placed:
        if str(p.get("estate_id",""))!=estate_id:continue
        match str(p.get("piece","")):
            "simple_bed":beds.append(p)
            "wooden_door":doors.append(p)
            "wood_table":tables.append(p)
            "occult_altar":altars.append(p)
    _sync_bedrooms(estate_id,beds)
    _sync_common_rooms(estate_id,tables,altars)
    for d in doors:
        var did=str(d.get("id",""))
        if not door_locks.has(did):door_locks[did]={"locked":false,"owner":"player","key_id":"","access":["player"]}

func _sync_bedrooms(estate_id:String,beds:Array):
    var existing:Dictionary={}
    for r in rooms:
        if str(r.get("estate_id",""))==estate_id and str(r.get("type",""))=="bedroom":existing[str(r.get("anchor_piece_id",""))]=r
    for bed in beds:
        var bid=str(bed.get("id",""));if existing.has(bid):continue
        rooms.append({"id":"room_%d"%next_room_id,"estate_id":estate_id,"type":"bedroom","name":"Спальня %d"%next_room_id,"anchor_piece_id":bid,"pos":bed.get("pos",Vector2.ZERO),"owner_npc_id":"","private":true,"comfort":2.0})
        next_room_id+=1

func _sync_common_rooms(estate_id:String,tables:Array,altars:Array):
    if not tables.is_empty() and _room_type_count(estate_id,"hall")==0:
        rooms.append({"id":"room_%d"%next_room_id,"estate_id":estate_id,"type":"hall","name":"Общий зал","anchor_piece_id":tables[0].get("id",""),"pos":tables[0].get("pos",Vector2.ZERO),"owner_npc_id":"","private":false,"comfort":3.0});next_room_id+=1
    if not altars.is_empty() and _room_type_count(estate_id,"occult_chamber")==0:
        rooms.append({"id":"room_%d"%next_room_id,"estate_id":estate_id,"type":"occult_chamber","name":"Тайная ритуальная комната","anchor_piece_id":altars[0].get("id",""),"pos":altars[0].get("pos",Vector2.ZERO),"owner_npc_id":"player","private":true,"comfort":0.0});next_room_id+=1

func _room_type_count(estate_id:String,type:String)->int:
    var c=0
    for r in rooms:
        if str(r.get("estate_id",""))==estate_id and str(r.get("type",""))==type:c+=1
    return c

func assign_bedroom(npc_id:String)->Dictionary:
    for i in rooms.size():
        if str(rooms[i].get("type",""))!="bedroom":continue
        if str(rooms[i].get("owner_npc_id",""))!="":continue
        rooms[i]["owner_npc_id"]=npc_id
        events.append({"type":"room_assign","text":"Для жителя назначена личная спальня."})
        return {"ok":true,"room":rooms[i]}
    return {"ok":false,"reason":"Нет свободной спальни. Поставь ещё кровать."}

func unassign_room(npc_id:String):
    for i in rooms.size():
        if str(rooms[i].get("owner_npc_id",""))==npc_id:rooms[i]["owner_npc_id"]=""

func create_key_for_nearest_door(player_pos:Vector2,placed:Array)->Dictionary:
    var door=_nearest_piece(player_pos,placed,"wooden_door",80.0)
    if door.is_empty():return {"ok":false,"reason":"Рядом нет двери."}
    var did=str(door.get("id",""));if not door_locks.has(did):door_locks[did]={"locked":false,"owner":"player","key_id":"","access":["player"]}
    if str(door_locks[did].get("key_id",""))!="":return {"ok":false,"reason":"Для этой двери уже существует ключ."}
    var key_id="estate_key_%d"%next_key_id;next_key_id+=1
    door_locks[did]["key_id"]=key_id;door_locks[did]["locked"]=true
    keys[key_id]={"id":key_id,"door_id":did,"name":"ключ от двери владения","owner":"player"}
    events.append({"type":"lock","text":"На дверь установлен замок и изготовлен ключ."})
    return {"ok":true,"key":keys[key_id],"door_id":did}

func toggle_nearest_door_lock(player_pos:Vector2,placed:Array,inventory:Array)->Dictionary:
    var door=_nearest_piece(player_pos,placed,"wooden_door",80.0)
    if door.is_empty():return {"ok":false,"reason":"Рядом нет двери."}
    var did=str(door.get("id",""));if not door_locks.has(did):return {"ok":false,"reason":"На двери нет замка."}
    var key_id=str(door_locks[did].get("key_id",""))
    if key_id!="" and not _inventory_has_key(inventory,key_id):return {"ok":false,"reason":"Нужен подходящий ключ."}
    door_locks[did]["locked"]=not bool(door_locks[did].get("locked",false))
    return {"ok":true,"locked":door_locks[did]["locked"]}

func add_guard_post(pos:Vector2,npc_id:String)->Dictionary:
    for p in guard_posts:
        if str(p.get("npc_id",""))==npc_id:p["pos"]=pos;return {"ok":true,"post":p}
    var post={"id":"guard_post_%d"%(guard_posts.size()+1),"pos":pos,"npc_id":npc_id,"alert":false};guard_posts.append(post)
    events.append({"type":"guard_post","text":"Охраннику назначен постоянный пост."});return {"ok":true,"post":post}

func tick(npcs:Array,estate:Dictionary,placed:Array,day:int,hour:float,crime_pressure:float):
    if estate.is_empty():return
    rebuild_from_castle(estate,placed)
    _run_guard_posts(npcs)
    if day!=last_intrusion_day and hour>=1.0 and hour<=4.5:
        last_intrusion_day=day
        var security=float(estate.get("security",0))+float(guard_posts.size())*8.0+_locked_door_count()*3.0
        var chance=clampf(0.05+crime_pressure/180.0-security/240.0,0.01,0.55)
        if randf()<chance:_spawn_intrusion(npcs,estate,day,hour,security)
    _resolve_intruders(npcs,estate,day,hour)

func _run_guard_posts(npcs:Array):
    for post in guard_posts:
        var idx=_npc_index(npcs,str(post.get("npc_id","")));if idx<0:continue
        if not bool(npcs[idx].get("alive",true)):continue
        npcs[idx]["target"]=post.get("pos",npcs[idx].get("pos",Vector2.ZERO))
        npcs[idx]["guarding_estate"]=true

func _spawn_intrusion(npcs:Array,estate:Dictionary,day:int,hour:float,security:float):
    var candidates:Array=[]
    for n in npcs:
        if not bool(n.get("alive",true)):continue
        var role=str(n.get("role","")).to_lower();var vice=str(n.get("vice","")).to_lower()
        if "вор" in role or "банд" in role or "краж" in vice or str(n.get("faction",""))=="underworld":candidates.append(str(n.get("id","")))
    var id="unknown_intruder" if candidates.is_empty() else str(candidates.pick_random())
    intruders.append({"npc_id":id,"estate_id":estate.get("id",""),"stage":"approaching","day":day,"hour":hour,"detected":false,"loot":0.0,"resolved":false})
    events.append({"type":"intrusion","text":"Ночью кто-то пытается проникнуть во владение."})

func _resolve_intruders(npcs:Array,estate:Dictionary,day:int,hour:float):
    for intr in intruders:
        if bool(intr.get("resolved",false)):continue
        var guards=_active_guard_count(npcs)
        var locked=_locked_door_count()
        var detect=clampf(0.2+guards*.22+locked*.08,0.1,0.95)
        if randf()<detect:
            intr["detected"]=true;intr["resolved"]=true
            events.append({"type":"intruder_caught","text":"Охрана обнаружила ночного нарушителя."})
        else:
            var treasury=float(estate.get("treasury",0));var stolen=minf(treasury,randf_range(2,10));estate["treasury"]=maxf(0,treasury-stolen);intr["loot"]=stolen;intr["resolved"]=true
            events.append({"type":"burglary","text":"Ночной вор проник внутрь и украл %.0f монет."%stolen})

func private_room_for(npc_id:String)->Dictionary:
    for r in rooms:
        if str(r.get("owner_npc_id",""))==npc_id:return r
    return {}

func _locked_door_count()->int:
    var c=0
    for d in door_locks.values():
        if bool(d.get("locked",false)):c+=1
    return c
func _active_guard_count(npcs:Array)->int:
    var c=0
    for p in guard_posts:
        var idx=_npc_index(npcs,str(p.get("npc_id","")));if idx>=0 and bool(npcs[idx].get("alive",true)):c+=1
    return c
func _inventory_has_key(inventory:Array,key_id:String)->bool:
    for i in inventory:
        if str(i.get("key_id",i.get("id","")))==key_id:return true
    return false
func _nearest_piece(pos:Vector2,placed:Array,type:String,range:float)->Dictionary:
    var best:Dictionary={};var d0=INF
    for p in placed:
        if str(p.get("piece",""))!=type:continue
        var d=pos.distance_to(p.get("pos",Vector2.ZERO));if d<range and d<d0:best=p;d0=d
    return best
func _npc_index(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"rooms":rooms,"door_locks":door_locks,"keys":keys,"guard_posts":guard_posts,"intruders":intruders,"next_room_id":next_room_id,"next_key_id":next_key_id,"last_intrusion_day":last_intrusion_day}
func restore(data:Dictionary):
    var r=data.get("rooms",[]);if typeof(r)==TYPE_ARRAY:rooms=r
    var d=data.get("door_locks",{});if typeof(d)==TYPE_DICTIONARY:door_locks=d
    var k=data.get("keys",{});if typeof(k)==TYPE_DICTIONARY:keys=k
    var g=data.get("guard_posts",[]);if typeof(g)==TYPE_ARRAY:guard_posts=g
    var i=data.get("intruders",[]);if typeof(i)==TYPE_ARRAY:intruders=i
    next_room_id=int(data.get("next_room_id",next_room_id));next_key_id=int(data.get("next_key_id",next_key_id));last_intrusion_day=int(data.get("last_intrusion_day",last_intrusion_day))
