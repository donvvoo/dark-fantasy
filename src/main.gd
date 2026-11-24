## The one scene of 어비스 키우기 (Raise Abyss): draws the road, the party and the panels at
## 360x640 real pixels, turns taps and keys into requests to `Game`, plays the
## sounds `Game` asks for, and saves on Android pause, back and close.
## Rules live in src/core/game_state.gd; this script only reads them.
extends Node2D

const W := 360
const H := 640
const STEP := 1.0 / 60.0
const HUD_H := 40
const FIELD_B := 330
const PANEL_Y := 358
const TAB_Y := 584
const GROUND_Y := 300

const PAL := {
	"ink": Color("f3e6cc"), "muted": Color("c4ad8a"), "dim": Color("a08c72"), "torch": Color("ff9a3c"), "torch_hi": Color("ffd27a"),
	"gold": Color("f6c453"), "threat": Color("e04848"), "ember": Color("ff6a2a"), "holy": Color("ffe9a6"), "gem": Color("5fb6ff"),
	"soul": Color("c084ff"), "scroll": Color("e8d3a8"), "wood": Color("5b3a22"), "wood_hi": Color("7d5230"), "wood_dk": Color("3a2414"),
	"trim": Color("d4a24a"), "trim_hi": Color("ffe08a"), "leather": Color("2a1d16"), "leather_hi": Color("36261c"), "good": Color("8ee27a"),
	"black": Color("0b0705"),
}
const TABS := [["party", "파티", "helm"], ["skill", "스킬", "book"], ["gear", "장비", "sword"], ["adv", "모험", "door"], ["quest", "임무", "scroll"], ["rebirth", "환생", "flame"]]
const BM := {
	"coin": ["..kkkkk..", ".kyyyyyk.", "kywwyyyok", "kywyyyyok", "kyyyyyyok", "kyyyyyyok", "kyyyyyook", ".koooook.", "..kkkkk.."],
	"flame": ["...r....", "...rr...", "..rrr...", "..rorr..", ".rroorr.", ".rooyor.", "rroyyorr", "rooyyyor", "rooywyor", ".rooyor.", "..rrrr.."],
	"sword": ["..........kk", ".........kwk", "........kwsk", ".......kwsk.", "......kwsk..", ".....kwsk...", ".bb.kwsk....", "..bbwsk.....", "...bbk......", "..hkbb......", ".hh..b......", "hh.........."],
	"armor": [".kkk....kkk.", "kcwck..kccck", "kcwcckkcccck", "kcccccccccck", ".kcwccccccck", ".kcwcccccck", "..kcwccccck", "..kccccccck", "...kccccck", "....kccck", ".....kck", "......k"],
	"speaker": ["....k", "...kk", "kkkkk", "kkkkk", "kkkkk", "kkkkk", "...kk", "....k"],
	"waves": ["..w.", "...w", "w..w", ".w.w", ".w.w", "w..w", "...w", "..w."],
	"cross": ["x...x", ".x.x.", "..x..", ".x.x.", "x...x"],
	"gem": ["..kkk..", ".kbwbk.", "kbbwbbk", "kbbbbbk", ".kbbbk.", "..kbk..", "...k..."],
	"scroll": [".kkkkkk.", "kppppppk", "kplllppk", "kppppppk", "kplllppk", "kppppppk", ".kkkkkk."],
	"soul": ["...k...", "..kpk..", ".kpwpk.", "kppwppk", "kpppppk", "kpppppk", ".kpppk.", "..kkk.."],
	"key": [".kkk.....", "kyyyk....", "ky.ykkkkk", "kyyyyyyyk", ".kkk.kyk.", "......k.."],
	"star": ["..y..", ".yyy.", "yyyyy", ".yyy.", ".y.y."],
	"helm": ["..kkkkk..", ".ksswssk.", "kssswsssk", "ksssssssk", "kskkkkksk", "kskrrrksk", "ksskkkssk", ".kssssk..", "..kkkk..."],
	"book": ["kkkkkkkk.", "krrrrrrkk", "krryyrrkw", "krrrrrrkw", "krryyrrkw", "krrrrrrkw", "kkkkkkkkw", ".wwwwwwww"],
	"door": ["..kkkkk..", ".kgggggk.", "kgkkkkkgk", "kgkdddkgk", "kgkdddkgk", "kgkdddkgk", "kgkddykgk", "kgkdddkgk", "kgkkkkkgk", "kkkkkkkkk"],
	"crown": ["y...y...y", "yy.yyy.yy", "yyyyyyyyy", "yryybyyry", "yyyyyyyyy"],
}
var ICON_PAL := {
	"coin": {"k": Color("4a2e08"), "y": Color("f6c453"), "w": Color("fff2b0"), "o": Color("b97f1c")},
	"gem": {"k": Color("0b1630"), "b": Color("5fb6ff"), "w": Color("d8efff")},
	"scroll": {"k": Color("3a2510"), "p": Color("e8d3a8"), "l": Color("8a6a40")},
	"soul": {"k": Color("2a0f40"), "p": Color("c084ff"), "w": Color("f0d8ff")},
	"key": {"k": Color("3a2508"), "y": Color("f6c453")}, "star": {"y": Color("ffe08a")},
	"helm": {"k": Color("120f12"), "s": Color("b8bcc8"), "w": Color.WHITE, "r": Color("e04848")},
	"book": {"k": Color("1a0c08"), "r": Color("8e2a2a"), "y": Color("ffe08a"), "w": Color("e8d3a8")},
	"door": {"k": Color("0c0a10"), "g": Color("8a8494"), "d": Color("24183a"), "y": Color("f6c453")},
	"crown": {"y": Color("ffe08a"), "r": Color("e04848"), "b": Color("5fb6ff")},
	"sword": {"k": Color("120f12"), "w": Color.WHITE, "s": Color("c8ccd8"), "b": Color("9a7a44"), "h": Color("5a3c22")},
	"flame": {"r": Color("ff6a2a"), "o": Color("ff9a3c"), "y": Color("ffd27a"), "w": Color("fff6d8")},
}

var px: PixelDraw
var scene := "title"
var acc := 0.0
var muted := false
var toast := {}
var pop := {}
var players: Array[AudioStreamPlayer] = []
var sounds := {}
var buttons_cache: Array = []

# ---- Lifecycle ----------------------------------------------------------------------------

func _ready() -> void:
	px = PixelDraw.new(self)
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	Game.toasted.connect(func(m, c): toast = {"msg": m, "color": c, "t": 2.2})
	Game.popped.connect(func(t, l, c): pop = {"title": t, "lines": l, "color": c, "t": 3.2})
	Game.sound.connect(_play)
	Game.results_reached.connect(func(): scene = "results")
	_build_sounds()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if scene in ["play", "pause"]: Game.save()
		NOTIFICATION_WM_CLOSE_REQUEST:
			if scene in ["play", "pause"]: Game.save()
			get_tree().quit()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Android back: play pauses, pause saves and quits, other screens step back.
			if scene == "play": scene = "pause"
			elif scene == "pause":
				Game.save()
				get_tree().quit()
			elif scene == "results": scene = "play"

func _process(delta: float) -> void:
	acc += minf(delta, 0.25)
	while acc >= STEP:
		acc -= STEP
		_update(STEP)
	queue_redraw()

func _update(dt: float) -> void:
	if toast.has("t"):
		toast.t -= dt
		if toast.t <= 0: toast = {}
	if pop.has("t"):
		pop.t -= dt
		if pop.t <= 0: pop = {}
	if scene == "play":
		Game.step(dt, hero_x, enemy_x())

# ---- Input ----------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_tap(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event.keycode)

func _tap(p: Vector2) -> void:
	match scene:
		"title":
			if p.y > 572 and Game.has_save(): Game.reset()
			elif not Game.continue_save(): Game.reset()
			scene = "play"
			_play("click")
		"pause": scene = "play"
		"results": scene = "play"
		"play":
			var s := Game.state
			if s.away != null:
				Game.claim_away()
				return
			var b := _hit(p)
			if not b.is_empty(): _press(b.id)
			elif p.y > HUD_H and p.y < FIELD_B: Game.tap_attack(enemy_x())

