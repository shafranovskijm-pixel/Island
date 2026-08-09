extends RefCounted

func all()->Dictionary:
    var r:Dictionary={}

    # MATERIALS AND PROCESSING
    r["planks"]=_recipe("materials","carpentry","building",0.0,0.0,"hand",{"wood":1.0},[],_resource("plank","доски",4.0))
    r["sticks"]=_recipe("materials","carpentry","building",0.0,0.0,"hand",{"plank":2.0},[],_resource("stick","палки",4.0))
    r["fiber_rope"]=_recipe("materials","survival","foraging",0.0,0.0,"hand",{"fiber":3.0},[],_resource("rope","верёвка",1.0))
    r["woven_cloth"]=_recipe("materials","textiles","building",1.0,1.0,"loom",{"fiber":5.0},[],_resource("cloth","ткань",2.0))
    r["charcoal"]=_recipe("materials","survival","foraging",0.0,0.0,"campfire",{"wood":3.0},[],_resource("coal","древесный уголь",2.0))
    r["stone_bricks"]=_recipe("materials","masonry","building",1.0,1.0,"workbench",{"stone":4.0},["hammer"],_resource("stone_brick","каменные блоки",4.0))
    r["fired_bricks"]=_recipe("materials","masonry","building",1.0,1.0,"furnace",{"clay":4.0,"coal":1.0},[],_resource("brick","кирпичи",4.0))
    r["glass"]=_recipe("materials","smelting","building",1.0,1.0,"furnace",{"sand":4.0,"coal":1.0},[],_resource("glass","стекло",4.0))
    r["copper_ingot"]=_recipe("materials","smelting","smithing",1.0,1.0,"furnace",{"copper_ore":3.0,"coal":1.0},[],_resource("copper_ingot","медный слиток",1.0))
    r["iron_ingot"]=_recipe("materials","smelting","smithing",2.0,2.0,"furnace",{"iron_ore":3.0,"coal":2.0},[],_resource("iron_ingot","железный слиток",1.0))
    r["metal_parts"]=_recipe("materials","smithing","smithing",2.0,2.0,"forge",{"iron_ingot":1.0},["hammer"],_resource("tools","металлические детали",3.0))
    r["lamp_oil"]=_recipe("materials","alchemy","medicine",1.0,1.0,"alchemy",{"fish":2.0,"herbs":1.0},[],_resource("oil","ламповое масло",2.0))

    # STATIONS
    r["workbench"]=_recipe("stations","carpentry","building",0.0,0.0,"hand",{"plank":8.0,"stick":4.0},["knife"],_station("workbench","верстак"))
    r["campfire"]=_recipe("stations","survival","foraging",0.0,0.0,"hand",{"wood":4.0,"stone":4.0},[],_station("campfire","костёр"))
    r["furnace"]=_recipe("stations","masonry","building",1.0,1.0,"workbench",{"stone":12.0,"clay":4.0},["hammer"],_station("furnace","каменная печь"))
    r["forge"]=_recipe("stations","smithing","smithing",2.0,2.0,"workbench",{"stone_brick":12.0,"iron_ingot":4.0,"coal":4.0},["hammer"],_station("forge","кузница"))
    r["sawbench"]=_recipe("stations","carpentry","building",2.0,2.0,"workbench",{"plank":10.0,"iron_ingot":2.0},["hammer"],_station("sawbench","пильный стол"))
    r["loom"]=_recipe("stations","textiles","building",1.0,1.0,"workbench",{"plank":8.0,"rope":4.0},["hammer"],_station("loom","ткацкий станок"))
    r["kitchen"]=_recipe("stations","cooking","foraging",1.0,1.0,"workbench",{"plank":8.0,"stone":4.0,"iron_ingot":1.0},["hammer"],_station("kitchen","кухонный стол"))
    r["alchemy_table"]=_recipe("stations","alchemy","medicine",2.0,2.0,"workbench",{"plank":6.0,"glass":2.0,"copper_ingot":1.0},["hammer"],_station("alchemy","алхимический стол"))
    r["occult_altar"]=_recipe("stations","occult","magic",3.0,3.0,"workbench",{"stone_brick":12.0,"ritual_chalk":1.0,"glass":2.0},["hammer"],_station("occult","ритуальный алтарь"))

    # BASIC AND ADVANCED TOOLS
    r["stone_knife"]=_recipe("tools","survival","foraging",0.0,0.0,"hand",{"stone":2.0,"stick":1.0,"rope":1.0},[],_tool("knife","каменный нож",28))
    r["wooden_hammer"]=_recipe("tools","carpentry","building",0.0,0.0,"hand",{"plank":2.0,"stick":2.0,"rope":1.0},["knife"],_tool("hammer","деревянный молоток",35))
    r["stone_axe"]=_recipe("tools","woodcutting","building",0.5,1.0,"workbench",{"stone":3.0,"stick":2.0,"rope":1.0},["hammer"],_tool("axe","каменный топор",55))
    r["stone_pickaxe"]=_recipe("tools","mining","building",0.5,1.0,"workbench",{"stone":4.0,"stick":2.0,"rope":1.0},["hammer"],_tool("pickaxe","каменная кирка",55))
    r["stone_shovel"]=_recipe("tools","mining","building",0.5,1.0,"workbench",{"stone":2.0,"stick":2.0,"rope":1.0},["hammer"],_tool("shovel","каменная лопата",48))
    r["stone_hoe"]=_recipe("tools","farming","farming",0.5,1.0,"workbench",{"stone":2.0,"stick":2.0,"rope":1.0},["hammer"],_tool("hoe","каменная мотыга",48))
    r["fishing_rod"]=_recipe("tools","fishing","sailing",1.0,1.0,"workbench",{"stick":3.0,"rope":2.0},["knife"],_tool("fishing_rod","удочка",45))
    r["torch"]=_recipe("tools","survival","foraging",0.0,0.0,"hand",{"stick":1.0,"fiber":1.0,"oil":1.0},[],_tool("fire_source","факел",18))
    r["bucket"]=_recipe("tools","smithing","smithing",1.0,1.0,"forge",{"iron_ingot":3.0},["hammer"],_tool("bucket","железное ведро",90))
    r["lockpick"]=_recipe("tools","thievery","stealth",1.0,2.0,"forge",{"iron_ingot":1.0},["hammer"],_tool("lockpick","набор отмычек",24))
    r["iron_knife"]=_recipe("tools","smithing","smithing",2.0,2.0,"forge",{"iron_ingot":2.0,"stick":1.0},["hammer"],_tool("knife","железный нож",120))
    r["iron_axe"]=_recipe("tools","smithing","smithing",2.0,3.0,"forge",{"iron_ingot":3.0,"stick":2.0},["hammer"],_tool("axe","железный топор",150))
    r["iron_pickaxe"]=_recipe("tools","smithing","smithing",2.0,3.0,"forge",{"iron_ingot":4.0,"stick":2.0},["hammer"],_tool("pickaxe","железная кирка",160))
    r["iron_hammer"]=_recipe("tools","smithing","smithing",2.0,3.0,"forge",{"iron_ingot":3.0,"stick":2.0},["hammer"],_tool("hammer","кузнечный молот",180))
    r["iron_shovel"]=_recipe("tools","smithing","smithing",2.0,2.0,"forge",{"iron_ingot":2.0,"stick":2.0},["hammer"],_tool("shovel","железная лопата",140))
    r["iron_hoe"]=_recipe("tools","smithing","smithing",2.0,2.0,"forge",{"iron_ingot":2.0,"stick":2.0},["hammer"],_tool("hoe","железная мотыга",140))

    # WEAPONS AND PROTECTION
    r["wooden_club"]=_recipe("weapons","weapons","building",0.0,0.0,"hand",{"wood":2.0,"rope":1.0},["knife"],_weapon("club","дубина",6,45))
    r["stone_spear"]=_recipe("weapons","weapons","foraging",0.5,1.0,"workbench",{"stick":3.0,"stone":2.0,"rope":1.0},["knife"],_weapon("spear","каменное копьё",9,65))
    r["short_bow"]=_recipe("weapons","weapons","foraging",1.0,2.0,"workbench",{"stick":4.0,"rope":2.0},["knife"],_weapon("bow","короткий лук",8,70))
    r["arrows"]=_recipe("weapons","weapons","foraging",0.5,1.0,"workbench",{"stick":3.0,"stone":2.0,"fiber":2.0},["knife"],_stack_item("ammo","стрелы",8,"arrow"))
    r["stone_sword"]=_recipe("weapons","weapons","building",1.0,2.0,"workbench",{"stone":5.0,"stick":1.0,"rope":1.0},["hammer"],_weapon("sword","каменный меч",10,70))
    r["iron_sword"]=_recipe("weapons","smithing","smithing",2.0,3.0,"forge",{"iron_ingot":4.0,"stick":1.0},["hammer"],_weapon("sword","железный меч",15,170))
    r["wooden_shield"]=_recipe("weapons","carpentry","building",1.0,2.0,"workbench",{"plank":6.0,"rope":2.0},["hammer"],_armor("shield","деревянный щит",4,95))
    r["iron_shield"]=_recipe("weapons","smithing","smithing",3.0,4.0,"forge",{"iron_ingot":6.0,"plank":2.0},["hammer"],_armor("shield","железный щит",8,210))
    r["cloth_tunic"]=_recipe("weapons","textiles","building",1.0,2.0,"loom",{"cloth":5.0,"rope":1.0},["knife"],_armor("body","простая туника",1,60))
    r["iron_mail"]=_recipe("weapons","smithing","smithing",4.0,6.0,"forge",{"iron_ingot":10.0,"cloth":2.0},["hammer"],_armor("body","железная кольчуга",10,260))

    # BUILDING BLOCKS, FURNITURE, STORAGE
    r["wooden_crate"]=_recipe("building","carpentry","building",1.0,2.0,"workbench",{"plank":6.0},["hammer"],_placeable("container","деревянный ящик",{"capacity":8}))
    r["wooden_chest"]=_recipe("building","carpentry","building",1.0,2.0,"workbench",{"plank":10.0,"iron_ingot":1.0},["hammer"],_placeable("container","сундук",{"capacity":20,"lockable":true}))
    r["wooden_door"]=_recipe("building","carpentry","building",1.0,2.0,"workbench",{"plank":8.0,"iron_ingot":1.0},["hammer"],_placeable("door","деревянная дверь",{"lockable":true}))
    r["ladder"]=_recipe("building","carpentry","building",0.5,1.0,"workbench",{"stick":8.0,"rope":2.0},["hammer"],_placeable("ladder","лестница",{}))
    r["fence"]=_recipe("building","carpentry","building",0.5,1.0,"workbench",{"plank":4.0,"stick":4.0},["hammer"],_placeable("fence","секция забора",{}))
    r["wood_wall"]=_recipe("building","carpentry","building",1.0,2.0,"workbench",{"plank":12.0},["hammer"],_placeable("wall","деревянная стена",{"strength":25}))
    r["stone_wall"]=_recipe("building","masonry","building",2.0,3.0,"workbench",{"stone_brick":12.0},["hammer"],_placeable("wall","каменная стена",{"strength":55}))
    r["wood_floor"]=_recipe("building","carpentry","building",1.0,1.0,"workbench",{"plank":8.0},["hammer"],_placeable("floor","деревянный настил",{}))
    r["wood_roof"]=_recipe("building","carpentry","building",1.0,2.0,"workbench",{"plank":10.0,"fiber":4.0},["hammer"],_placeable("roof","крыша",{}))
    r["simple_bed"]=_recipe("building","carpentry","building",1.0,2.0,"workbench",{"plank":6.0,"cloth":4.0},["hammer"],_placeable("bed","простая кровать",{"rest":30}))
    r["wood_table"]=_recipe("building","carpentry","building",1.0,1.0,"workbench",{"plank":6.0,"stick":4.0},["hammer"],_placeable("furniture","деревянный стол",{}))
    r["wood_chair"]=_recipe("building","carpentry","building",1.0,1.0,"workbench",{"plank":3.0,"stick":3.0},["hammer"],_placeable("furniture","деревянный стул",{}))
    r["barrel"]=_recipe("building","carpentry","building",2.0,2.0,"sawbench",{"plank":8.0,"iron_ingot":1.0},["hammer"],_placeable("container","бочка",{"capacity":28,"liquid":true}))
    r["handcart"]=_recipe("building","carpentry","building",3.0,4.0,"sawbench",{"plank":14.0,"iron_ingot":3.0},["hammer"],_placeable("vehicle","ручная телега",{"capacity":40}))

    # FOOD AND DRINK
    r["cooked_fish"]=_recipe("food","cooking","foraging",0.0,0.0,"campfire",{"fish":1.0,"wood":1.0},[],_food("жареная рыба",28))
    r["root_stew"]=_recipe("food","cooking","foraging",1.0,1.0,"kitchen",{"food":3.0,"herbs":1.0},["knife"],_food("похлёбка из кореньев",38))
    r["flat_bread"]=_recipe("food","cooking","farming",1.0,1.0,"kitchen",{"food":2.0,"wood":1.0},[],_food("лепёшка",25))
    r["fish_stew"]=_recipe("food","cooking","foraging",1.0,2.0,"kitchen",{"fish":2.0,"food":2.0,"herbs":1.0},["knife"],_food("рыбная похлёбка",52))
    r["dried_fish"]=_recipe("food","cooking","sailing",1.0,1.0,"campfire",{"fish":2.0,"wood":1.0},[],_stack_item("food","вяленая рыба",2,"dried_fish"))
    r["herbal_tea"]=_recipe("food","medicine","medicine",1.0,1.0,"campfire",{"herbs":2.0,"wood":1.0},[],_medicine_food("травяной чай",10,8))
    r["ale"]=_recipe("food","brewing","farming",2.0,2.0,"kitchen",{"food":4.0,"herbs":1.0},[],_stack_item("drink","простое пиво",2,"ale"))
    r["feast"]=_recipe("food","cooking","farming",3.0,5.0,"kitchen",{"food":8.0,"fish":4.0,"herbs":2.0},["knife"],_food("богатый пир",100))

    # FARMING
    r["seed_bundle"]=_recipe("farming","farming","farming",0.5,1.0,"hand",{"food":2.0,"fiber":1.0},[],_stack_item("seed","мешочек семян",3,"root"))
    r["compost"]=_recipe("farming","farming","farming",1.0,1.0,"hand",{"food":3.0,"fiber":2.0},[],_resource("compost","компост",2.0))
    r["watering_can"]=_recipe("farming","smithing","farming",1.0,2.0,"forge",{"iron_ingot":3.0},["hammer"],_tool("watering_can","лейка",100))
    r["irrigation_kit"]=_recipe("farming","carpentry","farming",2.0,3.0,"workbench",{"plank":8.0,"rope":4.0,"bucket":1.0},["hammer"],_placeable("irrigation","простая система полива",{"growth_bonus":0.25}))
    r["scarecrow"]=_recipe("farming","farming","farming",1.0,2.0,"workbench",{"stick":5.0,"cloth":2.0,"fiber":2.0},["knife"],_placeable("farm_support","пугало",{"crop_protection":0.25}))
    r["animal_pen"]=_recipe("farming","carpentry","farming",2.0,4.0,"workbench",{"plank":16.0,"stick":10.0,"rope":4.0},["hammer"],_placeable("animal_pen","загон для животных",{"capacity":4}))

    # MEDICINE AND ALCHEMY
    r["bandage"]=_recipe("alchemy","medicine","medicine",0.5,1.0,"hand",{"cloth":2.0,"herbs":1.0},["knife"],_stack_item("medicine","повязка",2,"bandage"))
    r["healing_draught"]=_recipe("alchemy","alchemy","medicine",2.0,3.0,"alchemy",{"herbs":3.0,"medicine":1.0,"glass":1.0},[],_medicine_food("лечебный отвар",0,25))
    r["antidote"]=_recipe("alchemy","alchemy","medicine",3.0,4.0,"alchemy",{"herbs":4.0,"medicine":2.0,"glass":1.0},[],_effect_item("medicine","противоядие","cure_poison"))
    r["weak_poison"]=_recipe("alchemy","alchemy","medicine",3.0,4.0,"alchemy",{"herbs":3.0,"oil":1.0,"glass":1.0},[],_effect_item("poison","слабый яд","poison"))
    r["smoke_bomb"]=_recipe("alchemy","alchemy","medicine",4.0,5.0,"alchemy",{"coal":2.0,"oil":1.0,"cloth":1.0},[],_effect_item("tool","дымовая бомба","smoke"))

    # OCCULT CRAFTING
    r["ritual_chalk"]=_recipe("occult","occult","magic",2.0,2.0,"hand",{"stone":1.0,"coal":1.0,"herbs":1.0},[],_resource("ritual_chalk","ритуальный мел",1.0))
    r["ward_candle"]=_recipe("occult","occult","magic",3.0,3.0,"occult",{"oil":2.0,"fiber":1.0,"ritual_chalk":1.0},[],_effect_item("ritual","свеча оберега","ward"))
    r["occult_focus"]=_recipe("occult","occult","magic",4.0,6.0,"occult",{"copper_ingot":2.0,"glass":2.0,"ritual_chalk":2.0},[],_tool("magic_focus","оккультный фокус",120))

    return r

