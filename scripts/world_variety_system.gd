extends RefCounted

var weather:="clear"
var season_day:=0
var wildlife:Dictionary={"fish":55.0,"boar":14.0,"deer":18.0,"rats":22.0,"bats":10.0,"wolves":4.0}
var public_mood:Dictionary={"fear":5.0,"hope":45.0,"anger":8.0,"curiosity":20.0}
var rumors:Array=[]
var calendar:Array=[]
var events:Array=[]
var last_day:=-1

func _init():
    calendar=[
        {"day_mod":9,"name":"Рыбацкая ярмарка","location":"fisher_cove"},
        {"day_mod":13,"name":"Ночной рынок","location":"slums"},
        {"day_mod":17,"name":"День основания острова","location":"market"},
        {"day_mod":21,"name":"Поминовение мёртвых","location":"graveyard"}
    ]

func tick(day:int,hour:float,ctx:Dictionary):
    if day==last_day or hour<5.0:return
    last_day=day;season_day=(season_day+1)%60
    _roll_weather(ctx);_wildlife_cycle(ctx);_mood_cycle(ctx);_calendar_events(day);_rumor_decay()

func _roll_weather(ctx:Dictionary):
    var roll=randf()
    var old=weather
    if roll<.10:weather="storm"
    elif roll<.25:weather="rain"
    elif roll<.33:weather="fog"
    elif roll<.42:weather="wind"
    else:weather="clear"
    if old!=weather:events.append({"type":"weather","text":"Погода меняется: %s."%weather})

func _wildlife_cycle(ctx:Dictionary):
    wildlife["fish"]=clampf(float(wildlife["fish"])+(5 if weather in ["rain","wind"] else 1)-float(ctx.get("fishing_pressure",0)),0,100)
    wildlife["rats"]=clampf(float(wildlife["rats"])+float(ctx.get("hunger",0))*.025-float(ctx.get("prosperity",50))*.008,0,100)
    wildlife["bats"]=clampf(float(wildlife["bats"])+(2 if weather=="fog" else .2),0,100)
    wildlife["boar"]=clampf(float(wildlife["boar"])+randf_range(-1,1),0,40)
    if float(wildlife["rats"])>55:events.append({"type":"wildlife","text":"Крысы всё чаще появляются возле складов и домов."})

func _mood_cycle(ctx:Dictionary):
    public_mood["anger"]=clampf(float(ctx.get("unrest",0))*.55+float(ctx.get("hunger",0))*.25,0,100)
    public_mood["fear"]=clampf(float(ctx.get("crime",0))*.35+(15 if bool(ctx.get("vampire_rumors",false)) else 0),0,100)
    public_mood["hope"]=clampf(float(ctx.get("prosperity",50))*.7-float(public_mood["anger"])*.2,0,100)
    public_mood["curiosity"]=clampf(25+float(ctx.get("foreigners",0))*4,0,100)

func _calendar_events(day:int):
    for c in calendar:
        if day%int(c["day_mod"])==0:
            events.append({"type":"festival","location":c["location"],"text":"Сегодня проходит событие: %s."%c["name"]})

func add_rumor(text:String,source:String="unknown",truth:float=.7):
    rumors.append({"text":text,"source":source,"truth":truth,"age":0,"spread":1.0})
    if rumors.size()>50:rumors.pop_front()

func _rumor_decay():
    for r in rumors:
        r["age"]=int(r.get("age",0))+1;r["spread"]=maxf(0,float(r.get("spread",1))-.04)

func fishing_multiplier()->float:
    return clampf(.55+float(wildlife["fish"])/70.0+(0.2 if weather in ["rain","wind"] else 0),.35,1.8)

func travel_risk()->float:
    return {"storm":1.8,"fog":1.35,"rain":1.15,"wind":1.2,"clear":1.0}.get(weather,1.0)

func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"weather":weather,"season_day":season_day,"wildlife":wildlife,"public_mood":public_mood,"rumors":rumors,"last_day":last_day}
func restore(data:Dictionary):
    weather=str(data.get("weather",weather));season_day=int(data.get("season_day",season_day));last_day=int(data.get("last_day",last_day))
    var w=data.get("wildlife",{});if typeof(w)==TYPE_DICTIONARY:wildlife=w
    var m=data.get("public_mood",{});if typeof(m)==TYPE_DICTIONARY:public_mood=m
    var r=data.get("rumors",[]);if typeof(r)==TYPE_ARRAY:rumors=r
