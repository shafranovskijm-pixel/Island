extends RefCounted
var priesthoods={"perun":{"followers":0,"volkhv":"","influence":12.0},"veles":{"followers":0,"volkhv":"","influence":15.0},"mokosh":{"followers":0,"volkhv":"","influence":10.0},"dazhbog":{"followers":0,"volkhv":"","influence":8.0},"stribog":{"followers":0,"volkhv":"","influence":9.0}}
var sacred_sites:Array=[]
var prophecies:Array=[]
var events:Array=[]
var next_id:=1
func consecrate(god:String,pos:Vector2)->Dictionary:
    if not priesthoods.has(god):return {"ok":false,"reason":"Неизвестная традиция."}
    var s={"id":"sacred_%d"%next_id,"god":god,"pos":pos,"sanctity":20.0,"offerings":0,"desecrated":false};next_id+=1;sacred_sites.append(s);events.append({"type":"sacred_site","text":"Место посвящено божеству %s."%god});return {"ok":true,"site":s}
func appoint_volkhv(god:String,npc:Dictionary)->Dictionary:
    if not priesthoods.has(god):return {"ok":false,"reason":"Неизвестный культ."}
    if int(npc.get("rel",0))<2:return {"ok":false,"reason":"Этот человек не доверяет тебе настолько."}
    priesthoods[god]["volkhv"]=str(npc.get("id",""));npc["religious_role"]="volkhv_%s"%god;events.append({"type":"volkhv","text":"%s становится волхвом традиции %s."%[npc.get("name","Житель"),god]});return {"ok":true}
func ritual(god:String,kind:String,participants:int,faith)->Dictionary:
    if not priesthoods.has(god):return {"ok":false,"reason":"Неизвестный бог."}
    var base={"prayer":2.0,"feast":5.0,"oath":4.0,"healing":6.0,"storm":7.0,"harvest":7.0,"divination":5.0}.get(kind,2.0)
    var power=base+participants*.7+float(faith.favor.get(god,0))*.05;priesthoods[god]["influence"]=float(priesthoods[god]["influence"])+power*.12
    if kind=="divination":_make_prophecy(god,power)
    events.append({"type":"ritual","text":"Проведён обряд %s в традиции %s. Участников: %d."%[kind,god,participants]});return {"ok":true,"power":power}
func recruit(god:String,npc:Dictionary)->Dictionary:
    if not priesthoods.has(god):return {"ok":false}
    var chance=clampf(.18+float(npc.get("stress",0))*.004+float(priesthoods[god]["influence"])*.006,.1,.8);var success=randf()<chance
    if success:priesthoods[god]["followers"]=int(priesthoods[god]["followers"])+1;npc["old_faith"]=god;events.append({"type":"conversion","text":"%s принимает традицию %s."%[npc.get("name","Житель"),god]})
    return {"ok":true,"success":success}
func _make_prophecy(god:String,power:float):
    var themes=["кровь у ворот","корабль без флага","смерть важного человека","великий урожай","предательство в доме","огонь с неба","ребёнок, меняющий порядок"]
    var p={"id":"prophecy_%d"%next_id,"god":god,"theme":themes[randi()%themes.size()],"clarity":clampf(power/20.0,.1,.9),"fulfilled":false};next_id+=1;prophecies.append(p);events.append({"type":"prophecy","text":"Волхв произносит смутное пророчество: %s."%p["theme"]})
func tick(npcs:Array):
    for god in priesthoods.keys():
        var f=0
        for n in npcs:
            if str(n.get("old_faith",""))==god:f+=1
        priesthoods[god]["followers"]=f
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"priesthoods":priesthoods,"sacred_sites":sacred_sites,"prophecies":prophecies,"next_id":next_id}
func restore(data:Dictionary):
    var p=data.get("priesthoods",{});if typeof(p)==TYPE_DICTIONARY:priesthoods=p
    var s=data.get("sacred_sites",[]);if typeof(s)==TYPE_ARRAY:sacred_sites=s
    var pr=data.get("prophecies",[]);if typeof(pr)==TYPE_ARRAY:prophecies=pr
    next_id=int(data.get("next_id",next_id))
