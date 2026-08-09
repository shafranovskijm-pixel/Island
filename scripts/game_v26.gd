extends "res://scripts/game_v25.gd"

const ResourceGathering=preload("res://scripts/resource_gathering.gd")
const PlayerFarming=preload("res://scripts/player_farming.gd")
var gathering=ResourceGathering.new()
var farming=PlayerFarming.new()
var farming_plot_id:=""

func _ready():
    super._ready()
    gathering.setup()
    if farming.plots.is_empty():
        var p=farming.create_plot("player",Vector2(300,690));farming_plot_id=str(p["id"])
    if not _has_seed("root"):
        inventory.append({"id":"seed_root_start","name":"семена корнеплода","kind":"seed","crop":"root","value":1})

func _process(delta):
    super._process(delta)
    gathering.tick(day)
    farming.tick(day,"clear")
    for e in gathering.drain():history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","gather")),str(e.get("text","Добыча.")),{"worker":0.12})
    for e in farming.drain():history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","farm")),str(e.get("text","Фермерство.")),{"worker":0.18})

func gather_nearby():
    var node=gathering.nearby(player)
    var result=gathering.gather(str(node.get("id","")),inventory,learning,skills,day,hour)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Здесь нечего добывать.")));return
    _notify("Добыто: %s x%.1f"%[result["item"].get("name","ресурс"),float(result.get("amount",0))])
    saves.save_game(_capture_save())

func plant_player_crop(crop:String="root"):
    if farming_plot_id=="":return
    var result=farming.plant(farming_plot_id,crop,inventory,learning,day,hour)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не удалось посеять.")));return
    _notify("Посев выполнен.");saves.save_game(_capture_save())

func water_player_crop():
    var result=farming.water(farming_plot_id,day,hour)
    if bool(result.get("ok",false)):_notify("Грядка полита.")

func harvest_player_crop():
    var result=farming.harvest(farming_plot_id,inventory,learning,day,hour)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Урожай пока не готов.")));return
    _notify("Собран урожай x%.1f"%float(result.get("quantity",0)));saves.save_game(_capture_save())

func _has_seed(crop:String)->bool:
    for i in inventory:
        if str(i.get("kind",""))=="seed" and str(i.get("crop",""))==crop:return true
    return false

func _player_resource_totals()->Dictionary:
    var out:Dictionary={}
    for item in inventory:
        if str(item.get("kind",""))!="resource":continue
        var key=str(item.get("resource",""));if key=="":continue
        out[key]=float(out.get(key,0))+float(item.get("quantity",1))
    return out

func _consume_personal_resources(req:Dictionary):
    for key in req.keys():
        var remaining=float(req[key])
        for i in range(inventory.size()-1,-1,-1):
            var item=inventory[i]
            if str(item.get("kind",""))!="resource" or str(item.get("resource",""))!=str(key):continue
            var q=float(item.get("quantity",1));var take=minf(q,remaining);q-=take;remaining-=take
            if q<=0.001:inventory.remove_at(i)
            else:inventory[i]["quantity"]=q
            if remaining<=0.001:break

func craft_item(recipe_id:String):
    if not crafting.recipes.has(recipe_id):_notify("Неизвестный рецепт.");return
    var loc=current_location_id
    if player_home_id!="" and current_location_id in ["market","slums","castle"]:loc="player_home"
    var personal=_player_resource_totals()
    var check=crafting.can_craft(recipe_id,learning,personal,inventory,loc)
    if not bool(check.get("ok",false)):_notify(str(check.get("reason","Не удалось изготовить предмет.")));return
    var req:Dictionary=crafting.recipes[recipe_id].get("inputs",{}).duplicate(true)
    _consume_personal_resources(req)
    var scratch=_player_resource_totals()
    for key in req.keys():scratch[key]=float(scratch.get(key,0))+float(req[key])
    var result=crafting.craft(recipe_id,learning,scratch,inventory,loc)
    if bool(result.get("ok",false)):
        _notify("Создано: %s"%result["item"].get("name",recipe_id));saves.save_game(_capture_save())

func available_recipes()->Array:
    crafting.unlock_from_knowledge(learning)
    var resources=_player_resource_totals();var out:Array=[]
    for id in crafting.recipes.keys():
        if bool(crafting.known_recipes.get(id,false)):
            var check=crafting.can_craft(id,learning,resources,inventory,current_location_id)
            out.append({"id":id,"name":crafting.recipes[id]["output"].get("name",id),"ready":bool(check.get("ok",false)),"reason":str(check.get("reason",""))})
    return out

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(s.x-520,s.y-148,150,54).has_point(event.position):gather_nearby();return
        if Rect2(s.x-350,s.y-148,150,54).has_point(event.position):
            if _farm_ready():harvest_player_crop()
            elif _farm_planted():water_player_crop()
            else:plant_player_crop("root")
            return
    super._unhandled_input(event)

func _farm_ready()->bool:
    for p in farming.plots:
        if str(p.get("id",""))==farming_plot_id:return bool(p.get("ready",false))
    return false
func _farm_planted()->bool:
    for p in farming.plots:
        if str(p.get("id",""))==farming_plot_id:return str(p.get("crop",""))!=""
    return false

func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    for n in gathering.nodes:
        var p=n["pos"]-cam
        draw_circle(p,10,Color("#7a8b57"))
        draw_string(ThemeDB.fallback_font,p+Vector2(-30,-16),str(n["name"]),0,100,10,Color.WHITE)
    for p in farming.plots:
        var pp=p["pos"]-cam;draw_rect(Rect2(pp-Vector2(24,16),Vector2(48,32)),Color("#6f5134"))
        if str(p.get("crop",""))!="":draw_string(ThemeDB.fallback_font,pp+Vector2(-18,4),"%.0f%%"%(float(p.get("stage",0))*100.0),0,60,10,Color("#d7e7a4"))

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var g=Rect2(s.x-520,s.y-148,150,54);draw_rect(g,Color("#486f56"));draw_string(ThemeDB.fallback_font,g.position+Vector2(27,33),"ДОБЫВАТЬ",0,110,14,Color.WHITE)
    var f=Rect2(s.x-350,s.y-148,150,54);draw_rect(f,Color("#6e6842"));var label="УРОЖАЙ" if _farm_ready() else ("ПОЛИТЬ" if _farm_planted() else "ПОСЕЯТЬ");draw_string(ThemeDB.fallback_font,f.position+Vector2(30,33),label,0,100,14,Color.WHITE)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["gathering"]=gathering.serialize();data["farming"]=farming.serialize();data["farming_plot_id"]=farming_plot_id;return data
func _apply_save(data:Dictionary):
    super._apply_save(data)
    var g=data.get("gathering",{});if typeof(g)==TYPE_DICTIONARY:gathering.restore(g)
    var f=data.get("farming",{});if typeof(f)==TYPE_DICTIONARY:farming.restore(f)
    farming_plot_id=str(data.get("farming_plot_id",farming_plot_id))