func _key(k: int) -> void:
	if scene != "play":
		if k in [KEY_ENTER, KEY_SPACE]: _tap(Vector2(W / 2, 300))
		elif k == KEY_P and scene == "pause": scene = "play"
		return
	var s := Game.state
	if s.away != null:
		Game.claim_away()
		return
	match k:
		KEY_SPACE: Game.tap_attack(enemy_x())
		KEY_1, KEY_2, KEY_3, KEY_4:
			s.tab = "party"
			Game.buy_hero(k - KEY_1)
		KEY_Q: s.tab = "party"
		KEY_W: s.tab = "skill"
		KEY_E: s.tab = "gear"
		KEY_A: s.tab = "adv"
		KEY_F: s.tab = "quest"
		KEY_S: s.tab = "rebirth"
		KEY_Z, KEY_X, KEY_C:
			var i := [KEY_Z, KEY_X, KEY_C].find(k)
			if s.tab == "gear" and s.drop != null and i < 2:
				if i == 0: Game.equip_drop()
				else: Game.store_drop()
			elif s.slots[i] != null: Game.cast_skill(s.slots[i], enemy_x())
		KEY_B: Game.challenge_boss()
		KEY_D: Game.enter_dungeon()
		KEY_G: Game.start_trial()
		KEY_R: if s.tab == "rebirth": Game.rebirth()
		KEY_P, KEY_ESCAPE: scene = "pause"
		KEY_M: muted = not muted

func _hit(p: Vector2) -> Dictionary:
	var bs := buttons()
	for i in range(bs.size() - 1, -1, -1):
		var b: Dictionary = bs[i]
		if Rect2(b.x, b.y, b.w, b.h).has_point(p): return b
	return {}

func _press(id: String) -> void:
	var parts := id.split(":")
	var k := parts[0]
	var v := parts[1] if parts.size() > 1 else ""
	var s := Game.state
	match k:
		"pause": scene = "pause"
		"mute": muted = not muted
		"boss": Game.challenge_boss()
		"leave": Game.leave_mode(false)
		"auto": s.autoSkill = not s.autoSkill
		"cast":
			var id2 = s.slots[int(v)]
			if id2 != null: Game.cast_skill(id2, enemy_x())
		"tab":
			s.tab = v
			_play("click")
		"buy": Game.buy_hero(int(v))
		"evo": Game.evolve(int(v))
		"sel": s.selSkill = v
		"equipsk": Game.equip_skill(s.selSkill)
		"upsk": Game.upgrade_skill(s.selSkill)
		"enh": Game.enhance(v)
		"equip": Game.equip_drop()
		"store": Game.store_drop()
		"merge": Game.merge(v)
		"dungeon": Game.enter_dungeon()
		"trial": Game.start_trial()
		"spirit":
			if Game.spirit_lv(v) > 0: s.spirit = v
		"spup": Game.upgrade_spirit(v)
		"rebirth": Game.rebirth()
		"qv": s.questView = v
		"qd": Game.claim_daily(int(v))
		"qbonus": Game.claim_daily_bonus()
		"qa": Game.claim_ach(v)
		"qatt": Game.claim_attend()

# ---- Layout ---------------------------------------------------------------------------------

func hero_order() -> Array:
	var out := []
	for h in Game.HEROES:
		if Game.state.lv[h.id] > 0: out.append(h.id)
	return out

func hero_x(id: String) -> float:
	var i := hero_order().find(id)
	return 170.0 if i <= 0 else 168.0 - 12.0 - i * 42.0

func enemy_x() -> float:
	var e = Game.state.enemy
	var base := 280.0 if (e != null and e.boss) else 272.0
	return base + (e.x * 120.0 if e != null else 0.0)

func buttons() -> Array:
	var s := Game.state
	var b := []
	b.append({"id": "pause", "x": W - 34, "y": 6, "w": 28, "h": 28})
	b.append({"id": "mute", "x": W - 66, "y": 6, "w": 28, "h": 28})
	for i in 3: b.append({"id": "cast:%d" % i, "x": 8 + i * 42, "y": HUD_H + 6, "w": 38, "h": 38})
	b.append({"id": "auto", "x": 134, "y": HUD_H + 12, "w": 40, "h": 26})
	if s.farming and s.mode == "stage": b.append({"id": "boss", "x": W - 112, "y": HUD_H + 8, "w": 104, "h": 32})
	if s.mode != "stage": b.append({"id": "leave", "x": W - 82, "y": HUD_H + 8, "w": 74, "h": 30})
	for i in TABS.size(): b.append({"id": "tab:" + TABS[i][0], "label": TABS[i][1], "icon": TABS[i][2], "x": i * 60, "y": TAB_Y, "w": 60, "h": H - TAB_Y})
	var P := PANEL_Y
	match s.tab:
		"party":
			for i in Game.HEROES.size():
				var h: Dictionary = Game.HEROES[i]
				var y := P + 4 + i * 56
				b.append({"id": "buy:%d" % i, "x": W - 104, "y": y + 7, "w": 96, "h": 42})
				if s.lv[h.id] >= Game.evo_need(h.id).lv and int(s.stars[h.id]) < 5:
					b.append({"id": "evo:%d" % i, "x": W - 164, "y": y + 7, "w": 56, "h": 42})
		"skill":
			for i in Game.SKILLS.size():
				b.append({"id": "sel:" + Game.SKILLS[i].id, "x": 8 + (i % 3) * 116, "y": P + 6 + (i / 3) * 58, "w": 112, "h": 54})
			b.append({"id": "equipsk", "x": 14, "y": P + 180, "w": 160, "h": 38})
			b.append({"id": "upsk", "x": 186, "y": P + 180, "w": 160, "h": 38})
		"gear":
			for i in 2: b.append({"id": "enh:" + ["weapon", "armor"][i], "x": 14 + i * 174, "y": P + 54, "w": 158, "h": 30})
			if s.drop != null:
				b.append({"id": "equip", "x": W - 152, "y": P + 104, "w": 68, "h": 38})
				b.append({"id": "store", "x": W - 80, "y": P + 104, "w": 68, "h": 38})
			for i in 2: b.append({"id": "merge:" + ["weapon", "armor"][i], "x": W - 122, "y": P + 162 + i * 30, "w": 110, "h": 28})
		"adv":
			b.append({"id": "dungeon", "x": W - 98, "y": P + 14, "w": 88, "h": 44})
			b.append({"id": "trial", "x": W - 98, "y": P + 86, "w": 88, "h": 44})
			for i in Game.SPIRITS.size():
				var sp: Dictionary = Game.SPIRITS[i]
				b.append({"id": "spirit:" + sp.id, "x": 8 + i * 116, "y": P + 146, "w": 112, "h": 50})
				b.append({"id": "spup:" + sp.id, "x": 12 + i * 116, "y": P + 196, "w": 104, "h": 26})
		"rebirth":
			b.append({"id": "rebirth", "x": 40, "y": P + 166, "w": W - 80, "h": 48})
		"quest":
			var views := [["daily", "일일 임무"], ["ach", "업적"], ["attend", "출석"]]
			for i in 3: b.append({"id": "qv:" + views[i][0], "label": views[i][1], "x": 8 + i * 116, "y": P + 6, "w": 112, "h": 24})
			if s.questView == "daily":
				for i in Game.DAILY.size(): b.append({"id": "qd:%d" % i, "x": W - 80, "y": P + 36 + i * 31, "w": 70, "h": 28})
				b.append({"id": "qbonus", "x": W - 80, "y": P + 191, "w": 70, "h": 28})
			elif s.questView == "ach":
				for i in Game.ACH.size(): b.append({"id": "qa:" + Game.ACH[i].id, "x": W - 80, "y": P + 36 + i * 31, "w": 70, "h": 28})
			else:
				b.append({"id": "qatt", "x": 60, "y": P + 186, "w": W - 120, "h": 34})
	return b

func _btn(id: String) -> Dictionary:
	for b in buttons_cache:
		if b.id == id: return b
	return {}

# ---- Sound: short synthesized tones, made once ---------------------------------------------

const SFX := {
	"tap": [760, 0.05, "square", 0.12], "crit": [980, 0.06, "square", 0.14], "swing": [300, 0.05, "square", 0.06],
	"arrow": [1200, 0.03, "triangle", 0.05], "holy": [880, 0.2, "sine", 0.08], "fire": [160, 0.25, "saw", 0.08],
	"kill": [520, 0.12, "triangle", 0.2], "kill_boss": [220, 0.3, "triangle", 0.25], "boss": [110, 0.5, "saw", 0.25],
	"fail": [90, 0.5, "saw", 0.25], "deny": [140, 0.08, "square", 0.1], "click": [400, 0.04, "square", 0.08],
	"buy": [660, 0.07, "square", 0.12], "join": [392, 0.3, "triangle", 0.25], "milestone": [784, 0.25, "triangle", 0.2],
	"drop": [880, 0.15, "square", 0.12], "equip": [700, 0.15, "triangle", 0.2], "enhance": [1046, 0.12, "triangle", 0.2],
	"merge": [990, 0.2, "triangle", 0.2], "evolve": [880, 0.4, "triangle", 0.2], "reward": [1046, 0.25, "triangle", 0.2],
	"dungeon": [98, 0.6, "saw", 0.2], "trial": [196, 0.5, "square", 0.15], "rankup": [784, 0.5, "triangle", 0.2],
	"loot": [440, 0.2, "triangle", 0.25], "rebirth": [392, 0.8, "triangle", 0.2],
	"skill_slash": [220, 0.25, "saw", 0.2], "skill_rain": [1300, 0.15, "triangle", 0.1], "skill_sanct": [660, 0.6, "sine", 0.15],
	"skill_storm": [80, 0.6, "saw", 0.25], "skill_cry": [150, 0.4, "square", 0.2], "skill_gold": [1046, 0.3, "triangle", 0.15],
}

