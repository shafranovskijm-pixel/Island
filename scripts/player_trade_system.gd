extends RefCounted

var cargo:Dictionary={}
var warehouse:Dictionary={}
var warehouse_rent_paid_until:=0
var trade_profit:=0.0
var contraband_heat:=0.0
var events:Array=[]

func buy(resource:String,district:String,qty:float,coins:int,trade_network,production)->Dictionary:
    if qty<=0:return {"ok":false,"reason":"Количество должно быть больше нуля."}
    var stock=float(trade_network.market_warehouses.get(district,{}).get(resource,0.0))
    if stock<qty:return {"ok":false,"reason":"На складе недостаточно товара."}
    var price=trade_network._district_price(resource,district,production,true)
    var total=price*qty
    if float(coins)<total:return {"ok":false,"reason":"Не хватает денег."}
    trade_network.market_warehouses[district][resource]=stock-qty
    cargo[resource]=float(cargo.get(resource,0.0))+qty
    events.append({"type":"player_buy","text":"Куплено %.1f ед. %s в районе %s за %.1f."%[qty,resource,district,total]})
    return {"ok":true,"coins":int(floor(float(coins)-total)),"cost":total,"price":price}

func sell(resource:String,district:String,qty:float,coins:int,trade_network,production)->Dictionary:
    var have=float(cargo.get(resource,0.0));if qty<=0 or have<qty:return {"ok":false,"reason":"У тебя нет такого количества груза."}
    var price=trade_network._district_price(resource,district,production,false)
    var revenue=price*qty
    cargo[resource]=have-qty
    if float(cargo[resource])<=0.001:cargo.erase(resource)
    trade_network.market_warehouses[district][resource]=float(trade_network.market_warehouses.get(district,{}).get(resource,0.0))+qty
    trade_profit+=revenue
    events.append({"type":"player_sell","text":"Продано %.1f ед. %s в районе %s за %.1f."%[qty,resource,district,revenue]})
    return {"ok":true,"coins":int(floor(float(coins)+revenue)),"revenue":revenue,"price":price}

func rent_warehouse(day:int,coins:int)->Dictionary:
    var rent:=18
    if coins<rent:return {"ok":false,"reason":"Не хватает денег на аренду склада."}
    warehouse_rent_paid_until=maxi(day,warehouse_rent_paid_until)+7
    events.append({"type":"warehouse_rent","text":"Склад арендован до дня %d."%warehouse_rent_paid_until})
    return {"ok":true,"coins":coins-rent}

func store(resource:String,qty:float,day:int)->Dictionary:
    if day>warehouse_rent_paid_until:return {"ok":false,"reason":"Склад не арендован."}
    var have=float(cargo.get(resource,0.0));if qty<=0 or have<qty:return {"ok":false,"reason":"Недостаточно груза."}
    cargo[resource]=have-qty;if float(cargo[resource])<=0.001:cargo.erase(resource)
    warehouse[resource]=float(warehouse.get(resource,0.0))+qty
    return {"ok":true}

func withdraw(resource:String,qty:float,day:int)->Dictionary:
    if day>warehouse_rent_paid_until:return {"ok":false,"reason":"Склад закрыт из-за неоплаченной аренды."}
    var have=float(warehouse.get(resource,0.0));if qty<=0 or have<qty:return {"ok":false,"reason":"Недостаточно товара на складе."}
    warehouse[resource]=have-qty;if float(warehouse[resource])<=0.001:warehouse.erase(resource)
    cargo[resource]=float(cargo.get(resource,0.0))+qty
    return {"ok":true}

func smuggle(resource:String,district:String,qty:float,coins:int,trade_network,production,stealth:int,wanted:int)->Dictionary:
    var sale=sell(resource,district,qty,coins,trade_network,production)
    if not bool(sale.get("ok",false)):return sale
    var illegal_bonus=1.35
    var bonus=float(sale["revenue"])*(illegal_bonus-1.0)
    sale["coins"]=int(sale["coins"]+bonus)
    trade_profit+=bonus
    var detect_chance=clampf(0.35+qty*.03+float(wanted)*.08-float(stealth)*.035,0.05,0.90)
    var detected=randf()<detect_chance
    contraband_heat=clampf(contraband_heat+qty*(2.0 if detected else .6),0.0,100.0)
    events.append({"type":"smuggling","detected":detected,"text":"Контрабандная сделка %s."%("замечена стражей" if detected else "прошла незаметно")})
    sale["detected"]=detected;sale["bonus"]=bonus;return sale

func cargo_value(trade_network,production,district:String)->float:
    var total:=0.0
    for resource in cargo.keys():total+=float(cargo[resource])*trade_network._district_price(str(resource),district,production,false)
    return total

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out

func serialize()->Dictionary:return {"cargo":cargo,"warehouse":warehouse,"warehouse_rent_paid_until":warehouse_rent_paid_until,"trade_profit":trade_profit,"contraband_heat":contraband_heat}
func restore(data:Dictionary):
    var c=data.get("cargo",{});if typeof(c)==TYPE_DICTIONARY:cargo=c
    var w=data.get("warehouse",{});if typeof(w)==TYPE_DICTIONARY:warehouse=w
    warehouse_rent_paid_until=int(data.get("warehouse_rent_paid_until",0));trade_profit=float(data.get("trade_profit",0));contraband_heat=float(data.get("contraband_heat",0))
