extends "res://scripts/game_v26.gd"

const CraftingStationSystem=preload("res://scripts/crafting_station_system.gd")
var crafting_stations=CraftingStationSystem.new()
var craft_category_index:=0
var craft_page:=0
const RECIPES_PER_PAGE:=8

func _ready():
    super._ready()
    # Keep the first survival chain possible without an already-built advanced station.
    if crafting.recipes.has("torch"):
        crafting.recipes["torch"]["inputs"]={"stick":1.0,"fiber":1.0,"coal":1.0}
    if crafting.recipes.has("irrigation_kit"):
        crafting.recipes["irrigation_kit"]["inputs"]={"plank":8.0,"rope":4.0}
        crafting.recipes["irrigation_kit"]["tools"]=["bucket","hammer"]
    if crafting.recipes.has("seed_bundle"):
        crafting.recipes["seed_bundle"]["output"]["crop"]="root"
    _sync_crafting_practice_aliases()
    crafting.unlock_from_knowledge(learning)

func _process(delta):
    super._process(delta)
    for e in crafting_stations.drain():
        history.record(day,hour,str(e.get("type","structure")),str(e.get("text","Изменение постройки.")),{"worker":0.08})

func _sync_crafting_practice_aliases():
    var p:Dictionary=learning.study_progress
    p["survival"]=maxf(float(p.get("survival",0)),float(p.get("foraging",0)))
    p["cooking"]=maxf(float(p.get("cooking",0)),float(p.get("foraging",0))*.85)
    p["carpentry"]=maxf(float(p.get("carpentry",0)),float(p.get("building",0))*.8+float(p.get("foraging",0))*.25)
    p["masonry"]=maxf(float(p.get("masonry",0)),float(p.get("building",0))*.9+float(p.get("mining",0))*.25)
    p["woodcutting"]=maxf(float(p.get("woodcutting",0)),float(p.get("foraging",0))*.75)
    p["mining"]=maxf(float(p.get("mining",0)),float(p.get("building",0))*.35)
    p["smelting"]=maxf(float(p.get("smelting",0)),float(p.get("mining",0))*.65+float(p.get("building",0))*.35)
    p["smithing"]=maxf(float(p.get("smithing",0)),float(p.get("mining",0))*.45+float(p.get("building",0))*.55)
    p["textiles"]=maxf(float(p.get("textiles",0)),float(p.get("foraging",0))*.45+float(p.get("building",0))*.35)
    p["fishing"]=maxf(float(p.get("fishing",0)),float(p.get("sailing",0))*.7+float(p.get("foraging",0))*.3)
    p["thievery"]=maxf(float(p.get("thievery",0)),float(p.get("stealth",0)))
    p["weapons"]=maxf(float(p.get("weapons",0)),float(p.get("labor",0))*.55+float(p.get("stealth",0))*.25)
    p["alchemy"]=maxf(float(p.get("alchemy",0)),float(p.get("medicine",0)))
    p["brewing"]=maxf(float(p.get("brewing",0)),float(p.get("farming",0))*.8+float(p.get("cooking",0))*.2)
    p["occult"]=maxf(float(p.get("occult",0)),float(p.get("magic",0)))

func _craft_location()->String:
    if player_home_id!="" and current_location_id in ["market","slums","castle"]:
        return "player_home"
    return current_location_id

func current_crafting_stations()->Array:
    return crafting_stations.stations_near(player,_craft_location())

func _player_resource_totals()->Dictionary:
    var out:Dictionary=super._player_resource_totals()
    # Some durable crafted objects can be requirements without being consumed.
    for item in inventory:
        var tool_type=str(item.get("tool_type",""))
        if tool_type!="":out[tool_type]=float(out.get(tool_type,0.0))+float(item.get("quantity",1.0))
    return out

