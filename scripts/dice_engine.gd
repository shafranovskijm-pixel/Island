extends RefCounted

var rng:=RandomNumberGenerator.new()

func _init():rng.randomize()

func check(stat:int,skill:int,dc:int,advantage:int=0)->Dictionary:
    var r1=rng.randi_range(1,20);var roll=r1
    if advantage!=0:
        var r2=rng.randi_range(1,20)
        roll=maxi(r1,r2) if advantage>0 else mini(r1,r2)
    var total=roll+stat+skill
    var success=total>=dc
    var critical=roll==20
    var fumble=roll==1
    if critical:success=true
    if fumble:success=false
    return {"roll":roll,"total":total,"dc":dc,"success":success,"critical":critical,"fumble":fumble,"margin":total-dc}

func should_roll(action:Dictionary)->bool:
    return bool(action.get("uncertain",true)) and int(action.get("stakes",1))>0

func dc_for(verb:String,context:Dictionary)->int:
    var base={"climb":11,"break":12,"steal":12,"hide":11,"deceive":12,"persuade":11,"threaten":12,"burn":9,"sever":10,"pick_lock":13,"throw":9,"sneak":11,"search":10}.get(verb,10)
    if bool(context.get("dark",false)):base+=1 if verb in ["search","climb"] else -1
    if bool(context.get("rain",false)) and verb=="climb":base+=3
    if bool(context.get("guarded",false)) and verb in ["steal","sneak","pick_lock"]:base+=3
    return clampi(int(base),5,25)
