extends RefCounted

var events:Array=[]
var alarm_level:=0
var last_processed_signature:=""

func process_reactions(reactions:Array,npcs:Array,power,player_factions,day:int,hour:float)->Dictionary:
    var wanted_delta:=0
    var reputation_delta:=0
    for r in reactions:
        var severity=int(r.get("severity",1))
        alarm_level=maxi(alarm_level,severity)
        if severity>=5:wanted_delta+=2;reputation_delta-=2
        else:wanted_delta+=1;reputation_delta-=1
        var victim=str(r.get("victim",""))
        if victim=="king":
            power.crisis_for("осквернение останков короля",victim,"трон",day,hour)
            player_factions.change("crown",-18,"осквернение короны")
            player_factions.change("guard",-14,"угроза государству")
            player_factions.change("underworld",4,"дерзость против власти")
            _log(day,hour,"По острову расходится весть о чудовищном оскорблении Короны.")
    return {"wanted_delta":wanted_delta,"reputation_delta":reputation_delta,"alarm_level":alarm_level}

func react_to_mutation(mutation:Dictionary,current_location:String,npcs:Array,day:int,hour:float)->Dictionary:
    var t=str(mutation.get("type",""))
    var out={"crime":0,"noise":0,"fire":false,"text":""}
    match t:
        "broken":
            out={"crime":1,"noise":2,"fire":false,"text":"Шум разрушения может привлечь свидетелей."}
        "burning":
            out={"crime":2,"noise":3,"fire":true,"text":"Пожар меняет приоритеты жителей и угрожает имуществу."}
        "unlocked":
            out={"crime":1,"noise":0,"fire":false,"text":"Вскрытый замок может позже стать уликой."}
        "body_part_removed":
            out={"crime":2,"noise":1,"fire":false,"text":"Осквернение тела может иметь социальные и религиозные последствия."}
        "social":
            if str(mutation.get("verb",""))=="threaten":out={"crime":1,"noise":1,"fire":false,"text":"Угроза запоминается свидетелями."}
    if str(out.get("text",""))!="":_log(day,hour,str(out["text"]))
    return out

func _log(day:int,hour:float,text:String):
    events.append({"day":day,"hour":hour,"text":text})
    if events.size()>100:events.pop_front()
