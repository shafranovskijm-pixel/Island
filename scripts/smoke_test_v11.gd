extends SceneTree

const LocationSystem=preload("res://scripts/location_system.gd")
const LocationPopulation=preload("res://scripts/location_population.gd")
const FactionConflictSystem=preload("res://scripts/faction_conflict_system.gd")
const IntrigueSystem=preload("res://scripts/intrigue_system.gd")
const FamilySystem=preload("res://scripts/family_system.gd")

func _init():
    var locations=LocationSystem.new()
    var population=LocationPopulation.new()
    var conflicts=FactionConflictSystem.new()
    var intrigue=IntrigueSystem.new()
    var families=FamilySystem.new()
    var npcs=population.extra_npcs(locations.spawn_points())
    conflicts.setup();intrigue.setup();families.setup(npcs)
    if not locations.locations.has("castle") or not locations.locations.has("graveyard") or not locations.locations.has("crypt"):
        _fail("required systemic locations missing");return
    if _find(npcs,"king")<0 or _find(npcs,"vampire")<0 or _find(npcs,"cult_leader")<0:
        _fail("key location NPCs missing");return
    var control={"castle":"crown","guard_barracks":"guard","temple":"temple","slums":"underworld","port":"merchants","market":"merchants","graveyard":"temple","crypt":"occult","occult_lodge":"occult"}
    for day in range(1,18):
        var r=conflicts.tick(npcs,control,day,22.0)
        npcs=r["npcs"];control=r["control"]
        npcs=intrigue.tick(npcs,day,22.0,conflicts.relations)
        npcs=families.tick(npcs,day,22.0)
    if conflicts.relations.size()<5:
        _fail("faction relations missing");return
    if families.families.is_empty():
        _fail("family system missing");return
    if not families.families.has("royal_house"):
        _fail("royal dynasty missing");return
    locations.discover("crypt_entrance")
    var access=locations.can_enter("crypt",{"occult":0,"stealth":0})
    if not bool(access.get("ok",false)):
        _fail("discovered crypt still inaccessible");return
    print("ISLAND_V11_SMOKE_TEST_OK")
    print("NPCS=",npcs.size()," LOCATIONS=",locations.locations.size()," FACTIONS=",conflicts.factions.size()," FAMILIES=",families.families.size())
    quit(0)

func _find(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1

func _fail(text:String):
    push_error("ISLAND_V11_SMOKE_TEST_FAILED: "+text)
    quit(1)
