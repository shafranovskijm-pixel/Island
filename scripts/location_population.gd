extends RefCounted

func extra_npcs(points:Dictionary)->Array:
    return [
        _npc("king","Король Эдрик","король",points["king"],"crown","castle",Color("#d8c06a"),"сохранить власть и династию",85),
        _npc("queen","Королева Мира","королева",points["queen"],"crown","castle",Color("#d7a0b8"),"усилить влияние своей семьи",72),
        _npc("chancellor","Канцлер Освальд","канцлер",points["chancellor"],"crown","castle",Color("#9b8769"),"стать незаменимым при дворе",80),
        _npc("captain_guard","Капитан Рейн","капитан стражи",points["captain_guard"],"guard","guard_barracks",Color("#657d9c"),"удержать порядок любой ценой",62),
        _npc("priest","Отец Северан","жрец Рассвета",points["priest"],"temple","temple",Color("#e2dfc8"),"искоренить запретную магию",58),
        _npc("undertaker","Мортен","могильщик",points["undertaker"],"","graveyard",Color("#77756f"),"не задавать лишних вопросов и дожить до старости",18),
        _npc("vampire","Леди Веспера","неизвестная дворянка",points["vampire"],"occult","crypt",Color("#8c5d70"),"питать тайную кровь острова и не раскрыться",76),
        _npc("cult_leader","Астер","наставник Ордена",points["cult_leader"],"occult","occult_lodge",Color("#69558c"),"вернуть Ордену утраченную силу",69),
        _npc("beggar","Кривой Нел","нищий",points["beggar"],"","slums",Color("#8b775e"),"пережить ещё одну неделю",4),
        _npc("smuggler","Сайра","контрабандистка",points["smuggler"],"underworld","slums",Color("#785f65"),"подчинить чёрный рынок",44),
        _npc("archmage","Талем","маг-исследователь",points["mage"],"","mage_ruins",Color("#6585c9"),"понять, почему мёртвые острова помнят имена",31)
    ]

func _npc(id:String,name:String,role:String,pos:Vector2,faction:String,home_location:String,color:Color,goal:String,influence:int)->Dictionary:
    return {
        "id":id,"name":name,"role":role,"pos":pos,"color":color,"rel":0,"memory":[],"suspicion":0,
        "faction":faction,"home_location":home_location,"goal":goal,"influence":influence,
        "location_id":home_location,"alive":true,"hidden":home_location in ["crypt","occult_lodge"]
    }

func location_dialogue(npc:Dictionary,location_id:String)->Array:
    match str(npc.get("id","")):
        "king": return ["Просить аудиенции","Говорить о делах острова","Уйти"]
        "queen": return ["Предложить услугу двору","Поговорить о слухах","Уйти"]
        "chancellor": return ["Искать покровительство","Предложить информацию","Уйти"]
        "captain_guard": return ["Предложить помощь страже","Спросить о преступлениях","Уйти"]
        "priest": return ["Попросить благословение","Говорить о запретной магии","Уйти"]
        "undertaker": return ["Помочь с могилами","Спросить о ночных посетителях","Уйти"]
        "vampire": return ["Говорить с Весперой","Предложить кровь или услугу","Уйти"]
        "cult_leader": return ["Просить посвящения","Предложить участие в ритуале","Уйти"]
        "beggar": return ["Сесть рядом и поговорить","Поделиться монетой","Уйти"]
        "smuggler": return ["Искать работу","Спросить о тайных путях","Уйти"]
        "archmage": return ["Помочь в исследовании","Спросить о древней магии","Уйти"]
    return ["Поговорить","Попросить помощи","Уйти"]
