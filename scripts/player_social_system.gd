extends RefCounted

var relations:Dictionary={}

func setup(npcs:Array):
    for npc in npcs:
        var id:String=npc.get("id","")
        if id=="" or relations.has(id):
            continue
        relations[id]={
            "friendship":0.0,"trust":5.0,"respect":0.0,"fear":0.0,
            "attraction":0.0,"love":0.0,"jealousy":0.0,"resentment":0.0,
            "debt":0.0,"romance":false,"known_days":0
        }

func interact(npc:Dictionary,kind:String,player_charm:int=0) -> Dictionary:
    var id:String=npc.get("id","")
    if not relations.has(id):
        setup([npc])
    var r:Dictionary=relations[id]
    match kind:
        "help":
            r["friendship"]+=3.0
            r["trust"]+=2.0
            r["respect"]+=1.0
        "talk":
            r["friendship"]+=1.0+float(player_charm)*0.15
            r["trust"]+=0.5
        "beg":
            r["respect"]-=0.5
            r["friendship"]+=0.2
        "steal_seen":
            r["trust"]-=8.0
            r["resentment"]+=8.0
            r["fear"]+=1.0
        "flirt":
            r["attraction"]+=1.0+float(player_charm)*0.35
            if float(r["trust"])>15.0:
                r["love"]+=0.4
        "apologize":
            r["resentment"]=maxf(0.0,float(r["resentment"])-2.0-float(player_charm)*0.1)
        "threaten":
            r["fear"]+=5.0
            r["trust"]-=3.0
            r["resentment"]+=2.0
    if not bool(r["romance"]) and float(r["love"])>30.0 and float(r["trust"])>25.0 and float(r["friendship"])>25.0:
        r["romance"]=true
    relations[id]=r
    return r

func status(id:String) -> String:
    if not relations.has(id): return "незнакомец"
    var r:Dictionary=relations[id]
    if bool(r["romance"]): return "романтические отношения"
    if float(r["resentment"])>35.0: return "враг"
    if float(r["fear"])>35.0: return "боится тебя"
    if float(r["friendship"])>35.0 and float(r["trust"])>25.0: return "близкий друг"
    if float(r["friendship"])>15.0: return "приятель"
    if float(r["trust"])<0.0: return "не доверяет"
    return "знакомый"

func can_flirt(id:String) -> bool:
    if not relations.has(id): return false
    var r:Dictionary=relations[id]
    return float(r["friendship"])>=8.0 and float(r["resentment"])<15.0

func to_dict() -> Dictionary:
    return relations.duplicate(true)

func from_dict(data:Dictionary):
    relations=data.duplicate(true)
