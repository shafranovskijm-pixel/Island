extends RefCounted
var livestock:Array=[]
var events:Array=[]
var next_id:=1
var last_day:=-1
func buy(species:String,owner:String="player")->Dictionary:
    var defs={"chicken":{"name":"курица","price":6,"product":"egg"},"goat":{"name":"коза","price":18,"product":"milk"},"cow":{"name":"корова","price":35,"product":"milk"},"horse":{"name":"лошадь","price":45,"product":""}}
    if not defs.has(species):return {"ok":false,"reason":"Неизвестное животное."}
    var d=defs[species];var a={"id":"livestock_%d"%next_id,"species":species,"name":d["name"],"owner":owner,"hunger":10.0,"health":100.0,"bond":15.0,"pregnant":false,"pregnancy_days":0,"product":d["product"],"last_product_day":-1,"mounted":false,"born_day":last_day};next_id+=1;livestock.append(a);return {"ok":true,"animal":a,"price":d["price"]}
func tick(day:int,food_store:float)->float:
    if day==last_day:return food_store
    last_day=day;var births:Array=[]
    for a in livestock:
        if str(a.get("owner",""))!="player":continue
        if food_store>=1:food_store-=1;a["hunger"]=maxf(0,float(a["hunger"])-35)
        else:a["hunger"]=minf(100,float(a["hunger"])+25)
        if float(a["hunger"])>80:a["health"]=maxf(0,float(a["health"])-8)
        if bool(a.get("pregnant",false)):
            a["pregnancy_days"]=int(a["pregnancy_days"])+1
            if int(a["pregnancy_days"])>=8:
                births.append(str(a["species"]));a["pregnant"]=false;a["pregnancy_days"]=0
    for species in births:
        var born=buy(species,"player")
        if bool(born.get("ok",false)):
            var child:Dictionary=born["animal"];child["bond"]=5.0;child["hunger"]=20.0;child["born_day"]=day
            for i in livestock.size():
                if str(livestock[i].get("id",""))==str(child["id"]):livestock[i]=child;break
            events.append({"type":"livestock_birth","species":species,"animal_id":child["id"],"text":"В хозяйстве появился детёныш: %s."%child["name"]})
    return food_store
func collect_products(day:int)->Dictionary:
    var out={"egg":0.0,"milk":0.0}
    for a in livestock:
        if float(a.get("health",0))<35 or int(a.get("last_product_day",-1))==day:continue
        var p=str(a.get("product",""));if p=="":continue
        out[p]=float(out.get(p,0))+(1.0 if p=="egg" else (3.0 if str(a["species"])=="cow" else 1.5));a["last_product_day"]=day
    return out
func breed(species:String)->Dictionary:
    var candidates=[]
    for a in livestock:
        if str(a.get("species",""))==species and float(a.get("health",0))>60 and not bool(a.get("pregnant",false)):candidates.append(a)
    if candidates.size()<2:return {"ok":false,"reason":"Нужны как минимум два здоровых животных одного вида."}
    candidates[0]["pregnant"]=true;candidates[0]["pregnancy_days"]=0;events.append({"type":"livestock_breeding","species":species,"text":"В хозяйстве ожидается потомство."});return {"ok":true}
func first_horse()->Dictionary:
    for a in livestock:
        if str(a.get("species",""))=="horse" and float(a.get("health",0))>20:return a
    return {}
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"livestock":livestock,"next_id":next_id,"last_day":last_day}
func restore(data:Dictionary):
    var l=data.get("livestock",[]);if typeof(l)==TYPE_ARRAY:livestock=l
    next_id=int(data.get("next_id",next_id));last_day=int(data.get("last_day",last_day))
