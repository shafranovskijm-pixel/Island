extends RefCounted

var connectors=[" и потом "," потом "," затем "," после этого "," пока "," и "]

func build_plan(text:String,free_engine,world:Dictionary)->Dictionary:
    var cleaned=text.strip_edges()
    var parts=_split_steps(cleaned)
    var steps:Array=[]
    for part in parts:
        var parsed=free_engine.parse_local(part,world)
        if not bool(parsed.get("ok",false)):
            return {"ok":false,"needs_ai":true,"reason":"Один из шагов требует AI-разбора.","raw":text,"failed_step":part}
        parsed["source_text"]=part
        steps.append(parsed)
    return {"ok":true,"steps":steps,"raw":text}

func _split_steps(text:String)->Array:
    var parts:Array=[text]
    for connector in connectors:
        var next:Array=[]
        for p in parts:
            var chunks=str(p).split(connector,false)
            if chunks.size()>1:
                for c in chunks:
                    if str(c).strip_edges()!="":next.append(str(c).strip_edges())
            else:next.append(p)
        parts=next
    if parts.size()>5:parts=parts.slice(0,5)
    return parts

func revalidate_remaining(steps:Array,start_index:int,free_engine,world:Dictionary)->Dictionary:
    for i in range(start_index,steps.size()):
        var v=free_engine.validate(steps[i],world)
        if not bool(v.get("ok",false)):
            return {"ok":false,"index":i,"reason":v.get("reason","Следующий шаг больше невозможен.")}
    return {"ok":true}
