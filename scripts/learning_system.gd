extends RefCounted

var knowledge := {}
var study_progress := {}
var read_books := {}
var events:Array=[]

var books := {
    "foraging_1":{"title":"Съедобное и опасное на островах","skill":"foraging","theory":2.0,"location":"library"},
    "farming_1":{"title":"Основы земледелия","skill":"farming","theory":2.0,"location":"library"},
    "building_1":{"title":"Дом из дерева и камня","skill":"building","theory":2.0,"location":"library"},
    "smithing_1":{"title":"Руда, жар и металл","skill":"smithing","theory":2.0,"location":"library"},
    "cooking_1":{"title":"Пища простого островитянина","skill":"foraging","theory":1.25,"location":"library"},
    "textiles_1":{"title":"Верёвка, ткань и парусина","skill":"building","theory":1.25,"location":"library"},
    "trade_1":{"title":"Счёт, цена и прибыль","skill":"trade","theory":2.0,"location":"library"},
    "sailing_1":{"title":"Парус, ветер и течение","skill":"sailing","theory":1.5,"location":"library"},
    "medicine_1":{"title":"Травы, жар и раны","skill":"medicine","theory":1.5,"location":"temple_archive"},
    "alchemy_1":{"title":"Перегонка, настои и яды","skill":"medicine","theory":1.75,"location":"temple_archive"},
    "politics_1":{"title":"О власти и долгах знати","skill":"politics","theory":1.5,"location":"castle"},
    "occult_1":{"title":"Запретные знаки Пепельной Луны","skill":"magic","theory":2.5,"location":"occult_lodge"},
    "locks_1":{"title":"Замки и механизмы","skill":"stealth","theory":1.5,"location":"library"}
}

var mentors := {
    "fisher":{"skills":["sailing","foraging","fishing"],"min_rel":1},
    "marek":{"skills":["trade"],"min_rel":1},
    "archmage":{"skills":["magic"],"min_rel":1},
    "captain_guard":{"skills":["labor","politics","weapons"],"min_rel":1},
    "undertaker":{"skills":["foraging","medicine"],"min_rel":1},
    "priest":{"skills":["medicine","alchemy"],"min_rel":1},
    "smuggler":{"skills":["stealth","trade","thievery"],"min_rel":1},
    "librarian":{"skills":["building","smithing","foraging"],"min_rel":2}
}

func study_book(book_id:String,location_id:String,day:int,hour:float)->Dictionary:
    if not books.has(book_id):return {"ok":false,"reason":"Такой книги здесь нет."}
    var b:Dictionary=books[book_id]
    if str(b["location"])!=location_id:return {"ok":false,"reason":"Эта книга находится в другом месте."}
    var skill=str(b["skill"]);knowledge[skill]=float(knowledge.get(skill,0))+float(b["theory"])
    read_books[book_id]=int(read_books.get(book_id,0))+1
    study_progress[skill]=float(study_progress.get(skill,0))+1.0
    _log(day,hour,"study","Прочитал: «%s». Теория навыка %s выросла."%[b["title"],skill])
    return {"ok":true,"skill":skill,"theory":knowledge[skill],"title":b["title"]}

func mentor_lesson(npc:Dictionary,skill:String,day:int,hour:float)->Dictionary:
    var id=str(npc.get("id",""));if not mentors.has(id):return {"ok":false,"reason":"Этот человек не умеет этому учить."}
    var m:Dictionary=mentors[id]
    if skill not in m["skills"]:return {"ok":false,"reason":"Наставник не обучает этому навыку."}
    if int(npc.get("rel",0))<int(m["min_rel"]):return {"ok":false,"reason":"Сначала нужно заслужить доверие наставника."}
    knowledge[skill]=float(knowledge.get(skill,0))+1.0
    study_progress[skill]=float(study_progress.get(skill,0))+1.5
    _log(day,hour,"mentor","%s дал урок по навыку %s."%[npc.get("name","Наставник"),skill])
    return {"ok":true,"skill":skill}

func practice(skill:String,amount:float,day:int,hour:float):
    var theory_bonus=1.0+minf(0.75,float(knowledge.get(skill,0))*.08)
    study_progress[skill]=float(study_progress.get(skill,0))+amount*theory_bonus
    if amount>=0.8:_log(day,hour,"practice","Практика улучшает навык %s."%skill)

func effective_bonus(skill:String)->int:
    return int(floor(float(knowledge.get(skill,0))*.35+float(study_progress.get(skill,0))*.20))

func available_books(location_id:String)->Array:
    var out:Array=[]
    for id in books.keys():
        if str(books[id]["location"])==location_id:
            var b=books[id].duplicate(true);b["id"]=id;out.append(b)
    return out

func _log(day:int,hour:float,type:String,text:String):
    events.append({"day":day,"hour":hour,"type":type,"text":text})

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out

func serialize()->Dictionary:return {"knowledge":knowledge,"study_progress":study_progress,"read_books":read_books}
func restore(data:Dictionary):
    if typeof(data.get("knowledge",{}))==TYPE_DICTIONARY:knowledge=data["knowledge"]
    if typeof(data.get("study_progress",{}))==TYPE_DICTIONARY:study_progress=data["study_progress"]
    if typeof(data.get("read_books",{}))==TYPE_DICTIONARY:read_books=data["read_books"]
