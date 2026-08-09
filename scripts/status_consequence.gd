extends RefCounted

func classify(victim_id:String,npcs:Array)->Dictionary:
    var role="";var faction="";var influence=0
    for n in npcs:
        if str(n.get("id",""))==victim_id:
            role=str(n.get("role",""));faction=str(n.get("faction",""));influence=int(n.get("influence",0));break
    var tier="common"
    if victim_id=="king" or "король" in role: tier="royal"
    elif faction=="temple" or "жрец" in role: tier="temple"
    elif faction=="occult": tier="occult"
    elif faction=="guard": tier="guard"
    elif faction=="underworld": tier="underworld"
    elif influence>=50:tier="elite"
    return {"tier":tier,"role":role,"faction":faction,"influence":influence}

func apply(victim_id:String,npcs:Array,player_factions,power,day:int,hour:float)->Dictionary:
    var c=classify(victim_id,npcs);var tier=str(c["tier"])
    var out={"wanted":1,"fear":2,"text":"Люди воспринимают трофей как страшную улику."}
    match tier:
        "royal":
            out={"wanted":6,"fear":10,"text":"Останки монарха превращают происшествие в государственный кризис."}
            player_factions.change("crown",-25,"осквернение монарха");player_factions.change("guard",-20,"угроза Короне");power.crisis_for("останки монарха появились публично",victim_id,"трон",day,hour)
        "temple":
            out={"wanted":3,"fear":5,"text":"Храм объявляет произошедшее святотатством."};player_factions.change("temple",-22,"святотатство");player_factions.change("occult",5,"удар по храму")
        "occult":
            out={"wanted":2,"fear":6,"text":"Орден воспринимает это как вызов, а храм — как возможную зацепку."};player_factions.change("occult",-18,"убийство своего");player_factions.change("temple",4,"ослабление культа")
        "guard":
            out={"wanted":4,"fear":6,"text":"Стража считает это нападением на порядок острова."};player_factions.change("guard",-20,"нападение на стражу")
        "underworld":
            out={"wanted":2,"fear":7,"text":"Преступный мир читает это как сообщение о силе и угрозе."};player_factions.change("underworld",-10,"убийство участника подполья")
        "elite":
            out={"wanted":3,"fear":5,"text":"Гибель влиятельного человека вызывает волну слухов и борьбы за его имущество."}
    return out
