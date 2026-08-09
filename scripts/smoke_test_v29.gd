extends SceneTree

const Trade=preload("res://scripts/npc_trade_network.gd")

class DummyProduction:
    var resources={"food":120.0,"wood":80.0,"stone":60.0,"cloth":20.0,"tools":10.0,"medicine":6.0}
    var prices={"food":2.0,"wood":3.0,"stone":3.0,"cloth":5.0,"tools":8.0,"medicine":9.0}
    var hunger_pressure=20.0

func _init():
    var trade=Trade.new()
    var npcs=[
        {"id":"marek","name":"Марек","role":"торговец","alive":true,"money":30,"home_location":"market","pos":Vector2.ZERO,"stress":0,"influence":0},
        {"id":"smuggler","name":"Сайра","role":"контрабандистка","alive":true,"money":24,"home_location":"slums","pos":Vector2.ZERO,"stress":0,"influence":0}
    ]
    var props=[{"active":true,"kind":"farm","output":{"food":18.0}}]
    var prod=DummyProduction.new()
    var before_market=trade.district_stock("market","food")
    var result=trade.tick(npcs,props,prod,1,10.0)
    npcs=result["npcs"]
    assert(trade.trader_state.has("marek"))
    assert(trade.trader_state.has("smuggler"))
    assert(trade.district_stock("market","food")>=0.0)
    assert(trade.district_stock("port","food")>=0.0)
    assert(npcs[0].has("trade_profit"))
    print("SMOKE_V29_TRADE_OK before=",before_market," after=",trade.district_stock("market","food"))
    quit(0)
