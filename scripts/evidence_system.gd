extends RefCounted

var events:Array=[]

func inspect_player_inventory(npcs:Array,inventory:Array,player_pos:Vector2,day:int,hour:float)->Array:
    var reactions:Array=[]
    for item in inventory:
        if not bool(item.get("recognizable",false)):continue
        for i in npcs.size():
            var n=npcs[i]
            if not bool(n.get("alive",true)):continue
            if player_pos.distance_to(n.get("pos",Vector2.ZERO))>135:continue
            var reaction=_reaction_for(n,item,day,hour)
            if not reaction.is_empty():
                reactions.append(reaction)
                n["memory"].append({"type":"evidence_seen","item":item.get("name",""),"former_person":item.get("former_person",""),"day":day,"hour":hour})
                n["suspicion"]=int(n.get("suspicion",0))+int(reaction.get("suspicion",1))
                n["stress"]=minf(100.0,float(n.get("stress",0))+float(reaction.get("stress",0)))
                npcs[i]=n
    return reactions

func _reaction_for(n:Dictionary,item:Dictionary,day:int,hour:float)->Dictionary:
    if str(item.get("kind",""))!="body_part":return {}
    var victim=str(item.get("former_person",""))
    var faction=str(n.get("faction",""))
    var text="%s замечает %s."%[n.get("name","Кто-то"),item.get("name","страшный предмет")]
    var severity:=2
    if victim=="king":
        severity=8
        if faction in ["crown","guard"]:text="%s узнаёт голову короля. Начинается паника и зовут стражу."%n.get("name","Свидетель")
        elif faction=="underworld":text="%s понимает, что баланс власти только что рухнул."%n.get("name","Свидетель")
        elif faction=="occult":text="%s видит в королевской голове политический и ритуальный трофей."%n.get("name","Свидетель")
    elif victim!="":
        text="%s узнаёт в трофее останки %s."%[n.get("name","Свидетель"),victim]
    var e={"npc_id":n.get("id",""),"victim":victim,"severity":severity,"suspicion":severity,"stress":severity*2,"text":text,"day":day,"hour":hour}
    _log(e)
    return e

func _log(e:Dictionary):
    events.append(e)
    if events.size()>120:events.pop_front()