func _build_sounds() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	for name in SFX:
		var d: Array = SFX[name]
		sounds[name] = _tone(d[0], d[1], d[2], d[3])

func _tone(freq: float, dur: float, wave: String, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var ph := fmod(t * freq, 1.0)
		var v := 0.0
		match wave:
			"square": v = 1.0 if ph < 0.5 else -1.0
			"triangle": v = 4.0 * absf(ph - 0.5) - 1.0
			"saw": v = 2.0 * ph - 1.0
			_: v = sin(TAU * ph)
		v *= vol * pow(0.001, t / dur)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.data = data
	return s

func _play(name: String) -> void:
	if muted or not sounds.has(name): return
	for p in players:
		if not p.playing:
			p.stream = sounds[name]
			p.play()
			return

# ---- Drawing --------------------------------------------------------------------------------

func _draw() -> void:
	buttons_cache = buttons()
	match scene:
		"title": _draw_title()
		"play": _draw_play()
		"pause":
			_draw_play()
			_shade(0.7)
			wood_frame(70, H / 2 - 50, W - 140, 90, PAL.leather)
			px.text_outlined("일시정지", W / 2, H / 2 - 14, 20, PAL.ink)
			px.text("탭하면 계속 · 뒤로 가기 한 번 더: 저장 후 종료", W / 2, H / 2 + 18, 11, PAL.muted)
		"results": _draw_results()

func _shade(a: float) -> void: draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.015, 0.03, a))

func icon(name: String, x: float, y: float, s: int = 1) -> void: px.bitmap(BM[name], x, y, ICON_PAL[name], s)
func coin(x: float, y: float, s: int = 1) -> void: px.bitmap(BM.coin, x - 4 * s, y - 4 * s, ICON_PAL.coin, s)
func flame(x: float, y: float, s: int = 1) -> void: px.bitmap(BM.flame, x - 4 * s, y - 6 * s, ICON_PAL.flame, s)
func sword_icon(x: float, y: float, c: Color) -> void:
	var pal: Dictionary = ICON_PAL.sword.duplicate()
	pal.s = c
	px.bitmap(BM.sword, x - 12, y - 12, pal, 2)
func armor_icon(x: float, y: float, c: Color) -> void:
	px.bitmap(BM.armor, x - 12, y - 12, {"k": Color("120f12"), "c": c, "w": Color(1, 1, 1, 0.6)}, 2)
func stars(x: float, y: float, n: int) -> void:
	for i in n: px.bitmap(BM.star, x + i * 6, y, ICON_PAL.star, 1)

func wood_frame(x: float, y: float, w: float, h: float, _fill: Color = PAL.leather) -> void:
	if px.nine("ui_panel", x, y, w, h): return
	px.rect(x, y, w, h, PAL.black)
	px.rect(x + 1, y + 1, w - 2, h - 2, PAL.wood)
	px.rect(x + 3, y + 3, w - 6, h - 6, PAL.trim)
	px.rect(x + 4, y + 4, w - 8, h - 8, _fill)

## A leather card. `edge` tints the border for rarity or state; plain cards use the PixelLab part.
func card(x: float, y: float, w: float, h: float, edge: Color = Color(), fill: Color = Color()) -> void:
	if edge == Color() and px.nine("ui_card", x, y, w, h):
		px.rect(x + 4, y + 4, w - 8, h - 8, Color(0.04, 0.03, 0.02, 0.45))
		return
	var e := edge if edge != Color() else Color("6a4a2a")
	var f := fill if fill != Color() else PAL.leather_hi
	px.rect(x + 1, y, w - 2, h, PAL.black)
	px.rect(x, y + 1, w, h - 2, PAL.black)
	px.rect(x + 1, y + 1, w - 2, h - 2, e)
	px.rect(x + 2, y + 2, w - 4, h - 4, f)
	px.rect(x + 2, y + 2, w - 4, 1, Color(1, 1, 1, 0.07))
	for c in [Vector2(x + 1, y + 1), Vector2(x + w - 4, y + 1), Vector2(x + 1, y + h - 2), Vector2(x + w - 4, y + h - 2)]:
		px.rect(c.x, c.y, 3, 1, PAL.trim)

func ribbon(cx: float, y: float, w: float, label: String) -> void:
	if not px.nine("ui_ribbon", cx - w / 2 - 14, y - 3, w + 28, 24):
		px.rect(cx - w / 2, y, w, 18, Color("8e1f1f"))
	px.text(label, cx, y + 9, 11, PAL.trim_hi)

## A button from the PixelLab parts; `cur` names the currency icon drawn beside `sub`.
func button(b: Dictionary, label: String, sub: String, enabled: bool, hot: bool, cur: String = "coin") -> void:
	if b.is_empty(): return
	var x: float = b.x
	var y: float = b.y
	var w: float = b.w
	var h: float = b.h
	if not px.nine("ui_btn_hot" if (hot and enabled) else "ui_btn", x, y, w, h):
		px.rect(x, y, w, h, PAL.trim if enabled else Color("4a4040"))
	if not enabled: px.rect(x + 2, y + 2, w - 4, h - 4, Color(0.04, 0.03, 0.02, 0.55))
	var lx := x + w / 2
	px.text(label, lx, y + (13.0 if sub != "" else (h - 3) / 2), 11, PAL.ink if enabled else PAL.dim)
	if sub != "":
		var tw := px.text_width(sub, 11)
		var ix := roundf(lx - tw / 2 - 6)
		if cur == "coin": coin(ix, y + 28)
		else: icon(cur, ix - 4, y + 24)
		var cc: Color = {"coin": PAL.gold, "gem": PAL.gem, "soul": PAL.soul, "key": PAL.gold}.get(cur, PAL.scroll)
		px.text(sub, lx + 5, y + 28, 11, cc if enabled else PAL.dim)

func bar(x: float, y: float, w: float, h: float, p: float, c: Color, back: Color = Color("140c08")) -> void:
	p = clampf(p, 0, 1)
	px.rect(x - 1, y - 1, w + 2, h + 2, PAL.black)
	px.rect(x, y, w, h, back)
	px.rect(x, y, roundf(w * p), h, c)
	px.rect(x, y, roundf(w * p), 1, Color(1, 1, 1, 0.3))

# ---- The title --------------------------------------------------------------------------------

