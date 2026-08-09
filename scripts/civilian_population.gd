extends RefCounted

var rng:=RandomNumberGenerator.new()
var serial:=0

func setup()->Array:
    rng.seed=77193
    var result:Array=[]
    for i in 5:result.append(_make("крестьянин","farmer",Vector2(230+rng.randi_range(0,180),600+rng.randi_range(-120,120))))
    for i in 2:result.append(_make("строитель","builder",Vector2(760+rng.randi_range(-90,90),760+rng.randi_range(-70,70))))
    for i in 2:result.append(_make("лесоруб","lumberjack",Vector2(1180+rng.randi_range(-80,80),920+rng.randi_range(-80,80))))
    for i in 2:result.append(_make("каменщик","miner",Vector2(1180+rng.randi_range(-80,80),300+rng.randi_range(-70,70))))
    result.append(_make("ремесленник","artisan",Vector2(720,590)))
    result.append(_make("лекарь","healer",Vector2(800,300)))
    return result

func _make(role:String,job:String,pos:Vector2)->Dictionary:
    serial+=1
    var names=["Олли","Фарен","Мара","Дорн","Элла","Рик","Нора","Хольт","Брин","Седа","Торн","Лея","Варн","Мина"]
    var name=names[(serial-1)%names.size()]+" "+str(serial)
    return {"id":"civilian_%d"%serial,"name":name,"role":role,"job":job,"pos":pos,"color":Color("#8f916d"),"rel":0,"memory":[],"suspicion":0,"alive":true,"faction":"","influence":rng.randi_range(0,8),"money":rng.randi_range(1,10),"goal":"заработать на жизнь и обеспечить себя","home_location":"slums" if rng.randf()<.45 else "market"}
