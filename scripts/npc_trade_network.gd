extends RefCounted

var trader_state:Dictionary={}
var market_warehouses:Dictionary={}
var events:Array=[]
var last_day:=-1

func _init():
    market_warehouses={
        "market":{"food":24.0,"wood":8.0,"stone":6.0,"cloth":5.0,"tools":5.0,"medicine":2.0},
        "port":{"food":18.0,"wood":12.0,"stone":4.0,"cloth":8.0,"tools":3.0,"medicine":4.0},
        "slums":{"food":5.0,"wood":2.0,"stone":1.0,"cloth":1.0,"tools":1.0,"medicine":0.0}
    }

func tick(npcs:Array,properties:Array,production,day:int,hour:float)->Dictionary:
    if day==last_day or hour<9.0:return {"npcs":npcs,"warehouses":market_warehouses}
    last_day=day
    _ensure_traders(npcs)
    _collect_property_surplus(properties,production)
    _import_from_public_stock(production)
    _run_trades(npcs,production,day,hour)
    _move_goods_between_districts(npcs,production,day,hour)
    _update_merchant_status(npcs)
    return {"npcs":npcs,"warehouses":market_warehouses}

func _ensure_traders(npcs:Array):
    for n in npcs:
        if not bool(n.get("alive",true)):continue
        if not _is_trader(n):continue
        var id=str(n.get("id",""))
        if not trader_state.has(id):
            trader_state[id]={"inventory":{},"cash":maxf(8.0,float(n.get("money",10))),"profit":0.0,"loss":0.0,"route":"market_port","bankrupt_days":0}

func _is_trader(n:Dictionary)->bool:
    var role=str(n.get("role","")).to_lower()
    return "торгов" in role or "контраб" in role or str(n.get("id","")) in ["marek","smuggler"]

func _collect_property_surplus(properties:Array,production):
    for p in properties:
        if not bool(p.get("active",true)):continue
        var kind=str(p.get("kind",""));var out:Dictionary=p.get("output",{})
        var district="market"
        if kind in ["farm","lumberyard","quarry"]:district="market"
        if kind in ["inn","shop"]:district="market"
        if not market_warehouses.has(district):market_warehouses[district]={}
        for resource in out.keys():
            var qty=float(out[resource])*0.18
            if qty<=0:continue
            market_warehouses[district][resource]=float(market_warehouses[district].get(resource,0.0))+qty

func _import_from_public_stock(production):
    # Only a small fraction of island-level reserves becomes immediately tradable each day.
    for resource in ["food","wood","stone","cloth","tools","medicine"]:
        var public=float(production.resources.get(resource,0.0))
        if public<=0:continue
        var transfer=minf(public*0.025,8.0)
        production.resources[resource]=maxf(0.0,public-transfer)
        market_warehouses["port"][resource]=float(market_warehouses["port"].get(resource,0.0))+transfer

func _run_trades(npcs:Array,production,day:int,hour:float):
    for i in npcs.size():
        var n=npcs[i]
        if not bool(n.get("alive",true)) or not _is_trader(n):continue
        var id=str(n["id"]);var state:Dictionary=trader_state[id]
        var district=_trader_district(n)
        var warehouse:Dictionary=market_warehouses.get(district,{})
        var resource=_best_trade_resource(warehouse,production)
        if resource=="":continue
        var buy_price=_district_price(resource,district,production,false)
        var qty=minf(4.0,float(warehouse.get(resource,0.0)))
        var cash=float(state.get("cash",0.0));qty=minf(qty,cash/maxf(buy_price,0.1))
        if qty<=0.1:continue
        warehouse[resource]=float(warehouse.get(resource,0.0))-qty
        state["cash"]=cash-qty*buy_price
        var inv:Dictionary=state.get("inventory",{});inv[resource]=float(inv.get(resource,0.0))+qty;state["inventory"]=inv
        var target=_best_sell_district(resource,district,production)
        var sell_price=_district_price(resource,target,production,true)
        var revenue=qty*sell_price
        market_warehouses[target][resource]=float(market_warehouses[target].get(resource,0.0))+qty
        inv[resource]=maxf(0.0,float(inv.get(resource,0.0))-qty)
        state["cash"]=float(state["cash"])+revenue
        var pnl=revenue-qty*buy_price
        if pnl>=0:state["profit"]=float(state.get("profit",0.0))+pnl
        else:state["loss"]=float(state.get("loss",0.0))+abs(pnl)
        n["money"]=int(round(float(state["cash"])))
        n["trade_profit"]=float(state.get("profit",0.0))-float(state.get("loss",0.0))
        n["target"]=_district_position(target)
        npcs[i]=n;trader_state[id]=state
        events.append({"day":day,"hour":hour,"type":"trade","npc_id":id,"text":"%s перевёз %.1f ед. %s из %s в %s."%[n.get("name","Торговец"),qty,resource,district,target]})