## The title: the mouth of the abyss in a dungeon wall. Stone bricks, a gate with the
## abyss glowing inside, stairs going down, wall torches, hanging chains, the hero at the edge.
func _draw_title() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	draw_rect(Rect2(0, 0, W, H), Color("0a080c"))
	# stone brick wall, row by row, shades from a fixed hash
	for row in range(0, 40):
		var y := row * 16
		var off := 0 if row % 2 == 0 else 14
		for col in range(-1, 14):
			var x := col * 28 + off
			var n := Backdrop.noise01(row * 31.0 + col * 7.0)
			var shade := Color("1c1820").lerp(Color("2a2430"), n)
			px.rect(x + 1, y + 1, 26, 14, shade)
			px.rect(x + 1, y + 1, 26, 1, shade.lightened(0.12))
			if n > 0.82: px.rect(x + 6 + int(n * 10), y + 5, 6, 1, Color("120e14"))
	# darkness falls off toward the edges
	for i in 6:
		var a := 0.12 * (i + 1)
		px.rect(0, 0, 10 + i * 8, H, Color(0, 0, 0, a * 0.5))
		px.rect(W - 10 - i * 8, 0, 10 + i * 8, H, Color(0, 0, 0, a * 0.5))
	# the gate: a stepped stone arch around the abyss
	var gx := W / 2.0
	var top := 250.0
	var gw := 150.0
	var floor_y := 470.0
	for k in 3:
		var pad := 14.0 - k * 5.0
		var c: Color = [Color("3a3440"), Color("2c2832"), Color("0d0a10")][k]
		px.rect(gx - gw / 2 - pad, top + 40, gw + pad * 2, floor_y - top - 40, c)
		var r := int(gw / 2 + pad)
		px.disc(gx, top + 40, r, c)
	px.rect(gx - gw / 2 + 4, top + 40, gw - 8, floor_y - top - 40, Color("050308"))
	px.disc(gx, top + 40, int(gw / 2) - 4, Color("050308"))
	# the abyss inside: pulsing purple and ember rings sinking down
	var pulse := 1.0 + sin(t * 2.0) * 0.06
	for st in [[64, Color(0.35, 0.08, 0.45, 0.35)], [48, Color(0.55, 0.12, 0.4, 0.35)], [32, Color(0.85, 0.25, 0.2, 0.35)], [18, Color(1, 0.55, 0.25, 0.45)]]:
		px.disc(gx, 400, roundi(st[0] * pulse), st[1])
	for i in 5: # rings falling into the dark
		var p := fmod(t * 0.25 + i * 0.2, 1.0)
		var r := roundi(70.0 * (1.0 - p))
		var c := Color(0.9, 0.35, 0.6, 0.25 * p)
		var ang := 0.0
		while ang < TAU:
			px.rect(gx + cos(ang) * r, 400 + sin(ang) * r * 0.45, 2, 2, c)
			ang += 0.2
	# keystone and arch runes
	px.rect(gx - 9, top - 30, 18, 22, Color("4a4250")); px.rect(gx - 5, top - 24, 10, 10, Color(1, 0.35, 0.25, 0.6 + sin(t * 3) * 0.3))
	for i in 7:
		var ang := PI + PI * (i + 0.5) / 7.0
		px.rect(gx + cos(ang) * (gw / 2 + 6) - 1, top + 40 + sin(ang) * (gw / 2 + 6) - 1, 3, 3, Color(0.8, 0.3, 0.9, 0.35 + 0.35 * sin(t * 2 + i)))
	# stairs going down into the abyss
	for i in 6:
		var y := floor_y - 8 - i * 9
		var w := 130.0 - i * 16.0
		px.rect(gx - w / 2, y, w, 9, Color("2e2834").darkened(i * 0.12))
		px.rect(gx - w / 2, y, w, 1, Color("4a4250").darkened(i * 0.12))
	px.rect(0, floor_y, W, H - floor_y, Color("15111a"))
	px.rect(0, floor_y, W, 2, Color("3a3440"))
	# skulls and bones by the stairs
	var skull := [".kkk.", "kwwwk", "kbwbk", ".kwk.", ".k.k."]
	px.bitmap(skull, gx - 92, floor_y - 6, {"k": Color("0b0705"), "w": Color("d8d0c0"), "b": Color("0b0705")}, 2)
	px.bitmap(skull, gx + 80, floor_y - 6, {"k": Color("0b0705"), "w": Color("c8c0b0"), "b": Color("0b0705")}, 2)
	px.rect(gx - 70, floor_y - 2, 14, 2, Color("c8c0b0")); px.rect(gx + 62, floor_y - 3, 12, 2, Color("c8c0b0"))
	# wall torches with flickering light
	for side in [-1, 1]:
		var tx: float = gx + side * 128.0
		var ty := 330.0
		var fl := sin(t * 11 + side) * 0.05 + sin(t * 6.7) * 0.04
		for st in [[90, 0.05], [60, 0.06], [34, 0.08]]:
			px.disc(tx, ty - 10, roundi(st[0] * (1.0 + fl)), Color(1, 0.5, 0.2, st[1]))
		px.rect(tx - 2, ty - 4, 4, 22, Color("3a2a1a")); px.rect(tx - 5, ty + 2, 10, 3, Color("5a4030"))
		flame(tx, ty - 8 - roundi(absf(sin(t * 9 + side)) * 2), 2)
	# hanging chains
	for cx in [44, 316]:
		for i in 12:
			var y := i * 9 + roundi(sin(t * 1.3 + cx) * 1.5)
			px.rect(cx - 2 + (i % 2) * 1, y, 4 if i % 2 == 0 else 2, 7, Color("4a4650"))
			px.rect(cx - 1, y + 1, 2, 5, Color("0a080c") if i % 2 == 0 else Color("6a6670"))
	# the hero at the edge of the abyss, and the fire spirit
	px.sprite("knight", gx - 50, floor_y + 2, {"scale": 2.0})
	px.sprite("spirit_fire", gx + 18, 360 + roundi(sin(t * 3) * 4))
	# rising embers and ash from the abyss
	for i in 30:
		var p := fmod(t * (10 + Backdrop.noise01(i) * 16) + Backdrop.noise01(i + 40) * 300, 300)
		var x := gx - 60 + Backdrop.noise01(i + 9) * 120 + sin(t + i) * 10
		px.rect(x, 420 - p, 2, 2, Color(1, 0.45, 0.2, 0.7) if i % 3 else Color(0.8, 0.4, 1, 0.6))
	# the title carved into a stone plaque
	var py := 70.0
	px.rect(28, py, W - 56, 104, Color("0b0705"))
	px.rect(30, py + 2, W - 60, 100, Color("3a3440"))
	px.rect(34, py + 6, W - 68, 92, Color("26222c"))
	px.rect(30, py + 2, W - 60, 2, Color("5a5260"))
	for c in [Vector2(34, py + 6), Vector2(W - 40, py + 6), Vector2(34, py + 92), Vector2(W - 40, py + 92)]: px.rect(c.x, c.y, 6, 6, Color("5a5260"))
	px.line(60, py + 8, 74, py + 30, 1, Color("16121a")); px.line(290, py + 70, 304, py + 96, 1, Color("16121a"))
	var glow := 0.25 + sin(t * 2.5) * 0.1
	px.text("어비스 키우기", W / 2 + 2, 112, 40, Color(0.9, 0.2, 0.3, glow))
	px.text_outlined("어비스 키우기", W / 2, 110, 40, Color("e8d8c8"))
	ribbon(W / 2, 146, 160, "RAISE ABYSS")
	# the call to start
	var a: float = 0.6 + sin(t * 4) * 0.4
	px.text_outlined("탭해서 심연으로" if not Game.has_save() else "탭해서 이어하기", W / 2, 540, 18, Color(PAL.torch_hi, a))
	px.text("켜 두지 않아도 선봉대는 계속 싸웁니다", W / 2, 572, 11, PAL.muted, "center", false)
	if Game.has_save(): px.text("여기를 누르면 새로 시작", W / 2, 608, 11, PAL.dim)

func _draw_results() -> void:
	_draw_play()
	_shade(0.8)
	var s := Game.state
	wood_frame(24, 170, W - 48, 230)
	flame(W / 2, 214, 3)
	ribbon(W / 2, 248, 220, "잿불의 군주가 쓰러졌다")
	px.text("걸린 시간 %s · 환생 %d회" % [Game.fmt_time(s.playTime), s.rebirths], W / 2, 290, 11, PAL.ink, "center", false)
	px.text("잿불 %d개 · 서열 %s · 최고 스테이지 %d" % [s.embers, Game.RANKS[s.rank], s.bestStage], W / 2, 310, 11, PAL.ink, "center", false)
	px.text("행군은 계속된다. 탭해서 계속", W / 2, 360, 11, PAL.muted)

# ---- Play ------------------------------------------------------------------------------------

func _draw_play() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("07070a"))
	_draw_field()
	_draw_hud()
	_draw_strip()
	_draw_panel()
	_draw_away()

