extends RefCounted

var interiors := {
    "castle_courtyard":{"name":"Двор замка","parent":"castle","access":"public_guarded","tags":["court","guard"],"spawn":Vector2(1040,520)},
    "castle_hall":{"name":"Тронный зал","parent":"castle","access":"royal","tags":["royalty","politics"],"spawn":Vector2(1060,485)},
    "royal_chambers":{"name":"Королевские покои","parent":"castle","access":"royal_private","tags":["royalty","secret","wealth"],"spawn":Vector2(1010,465)},
    "castle_dungeon":{"name":"Подземелье замка","parent":"castle","access":"guard","tags":["jail","torture","crime"],"spawn":Vector2(1190,690)},
    "barracks_jail":{"name":"Тюремные камеры","parent":"guard_barracks","access":"guard","tags":["jail","law"],"spawn":Vector2(1250,655)},
    "tavern_common":{"name":"Общий зал таверны","parent":"tavern","access":"public","tags":["drink","gambling","romance","rumors"],"spawn":Vector2(1500,850)},
    "tavern_rooms":{"name":"Комнаты над таверной","parent":"tavern","access":"rent","tags":["sleep","romance","privacy"],"spawn":Vector2(1470,820)},
    "crypt_upper":{"name":"Верхний склеп","parent":"crypt","access":"secret","tags":["undead","loot","occult"],"spawn":Vector2(315,245)},
    "crypt_lower":{"name":"Нижний склеп","parent":"crypt","access":"occult","tags":["vampire","ritual","boss","secret"],"spawn":Vector2(300,220)},
    "temple_nave":{"name":"Зал храма","parent":"temple","access":"public","tags":["faith","healing"],"spawn":Vector2(785,280)},
    "temple_archive":{"name":"Архив храма","parent":"temple","access":"temple","tags":["books","occult_hunt","secret"],"spawn":Vector2(810,255)},
    "occult_chamber":{"name":"Ритуальный зал Ордена","parent":"occult_lodge","access":"occult","tags":["ritual","magic","secret"],"spawn":Vector2(525,255)}
}

func can_enter(id:String,state:Dictionary)->Dictionary:
    if not interiors.has(id): return {"ok":false,"reason":"Неизвестная внутренняя зона."}
    var access=str(interiors[id].get("access","public"))
    match access:
        "public": return {"ok":true,"reason":""}
        "public_guarded":
            if int(state.get("wanted",0))<=1: return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Стража узнаёт тебя и перекрывает проход."}
        "royal":
            if bool(state.get("royal_invitation",false)) or int(state.get("politics",0))>=3 or int(state.get("influence",0))>=4: return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Нужна аудиенция, положение при дворе или иной способ пройти."}
        "royal_private":
            if int(state.get("stealth",0))>=5 or bool(state.get("royal_access",false)): return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Королевские покои охраняются."}
        "guard":
            if int(state.get("guard_trust",0))>=2 or bool(state.get("prisoner",false)): return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Стража не позволяет войти."}
        "rent":
            if bool(state.get("room_rented",false)): return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Сначала нужно снять комнату."}
        "secret":
            if bool(state.get("crypt_known",false)) or int(state.get("stealth",0))>=3: return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Ты не знаешь безопасного пути внутрь."}
        "occult":
            if bool(state.get("occult_member",false)) or int(state.get("magic",0))>=4: return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Проход открывается только посвящённым или тем, кто понимает знаки."}
        "temple":
            if int(state.get("temple_trust",0))>=2: return {"ok":true,"reason":""}
            return {"ok":false,"reason":"Архив закрыт для прихожан."}
    return {"ok":true,"reason":""}

func name_of(id:String)->String:
    return str(interiors.get(id,{}).get("name","Неизвестное место"))
