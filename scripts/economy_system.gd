extends RefCounted

var rng := RandomNumberGenerator.new()
var events:Array = []
var market := {
    "food":{"stock":18.0,"base_price":2.0,"price":2.0,"demand":1.0},
    "fish":{"stock":10.0,"base_price":2.0,"price":2.0,"demand":1.0},
    "ale":{"stock":14.0,"base_price":1.0,"price":1.0,"demand":1.0},
    "cloth":{"stock":7.0,"base_price":5.0,"price":5.0,"demand":0.8},
    "rope":{"stock":5.0,"base_price":4.0,"price":4.0,"demand":0.7}
}
var jobs := {
    "dock_worker":{"name":"грузчик в порту","wage":2,"openings":2},
    "fisher_helper":{"name":"помощник рыбака","wage":1,"openings":1},
    "tavern_hand":{"name":"работник таверны","wage":1,"openings":1},
    "guard_aux":{"name":"помощник стражи","wage":2,"openings":1}
}
var tax_rate := 0.08

func setup():
    rng.randomize()

func tick(npcs:Array, day:int, hour:float, delta:float) -> Array:
    _update_prices(delta)
    for i in npcs.size():
        var npc=npcs[i]
        if not npc.has("income"): npc["income"]=rng.randi_range(0,3)
        if not npc.has("debt"): npc["debt"]=0
        if hour>17.8 and hour<18.2 and rng.randf()<delta*0.2:
            var income:int=int(npc.get("income",0))
            npc["money"]=int(npc.get("money",0))+income
            if int(npc["debt"])>0 and income>0:
                var payment:=mini(int(npc["debt"]),maxi(1,income/2))
                npc["debt"]-=payment
                npc["money"]-=payment
        if float(npc.get("needs",{}).get("hunger",0))>75.0 and int(npc.get("money",0))<=0:
            npc["stress"]=minf(100.0,float(npc.get("stress",0))+delta*0.25)
        npcs[i]=npc
    return npcs

func _update_prices(delta:float):
    for key in market.keys():
        var item:Dictionary=market[key]
        var scarcity:=1.0
        if float(item["stock"])<5.0: scarcity=1.8
        elif float(item["stock"])<10.0: scarcity=1.25
        var target:=float(item["base_price"])*float(item["demand"])*scarcity*(1.0+tax_rate)
        item["price"]=lerpf(float(item["price"]),target,minf(1.0,delta*0.08))
        market[key]=item

func consume(kind:String, amount:float, day:int, hour:float):
    if not market.has(kind): return
    var item:Dictionary=market[kind]
    item["stock"]=maxf(0.0,float(item["stock"])-amount)
    market[kind]=item
    if float(item["stock"])<3.0:
        _log(day,hour,"На острове почти закончился товар: %s."%kind)

func supply(kind:String, amount:float, day:int, hour:float):
    if not market.has(kind): return
    var item:Dictionary=market[kind]
    item["stock"]+=amount
    market[kind]=item
    _log(day,hour,"Поставка пополнила запас %s (+%d)."%[kind,int(amount)])

func set_tax(value:float, day:int, hour:float):
    tax_rate=clampf(value,0.0,0.5)
    _log(day,hour,"Совет изменил портовый налог до %d%%."%int(tax_rate*100.0))

func price(kind:String) -> int:
    if not market.has(kind): return 0
    return maxi(1,int(round(float(market[kind]["price"]))))

func borrow(npc:Dictionary, amount:int) -> Dictionary:
    npc["money"]=int(npc.get("money",0))+amount
    npc["debt"]=int(npc.get("debt",0))+int(ceil(float(amount)*1.2))
    return npc

func _log(day:int,hour:float,text:String):
    if events.size()>100: events.pop_front()
    events.append({"day":day,"hour":hour,"text":text})