func _draw_field() -> void:
	var s := Game.state
	var t: float = s.t
	var gy := GROUND_Y
	Backdrop.draw(px, s, W, HUD_H, gy, FIELD_B, hero_x("knight"))
	if s.buffs.sanct > 0:
		var a: float = minf(1.0, s.buffs.sanct) * 0.12
		px.rect(20, HUD_H, 180, gy - HUD_H, Color(1, 0.91, 0.65, a))
	var order := hero_order()
	order.reverse()
	for id in order:
		var an: float = s.anim[id]
		var x := hero_x(id)
		var y := gy
		px.sprite(id, x, y, _motion(id, an, t))
		var st := int(s.stars[id])
		if st > 0: stars(roundf(x - st * 3), y - 72, st)
		if id == "cleric" and an > 0: px.rect(hero_x(id) - 14, gy - 76, 28, 3, Color(PAL.holy, an / 0.4 * 0.6))
		if id == "pyro" and an > 0: flame(hero_x(id) + 18, gy - 30)
	if s.spirit != null and Game.spirit_lv(s.spirit) > 0:
		for sp in Game.SPIRITS:
			if sp.id == s.spirit: px.sprite(sp.sprite, hero_x("knight") - 30, gy - 40 + roundi(sin(t * 3) * 4))
	var e = s.enemy
	if e != null:
		var ex := enemy_x()
		var fly: float = -26.0 + sin(t * 6) * 5.0 if e.kind.get("fly", false) else 0.0
		var alpha: float = maxf(0.0, 1.0 - e.dead / 0.4) if e.dead > 0 else 1.0
		var opts := {"flash": e.flash > 0, "modulate": Color(1, 1, 1, alpha), "rot": e.dead * 1.2 if e.dead > 0 else 0.0}
		if e.dead == 0: opts.merge(_enemy_motion(e, t))
		px.sprite(e.kind.id, ex, gy + fly + (e.dead * 30.0 if e.dead > 0 else 0.0), opts)
		if s.buffs.burn > 0 and e.dead == 0 and int(t * 10) % 2 == 0: flame(ex + (fmod(t * 37.0, 1.0) - 0.5) * 30, gy - 30 - fmod(t * 53.0, 1.0) * 30)
		if e.dead == 0 and e.x < 0.05:
			var bw := 120.0 if e.boss else 70.0
			var by := gy - (150.0 if e.boss else 82.0) + fly
			bar(ex - bw / 2, by, bw, 6, e.hp / e.max, PAL.threat, Color("3a1414"))
			px.text_outlined(e.kind.name, ex, by - 10, 11, PAL.threat if e.boss else PAL.muted)
	for sh in s.shots:
		var p: float = minf(1.0, sh.t / sh.dur)
		var x: float = sh.x0 + (sh.x1 - sh.x0) * p
		var y: float = gy + sh.y0 + (sh.y1 - sh.y0) * p - sin(p * PI) * sh.arc
		match sh.kind:
			"arrow":
				px.rect(x - 10, y - 1, 14, 2, Color("c9b48a")); px.rect(x + 4, y - 2, 4, 4, Color("e8e8f0")); px.rect(x - 12, y - 2, 3, 4, Color("5fb04a"))
			"fall":
				px.rect(x - 1, y - 12, 2, 14, Color("c9b48a")); px.rect(x - 2, y + 1, 4, 4, Color("e8e8f0")); px.rect(x - 2, y - 14, 4, 3, Color("5fb04a"))
			"fire":
				for k in 4: px.rect(x - 6 - k * 6, y - 4 + k, 8, 8 - k * 2, Color(PAL.ember, 0.35))
				flame(x, y)
	for f in s.fx: _draw_fx(f, gy)
	for p in s.sparks:
		if p.get("slash", false):
			var a: float = 1.0 - p.t / 0.2
			var ang := -1.2
			while ang <= 0.2:
				px.rect(p.x - 10 + cos(ang) * 22, gy + p.y + 10 + sin(ang) * 22, 3, 2, Color(1, 1, 1, a))
				ang += 0.09
		elif p.get("pillar", false):
			var a: float = 1.0 - p.t / 0.45
			px.rect(p.x - 10, HUD_H, 20, gy - HUD_H, Color(1, 0.91, 0.65, 0.27 * a))
			px.rect(p.x - 4, HUD_H, 8, gy - HUD_H, Color(1, 0.96, 0.82, 0.67 * a))
		else:
			px.rect(p.x, gy + p.y, 3, 3, PAL.gold if p.get("gold", false) else PAL.torch_hi)
	for f in s.floats:
		var a: float = maxf(0.0, 1.0 - f.t / 0.9)
		px.text_outlined(f.txt, f.x, gy + f.y - f.t * 40, 20 if f.big else 11, Color(f.color, a))
	if s.mode == "stage" and s.taps < 6 and s.rebirths == 0 and s.lv.knight < Game.tune("autoUnlockLevel"):
		px.text_outlined("화면을 탭해서 베기", W / 2, HUD_H + 130, 18, Color(PAL.torch_hi, 0.6 + sin(t * 6) * 0.4))
	if not toast.is_empty():
		var a: float = minf(1.0, toast.t / 0.3)
		var tw := minf(W - 24, px.text_width(toast.msg, 11) + 28)
		card(W / 2 - tw / 2, HUD_H + 152, tw, 22, Color("6a4a2a", a), Color(0.1, 0.07, 0.05, 0.85 * a))
		px.text(toast.msg, W / 2, HUD_H + 163, 11, Color(toast.color, a))
	if not pop.is_empty():
		var lines: PackedStringArray = pop.lines
		var h := 40 + lines.size() * 16
		wood_frame(40, 120, W - 80, h)
		ribbon(W / 2, 112, minf(220, px.text_width(pop.title, 11) + 40), pop.title)
		for i in lines.size(): px.text(lines[i], W / 2, 144 + i * 16, 11, PAL.muted if i > 0 else pop.color)

## Which frame a hero shows: its attack while one plays, otherwise a looping walk.
func _motion(id: String, attack_left: float, t: float) -> Dictionary:
	var dur := Game.tune("attackAnimTime")
	if attack_left > 0:
		var n := px.frame_count(id, "attack")
		if n > 0: return {"anim": "attack", "frame": int((1.0 - attack_left / dur) * n)}
	var w := px.frame_count(id, "walk")
	if w > 1: return {"anim": "walk", "frame": 1 + int(t * Game.tune("walkFps") + id.length()) % (w - 1)}
	return {}

## Enemies walk toward the party and strike on a steady beat (the blow is for show; heroes take no damage).
var _enemy_ref = null
var _enemy_clock := 0.0
func _enemy_motion(e: Dictionary, t: float) -> Dictionary:
	if not is_same(e, _enemy_ref):
		_enemy_ref = e
		_enemy_clock = t
	var every := Game.tune("enemyAttackEvery") * (1.4 if e.boss else 1.0)
	var since := fmod(t - _enemy_clock, every)
	var dur := Game.tune("attackAnimTime") * (1.4 if e.boss else 1.0)
	var id: String = e.kind.id
	if e.x <= 0.05 and since > every - dur:
		var n := px.frame_count(id, "attack")
		if n > 0: return {"anim": "attack", "frame": int((since - (every - dur)) / dur * n)}
	var w := px.frame_count(id, "walk")
	if w > 1: return {"anim": "walk", "frame": 1 + int(t * Game.tune("walkFps")) % (w - 1)}
	return {}

func _draw_fx(f: Dictionary, gy: float) -> void:
	var ex := enemy_x()
	match f.kind:
		"bigslash":
			var a: float = maxf(0.0, 1.0 - f.t / 0.35)
			var ang := -1.6
			while ang <= 0.6:
				px.rect(ex - 20 + cos(ang) * 46, gy - 40 + sin(ang) * 46, 4, 4, Color(PAL.torch, a) if (ang < -0.6 or ang > 0) else Color(1, 0.96, 0.85, a))
				ang += 0.05
		"storm":
			for k in 14: flame(ex - 30 + fmod(k * 0.618, 1.0) * 60, gy - 10 - fmod(f.t * 200 + k * 37, 140), 2)
		"sanct":
			px.disc(110, gy - 30, roundi(20 + f.t * 160), Color(1, 0.91, 0.65, 0.15 * (1.0 - f.t / 0.6)))
		"cry":
			var r: float = 10 + f.t * 220
			var ang := 0.0
			while ang < TAU:
				px.rect(hero_x("knight") + cos(ang) * r, gy - 34 + sin(ang) * r * 0.6, 3, 3, Color(PAL.threat, maxf(0, 1.0 - f.t / 0.5)))
				ang += 0.12
		"gold":
			for k in 10: coin(40 + fmod(k * 0.618, 1.0) * 260, HUD_H + 20 + fmod(f.t * 180 + k * 41, 240))

