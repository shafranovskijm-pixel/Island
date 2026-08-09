extends "res://scripts/game_v38.gd"

const JusticeSystem=preload("res://scripts/justice_system.gd")
const EvidenceManipulation=preload("res://scripts/evidence_manipulation_system.gd")
var justice=JusticeSystem.new()
var evidence_actions=EvidenceManipulation.new()
var justice_menu_open:=false
var last_justice_day:=-1

func _process(delta):
    super._process(delta)
    if day!=last_justice_day and hour>=6:
        last_justice_day=day;justice.tick_day()
    for ev in justice.drain():history.record(day,hour,str(ev.get("type","justice")),str(ev.get("text","Правосудие.")),{"social":0.08})
    for ev in evidence_actions.drain():history.record(day,hour,str(ev.get("type","evidence")),str(ev.get("text","Изменение доказательств.")),{"stealth":0.1})
    _maybe_arrest_player()

func _maybe_arrest_player():
    if bool(justice.state.get("arrested",false)) or bool(justice.state.get("jailed",false)):return
    for c in investigations.cases:
        if str(c.get("status",""))=="suspect_identified" and str(c.get("primary_suspect",""))=="player":
            var guard=_nearest_guard_to_player()
            if guard>=0 and player.distance_to(npcs[guard].get("pos",Vector2.ZERO))<90:
                justice.arrest(c);_notify("Стража задерживает тебя. Теперь дело может дойти до суда.");return

func _nearest_guard_to_player()->int:
    var best=-1;var d0=INF
    for i in npcs.size():
        var role=str(npcs[i].get("role","")).to_lower();if "страж" not in role and "guard" not in role:continue
        var d=player.distance_to(npcs[i].get("pos",Vector2.ZERO));if d<d0:best=i;d0=d
    return best

func current_player_case()->Dictionary:
    for c in investigations.cases:
        if str(c.get("primary_suspect",""))=="player" and str(c.get("status","")) not in ["cold","closed"]:return c
    return {}

func _resolve_case_record(case_id:String,outcome:String):
    for i in investigations.cases.size():
        if str(investigations.cases[i].get("id",""))!=case_id:continue
        investigations.cases[i]["status"]="closed";investigations.cases[i]["justice_outcome"]=outcome;investigations.cases[i]["closed_day"]=day;return

func request_trial():
    var c=current_player_case();if c.is_empty():_notify("Нет активного дела против тебя.");return
    if not bool(justice.state.get("trial_pending",false)):_notify("Сначала стража должна официально задержать тебя.");return
    var copy=c.duplicate(true);var scores=justice.case_scores(c,"player")
    copy["evidence_score"]=maxf(0,float(scores.get("evidence",0))-evidence_actions.defense_modifier(str(c.get("id",""))))
    copy["witness_score"]=float(scores.get("witness",0))
    var result=justice.resolve_trial(copy,reputation,influence,coins)
    if not bool(result.get("ok",false)):_notify(str(result.get("reason","Суд не состоялся.")));return
    _resolve_case_record(str(c.get("id","")),"guilty" if bool(result.get("guilty",false)) else "acquitted")
    if bool(result.get("guilty",false)):_notify("Виновен. Заключение %d дн., штраф %d."%[result.get("jail_days",0),result.get("fine",0)])
    else:_notify("Суд оправдал тебя из-за недостатка доказательств.")

func ask_nearest_for_alibi():
    var c=current_player_case();if c.is_empty():_notify("Нет дела, для которого нужно алиби.");return
    var i=_nearest_npc();if i<0:_notify("Рядом никого нет.");return
    var r=evidence_actions.create_alibi(str(c["id"]),npcs[i],day,hour);_notify(str(r.get("reason","Алиби получено.")) if not bool(r.get("ok",false)) else "%s готов подтвердить твоё алиби."%npcs[i].get("name","Свидетель"))

func destroy_first_evidence():
    var c=current_player_case();if c.is_empty():_notify("Нет активного дела.");return
    if c.get("evidence",[]).is_empty():_notify("В деле пока нет физической улики.");return
    var r=evidence_actions.destroy_evidence(c,0);_notify("Улика уничтожена." if bool(r.get("ok",false)) else str(r.get("reason","Не получилось.")))