func craft_item(recipe_id:String):
    _sync_crafting_practice_aliases()
    if not crafting.recipes.has(recipe_id):
        _notify("Неизвестный рецепт.");return
    var loc=_craft_location()
    var stations=current_crafting_stations()
    var personal=_player_resource_totals()
    var check=crafting.can_craft(recipe_id,learning,personal,inventory,loc,stations)
    if not bool(check.get("ok",false)):
        _notify(str(check.get("reason","Не удалось изготовить предмет.")));return

    var req:Dictionary=crafting.recipes[recipe_id].get("inputs",{}).duplicate(true)
    _consume_personal_resources(req)
    var scratch=_player_resource_totals()
    for key in req.keys():scratch[key]=float(scratch.get(key,0.0))+float(req[key])
    var result=crafting.craft(recipe_id,learning,scratch,inventory,loc,stations)
    if not bool(result.get("ok",false)):
        _notify(str(result.get("reason","Крафт сорвался.")));return
    var item:Dictionary=result.get("item",{})
    var suffix=""
    if bool(item.get("placeable",false)):suffix=" — можно разместить в мире"
    _notify("Создано: %s%s"%[item.get("name",recipe_id),suffix])
    saves.save_game(_capture_save())

func place_next_structure():
    var item=crafting_stations.first_placeable(inventory)
    if item.is_empty():
        _notify("В инвентаре нет станции или постройки для размещения.");return
    var result=crafting_stations.place_from_inventory(str(item.get("id","")),inventory,player+Vector2(45,0))
    if not bool(result.get("ok",false)):
        _notify(str(result.get("reason","Не удалось разместить.")));return
    _notify("Размещено: %s"%result["structure"].get("name","объект"))
    saves.save_game(_capture_save())

func _category_ids()->Array:
    return crafting.category_ids()

func _current_category()->String:
    var ids=_category_ids()
    if ids.is_empty():return "materials"
    craft_category_index=clampi(craft_category_index,0,ids.size()-1)
    return str(ids[craft_category_index])

func _category_recipes()->Array:
    _sync_crafting_practice_aliases()
    return crafting.recipes_by_category(_current_category(),learning)

func _visible_recipe_entries()->Array:
    var all=_category_recipes()
    var max_page=maxi(0,int(ceil(float(all.size())/RECIPES_PER_PAGE))-1)
    craft_page=clampi(craft_page,0,max_page)
    var out:Array=[]
    var start=craft_page*RECIPES_PER_PAGE
    for i in range(start,mini(all.size(),start+RECIPES_PER_PAGE)):
        out.append(all[i])
    return out

func _unhandled_input(event):
    if crafting_menu_open and event is InputEventScreenTouch and event.pressed:
        if _handle_advanced_crafting_touch(event.position):return
    super._unhandled_input(event)

func _handle_advanced_crafting_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size
    var panel=Rect2(s.x*.39,s.y*.08,s.x*.59,s.y*.82)
    if not panel.has_point(pos):return false
    var left=Rect2(panel.position+Vector2(18,48),Vector2(50,38))
    var right=Rect2(panel.end.x-68,panel.position.y+48,50,38)
    var place=Rect2(panel.position.x+18,panel.end.y-55,panel.size.x-36,38)
    if left.has_point(pos):
        craft_category_index=(craft_category_index-1+_category_ids().size())%_category_ids().size();craft_page=0;return true
    if right.has_point(pos):
        craft_category_index=(craft_category_index+1)%_category_ids().size();craft_page=0;return true
    if place.has_point(pos):place_next_structure();return true
    var page_left=Rect2(panel.position.x+18,panel.end.y-98,55,32)
    var page_right=Rect2(panel.end.x-73,panel.end.y-98,55,32)
    if page_left.has_point(pos):craft_page=maxi(0,craft_page-1);return true
    if page_right.has_point(pos):craft_page+=1;return true
    var y=panel.position.y+105
    var entries=_visible_recipe_entries()
    for i in entries.size():
        var row=Rect2(panel.position.x+18,y+i*47,panel.size.x-36,39)
        if row.has_point(pos):
            craft_item(str(entries[i]["id"]));return true
    return true