func _draw_hud() -> void:
	var s := Game.state
	px.rect(0, 0, W, HUD_H, PAL.wood)
	px.rect(0, 0, W, 1, PAL.wood_hi)
	px.rect(0, HUD_H - 4, W, 1, PAL.black); px.rect(0, HUD_H - 3, W, 2, PAL.trim); px.rect(0, HUD_H - 1, W, 1, PAL.black)
	card(4, 5, 112, 27, Color("6a4a2a"), Color("1a120e"))
	coin(16, 18, 2)
	px.text(Game.fmt(s.gold), 30, 19, 20, PAL.gold, "left")
	var boss: bool = s.enemy != null and s.enemy.boss and s.mode == "stage"
	var label: String = "지하묘지 B%d · %d/2" % [s.floor, s.modeIdx + 1] if s.mode == "dungeon" else ("시험 · " + Game.RANKS[mini(s.rank + 1, 5)] if s.mode == "trial" else "스테이지 %d" % s.stage)
	px.text(label, 186, 12, 11, PAL.threat if boss else PAL.ink)
	if s.mode == "stage": px.text(Game.ZONE_NAMES[Game.zone_index(s.stage)], 186, 26, 11, PAL.muted, "center", false)
	else:
		icon("crown", 160, 22)
		px.text(Game.RANKS[s.rank], 172, 26, 11, PAL.trim_hi, "left")
	var pb := _btn("pause")
	var mb := _btn("mute")
	card(pb.x, pb.y, pb.w, pb.h, PAL.trim, Color("3a2616"))
	px.rect(pb.x + 9, pb.y + 8, 4, 12, PAL.ink); px.rect(pb.x + 16, pb.y + 8, 4, 12, PAL.ink)
	card(mb.x, mb.y, mb.w, mb.h, PAL.trim, Color("3a2616"))
	px.bitmap(BM.speaker, mb.x + 6, mb.y + 6, {"k": PAL.ink}, 2)
	if muted: px.bitmap(BM.cross, mb.x + 16, mb.y + 9, {"x": PAL.threat}, 2)
	else: px.bitmap(BM.waves, mb.x + 16, mb.y + 6, {"w": PAL.ink}, 2)
	for i in 3:
		var b := _btn("cast:%d" % i)
		var open := i < Game.slots_open()
		card(b.x, b.y, b.w, b.h, PAL.trim if open else Color("3a3030"), Color("120c0a"))
		if not open:
			icon("crown", b.x + 15, b.y + 16)
			continue
		var id = s.slots[i]
		if id == null: continue
		var sk := Game.skill_by_id(id)
		var cd := float(s.skillCd.get(id, 0.0))
		px.icon_tex(sk.icon, b.x + 3, b.y + 3)
		if cd > 0:
			px.rect(b.x + 2, b.y + 2, b.w - 4, roundf((b.h - 4) * cd / Game.tune(sk.cd)), Color(0, 0, 0, 0.65))
			px.text_outlined(str(ceili(cd)), b.x + b.w / 2, b.y + b.h / 2, 11, PAL.ink)
	var ab := _btn("auto")
	card(ab.x, ab.y, ab.w, ab.h, PAL.trim_hi if s.autoSkill else Color("4a4040"), Color("5a2a14") if s.autoSkill else Color("1a1414"))
	px.text("AUTO", ab.x + ab.w / 2, ab.y + ab.h / 2, 11, PAL.torch_hi if s.autoSkill else PAL.dim)
	var bb := _btn("boss")
	if not bb.is_empty(): button(bb, "보스 도전", "", true, true)
	var lb := _btn("leave")
	if not lb.is_empty(): button(lb, "나가기", "", true, false)

func _draw_strip() -> void:
	var s := Game.state
	px.rect(0, FIELD_B, W, PANEL_Y - FIELD_B, PAL.wood)
	px.rect(0, FIELD_B, W, 2, PAL.trim)
	px.rect(0, FIELD_B + 2, W, 1, PAL.black)
	var e = s.enemy
	if s.mode == "stage" and e != null and e.boss and e.dead == 0:
		var total := Game.tune("bossTime") + Game.frost_bonus()
		bar(8, FIELD_B + 6, W - 16, 6, s.bossT / total, Color("ff4a4a") if s.bossT / total < 0.3 else PAL.threat, Color("2a1010"))
	elif s.mode == "stage":
		var n := int(Game.tune("killsPerStage"))
		var w := (W - 16.0) / n
		for i in n:
			px.rect(8 + i * w, FIELD_B + 5, w - 2, 8, PAL.black)
			px.rect(9 + i * w, FIELD_B + 6, w - 4, 6, PAL.torch if i < s.kills else Color("2a1a10"))
	else:
		var total := (Game.tune("dungeonTime") if s.mode == "dungeon" else Game.tune("trialTime")) + Game.frost_bonus()
		bar(8, FIELD_B + 6, W - 16, 6, s.modeT / total, PAL.soul if s.mode == "dungeon" else PAL.gem)
	var y := FIELD_B + 21
	for r in [["gem", s.stones, PAL.gem, 8], ["scroll", s.scrolls, PAL.scroll, 66], ["soul", s.souls, PAL.soul, 122], ["key", s.keys, PAL.gold, 174]]:
		icon(r[0], r[3], y - 4)
		px.text(Game.fmt(r[1]), r[3] + 12, y, 11, r[2], "left")
	if s.embers > 0:
		flame(234, y)
		px.text(str(s.embers), 242, y, 11, PAL.ember, "left")
	px.text("초당 " + Game.fmt(Game.total_dps()), W - 8, y, 11, PAL.ink, "right")

func _draw_panel() -> void:
	var s := Game.state
	wood_frame(0, PANEL_Y, W, TAB_Y - PANEL_Y + 2)
	match s.tab:
		"party": _draw_party()
		"skill": _draw_skills()
		"gear": _draw_gear()
		"adv": _draw_adventure()
		"quest": _draw_quests()
		"rebirth": _draw_rebirth()
	px.rect(0, TAB_Y, W, H - TAB_Y, PAL.wood_dk)
	for b in buttons_cache:
		if not b.id.begins_with("tab:"): continue
		var on: bool = s.tab == b.id.substr(4)
		if not px.nine("ui_tab", b.x, b.y, b.w, b.h): px.rect(b.x, b.y, b.w, b.h, PAL.wood_hi if on else PAL.wood)
		if not on: px.rect(b.x, b.y, b.w, b.h, Color(0, 0, 0, 0.45))
		else: px.rect(b.x + 2, b.y + 2, b.w - 4, 2, PAL.trim)
		icon(b.icon, b.x + b.w / 2 - BM[b.icon][0].length(), b.y + 6, 2)
		px.text(b.label, b.x + b.w / 2, b.y + b.h - 11, 11, PAL.trim_hi if on else PAL.muted)
		if _tab_alert(b.id.substr(4)):
			px.rect(b.x + b.w - 14, b.y + 5, 7, 7, PAL.black)
			px.rect(b.x + b.w - 13, b.y + 6, 5, 5, PAL.threat)

func _tab_alert(tab: String) -> bool:
	var s := Game.state
	match tab:
		"gear": return s.drop != null or Game.merge_target("weapon") >= 0 or Game.merge_target("armor") >= 0
		"rebirth": return Game.embers_for(s.maxStage) > 0
		"party":
			for h in Game.HEROES:
				if s.lv[h.id] > 0 and Game.can_evolve(h.id): return true
			return false
		"adv": return s.mode == "stage" and (s.keys > 0 or (s.rank < 5 and s.bestStage >= Game.rank_req(s.rank + 1)))
		"quest": return Game.quest_alert()
	return false

func _draw_party() -> void:
	var s := Game.state
	for i in Game.HEROES.size():
		var h: Dictionary = Game.HEROES[i]
		var y := PANEL_Y + 4 + i * 56
		var lv: int = s.lv[h.id]
		card(6, y + 4, W - 12, 52)
		card(10, y + 8, 44, 44, PAL.trim, Color("120c0a"))
		px.portrait(h.id, 12, y + 10, lv == 0)
		px.text(h.name, 60, y + 16, 11, PAL.ink if lv > 0 else PAL.muted, "left")
		stars(60 + px.text_width(h.name, 11) + 4, y + 13, int(s.stars[h.id]))
		var sub: String
		if lv == 0: sub = "%s · +%s/초" % [h.role, Game.fmt(Game.hero_dps(h, 1))]
		elif h.id == "knight" and lv < Game.tune("autoUnlockLevel"): sub = "Lv%d · 탭 %s · Lv%d부터 자동" % [lv, Game.fmt(Game.tap_damage()), int(Game.tune("autoUnlockLevel"))]
		else: sub = "Lv%d · 초당 %s (+%s)" % [lv, Game.fmt(Game.hero_dps(h)), Game.fmt(Game.hero_dps(h, lv + 1) - Game.hero_dps(h))]
		px.text(sub, 60, y + 31, 11, PAL.muted, "left", false)
		if lv > 0:
			var nm := Game.next_milestone(lv)
			var prev := 0
			var mi: int = Game.MILESTONES.find(nm)
			if mi > 0: prev = Game.MILESTONES[mi - 1]
			bar(60, y + 44, 70, 4, float(lv - prev) / float(nm - prev) if nm > 0 else 1.0, PAL.torch)
			if nm > 0: px.text("Lv%d x%s" % [nm, Game.fmt(Game.tune("milestoneMult"))], 134, y + 46, 11, PAL.dim, "left", false)
		var eb := _btn("evo:%d" % i)
		if not eb.is_empty(): button(eb, "진화", str(Game.evo_need(h.id).souls), Game.can_evolve(h.id), Game.can_evolve(h.id), "soul")
		var c := Game.hero_cost(h)
		var ok: bool = s.gold >= c
		button(_btn("buy:%d" % i), ("강화" if lv > 0 else "고용"), Game.fmt(c), ok, ok)

