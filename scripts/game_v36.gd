extends "res://scripts/game_v35.gd"

const PhysicalObjectWorld=preload("res://scripts/physical_object_world.gd")
const InjuryCombatSystem=preload("res://scripts/injury_combat_system.gd")
var physical_world=PhysicalObjectWorld.new()
var combat=InjuryCombatSystem.new()
var held_world_object:=""

func _ready():
    super._ready();physical_world.setup();combat.ensure("player")

func _process(delta):
    super._process(delta);combat.tick(delta)
    for ev in physical_world.drain():history.record(day,hour,str(ev.get("type","object")),str(ev.get("text","Предметное событие.")),{})
    for ev in combat.drain():history.record(day,hour,str(ev.get("type","combat")),str(ev.get("text","Бой.")),{"fighter":0.2})

func take_nearby_object():
    var near=physical_world.nearby(player,80);if near.is_empty():_notify("Рядом нет предмета, который можно взять.");return
    var result=physical_world.take(str(near[0]["id"]),"player")
    if bool(result.get("ok",false)):held_world_object=str(near[0]["id"]);_notify("В руках: %s"%near[0]["name"])

func break_held_object():
    if held_world_object=="":_notify("В руках ничего нет.");return
    var result=physical_world.break_object(held_world_object,"player")
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не получилось разбить.")));return
    var spawn=result.get("spawn",{})
    if typeof(spawn)==TYPE_DICTIONARY and not spawn.is_empty():held_world_object=str(spawn["id"]);physical_world.take(held_world_object,"player");_notify("Теперь в руках острый осколок.")
    else:_notify("Предмет сломан.")

func attack_nearest():
    var idx=_nearest_npc();if idx<0:_notify("Рядом нет противника.");return
    var target=npcs[idx];if player.distance_to(target.get("pos",Vector2.ZERO))>95:_notify("Слишком далеко.");return
    var weapon={"name":"кулак","damage":3.0,"weapon_type":"blunt"}
    if held_world_object!="":
        for o in physical_world.objects:
            if str(o.get("id",""))==held_world_object:
                weapon={"name":o.get("name","предмет"),"damage":o.get("damage",maxf(3,float(o.get("mass",1))*1.4)),"weapon_type":"glass_shard" if str(o.get("tag",""))=="glass_shard" else ("blunt" if str(o.get("material",""))!="metal" else "blade")};break
    var attacker={"id":"player","name":"герой","combat_bonus":int(skills.get("labor",0)/2)}
    var result=combat.attack(attacker,target,weapon,dice,int(skills.get("labor",0)/2))
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Атака невозможна.")));return
    target["stress"]=minf(100,float(target.get("stress",0))+15);target["memory"].append({"type":"attacked_by_player","day":day,"weapon":weapon["name"]});npcs[idx]=target
    if bool(result.get("hit",false)):
        wanted+=1
        if held_world_object!="":physical_world.mark_blood(held_world_object,str(target.get("id","")))
        _notify("Удар: %.1f урона%s"%[float(result.get("damage",0))," · цель без сознания" if bool(result.get("unconscious",false)) else ""])
    else:_notify("Промах.")

func drop_held_object():
    if held_world_object=="":return
    physical_world.drop(held_world_object,player+Vector2(25,0));held_world_object="";_notify("Предмет брошен на землю.")

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        var buttons=[Rect2(535,s.y-145,105,50),Rect2(645,s.y-145,105,50),Rect2(755,s.y-145,105,50),Rect2(865,s.y-145,105,50)]
        for i in buttons.size():
            if not buttons[i].has_point(event.position):continue
            match i:
                0:take_nearby_object()
                1:break_held_object()
                2:attack_nearest()
                3:drop_held_object()
            return
    super._unhandled_input(event)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var labels=["ВЗЯТЬ","РАЗБИТЬ","УДАРИТЬ","БРОСИТЬ"]
    for i in labels.size():
        var r=Rect2(535+i*110,s.y-145,105,50);draw_rect(r,Color("#5b4540"));draw_string(ThemeDB.fallback_font,r.position+Vector2(10,31),labels[i],0,88,11,Color.WHITE)
    if held_world_object!="":draw_string(ThemeDB.fallback_font,Vector2(540,s.y-155),"Предмет в руках",0,210,10,Color("#e0b9aa"))

func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    for o in physical_world.objects:
        if str(o.get("held_by",""))!="":continue
        var p:Vector2=o.get("pos",Vector2.ZERO)-cam
        draw_circle(p,7,Color("#b5a382") if not bool(o.get("broken",false)) else Color("#b78c8c"))
        draw_string(ThemeDB.fallback_font,p+Vector2(-25,-10),str(o.get("name","предмет")),0,70,8,Color.WHITE)

func _action_world_snapshot()->Dictionary:
    var world:Dictionary=super._action_world_snapshot();var objs:Array=world.get("nearby_objects",[])
    for o in physical_world.nearby(player,130):objs.append({"id":o["id"],"name":o["name"],"kind":"physical_object","aliases":[o.get("tag","")]})
    world["nearby_objects"]=objs;return world

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["physical_world"]=physical_world.serialize();data["combat_injuries"]=combat.serialize();data["held_world_object"]=held_world_object;return data
func _apply_save(data:Dictionary):
    super._apply_save(data)
    var p=data.get("physical_world",{});if typeof(p)==TYPE_DICTIONARY:physical_world.restore(p)
    var c=data.get("combat_injuries",{});if typeof(c)==TYPE_DICTIONARY:combat.restore(c)
    held_world_object=str(data.get("held_world_object",""))
