extends RefCounted
var discoveries:Dictionary={"people":{},"places":{},"rumors":[],"mechanics":{},"factions":{},"creatures":{},"recipes":{}}
var journal:Array=[]
var events:Array=[]
func discover(kind:String,id:String,data:Dictionary={}):
    if kind=="rumors":discoveries["rumors"].append(data);return
    if not discoveries.has(kind):discoveries[kind]={}
    if not discoveries[kind].has(id):events.append({"type":"discovery","text":"Новое знание: %s."%data.get("name",id)})
    discoveries[kind][id]=data.duplicate(true)
func learn_mechanic(id:String,source:String,text:String):discover("mechanics",id,{"name":id,"source":source,"text":text})
func add_journal(day:int,hour:float,title:String,text:String,tags:Array=[]):
    journal.append({"day":day,"hour":hour,"title":title,"text":text,"tags":tags});if journal.size()>250:journal.pop_front()
func known(kind:String,id:String)->bool:return discoveries.has(kind) and discoveries[kind].has(id)
func summary()->Dictionary:return {"people":discoveries["people"].size(),"places":discoveries["places"].size(),"mechanics":discoveries["mechanics"].size(),"factions":discoveries["factions"].size(),"creatures":discoveries["creatures"].size(),"journal":journal.size()}
func drain()->Array:
    var out=events.duplicate(true);events.clear();return out
func serialize()->Dictionary:return {"discoveries":discoveries,"journal":journal}
func restore(data:Dictionary):
    var d=data.get("discoveries",{});if typeof(d)==TYPE_DICTIONARY:discoveries=d
    var j=data.get("journal",[]);if typeof(j)==TYPE_ARRAY:journal=j