func _draw_skills() -> void:
	var s := Game.state
	for sk in Game.SKILLS:
		var b := _btn("sel:" + sk.id)
		var unl := Game.skill_unlocked(sk)
		var eq: bool = sk.id in s.slots
		var sel: bool = s.selSkill == sk.id
		card(b.x, b.y, b.w, b.h, PAL.trim_hi if sel else (PAL.trim if eq else Color("5a4030")), Color("3a2818") if sel else PAL.leather_hi)
		card(b.x + 5, b.y + 10, 36, 36, Color("6a4a2a"), Color("120c0a"))
		px.icon_tex(sk.icon, b.x + 7, b.y + 12, not unl)
		px.text(sk.name, b.x + 46, b.y + 16, 11, PAL.ink if unl else PAL.dim, "left")
		px.text("Lv%d" % int(s.skillLv.get(sk.id, 1)) if unl else "스테이지 %d" % int(Game.tune(sk.unlock)), b.x + 46, b.y + 32, 11, PAL.scroll if unl else PAL.dim, "left", false)
		if eq: px.text("장착", b.x + 46, b.y + 45, 11, PAL.trim_hi, "left")
	var sk := Game.skill_by_id(s.selSkill)
	var unl := Game.skill_unlocked(sk)
	var lv := int(s.skillLv.get(sk.id, 1))
	card(8, PANEL_Y + 124, W - 16, 98)
	px.text("%s  Lv%d" % [sk.name, lv], 18, PANEL_Y + 136, 11, PAL.trim_hi, "left")
	px.text("재사용 %d초" % int(Game.tune(sk.cd)), W - 18, PANEL_Y + 136, 11, PAL.muted, "right", false)
	px.text(Game.skill_desc(sk.id, 1.0 + Game.tune("skillLvStep") * (lv - 1)), 18, PANEL_Y + 152, 11, PAL.ink, "left", false)
	px.text("다음 레벨: " + Game.skill_desc(sk.id, 1.0 + Game.tune("skillLvStep") * lv) if unl else "최고 스테이지 %d에 해금" % int(Game.tune(sk.unlock)), 18, PANEL_Y + 167, 11, PAL.dim, "left", false)
	var on: bool = sk.id in s.slots
	button(_btn("equipsk"), "해제" if on else "장착 (슬롯 %d칸)" % Game.slots_open(), "", unl, unl and not on)
	button(_btn("upsk"), "레벨 업", str(lv), unl and s.scrolls >= lv, unl and s.scrolls >= lv, "scroll")

func _gear_card(x: float, y: float, w: float, item, slot: String) -> void:
	var c: Color = Game.RARITY[item.r].color if item != null else PAL.dim
	card(x, y, w, 80, c if item != null else Color("5a4030"), PAL.leather_hi)
	px.text("무기" if slot == "weapon" else "갑옷", x + 8, y + 10, 11, PAL.muted, "left", false)
	if slot == "weapon": sword_icon(x + 22, y + 32, c)
	else: armor_icon(x + 22, y + 32, c)
	if item == null:
		px.text("비어 있음", x + 42, y + 32, 11, PAL.dim, "left")
		return
	px.text(Game.RARITY[item.r].name + (" +%d" % item.plus if item.plus > 0 else ""), x + 42, y + 24, 11, c, "left")
	px.text(("피해 +%d%%" if slot == "weapon" else "금화 +%d%%") % Game.gear_pct(slot), x + 42, y + 38, 11, PAL.torch_hi, "left")

func _draw_gear() -> void:
	var s := Game.state
	var P := PANEL_Y
	for i in 2:
		var slot: String = ["weapon", "armor"][i]
		var g = s.gear[slot]
		_gear_card(8 + i * 174, P + 6, 170, g, slot)
		var b := _btn("enh:" + slot)
		if g == null: button(b, "장비 없음", "", false, false)
		elif g.plus >= Game.tune("enhMax"): button(b, "최대 강화", "", false, false)
		else:
			var c := Game.enh_cost(g)
			button(b, "강화 +%d · %d" % [g.plus + 1, c], "", s.stones >= c, s.stones >= c)
			icon("gem", b.x + 8, b.y + 10)
	var d = s.drop
	card(8, P + 92, W - 16, 62, Game.RARITY[d.r].color if d != null else Color("5a4030"), PAL.leather_hi)
	if d != null:
		if d.slot == "weapon": sword_icon(30, P + 122, Game.RARITY[d.r].color)
		else: armor_icon(30, P + 122, Game.RARITY[d.r].color)
		px.text("새 %s %s" % [Game.RARITY[d.r].name, "무기" if d.slot == "weapon" else "갑옷"], 50, P + 108, 11, Game.RARITY[d.r].color, "left")
		px.text(d.name, 50, P + 123, 11, PAL.ink, "left", false)
		var diff: int = d.pct - Game.gear_pct(d.slot)
		px.text("지금보다 %s%d%%" % ["+" if diff >= 0 else "", diff], 50, P + 138, 11, PAL.good if diff >= 0 else PAL.threat, "left")
		button(_btn("equip"), "장착", "", true, diff >= 0)
		button(_btn("store"), "보관", "", true, false)
	else:
		px.text("새 장비 없음 · 보스는 희귀 이상을 떨어뜨린다", W / 2, P + 123, 11, PAL.dim, "center", false)
	card(8, P + 158, W - 16, 66)
	px.text("보관함", 18, P + 170, 11, PAL.trim_hi, "left")
	for i in 2:
		var slot: String = ["weapon", "armor"][i]
		var y := P + 184 + i * 28
		var st: Array = s.stash[slot]
		px.text("무기" if slot == "weapon" else "갑옷", 18, y, 11, PAL.muted, "left", false)
		for k in 4: px.text(str(st[k]), 58 + k * 30, y, 11, Game.RARITY[k].color if st[k] > 0 else PAL.dim, "left")
		var m := Game.merge_target(slot)
		button(_btn("merge:" + slot), "%s%d→%s" % [Game.RARITY[m].name, int(Game.tune("mergeNeed")), Game.RARITY[m + 1].name] if m >= 0 else "합성 (%d개)" % int(Game.tune("mergeNeed")), "", m >= 0, m >= 0)

func _draw_adventure() -> void:
	var s := Game.state
	var P := PANEL_Y
	card(8, P + 6, W - 16, 60, Color("6a3a8a"), Color("241830"))
	icon("door", 16, P + 16, 3)
	px.text("지하묘지 B%d" % s.floor, 50, P + 18, 11, PAL.soul, "left")
	px.text("보스 2 · %d초" % int(Game.tune("dungeonTime") + Game.frost_bonus()), 50, P + 33, 11, PAL.muted, "left", false)
	px.text("보상 강화석 %d · 두루마리 %d" % [int(Game.tune("dungeonStones")) * s.floor * 2, (int(Game.tune("dungeonScrolls")) + s.floor / 2) * 2], 50, P + 48, 11, PAL.gem, "left", false)
	var ok_d: bool = s.mode == "stage" and s.keys > 0
	button(_btn("dungeon"), "입장", "%d/%d" % [s.keys, int(Game.tune("keysMax"))], ok_d, ok_d, "key")
	var next: int = s.rank + 1
	var top := next >= Game.RANKS.size()
	card(8, P + 78, W - 16, 60, Color("3a5a8a"), Color("18202e"))
	icon("crown", 16, P + 96, 3)
	px.text("최고 서열 " + Game.RANKS[s.rank] if top else "%s → %s" % [Game.RANKS[s.rank], Game.RANKS[next]], 50, P + 90, 11, PAL.trim_hi, "left")
	if not top:
		px.text("조건: 최고 스테이지 %d (지금 %d)" % [Game.rank_req(next), s.bestStage], 50, P + 105, 11, PAL.good if s.bestStage >= Game.rank_req(next) else PAL.muted, "left", false)
		px.text("보상: 모든 피해 x%s%s" % [Game.fmt(Game.tune("rankBonus")), " · 스킬 슬롯" if next <= 2 else ""], 50, P + 120, 11, PAL.gem, "left", false)
	var ok_t: bool = not top and s.mode == "stage" and s.bestStage >= Game.rank_req(next)
	button(_btn("trial"), "시험", "", ok_t, ok_t)
	for sp in Game.SPIRITS:
		var b := _btn("spirit:" + sp.id)
		var lv := Game.spirit_lv(sp.id)
		var on: bool = s.spirit == sp.id
		card(b.x, b.y, b.w, b.h + 28, PAL.trim_hi if on else (PAL.trim if lv > 0 else Color("4a4040")), Color("3a2818") if on else PAL.leather_hi)
		px.sprite(sp.sprite, b.x + 18, b.y + 44, {"dark": lv == 0})
		px.text(sp.name if lv > 0 else "???", b.x + 36, b.y + 12, 11, PAL.ink if lv > 0 else PAL.dim, "left")
		px.text("Lv%d%s" % [lv, " · 장착" if on else ""] if lv > 0 else Game.RANKS[sp.rank] + "에 합류", b.x + 36, b.y + 26, 11, PAL.trim_hi if on else PAL.muted, "left", false)
		if lv > 0: px.text(Game.spirit_desc(sp.id, lv), b.x + 36, b.y + 40, 11, PAL.gem, "left", false)
		var ub := _btn("spup:" + sp.id)
		if lv > 0:
			var c := Game.spirit_cost(sp.id)
			button(ub, "강화 %d" % c, "", s.stones >= c, s.stones >= c)
			icon("gem", ub.x + 8, ub.y + 8)
		else:
			button(ub, "잠김", "", false, false)