func _move_goods_between_districts(npcs:Array,production,day:int,hour:float):
    # Hungry districts attract food even when no named merchant has enough capital.
    var slum_food=float(market_warehouses["slums"].get("food",0.0))
    if float(production.hunger_pressure)>35.0 and slum_food<8.0:
        var available=float(market_warehouses["market"].get("food",0.0))
        var qty=minf(4.0,maxf(0.0,available-8.0))
        if qty>0:
            market_warehouses["market"]["food"]-=qty;market_warehouses["slums"]["food"]+=qty
            events.append({"day":day,"hour":hour,"type":"relief_trade","text":"Торговцы перенаправили часть еды в Нижние улицы из-за голода."})

func _best_trade_resource(warehouse:Dictionary,production)->String:
    var best="";var score=-INF
    for resource in warehouse.keys():
        var stock=float(warehouse.get(resource,0.0));if stock<=0.2:continue
        var island_price=float(production.prices.get(resource,1.0))
        var s=island_price/(1.0+stock*.08)
        if s>score:score=s;best=str(resource)
    return best

func _best_sell_district(resource:String,origin:String,production)->String:
    var best=origin;var best_price=-INF
    for district in market_warehouses.keys():
        if district==origin:continue
        var p=_district_price(resource,str(district),production,true)
        if p>best_price:best_price=p;best=str(district)
    return best

func _district_price(resource:String,district:String,production,selling:bool)->float:
    var base=float(production.prices.get(resource,2.0))
    var stock=float(market_warehouses.get(district,{}).get(resource,0.0))
    var scarcity=clampf(1.65-(stock/18.0),0.55,2.2)
    if district=="slums" and resource=="food":scarcity*=1.15
    if district=="port" and resource in ["cloth","medicine"]:scarcity*=0.85
    var margin=1.10 if selling else 0.90
    return maxf(0.5,base*scarcity*margin)

func _trader_district(n:Dictionary)->String:
    var id=str(n.get("id",""));var home=str(n.get("home_location",""))
    if id=="smuggler" or home=="slums":return "slums"
    if home=="port":return "port"
    return "market"

func _district_position(id:String)->Vector2:
    return {"market":Vector2(650,545),"port":Vector2(1560,650),"slums":Vector2(690,850)}.get(id,Vector2(650,545))

func _update_merchant_status(npcs:Array):
    for i in npcs.size():
        var n=npcs[i];var id=str(n.get("id",""));if not trader_state.has(id):continue
        var s:Dictionary=trader_state[id];var net=float(s.get("cash",0.0))+_inventory_value(s.get("inventory",{}))
        if net<2.0:
            s["bankrupt_days"]=int(s.get("bankrupt_days",0))+1;n["stress"]=minf(100.0,float(n.get("stress",0))+5.0)
        else:s["bankrupt_days"]=0
        if net>120.0:n["social_class"]="wealthy";n["influence"]=int(n.get("influence",0))+1
        elif net>45.0:n["social_class"]="comfortable"
        elif int(s["bankrupt_days"])>=4:n["social_class"]="poor"
        trader_state[id]=s;npcs[i]=n

func _inventory_value(inv:Dictionary)->float:
    var total:=0.0
    for key in inv.keys():total+=float(inv[key])*2.0
    return total

func district_stock(district:String,resource:String)->float:
    return float(market_warehouses.get(district,{}).get(resource,0.0))

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out

func serialize()->Dictionary:return {"trader_state":trader_state,"market_warehouses":market_warehouses,"last_day":last_day}
func restore(data:Dictionary):
    var t=data.get("trader_state",{});if typeof(t)==TYPE_DICTIONARY:trader_state=t
    var w=data.get("market_warehouses",{});if typeof(w)==TYPE_DICTIONARY:market_warehouses=w
    last_day=int(data.get("last_day",last_day))
