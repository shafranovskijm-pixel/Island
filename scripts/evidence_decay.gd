extends RefCounted

func tick_inventory(inventory:Array,delta:float,hour:float)->Array:
    for i in inventory.size():
        var item=inventory[i]
        if str(item.get("kind",""))!="body_part":continue
        item["decay"]=clampf(float(item.get("decay",0.0))+delta*0.06,0.0,100.0)
        if float(item["decay"])>35.0:item["bloody"]=false
        if float(item["decay"])>70.0:item["recognizable"]=false
        item["smell"]=clampf(float(item["decay"])*1.2,0.0,100.0)
        inventory[i]=item
    return inventory

func conceal(item:Dictionary,container:String)->Dictionary:
    item["concealed_in"]=container
    item["visible"]=false
    return item

func reveal(item:Dictionary)->Dictionary:
    item["concealed_in"]="";item["visible"]=true
    return item

func detection_modifier(item:Dictionary)->int:
    if bool(item.get("visible",true)):return 0
    var smell=float(item.get("smell",0.0))
    if smell>65:return 2
    return -4
