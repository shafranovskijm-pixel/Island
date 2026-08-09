extends RefCounted
var ages:Dictionary={}
var births:Array=[]
var events:Array=[]
var last_year_day:=-1
const YEAR_DAYS:=60
func ensure_npcs(npcs:Array):
    for n in npcs:
        var id=str(n.get("id",""));if not ages.has(id):ages[id]={"age":randi_range(18,55),"birthday":randi_range(0,YEAR_DAYS-1),"parents":[],"children":[]}
func tick(npcs:Array,day:int):
    ensure_npcs(npcs);var yd=day%YEAR_DAYS
    if yd==last_year_day:return
    last_year_day=yd
    for n in npcs:
        var id=str(n.get("id",""));if not ages.has(id):continue
        if int(ages[id]["birthday"])==yd:
            ages[id]["age"]=int(ages[id]["age"])+1;events.append({"type":"birthday","npc_id":id,"text":"Сегодня день рождения у %s. Возраст: %d."%[n.get("name","жителя"),ages[id]["age"]]})
            if int(ages[id]["age"])>=65:n["stress"]=minf(100,float(n.get("stress",0))+1)
func register_child(parent_a:String,parent_b:String,name:String,day:int)->Dictionary:
    var id="child_%d_%d"%[day,births.size()+1];ages[id]={"age":0,"birthday":day%YEAR_DAYS,"parents":[parent_a,parent_b],"children":[]};births.append({"id":id,"name":name,"parents":[parent_a,parent_b],"born_day":day});
    for p in [parent_a,parent_b]:
        if ages.has(p):ages[p]["children"].append(id)
    events.append({"type":"birth","npc_id":id,"text":"Родился ребёнок: %s."%name});return births.back()
func heirs_for(npc_id:String)->Array:
    if not ages.has(npc_id):return []
    return ages[npc_id].get("children",[]).duplicate()
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"ages":ages,"births":births,"last_year_day":last_year_day}
func restore(data:Dictionary):
    var a=data.get("ages",{});if typeof(a)==TYPE_DICTIONARY:ages=a
    var b=data.get("births",[]);if typeof(b)==TYPE_ARRAY:births=b
    last_year_day=int(data.get("last_year_day",last_year_day))
