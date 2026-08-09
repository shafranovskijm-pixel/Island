extends RefCounted

var ruler_id := "king"
var succession_order := ["queen","chancellor"]
var location_control := {
    "castle":"crown","guard_barracks":"guard","temple":"temple",
    "occult_lodge":"occult","slums":"underworld","port":"merchants"
}
var crises:Array=[]

func tick(npcs:Array,day:int,hour:float)->Array:
    var ruler_alive:=false
    for n in npcs:
        if str(n.get("id",""))==ruler_id and bool(n.get("alive",true)):
            ruler_alive=true
            break
    if not ruler_alive:
        _resolve_succession(npcs,day,hour)
    return npcs

func _resolve_succession(npcs:Array,day:int,hour:float):
    var next:=""
    for candidate in succession_order:
        for n in npcs:
            if str(n.get("id",""))==candidate and bool(n.get("alive",true)):
                next=candidate;break
        if next!="":break
    if next=="":
        crises.append({"day":day,"hour":hour,"type":"vacant_throne","text":"Трон остался без очевидного наследника."})
        ruler_id=""
    else:
        ruler_id=next
        crises.append({"day":day,"hour":hour,"type":"succession","text":"После кризиса власти новым правителем стал %s."%next})

func influence_over(location_id:String,faction:String,amount:int):
    if amount>=5:
        location_control[location_id]=faction

func controller(location_id:String)->String:
    return str(location_control.get(location_id,""))

func crisis_for(action:String,actor:String,target:String,day:int,hour:float):
    crises.append({"day":day,"hour":hour,"type":action,"actor":actor,"target":target,"text":"Политический кризис: %s → %s."%[actor,target]})
