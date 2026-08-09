extends RefCounted
var animals:Array=[]
var events:Array=[]
var next_id:=1
var last_spawn_day:=-1
func setup():
    _spawn("dog","бродячая собака",Vector2(650,610),35)
    _spawn("rat","крыса",Vector2(770,620),8)
    _spawn("boar","кабан",Vector2(1030,880),70)
    _spawn("deer","олень",Vector2(1120,820),45)
    _spawn("horse","лошадь",Vector2(900,520),80)
func tick(delta:float,day:int,player_pos:Vector2):
    if day!=last_spawn_day:
        last_spawn_day=day
        if _count("rat")<4 and randf()<.4:_spawn("rat","крыса",Vector2(randf_range(600,850),randf_range(560,700)),8)
    for a in animals:
        if not bool(a.get("alive",true)):continue
        if bool(a.get("tamed",false)) and str(a.get("owner",""))=="player":
            if a["pos"].distance_to(player_pos)>55:a["pos"]+=a["pos"].direction_to(player_pos)*delta*35
        elif randf()<delta*.18:a["target"]=a["pos"]+Vector2(randf_range(-120,120),randf_range(-120,120))
        if a.has("target"):a["pos"]+=a["pos"].direction_to(a["target"])*delta*12
func tame_near(pos:Vector2,food_available:bool,charm:int)->Dictionary:
    var i=_nearest(pos,85);if i<0:return {"ok":false,"reason":"Рядом нет животного."}
    var a=animals[i];if bool(a.get("tamed",false)):return {"ok":false,"reason":"Животное уже приручено."}
    if str(a["species"]) not in ["dog","horse"]:return {"ok":false,"reason":"Это дикое животное нельзя приручить таким способом."}
    if not food_available:return {"ok":false,"reason":"Нужна еда, чтобы заслужить доверие."}
    var success=randf()<clampf(.25+charm*.05,.2,.85)
    if success:a["tamed"]=true;a["owner"]="player";a["bond"]=30;animals[i]=a;events.append({"type":"animal_tamed","text":"%s теперь доверяет герою."%a["name"]})
    return {"ok":true,"success":success,"animal":a}
func hunt_near(pos:Vector2,skill:int)->Dictionary:
    var i=_nearest_wild(pos,105);if i<0:return {"ok":false,"reason":"Рядом нет подходящей добычи."}
    var a=animals[i];var chance=clampf(.35+skill*.05-(.18 if str(a["species"])=="boar" else 0),.15,.9);var success=randf()<chance
    if success:
        a["hp"]=0;a["alive"]=false;animals[i]=a;var meat={"boar":7.0,"deer":6.0,"rat":.5}.get(str(a["species"]),2.0);events.append({"type":"hunt","text":"Добыто животное: %s."%a["name"]});return {"ok":true,"success":true,"meat":meat,"animal":a}
    if str(a["species"])=="boar":events.append({"type":"animal_attack","text":"Раненый кабан бросается на охотника."})
    return {"ok":true,"success":false,"animal":a}
func _spawn(species:String,name:String,pos:Vector2,hp:float):animals.append({"id":"animal_%d"%next_id,"species":species,"name":name,"pos":pos,"hp":hp,"alive":true,"tamed":false,"owner":"","bond":0});next_id+=1
func _nearest(pos:Vector2,r:float)->int:
    var best=-1;var d0=INF
    for i in animals.size():
        if not bool(animals[i].get("alive",true)):continue
        var d=pos.distance_to(animals[i]["pos"]);if d<r and d<d0:best=i;d0=d
    return best
func _nearest_wild(pos:Vector2,r:float)->int:
    var best=-1;var d0=INF
    for i in animals.size():
        var a=animals[i];if not bool(a.get("alive",true)) or bool(a.get("tamed",false)) or str(a["species"]) in ["dog","horse"]:continue
        var d=pos.distance_to(a["pos"]);if d<r and d<d0:best=i;d0=d
    return best
func _count(species:String)->int:
    var c=0
    for a in animals:
        if bool(a.get("alive",true)) and str(a.get("species",""))==species:c+=1
    return c
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"animals":animals,"next_id":next_id,"last_spawn_day":last_spawn_day}
func restore(data:Dictionary):
    var a=data.get("animals",[]);if typeof(a)==TYPE_ARRAY:animals=a
    next_id=int(data.get("next_id",next_id));last_spawn_day=int(data.get("last_spawn_day",last_spawn_day))
