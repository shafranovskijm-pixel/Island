extends RefCounted

var events:Array=[]

func process_death(npcs:Array,dead_id:String,properties:Array,housing,day:int,hour:float)->Dictionary:
    var dead_idx=_find(npcs,dead_id)
    if dead_idx<0:return {"npcs":npcs,"properties":properties}
    var dead=npcs[dead_idx]
    var heir_id=_choose_heir(npcs,dead)
    var money=float(dead.get("money",0))
    var home_id=str(dead.get("home_id",""))
    var inherited_properties:Array=[]

    if heir_id!="":
        var heir_idx=_find(npcs,heir_id)
        if heir_idx>=0:
            npcs[heir_idx]["money"]=float(npcs[heir_idx].get("money",0))+money
            npcs[heir_idx]["stress"]=minf(100.0,float(npcs[heir_idx].get("stress",0))+18.0)
            if home_id!="" and str(npcs[heir_idx].get("home_id",""))=="":
                npcs[heir_idx]["home_id"]=home_id
            for p in properties:
                if str(p.get("owner",""))==dead_id:
                    p["owner"]=heir_id
                    inherited_properties.append(str(p.get("name","владение")))
            events.append({"day":day,"hour":hour,"type":"inheritance","text":"%s унаследовал имущество %s."%[npcs[heir_idx]["name"],dead.get("name",dead_id)]})
    else:
        for p in properties:
            if str(p.get("owner",""))==dead_id:
                p["owner"]="crown"
                inherited_properties.append(str(p.get("name","владение")))
        if money>0:
            events.append({"day":day,"hour":hour,"type":"escheat","text":"Имущество %s без наследника переходит под управление Короны."%dead.get("name",dead_id)})

    _free_job(dead_id,properties)
    dead["money"]=0
    dead["employment_property"]=""
    npcs[dead_idx]=dead
    return {"npcs":npcs,"properties":properties,"heir":heir_id,"inherited_properties":inherited_properties}

func _choose_heir(npcs:Array,dead:Dictionary)->String:
    var spouse=str(dead.get("spouse_id",""))
    if spouse!="" and _alive(npcs,spouse):return spouse
    var children=dead.get("children",[])
    if typeof(children)==TYPE_ARRAY:
        for child in children:
            var id=str(child)
            if _alive(npcs,id):return id
    var family=str(dead.get("family_id",""))
    if family!="":
        var best:="";var influence:=-1
        for n in npcs:
            if bool(n.get("alive",true)) and str(n.get("family_id",""))==family and str(n.get("id",""))!=str(dead.get("id","")):
                if int(n.get("influence",0))>influence:
                    best=str(n["id"]);influence=int(n.get("influence",0))
        return best
    return ""

func _free_job(dead_id:String,properties:Array):
    for p in properties:
        if dead_id in p.get("workers",[]):p["workers"].erase(dead_id)

func _find(npcs:Array,id:String)->int:
    for i in npcs.size():
        if str(npcs[i].get("id",""))==id:return i
    return -1

func _alive(npcs:Array,id:String)->bool:
    var idx=_find(npcs,id)
    return idx>=0 and bool(npcs[idx].get("alive",true))

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
