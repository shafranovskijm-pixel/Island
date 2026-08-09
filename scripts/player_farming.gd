extends RefCounted

var plots:Array=[]
var events:Array=[]
var next_id:=1

func create_plot(owner:String,pos:Vector2)->Dictionary:
    var p={"id":"plot_%d"%next_id,"owner":owner,"pos":pos,"crop":"","stage":0.0,"watered":false,"fertility":100.0,"ready":false,"last_day":0}
    next_id+=1;plots.append(p);return p

func plant(plot_id:String,crop:String,inventory:Array,knowledge,day:int,hour:float)->Dictionary:
    var idx=_find(plot_id);if idx<0:return {"ok":false,"reason":"Грядка не найдена."}
    if float(knowledge.knowledge.get("farming",0.0))<1.0:return {"ok":false,"reason":"Ты пока не знаешь основ земледелия."}
    var seed_idx=_seed_index(inventory,crop);if seed_idx<0:return {"ok":false,"reason":"Нет семян."}
    _consume_seed(inventory,seed_idx)
    plots[idx]["crop"]=crop;plots[idx]["stage"]=0.05;plots[idx]["ready"]=false;plots[idx]["last_day"]=day
    events.append({"day":day,"hour":hour,"type":"plant","text":"Посеяна культура: %s."%crop});return {"ok":true}

func water(plot_id:String,day:int,hour:float)->Dictionary:
    var idx=_find(plot_id);if idx<0:return {"ok":false,"reason":"Грядка не найдена."}
    plots[idx]["watered"]=true;events.append({"day":day,"hour":hour,"type":"water","text":"Грядка полита."});return {"ok":true}

func tick(day:int,weather:String="clear"):
    for i in plots.size():
        var p=plots[i]
        if str(p.get("crop",""))=="" or bool(p.get("ready",false)) or int(p.get("last_day",0))>=day:continue
        var growth:=0.10
        if bool(p.get("watered",false)) or weather=="rain":growth+=0.10
        growth*=clampf(float(p.get("fertility",100))/100.0,0.25,1.2)
        p["stage"]=minf(1.0,float(p["stage"])+growth);p["ready"]=float(p["stage"])>=1.0;p["watered"]=false;p["last_day"]=day;p["fertility"]=maxf(15.0,float(p["fertility"])-1.5);plots[i]=p

func harvest(plot_id:String,inventory:Array,knowledge,day:int,hour:float)->Dictionary:
    var idx=_find(plot_id);if idx<0:return {"ok":false,"reason":"Грядка не найдена."}
    var p=plots[idx];if not bool(p.get("ready",false)):return {"ok":false,"reason":"Урожай ещё не созрел."}
    var lvl=int(knowledge.effective_bonus("farming"));var qty=4.0+lvl*1.3
    var crop=str(p["crop"])
    _add_food_resource(inventory,qty,crop)
    knowledge.practice("farming",2.0,day,hour)
    plots[idx]["crop"]="";plots[idx]["stage"]=0.0;plots[idx]["ready"]=false
    events.append({"day":day,"hour":hour,"type":"harvest","text":"Собран урожай %s x%.1f."%[crop,qty]});return {"ok":true,"quantity":qty}

func _add_food_resource(inventory:Array,qty:float,crop:String):
    for item in inventory:
        if str(item.get("kind",""))=="resource" and str(item.get("resource",""))=="food":
            item["quantity"]=float(item.get("quantity",1.0))+qty
            return
    inventory.append({"id":"crop_%d"%Time.get_ticks_usec(),"name":"урожай: %s"%crop,"kind":"resource","resource":"food","quantity":qty,"value":2})

func _consume_seed(inventory:Array,index:int):
    var q=float(inventory[index].get("quantity",1.0))
    if q>1.0:inventory[index]["quantity"]=q-1.0
    else:inventory.remove_at(index)

func _seed_index(inventory:Array,crop:String)->int:
    for i in inventory.size():
        if str(inventory[i].get("kind",""))=="seed" and str(inventory[i].get("crop",inventory[i].get("subtype","")))==crop:return i
    return -1

func _find(id:String)->int:
    for i in plots.size():
        if str(plots[i].get("id",""))==id:return i
    return -1

func serialize()->Dictionary:return {"plots":plots,"next_id":next_id}
func restore(data:Dictionary):
    var p=data.get("plots",[]);if typeof(p)==TYPE_ARRAY:plots=p
    next_id=int(data.get("next_id",next_id))
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