func _quest_row(y: float, title: String, sub: String, p: float, b: Dictionary, label: String, ok: bool, done: bool) -> void:
	card(8, y - 2, W - 16, 30, Color("3a5a3a") if done else Color("5a4030"), Color("1e2a1e") if done else PAL.leather_hi)
	px.text(title, 16, y + 7, 11, PAL.dim if done else PAL.ink, "left")
	px.text(sub, 16, y + 20, 11, PAL.gem, "left", false)
	if p >= 0: bar(214, y + 12, 54, 4, p, PAL.torch)
	button(b, label, "", ok, ok)

func _draw_quests() -> void:
	var s := Game.state
	var P := PANEL_Y
	for b in buttons_cache:
		if not b.id.begins_with("qv:"): continue
		var v: String = b.id.substr(3)
		var on: bool = s.questView == v
		card(b.x, b.y, b.w, b.h, PAL.trim_hi if on else Color("5a4030"), Color("5a2a14") if on else PAL.leather_hi)
		px.text(b.label, b.x + b.w / 2, b.y + b.h / 2, 11, PAL.trim_hi if on else PAL.muted)
	match s.questView:
		"daily":
			for i in Game.DAILY.size():
				var q: Dictionary = Game.DAILY[i]
				var need := Game.tune(q.need)
				var have := minf(float(s.daily.prog.get(q.id, 0)), need)
				var got: bool = s.daily.claimed.get(q.id, false)
				_quest_row(P + 38 + i * 31, "%s %s/%s" % [q.name, Game.fmt(have), Game.fmt(need)], Game.reward_text(q.reward), have / need, _btn("qd:%d" % i), "완료" if got else "받기", Game.daily_done(q) and not got, got)
			var all := Game.all_daily_claimed()
			_quest_row(P + 193, "오늘의 임무 전부 완료", Game.reward_text(Game.DAILY_BONUS), -1, _btn("qbonus"), "완료" if s.daily.bonus else "받기", all and not s.daily.bonus, s.daily.bonus)
		"ach":
			for i in Game.ACH.size():
				var a: Dictionary = Game.ACH[i]
				var tier := Game.ach_tier(a)
				var top: bool = tier >= a.tiers.size()
				var need: int = a.tiers[mini(tier, a.tiers.size() - 1)]
				_quest_row(P + 38 + i * 31, "%s %s/%s" % [a.name, Game.fmt(mini(Game.ach_value(a), need)), Game.fmt(need)], "모든 단계 달성" if top else Game.reward_text(Game.ach_reward(a, tier)), minf(1.0, float(Game.ach_value(a)) / need), _btn("qa:" + a.id), "완료" if top else "받기", Game.ach_ready(a), top)
		_:
			var cur: int = int(s.attend.idx) % Game.ATTEND.size()
			var can := Game.can_attend()
			for i in Game.ATTEND.size():
				var x := 10 + (i % 4) * 86
				var y := P + 38 + (i / 4) * 72
				var got := i < cur or (not can and i == cur - 1)
				var today := can and i == cur
				card(x, y, 82, 66, PAL.trim_hi if today else (Color("3a5a3a") if got else Color("5a4030")), Color("5a2a14") if today else (Color("1e2a1e") if got else PAL.leather_hi))
				px.text("%d일째" % (i + 1), x + 41, y + 10, 11, PAL.trim_hi if today else PAL.muted)
				var r: Dictionary = Game.ATTEND[i]
				var key: String = r.keys()[0]
				icon({"stones": "gem", "scrolls": "scroll", "souls": "soul", "keys": "key"}[key], x + 32, y + 22, 2)
				px.text(Game.reward_text({key: r[key]}), x + 41, y + 52, 11, PAL.dim if got else PAL.ink)
			button(_btn("qatt"), "오늘 출석하기 (%d일째)" % (cur + 1) if can else "내일 다시 오세요", "", can, can)

func _draw_rebirth() -> void:
	var s := Game.state
	var P := PANEL_Y
	var gain := Game.embers_for(s.maxStage)
	var ok: bool = gain > 0 and s.mode == "stage"
	card(8, P + 6, W - 16, 152, Color("8a3a1a"), PAL.leather_hi)
	flame(W / 2, P + 30, 3)
	px.text("잿불 %d개 · 모든 피해·금화 x%s" % [s.embers, Game.fmt(Game.ember_mult())], W / 2, P + 58, 11, PAL.ember)
	px.text("환생하면 스테이지·금화·레벨이 처음으로 돌아간다.", W / 2, P + 80, 11, PAL.muted, "center", false)
	px.text("서열·별·장비·스킬·정령·재료는 그대로 남는다.", W / 2, P + 96, 11, PAL.muted, "center", false)
	px.text("이번 행군 최고 스테이지 %d" % s.maxStage, W / 2, P + 118, 11, PAL.ink)
	px.text("지금 환생하면 잿불 +%d  →  x%s" % [gain, Game.fmt(1 + (s.embers + gain) * Game.tune("emberBonus"))] if gain > 0 else "스테이지 %d에 닿으면 환생할 수 있다" % int(Game.tune("prestigeMinStage")), W / 2, P + 138, 11, PAL.torch_hi if gain > 0 else PAL.dim)
	button(_btn("rebirth"), "한 번 더 누르면 환생" if s.confirm > 0 else "환생하기", "", ok, ok)

func _draw_away() -> void:
	var a = Game.state.away
	if a == null: return
	_shade(0.78)
	wood_frame(26, 170, W - 52, 270)
	ribbon(W / 2, 162, 200, "방치 보상 상자")
	var t: float = Game.state.t
	var cx := W / 2.0
	var cy := 248.0
	px.disc(cx, cy - 6, 34 + roundi(sin(t * 4) * 2), Color(1, 0.82, 0.47, 0.12))
	px.rect(cx - 30, cy - 4, 60, 30, PAL.black); px.rect(cx - 28, cy - 2, 56, 26, PAL.wood); px.rect(cx - 28, cy + 6, 56, 3, PAL.trim); px.rect(cx - 4, cy + 4, 8, 8, PAL.trim_hi)
	px.rect(cx - 30, cy - 22, 60, 16, PAL.black); px.rect(cx - 28, cy - 20, 56, 12, PAL.wood_hi); px.rect(cx - 28, cy - 12, 56, 2, PAL.trim)
	px.text("자리를 비운 %s 동안 선봉대가 모은 것" % Game.fmt_time(a.secs), cx, 296, 11, PAL.muted, "center", false)
	coin(cx - 60, 322, 2)
	px.text("+" + Game.fmt(a.gold), cx - 44, 322, 20, PAL.gold, "left")
	var items := [["gem", a.stones, PAL.gem], ["scroll", a.scrolls, PAL.scroll], ["soul", a.souls, PAL.soul]]
	for i in items.size():
		var x := cx - 90 + i * 64
		icon(items[i][0], x, 350, 2)
		px.text("+" + Game.fmt(items[i][1]), x + 20, 358, 11, items[i][2], "left")
	px.text_outlined("탭해서 받기", cx, 410, 18, PAL.ink)
