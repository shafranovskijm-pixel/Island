extends RefCounted

var state={"hunger":12.0,"thirst":8.0,"fatigue":5.0,"hygiene":85.0,"comfort":45.0,"mood":55.0,"warmth":60.0,"last_sleep_day":0}
var events:Array=[]

func tick(delta:float,hour:float,weather:String,is_vampire:bool=false):
    if not is_vampire:state["hunger"]=minf(100,float(state["hunger"])+delta*.010)
    state["thirst"]=minf(100,float(state["thirst"])+delta*.014);state["fatigue"]=minf(100,float(state["fatigue"])+delta*.008);state["hygiene"]=maxf(0,float(state["hygiene"])-delta*.002)
    var cold=weather in ["rain","storm","wind"] and (hour<7 or hour>18);state["warmth"]=clampf(float(state["warmth"])+(delta*.01 if not cold else -delta*.02),0,100)
    state["mood"]=clampf(70-float(state["hunger"])*.18-float(state["thirst"])*.15-float(state["fatigue"])*.22+float(state["comfort"])*.15,0,100)

func eat(amount:float):state["hunger"]=maxf(0,float(state["hunger"])-amount);events.append({"type":"need","text":"Герой поел."})
func drink(amount:float):state["thirst"]=maxf(0,float(state["thirst"])-amount);events.append({"type":"need","text":"Герой утолил жажду."})
func wash():state["hygiene"]=100.0;state["mood"]=minf(100,float(state["mood"])+4);events.append({"type":"need","text":"Герой привёл себя в порядок."})
func sleep(day:int,quality:float=1.0):
    state["fatigue"]=maxf(0,float(state["fatigue"])-70*quality);state["comfort"]=clampf(35+quality*35,0,100);state["last_sleep_day"]=day;events.append({"type":"sleep","text":"Герой выспался."})
func penalty()->int:
    var p=0
    if float(state["hunger"])>75:p+=1
    if float(state["thirst"])>75:p+=2
    if float(state["fatigue"])>80:p+=2
    if float(state["warmth"])<20:p+=1
    return p
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return state.duplicate(true)
func restore(data:Dictionary):
    for k in state.keys():
        if data.has(k):state[k]=data[k]
