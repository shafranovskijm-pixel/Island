extends "res://scripts/game_v05.gd"

const SaveSystem = preload("res://scripts/save_system.gd")
const PlayerSocialSystem = preload("res://scripts/player_social_system.gd")

var saves = SaveSystem.new()
var player_social = PlayerSocialSystem.new()
var autosave_timer := 0.0

func _ready():
    super._ready()
    player_social.setup(npcs)
    var loaded:=saves.load_game()
    if not loaded.is_empty():
        _apply_save(loaded)
        _notify("Сохранённая жизнь острова восстановлена.")

func _process(delta):
    super._process(delta)
    autosave_timer += delta
    if autosave_timer >= 15.0:
        autosave_timer = 0.0
        saves.save_game(_capture_save())

func _do_action(action:int):
    var npc_id:=""
    if selected_npc>=0 and selected_npc<npcs.size():
        npc_id=str(npcs[selected_npc]["id"])
    super._do_action(action)
    if npc_id!="":
        var idx:=_find_npc(npc_id)
        if idx>=0:
            if action==0:
                player_social.interact(npcs[idx],"help",int(skills.get("charm",0)))
            elif action==1:
                player_social.interact(npcs[idx],"beg",int(skills.get("charm",0)))
    saves.save_game(_capture_save())

func _witness_theft(index:int,item:Dictionary):
    super._witness_theft(index,item)
    if index>=0 and index<npcs.size():
        player_social.interact(npcs[index],"steal_seen",int(skills.get("charm",0)))

func _dialog_touch(pos:Vector2):
    if selected_npc>=0:
        var s=get_viewport_rect().size
        var box:=Rect2(s.x*.08,s.y*.50,s.x*.84,s.y*.40)
        var flirt_rect:=Rect2(box.end.x-160,box.position.y+18,130,38)
        if flirt_rect.has_point(pos):
            _flirt()
            return
    super._dialog_touch(pos)

func _flirt():
    if selected_npc<0 or selected_npc>=npcs.size():
        return
    var npc=npcs[selected_npc]
    var id:String=npc["id"]
    if not player_social.can_flirt(id):
        _notify("Сначала нужно лучше узнать этого человека.")
        return
    skills["charm"]+=1
    var relation:Dictionary=player_social.interact(npc,"flirt",int(skills["charm"]))
    history.record(day,hour,"romance","Флиртовал с %s."%npc["name"],{"social":0.25})
    if bool(relation.get("romance",false)):
        history.record(day,hour,"relationship","Между тобой и %s начались романтические отношения."%npc["name"],{"social":1.0})
        _notify("Отношения изменились: романтика.")
    else:
        _notify("Ты проявил интерес. Реакция зависит от ваших отношений.")
    saves.save_game(_capture_save())

func _draw_dialog(s:Vector2):
    super._draw_dialog(s)
    if selected_npc<0 or selected_npc>=npcs.size():
        return
    var box:=Rect2(s.x*.08,s.y*.50,s.x*.84,s.y*.40)
    var npc=npcs[selected_npc]
    var status:=player_social.status(str(npc["id"]))
    draw_string(ThemeDB.fallback_font,box.position+Vector2(30,92),"Твои отношения: %s"%status,0,box.size.x-220,13,Color("#efc7c9"))
    var flirt_rect:=Rect2(box.end.x-160,box.position.y+18,130,38)
    draw_rect(flirt_rect,Color("#713e52"))
    draw_string(ThemeDB.fallback_font,flirt_rect.position+Vector2(22,25),"♥ ФЛИРТ",0,100,13,Color.WHITE)

func _find_npc(id:String)->int:
    for i in npcs.size():
        if str(npcs[i]["id"])==id:
            return i
    return -1

func _capture_save()->Dictionary:
    return {
        "version":1,"day":day,"hour":hour,"player":player,"coins":coins,
        "hunger":hunger,"energy":energy,"hygiene":hygiene,"wanted":wanted,
        "reputation":reputation,"skills":skills,"inventory":inventory,
        "npcs":npcs,"items":items,"player_relations":player_social.to_dict(),
        "market":economy.market,"tax_rate":economy.tax_rate,
        "ships":ship_system.ships,"next_ship_day":ship_system.next_arrival_day,
        "next_ship_hour":ship_system.next_arrival_hour,"factions":social.factions,
        "escaped":escaped,"escape_story":escape_story
    }

func _apply_save(data:Dictionary):
    day=int(data.get("day",day));hour=float(data.get("hour",hour))
    player=data.get("player",player);coins=int(data.get("coins",coins))
    hunger=float(data.get("hunger",hunger));energy=float(data.get("energy",energy));hygiene=float(data.get("hygiene",hygiene))
    wanted=int(data.get("wanted",wanted));reputation=int(data.get("reputation",reputation))
    skills=data.get("skills",skills);inventory=data.get("inventory",inventory)
    npcs=data.get("npcs",npcs);items=data.get("items",items)
    player_social.setup(npcs)
    var saved_rel=data.get("player_relations",{})
    if typeof(saved_rel)==TYPE_DICTIONARY:
        player_social.from_dict(saved_rel)
    economy.market=data.get("market",economy.market);economy.tax_rate=float(data.get("tax_rate",economy.tax_rate))
    ship_system.ships=data.get("ships",ship_system.ships)
    ship_system.next_arrival_day=int(data.get("next_ship_day",ship_system.next_arrival_day))
    ship_system.next_arrival_hour=float(data.get("next_ship_hour",ship_system.next_arrival_hour))
    social.factions=data.get("factions",social.factions)
    escaped=bool(data.get("escaped",false));escape_story=str(data.get("escape_story",""))
