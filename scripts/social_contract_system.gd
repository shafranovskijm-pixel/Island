extends RefCounted
var promises:Array=[]
var debts:Array=[]
var apprentices:Array=[]
var oaths:Array=[]
var events:Array=[]
var next_id:=1
func make_promise(from_id:String,to_id:String,kind:String,deadline:int,value:float=0)->Dictionary:
    var p={"id":"promise_%d"%next_id,"from":from_id,"to":to_id,"kind":kind,"deadline":deadline,"value":value,"status":"open"};next_id+=1;promises.append(p);events.append({"type":"promise","text":"Дано обещание: %s."%kind});return p
func add_debt(debtor:String,creditor:String,amount:float,due_day:int,interest:float=.08)->Dictionary:
    var d={"id":"debt_%d"%next_id,"debtor":debtor,"creditor":creditor,"amount":amount,"due_day":due_day,"interest":interest,"status":"open"};next_id+=1;debts.append(d);return d
func take_apprentice(npc_id:String,skill:String,day:int)->Dictionary:
    var a={"npc_id":npc_id,"skill":skill,"started":day,"progress":0.0,"loyalty":45.0,"status":"active"};apprentices.append(a);events.append({"type":"apprentice","text":"У героя появился ученик по навыку %s."%skill});return a
func swear_oath(npc_id:String,faction:String,kind:String)->Dictionary:
    var o={"npc_id":npc_id,"faction":faction,"kind":kind,"loyalty":55.0,"broken":false};oaths.append(o);events.append({"type":"oath","text":"Принесена клятва: %s."%kind});return o
func tick(day:int,npcs:Array):
    for p in promises:
        if str(p.get("status",""))!="open":continue
        if day>int(p.get("deadline",99999)):p["status"]="broken";_change_rel(npcs,str(p["to"]),-2);events.append({"type":"promise_broken","text":"Просроченное обещание портит отношения."})
    for d in debts:
        if str(d.get("status",""))!="open":continue
        if day>int(d.get("due_day",99999)):d["amount"]=float(d["amount"])*(1.0+float(d.get("interest",.08)));d["due_day"]=day+5;events.append({"type":"debt_overdue","text":"Просроченный долг вырос до %.1f."%d["amount"]})
    for a in apprentices:
        if str(a.get("status",""))!="active":continue
        a["progress"]=float(a.get("progress",0))+.18
        if float(a["progress"])>=5.0:a["status"]="trained";_change_rel(npcs,str(a["npc_id"]),1);events.append({"type":"apprentice_trained","text":"Ученик достиг самостоятельного уровня."})
    for o in oaths:
        if bool(o.get("broken",false)):continue
        if randf()<.015 and float(o.get("loyalty",50))<35:o["broken"]=true;events.append({"type":"betrayal","text":"Кто-то нарушает клятву и предаёт союз."})
func repay(debt_id:String,amount:float)->Dictionary:
    for d in debts:
        if str(d.get("id",""))!=debt_id or str(d.get("status",""))!="open":continue
        d["amount"]=maxf(0,float(d["amount"])-amount)
        if float(d["amount"])<=.01:d["status"]="paid";events.append({"type":"debt_paid","text":"Долг погашен."})
        return {"ok":true,"remaining":d["amount"]}
    return {"ok":false,"reason":"Долг не найден."}
func _change_rel(npcs:Array,id:String,delta:int):
    for n in npcs:
        if str(n.get("id",""))==id:n["rel"]=int(n.get("rel",0))+delta;return
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"promises":promises,"debts":debts,"apprentices":apprentices,"oaths":oaths,"next_id":next_id}
func restore(data:Dictionary):
    var p=data.get("promises",[]);if typeof(p)==TYPE_ARRAY:promises=p
    var d=data.get("debts",[]);if typeof(d)==TYPE_ARRAY:debts=d
    var a=data.get("apprentices",[]);if typeof(a)==TYPE_ARRAY:apprentices=a
    var o=data.get("oaths",[]);if typeof(o)==TYPE_ARRAY:oaths=o
    next_id=int(data.get("next_id",next_id))