func categories()->Array:
    return ["materials","stations","tools","weapons","building","food","farming","alchemy","occult"]

func category_name(id:String)->String:
    return {
        "materials":"Материалы","stations":"Станции","tools":"Инструменты","weapons":"Оружие и защита",
        "building":"Строительство","food":"Еда","farming":"Фермерство","alchemy":"Алхимия","occult":"Оккультное"
    }.get(id,id)

func _recipe(category:String,profession:String,theory:String,theory_required:float,practice_required:float,station:String,inputs:Dictionary,tools:Array,output:Dictionary)->Dictionary:
    return {"category":category,"profession":profession,"theory":theory,"theory_required":theory_required,"practice_required":practice_required,"station":station,"inputs":inputs,"tools":tools,"output":output}

func _resource(id:String,name:String,quantity:float)->Dictionary:
    return {"kind":"resource","resource":id,"name":name,"quantity":quantity,"value":1}

func _station(type:String,name:String)->Dictionary:
    return {"kind":"station","station_type":type,"name":name,"placeable":true,"condition":100.0,"value":12}

func _tool(type:String,name:String,durability:int)->Dictionary:
    return {"kind":"tool","tool_type":type,"name":name,"durability":durability,"max_durability":durability,"value":8}

func _weapon(type:String,name:String,damage:int,durability:int)->Dictionary:
    return {"kind":"weapon","weapon_type":type,"tool_type":type,"name":name,"damage":damage,"durability":durability,"max_durability":durability,"value":12}

func _armor(slot:String,name:String,armor:int,durability:int)->Dictionary:
    return {"kind":"armor","slot":slot,"name":name,"armor":armor,"durability":durability,"max_durability":durability,"value":14}

func _placeable(type:String,name:String,extra:Dictionary)->Dictionary:
    var out={"kind":"structure","structure_type":type,"name":name,"placeable":true,"condition":100.0,"value":8}
    for key in extra.keys():out[key]=extra[key]
    return out

func _food(name:String,hunger:int)->Dictionary:
    return {"kind":"food","name":name,"hunger":hunger,"quantity":1.0,"value":4}

func _medicine_food(name:String,hunger:int,heal:int)->Dictionary:
    return {"kind":"medicine","name":name,"hunger":hunger,"heal":heal,"quantity":1.0,"value":8}

func _stack_item(kind:String,name:String,quantity:int,subtype:String)->Dictionary:
    return {"kind":kind,"name":name,"subtype":subtype,"quantity":quantity,"value":2}

func _effect_item(kind:String,name:String,effect:String)->Dictionary:
    return {"kind":kind,"name":name,"effect":effect,"quantity":1.0,"value":10}
