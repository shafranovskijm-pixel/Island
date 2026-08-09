extends RefCounted

var locations := {
    "port": {"name":"Старый порт","center":Vector2(1560,650),"radius":240.0,"public":true,"tags":["trade","ships","crime"],"faction":"merchants"},
    "market": {"name":"Рыночная площадь","center":Vector2(650,545),"radius":210.0,"public":true,"tags":["trade","rumors"],"faction":"merchants"},
    "tavern": {"name":"Сломанный Маяк","center":Vector2(1500,850),"radius":125.0,"public":true,"tags":["drink","romance","rumors","gambling"],"faction":""},
    "castle": {"name":"Замок Чёрного Утёса","center":Vector2(1050,510),"radius":235.0,"public":false,"tags":["royalty","politics","guard","wealth"],"faction":"crown"},
    "guard_barracks": {"name":"Казармы стражи","center":Vector2(1240,640),"radius":145.0,"public":false,"tags":["guard","law","jail"],"faction":"guard"},
    "graveyard": {"name":"Старое кладбище","center":Vector2(370,300),"radius":225.0,"public":true,"tags":["death","occult","night"],"faction":""},
    "crypt": {"name":"Подземный склеп","center":Vector2(315,245),"radius":85.0,"public":false,"tags":["underground","vampire","occult","loot"],"faction":"occult"},
    "occult_lodge": {"name":"Дом Ордена Пепельной Луны","center":Vector2(530,260),"radius":135.0,"public":false,"tags":["occult","magic","ritual"],"faction":"occult"},
    "temple": {"name":"Храм Рассвета","center":Vector2(780,280),"radius":155.0,"public":true,"tags":["faith","healing","politics"],"faction":"temple"},
    "slums": {"name":"Нижние улицы","center":Vector2(690,850),"radius":250.0,"public":true,"tags":["poverty","begging","crime","black_market"],"faction":"underworld"},
    "mage_ruins": {"name":"Руины Звёздного Круга","center":Vector2(1030,225),"radius":180.0,"public":true,"tags":["magic","ruins","secret"],"faction":""},
    "fisher_cove": {"name":"Рыбацкая бухта","center":Vector2(390,820),"radius":190.0,"public":true,"tags":["fishing","sea","work"],"faction":""}
}

var secrets := {
    "crypt_entrance":false,
    "occult_order":false,
    "vampires":false,
    "castle_passage":false
}

func current_location(pos:Vector2) -> String:
    var best := "wilderness"
    var best_d := INF
    for id in locations.keys():
        var loc:Dictionary=locations[id]
        var d:=pos.distance_to(loc["center"])
        if d<=float(loc["radius"]) and d<best_d:
            best=id;best_d=d
    return best

func location_name(id:String)->String:
    if locations.has(id): return str(locations[id]["name"])
    return "Дикие земли"

func can_enter(id:String, state:Dictionary)->Dictionary:
    if not locations.has(id): return {"ok":true,"reason":""}
    if bool(locations[id].get("public",true)): return {"ok":true,"reason":""}
    match id:
        "castle":
            if int(state.get("influence",0))>=3 or bool(state.get("royal_invitation",false)) or int(state.get("stealth",0))>=4:
                return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Стража не пускает тебя в замок без причины, влияния или хитрости."}
        "guard_barracks":
            if int(state.get("wanted",0))>0: return {"ok":true,"reason":"Стража будет очень рада твоему визиту."}
            if int(state.get("guard_trust",0))>=2: return {"ok":true,"reason":""}
            return {"ok":false,"reason":"В казармы посторонним нельзя."}
        "crypt":
            if secrets["crypt_entrance"] or int(state.get("occult",0))>=2 or int(state.get("stealth",0))>=3:
                return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Ты пока не знаешь, как открыть древний вход в склеп."}
        "occult_lodge":
            if secrets["occult_order"] or int(state.get("magic",0))>=3:
                return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Обычный дом кажется пустым. Ты не знаешь правильного знака."}
    return {"ok":true,"reason":""}

func discover(secret:String):
    if secrets.has(secret): secrets[secret]=true

func spawn_points()->Dictionary:
    return {
        "king":Vector2(1060,485),"queen":Vector2(1015,520),"chancellor":Vector2(1110,545),
        "captain_guard":Vector2(1230,625),"priest":Vector2(785,280),
        "undertaker":Vector2(405,330),"vampire":Vector2(315,245),"cult_leader":Vector2(525,255),
        "beggar":Vector2(665,865),"smuggler":Vector2(735,825),"mage":Vector2(1020,225)
    }