func bribe_guard():
    var c=current_player_case();var result=justice.attempt_bribe(coins,int(skills.get("charm",0)));if not bool(result.get("ok",false)):_notify(str(result.get("reason","Не получилось.")));return
    coins-=int(result.get("cost",0))
    if bool(result.get("success",false)):
        if not c.is_empty():
            c["status"]="cold";c["bribed_day"]=day
        _notify("Взятка принята. Активное расследование временно остановилось.")
    else:
        wanted+=1;_notify("Взятку отвергли. Стало только хуже.")

func escape_jail():
    var r=justice.attempt_escape(int(skills.get("stealth",0)));if not bool(r.get("ok",false)):_notify(str(r.get("reason","Не получилось.")));return
    if bool(r.get("success",false)):wanted=maxi(wanted,4);_notify("Ты сбежал из тюрьмы.")
    else:_notify("Побег провален.")

func pay_justice_fine():
    var r=justice.pay_fine(coins);if not bool(r.get("ok",false)):_notify(str(r.get("reason","Не получилось.")));return
    coins-=int(r.get("cost",0));_notify("Штраф уплачен.")

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var s=get_viewport_rect().size
        if Rect2(s.x-155,70,135,44).has_point(event.position):justice_menu_open=not justice_menu_open;return
        if justice_menu_open and _handle_justice_touch(event.position):return
    super._unhandled_input(event)

func _handle_justice_touch(pos:Vector2)->bool:
    var s=get_viewport_rect().size;var panel=Rect2(s.x-330,120,310,300);if not panel.has_point(pos):return false
    var actions=["trial","alibi","destroy","bribe","fine","escape"];var y=panel.position.y+48
    for i in actions.size():
        var r=Rect2(panel.position.x+14,y+i*39,panel.size.x-28,32);if not r.has_point(pos):continue
        match actions[i]:
            "trial":request_trial()
            "alibi":ask_nearest_for_alibi()
            "destroy":destroy_first_evidence()
            "bribe":bribe_guard()
            "fine":pay_justice_fine()
            "escape":escape_jail()
        return true
    return true

func _draw_hud(s:Vector2):
    super._draw_hud(s);var b=Rect2(s.x-155,70,135,44);draw_rect(b,Color("#454b58"));draw_string(ThemeDB.fallback_font,b.position+Vector2(18,28),"ПРАВОСУДИЕ",0,105,11,Color.WHITE)
    if justice_menu_open:_draw_justice_panel(s)

func _draw_justice_panel(s:Vector2):
    var panel=Rect2(s.x-330,120,310,300);draw_rect(panel,Color(0.025,0.028,0.04,.97));draw_rect(panel,Color("#697184"),false,2)
    draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,28),"Закон и следствие",0,280,17,Color.WHITE)
    var labels=["ПОТРЕБОВАТЬ СУД","ПОПРОСИТЬ АЛИБИ","УНИЧТОЖИТЬ УЛИКУ","ПРЕДЛОЖИТЬ ВЗЯТКУ","ОПЛАТИТЬ ШТРАФ","ПОПЫТАТЬСЯ СБЕЖАТЬ"];var y=panel.position.y+48
    for i in labels.size():
        var r=Rect2(panel.position.x+14,y+i*39,panel.size.x-28,32);draw_rect(r,Color("#505767"));draw_string(ThemeDB.fallback_font,r.position+Vector2(9,21),labels[i],0,r.size.x-18,10,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(panel.position.x+14,panel.end.y-12),"Задержан %s · тюрьма %s · срок %d · штраф %d"%[justice.state["arrested"],justice.state["jailed"],justice.state["jail_days"],justice.state["fine_due"]],0,280,9,Color("#c9cfda"))

func _capture_save()->Dictionary:
    var data:Dictionary=super._capture_save();data["justice"]=justice.serialize();data["evidence_actions"]=evidence_actions.serialize();return data
func _apply_save(data:Dictionary):
    super._apply_save(data);var j=data.get("justice",{});if typeof(j)==TYPE_DICTIONARY:justice.restore(j);var e=data.get("evidence_actions",{});if typeof(e)==TYPE_DICTIONARY:evidence_actions.restore(e)
