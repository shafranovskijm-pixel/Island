extends "res://scripts/game_v24.gd"

const CraftingSystem=preload("res://scripts/crafting_system.gd")
var crafting=CraftingSystem.new()
var crafting_menu_open:=false

func _ready():
    super._ready()
    crafting.unlock_from_knowledge(learning)

func _process(delta):
    super._process(delta)
    crafting.unlock_from_knowledge(learning)
    for e in crafting.drain():
        history.record(day,hour,str(e.get("type","craft")),str(e.get("text","Ремесло.")),{"worker":0.15})

func craft_item(recipe_id:String):
    var loc=current_location_id
    if player_home_id!="" and current_location_id in ["market","slums","castle"]:loc="player_home"
    var result=crafting.craft(recipe_id,learning,production.resources,inventory,loc)
    if not bool(result.get("ok",false)):
        _notify(str(result.get("reason","Не удалось изготовить предмет.")));return
    var item:Dictionary=result.get("item",{})
    _notify("Создано: %s"%item.get("name",recipe_id))
    saves.save_game(_capture_save())

func available_recipes()->Array:
    crafting.unlock_from_knowledge(learning)
    var out:Array=[]
    for id in crafting.recipes.keys():
        if bool(crafting.known_recipes.get(id,false)):
            var check=crafting.can_craft(id,learning,production.resources,inventory,current_location_id)
            out.append({"id":id,"name":crafting.recipes[id]["output"].get("name",id),"ready":bool(check.get("ok",false)),"reason":str(check.get("reason",""))})
    return out

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(s.x-350,s.y-82,150,54).has_point(event.position):
            crafting_menu_open=not crafting_menu_open
            return
    super._unhandled_input(event)

func _draw_hud(s:Vector2):
    super._draw_hud(s)
    var r=Rect2(s.x-350,s.y-82,150,54)
    draw_rect(r,Color("#4c6548"))
    draw_string(ThemeDB.fallback_font,r.position+Vector2(28,33),"РЕМЕСЛО",0,110,15,Color.WHITE)
    if crafting_menu_open:_draw_crafting_panel(s)

func _draw_crafting_panel(s:Vector2):
    var panel=Rect2(s.x*.53,s.y*.20,s.x*.43,s.y*.58)
    draw_rect(panel,Color(0.03,0.04,0.03,.96))
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(20,30),"Известные ремёсла",0,panel.size.x-40,20,Color("#e7e1c4"))
    var y=65.0
    for rec in available_recipes():
        var status="готово" if rec["ready"] else rec["reason"]
        draw_string(ThemeDB.fallback_font,panel.position+Vector2(20,y),"• %s — %s"%[rec["name"],status],0,panel.size.x-40,13,Color.WHITE)
        y+=28
        if y>panel.size.y-20:break

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["crafting"]=crafting.serialize();return data

func _apply_save(data:Dictionary):
    super._apply_save(data)
    var c=data.get("crafting",{});if typeof(c)==TYPE_DICTIONARY:crafting.restore(c)