func _draw_crafting_panel(s:Vector2):
    var panel=Rect2(s.x*.39,s.y*.08,s.x*.59,s.y*.82)
    draw_rect(panel,Color(0.025,0.035,0.03,.97))
    draw_rect(panel,Color("#7f8f69"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(18,30),"Книга ремёсел",0,panel.size.x-36,21,Color("#eee8cf"))
    var category=_current_category()
    draw_rect(Rect2(panel.position+Vector2(18,48),Vector2(50,38)),Color("#4d5d48"))
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(35,74),"‹",0,20,24,Color.WHITE)
    draw_rect(Rect2(panel.end.x-68,panel.position.y+48,50,38),Color("#4d5d48"))
    draw_string(ThemeDB.fallback_font,Vector2(panel.end.x-51,panel.position.y+74),"›",0,20,24,Color.WHITE)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(82,74),crafting.category_name(category),0,panel.size.x-164,17,Color("#d9e3c3"))

    var stations=", ".join(current_crafting_stations())
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(18,98),"Рядом: %s"%stations,0,panel.size.x-36,11,Color("#aebda4"))
    var y=panel.position.y+105
    for i in _visible_recipe_entries().size():
        var rec:Dictionary=_visible_recipe_entries()[i]
        var id=str(rec["id"])
        var check=crafting.can_craft(id,learning,_player_resource_totals(),inventory,_craft_location(),current_crafting_stations())
        var row=Rect2(panel.position.x+18,y+i*47,panel.size.x-36,39)
        draw_rect(row,Color("#3f6048") if bool(check.get("ok",false)) else Color("#4a4440"))
        var name=str(rec["output"].get("name",id))
        var status="СОЗДАТЬ" if bool(check.get("ok",false)) else str(check.get("reason","недоступно"))
        draw_string(ThemeDB.fallback_font,row.position+Vector2(11,24),name,0,row.size.x*.42,13,Color.WHITE)
        draw_string(ThemeDB.fallback_font,row.position+Vector2(row.size.x*.44,24),status,0,row.size.x*.53,11,Color("#d9dccf"))

    var all=_category_recipes();var pages=maxi(1,int(ceil(float(all.size())/RECIPES_PER_PAGE)))
    var page_y=panel.end.y-82
    draw_rect(Rect2(panel.position.x+18,page_y,55,32),Color("#4d5d48"));draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+39,page_y+22),"‹",0,20,18,Color.WHITE)
    draw_rect(Rect2(panel.end.x-73,page_y,55,32),Color("#4d5d48"));draw_string(ThemeDB.fallback_font,Vector2(panel.end.x-52,page_y+22),"›",0,20,18,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+92,page_y+22),"Страница %d/%d · рецептов %d"%[craft_page+1,pages,all.size()],0,panel.size.x-184,12,Color("#bdc9b3"))
    var place=Rect2(panel.position.x+18,panel.end.y-55,panel.size.x-36,38)
    draw_rect(place,Color("#665640"));draw_string(ThemeDB.fallback_font,place.position+Vector2(18,25),"РАЗМЕСТИТЬ ПЕРВУЮ ПОСТРОЙКУ ИЗ ИНВЕНТАРЯ",0,place.size.x-36,13,Color.WHITE)

func _draw_world(cam:Vector2,s:Vector2):
    super._draw_world(cam,s)
    for structure in crafting_stations.structures:
        var p:Vector2=structure.get("pos",Vector2.ZERO)-cam
        var station_type=str(structure.get("station_type",structure.get("structure_type","structure")))
        draw_rect(Rect2(p-Vector2(16,13),Vector2(32,26)),Color("#806a4d"))
        draw_string(ThemeDB.fallback_font,p+Vector2(-30,-19),str(structure.get("name",station_type)),0,90,9,Color.WHITE)

func _action_world_snapshot()->Dictionary:
    var world:Dictionary=super._action_world_snapshot()
    var objects:Array=world.get("nearby_objects",[])
    for structure in crafting_stations.structures:
        if player.distance_to(structure.get("pos",Vector2.ZERO))<140:
            objects.append({"id":structure.get("id",""),"name":structure.get("name","постройка"),"kind":"structure","aliases":[structure.get("station_type",structure.get("structure_type",""))]})
    world["nearby_objects"]=objects
    return world

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save()
    data["crafting_stations"]=crafting_stations.serialize()
    data["craft_category_index"]=craft_category_index
    data["craft_page"]=craft_page
    return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var cs=data.get("crafting_stations",{})
    if typeof(cs)==TYPE_DICTIONARY:crafting_stations.restore(cs)
    craft_category_index=int(data.get("craft_category_index",0))
    craft_page=int(data.get("craft_page",0))
