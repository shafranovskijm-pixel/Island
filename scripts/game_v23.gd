extends "res://scripts/game_v22.gd"

const InheritanceSystem=preload("res://scripts/inheritance_system.gd")
var inheritance=InheritanceSystem.new()
var processed_deaths:Dictionary={}

func _process(delta):
    super._process(delta)
    _process_new_deaths()
    for e in inheritance.drain():
        history.record(int(e.get("day",day)),float(e.get("hour",hour)),str(e.get("type","inheritance")),str(e.get("text","Наследование.")),{})

func _process_new_deaths():
    for n in npcs:
        var id=str(n.get("id",""))
        if id=="" or bool(n.get("alive",true)) or processed_deaths.has(id):continue
        processed_deaths[id]=true
        var result=inheritance.process_death(npcs,id,property_economy.properties,housing,day,hour)
        npcs=result.get("npcs",npcs)
        property_economy.properties=result.get("properties",property_economy.properties)
        _death_economic_shock(n)

func _death_economic_shock(dead:Dictionary):
    var role=str(dead.get("role","")).to_lower()
    if "крест" in role or "фермер" in role:
        production.unrest=minf(100.0,production.unrest+3.0)
        history.record(day,hour,"labor_loss","После смерти %s фермерских рук на острове стало меньше."%dead.get("name","жителя"),{})
    elif "стро" in role:
        history.record(day,hour,"labor_loss","После смерти %s строительные работы могут замедлиться."%dead.get("name","жителя"),{})
    elif "лекар" in role or "целит" in role:
        history.record(day,hour,"healthcare_loss","Остров потерял лекаря: %s."%dead.get("name","жителя"),{})
    elif "страж" in role:
        production.crime_pressure=minf(100.0,production.crime_pressure+2.0)
    elif "торгов" in role:
        production.prosperity=maxf(0.0,production.prosperity-2.0)

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["processed_deaths"]=processed_deaths;return data

func _apply_save(data:Dictionary):
    super._apply_save(data);var p=data.get("processed_deaths",{});if typeof(p)==TYPE_DICTIONARY:processed_deaths=p
