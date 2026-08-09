extends SceneTree

const NPCTradeNetwork=preload("res://scripts/npc_trade_network.gd")
const PlayerTradeSystem=preload("res://scripts/player_trade_system.gd")

class FakeProduction:
    var prices={"food":2.0,"wood":3.0,"stone":3.0,"cloth":5.0,"tools":8.0,"medicine":9.0}
    var hunger_pressure:=20.0

func _init():
    var trade=NPCTradeNetwork.new()
    var player=PlayerTradeSystem.new()
    var production=FakeProduction.new()
    trade.market_warehouses["port"]["medicine"]=20.0
    trade.market_warehouses["slums"]["medicine"]=0.0

    var coins=100
    var buy=player.buy("medicine","port",3.0,coins,trade,production)
    assert(bool(buy.get("ok",false)))
    coins=int(buy["coins"])
    assert(float(player.cargo.get("medicine",0))==3.0)

    var before=coins
    var sell=player.sell("medicine","slums",2.0,coins,trade,production)
    assert(bool(sell.get("ok",false)))
    coins=int(sell["coins"])
    assert(coins>before)
    assert(float(player.cargo.get("medicine",0))==1.0)

    var rent=player.rent_warehouse(1,coins)
    assert(bool(rent.get("ok",false)))
    coins=int(rent["coins"])
    assert(player.warehouse_rent_paid_until>=8)

    var store=player.store("medicine",1.0,1)
    assert(bool(store.get("ok",false)))
    assert(float(player.warehouse.get("medicine",0))==1.0)
    var withdraw=player.withdraw("medicine",1.0,1)
    assert(bool(withdraw.get("ok",false)))
    assert(float(player.cargo.get("medicine",0))==1.0)

    trade.market_warehouses["port"]["food"]=10.0
    var buy_food=player.buy("food","port",1.0,coins,trade,production)
    assert(bool(buy_food.get("ok",false)))
    coins=int(buy_food["coins"])
    var smuggle=player.smuggle("food","slums",1.0,coins,trade,production,20,0)
    assert(bool(smuggle.get("ok",false)))
    assert(player.contraband_heat>=0.0)

    print("SMOKE_V30_TRADE_OK")
    quit(0)
