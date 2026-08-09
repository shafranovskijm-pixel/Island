extends RefCounted
var palette={"grass":Color("#496b48"),"sand":Color("#9b865e"),"water":Color("#315f72"),"road":Color("#75654f"),"stone":Color("#6c7070"),"wood":Color("#76543c"),"roof":Color("#563c3b"),"shadow":Color(0,0,0,.22),"skin":Color("#d2a67f"),"cloth":Color("#586a78"),"vampire":Color("#b9a7c4")}
func draw_ground(canvas:CanvasItem,rect:Rect2,kind:String):
    canvas.draw_rect(rect,palette.get(kind,palette["grass"]))
    for x in range(int(rect.position.x),int(rect.end.x),48):
        for y in range(int(rect.position.y),int(rect.end.y),48):
            var seed=(x*17+y*31)%13
            if seed<3:canvas.draw_circle(Vector2(x+seed*3,y+seed*2),1.5,Color(1,1,1,.06))
func draw_building(canvas:CanvasItem,pos:Vector2,size:Vector2,label:String,stone:bool=false):
    canvas.draw_rect(Rect2(pos+Vector2(5,7),size),palette["shadow"]);canvas.draw_rect(Rect2(pos,size),palette["stone"] if stone else palette["wood"])
    canvas.draw_colored_polygon(PackedVector2Array([pos+Vector2(-5,0),pos+Vector2(size.x*.5,-22),pos+Vector2(size.x+5,0)]),palette["roof"])
    canvas.draw_rect(Rect2(pos+Vector2(size.x*.42,size.y*.55),Vector2(18,size.y*.45)),Color("#3a2d27"));canvas.draw_string(ThemeDB.fallback_font,pos+Vector2(5,-27),label,0,size.x,10,Color("#eee5cf"))
func draw_person(canvas:CanvasItem,pos:Vector2,role:String="",vampire:bool=false):
    canvas.draw_circle(pos+Vector2(2,5),9,palette["shadow"]);canvas.draw_rect(Rect2(pos+Vector2(-6,-1),Vector2(12,18)),palette["cloth"]);canvas.draw_circle(pos+Vector2(0,-7),6,palette["vampire"] if vampire else palette["skin"])
    if "guard" in role.to_lower() or "страж" in role.to_lower():canvas.draw_line(pos+Vector2(7,-2),pos+Vector2(7,15),Color("#c2c5c5"),2)
func draw_animal(canvas:CanvasItem,pos:Vector2,species:String):
    var size=Vector2(15,8);if species in ["horse","cow"]:size=Vector2(24,12)
    var col={"dog":Color("#a88d6d"),"rat":Color("#77706b"),"boar":Color("#604b3e"),"deer":Color("#9a7651"),"horse":Color("#76513a"),"cow":Color("#8d7c69"),"goat":Color("#b5aa92"),"chicken":Color("#c9b98e")}.get(species,Color("#88745f"))
    canvas.draw_rect(Rect2(pos-size*.5,size),col);canvas.draw_circle(pos+Vector2(size.x*.5,-2),size.y*.38,col)
