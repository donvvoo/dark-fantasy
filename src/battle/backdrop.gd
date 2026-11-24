## The road behind the battle: five zones from the meadow to the demon castle,
## plus the crypt and the trial hall. Pure drawing, deterministic (no gameplay rng).
## Usage: Backdrop.draw(px, Game.state, 360, hud_h, ground_y, field_bottom, hero_x)
class_name Backdrop
extends RefCounted

const ZONES := [
	{"sky": ["5fa8e0", "6fb4e6", "82c0ea", "96cbee", "a9d6f0", "bfe0f0", "d6e8ea", "e8eedc", "f2ecc8"], "far": "7fae8a", "hill": "5c9a4c", "hill2": "4a8a3e",
		"ground": "7a5a38", "ground_hi": "a07a4a", "ground_dk": "5a4028", "grass": "5aa64a", "castle": 0.28, "castle_c": "6a7a9a", "night": 0.0, "mote": "ffffffcc", "mote2": "ffb6d0cc"},
	{"sky": ["2c4a5a", "30525e", "365a62", "3c6266", "446a68", "4c7268", "567a68", "628266", "6e8a64"], "far": "2f4a44", "hill": "24403a", "hill2": "1c342e",
		"ground": "4a3a2a", "ground_hi": "5e4a34", "ground_dk": "32281c", "grass": "3a6a34", "castle": 0.42, "castle_c": "2a3440", "night": 0.35, "mote": "d8ff8acc", "mote2": "a8e070cc"},
	{"sky": ["121319", "16161e", "1a1922", "1f1c27", "25202c", "2b2431", "352731", "43292c", "562c26"], "far": "22232d", "hill": "1b1c24", "hill2": "17181f",
		"ground": "3a332d", "ground_hi": "4a4139", "ground_dk": "2a2420", "grass": "2e3a2a", "castle": 0.6, "castle_c": "151520", "night": 1.0, "mote": "ff78328c", "mote2": "ffc87899"},
	{"sky": ["1a0a0a", "2a0e0c", "3a120e", "4e1810", "621e12", "7a2614", "922e14", "aa3a16", "c24a18"], "far": "3a1a14", "hill": "2a1410", "hill2": "1e0e0a",
		"ground": "2e2422", "ground_hi": "463632", "ground_dk": "1c1414", "grass": "3a2a1e", "castle": 0.85, "castle_c": "1a0c0c", "night": 0.8, "mote": "ff6e28cc", "mote2": "ffbe5acc", "lava": true},
	{"sky": ["0c0614", "120818", "180a1e", "1e0c24", "260e2a", "2e1030", "381236", "44143a", "52163c"], "far": "1e0e26", "hill": "160a1e", "hill2": "100616",
		"ground": "2a2230", "ground_hi": "3e3446", "ground_dk": "18141e", "grass": "2a1a2e", "castle": 1.6, "castle_c": "0e0812", "night": 1.0, "mote": "c878ff99", "mote2": "ff5a7899", "bolts": true},
]

static func noise01(i: float) -> float:
	var x := sin(i * 127.1 + 311.7) * 43758.5453
	return x - floor(x)

static func _c(hex: String) -> Color: return Color(hex)

static func draw(px: PixelDraw, s: Dictionary, w: int, top: int, gy: int, field_b: int, knight_x: float) -> void:
	if s.mode != "stage":
		_mode(px, s, w, top, gy, field_b)
		_torch(px, s, knight_x, gy, 1.0)
		_motes(px, s, w, top, field_b, -1)
		return
	var zi := Game.zone_index(s.stage)
	var Z: Dictionary = ZONES[zi]
	var t: float = s.t
	var scroll: float = s.scroll
	var sky: Array = Z.sky
	var bh := int(ceil(float(gy - top) / sky.size()))
	for i in sky.size(): px.rect(0, top + i * bh, w, bh, _c(sky[i]))
	match zi:
		0:
			px.disc(70, top + 52, 26, Color(1, 0.98, 0.82, 0.25)); px.disc(70, top + 52, 18, _c("fff4c0")); px.disc(66, top + 48, 12, _c("fffbe6"))
			for i in 4:
				var x := int(fposmod(noise01(i) * 500 - scroll * 0.04 - t * 4, 460)) - 60
				var y := top + 30 + i * 22
				px.rect(x, y, 50, 8, Color(1, 1, 1, 0.8)); px.rect(x + 8, y - 6, 26, 6, Color(1, 1, 1, 0.8)); px.rect(x + 4, y + 8, 40, 3, Color(0.9, 0.94, 0.97, 0.8))
		1:
			px.disc(290, top + 70, 22, Color(0.9, 1, 0.86, 0.15)); px.disc(290, top + 70, 14, _c("e8f0d0"))
		2:
			px.disc(300, top + 104, 22, Color(0.86, 0.82, 0.75, 0.07)); px.disc(300, top + 104, 16, _c("5d5a5e")); px.disc(296, top + 100, 11, _c("6c6a6c"))
		3:
			px.disc(250, top + 150, 40, Color(1, 0.35, 0.16, 0.2)); px.disc(250, top + 150, 30, _c("d8461c")); px.disc(246, top + 146, 22, _c("ee6a2a"))
		4:
			px.disc(80, top + 60, 20, Color(1, 0.24, 0.31, 0.15)); px.disc(80, top + 60, 14, _c("9a1a30")); px.disc(77, top + 57, 9, _c("c02a40"))
	# far hills and the demon castle growing on the horizon
	var moff := floorf(scroll * 0.06)
	for x in range(0, w, 2):
		var u := (x + moff) / 24.0
		var i := floorf(u)
		var f := u - i
		var h := 46.0 + (noise01(i) * (1 - f) + noise01(i + 1) * f) * 46.0
		px.rect(x, roundf(gy - 26 - h), 2, roundf(h + 26), _c(Z.far))
	_castle(px, 230 if zi == 4 else 270, gy - 52, Z.castle, _c(Z.castle_c), zi >= 2)
	var hoff := floorf(scroll * 0.18)
	for x in range(0, w, 2):
		var h := 30.0 + sin((x + hoff) / 38.0) * 12.0 + sin((x + hoff) / 15.0) * 4.0
		px.rect(x, roundf(gy - h), 2, roundf(h), _c(Z.hill))
	var off := floorf(scroll * 0.5)
	for k in range(-1, 6):
		var i := floorf(off / 70.0) + k
		var x := roundf(i * 70 - off + noise01(i + 9) * 30)
		_middle(px, zi, Z, x, i, gy, t)
	if zi == 4 and int(t * 0.7) % 4 == 0 and fmod(t * 0.7, 1.0) < 0.08:
		px.rect(0, top, w, gy - top, Color(0.85, 0.75, 1, 0.25))
		var x := 200.0 + noise01(floorf(t)) * 100.0
		var y := float(top)
		while y < gy - 120:
			var nx := x + (noise01(y + x) - 0.5) * 24.0
			px.line(x, y, nx, y + 14, 2, _c("f0e0ff"))
			x = nx
			y += 14
	if Z.night > 0:
		var fog := Color(0.63, 0.31, 0.24) if zi == 3 else (Color(0.55, 0.35, 0.7) if zi == 4 else Color(0.47, 0.47, 0.55))
		fog.a = 0.08 + Z.night * 0.04
		px.rect(0, gy - 30, w, 14, fog)
		px.rect(0, gy - 18, w, 8, fog)
	px.rect(0, gy - 6, w, field_b - gy + 6, _c(Z.ground))
	px.rect(0, gy - 8, w, 3, _c(Z.grass))
	var roff := int(scroll) % 32
	for x in range(-32, w + 32, 32):
		px.rect(x - roff, gy - 5, 30, 2, _c(Z.ground_hi))
		px.rect(x - roff + 14, gy + 6, 2, 10, _c(Z.ground_dk)); px.rect(x - roff, gy + 16, 30, 2, _c(Z.ground_dk)); px.rect(x - roff + 4, gy + 18, 2, 10, _c(Z.ground_dk))
		if zi <= 1:
			px.rect(x - roff + 6, gy - 11, 2, 4, _c(Z.grass)); px.rect(x - roff + 20, gy - 10, 2, 3, _c(Z.grass))
			if zi == 0 and noise01(x) > 0.5:
				px.rect(x - roff + 9, gy - 13, 2, 2, _c("ffe14a")); px.rect(x - roff + 23, gy - 12, 2, 2, _c("ff8ab0"))
		if Z.get("lava", false):
			px.rect(x - roff + 2, gy + 10, 10, 1, _c("ff6a2a")); px.rect(x - roff + 11, gy + 11, 1, 4, _c("ff6a2a"))
	_torch(px, s, knight_x, gy, Z.night)
	_motes(px, s, w, top, field_b, zi)

static func _middle(px: PixelDraw, zi: int, Z: Dictionary, x: float, i: float, gy: int, t: float) -> void:
	match zi:
		0:
			px.disc(x, gy - 12, 10, _c(Z.hill2)); px.disc(x + 10, gy - 10, 8, _c(Z.hill2)); px.rect(x - 2, gy - 18, 4, 2, _c("7cc06a"))
			if noise01(i) > 0.4:
				px.rect(x + 24, gy - 22, 3, 18, _c("8a6a44")); px.rect(x + 20, gy - 18, 30, 2, _c("8a6a44")); px.rect(x + 44, gy - 22, 3, 18, _c("8a6a44"))
		1:
			for tree in [[0.0, 70.0 + noise01(i) * 30.0, _c(Z.hill2)], [26.0, 50.0 + noise01(i + 2) * 20.0, _c("162a24")]]:
				var px_: float = x + tree[0]
				var hh: float = tree[1]
				px.rect(px_ - 2, gy - 12, 4, 12, _c("2a1e14"))
				var px_r := roundf(px_)
				px.ci.draw_colored_polygon(PackedVector2Array([Vector2(px_r, gy - 10 - hh), Vector2(px_r + 16, gy - 10), Vector2(px_r - 16, gy - 10)]), tree[2])
		2:
			var h := 40.0 + noise01(i + 3) * 30.0
			var ww := 30.0 + noise01(i + 5) * 16.0
			px.rect(x, gy - h, ww, h, _c("1b1c24"))
			var c := 0.0
			while c < ww:
				px.rect(x + c, gy - h - noise01(i * 3 + c) * 10.0, 5, 10, _c("1b1c24"))
				c += 6
			px.rect(x + ww / 2 - 3, gy - h + 10, 6, 8, _c("3a2318") if noise01(i + 2) > 0.5 else _c("0d0d11"))
			if noise01(i + 7) > 0.5:
				px.rect(x + ww + 12, gy - 60, 4, 56, _c("121216"))
				px.line(x + ww + 14, gy - 40, x + ww, gy - 58, 2, _c("121216")); px.line(x + ww + 14, gy - 50, x + ww + 30, gy - 66, 2, _c("121216"))
		3:
			var h := 30.0 + noise01(i + 3) * 50.0
			var ww := 14.0 + noise01(i + 5) * 10.0
			px.ci.draw_colored_polygon(PackedVector2Array([Vector2(roundf(x - ww * 0.1), gy - h), Vector2(roundf(x + ww * 0.3), gy - h), Vector2(roundf(x + ww * 0.6), gy), Vector2(roundf(x - ww / 2), gy)]), _c(Z.hill2))
			px.line(x, gy - h * 0.6, x + 3, gy - 4, 1, _c("ff7a2a"))
		_:
			px.rect(x - 30, gy - 70, 70, 70, _c("1a1020"))
			for c in range(-30, 40, 10): px.rect(x + c, gy - 78, 6, 8, _c("1a1020"))
			px.rect(x - 30, gy - 70, 70, 2, _c("2a1a32"))
			px.rect(x - 4, gy - 64, 10, 26, _c("6a1020")); px.rect(x - 2, gy - 58, 6, 6, _c("c8963e"))
			var fl := int(t * 10 + i) % 2
			px.rect(x + 26, gy - 50, 3, 10, _c("3a2a1a")); px.rect(x + 25, gy - 56 - fl, 5, 6, _c("ff9a3c")); px.rect(x + 26, gy - 58 - fl, 3, 3, _c("ffd27a"))

static func _castle(px: PixelDraw, cx: float, base: float, k: float, c: Color, lit: bool) -> void:
	var u := func(v: float) -> float: return roundf(v * k)
	px.rect(cx + u.call(-70), base - u.call(36), u.call(140), u.call(36), c)
	for tw in [[-60, 50, 12], [-38, 78, 14], [-14, 110, 18], [14, 96, 16], [40, 70, 14], [62, 46, 10]]:
		var x: float = cx + u.call(tw[0]) - u.call(tw[2] / 2.0)
		var top: float = base - u.call(tw[1])
		px.rect(x, top, u.call(tw[2]), u.call(tw[1]), c)
		var half: float = u.call(tw[2] / 2.0)
		for i in int(half) + 1:
			px.rect(x + i, top - (half - i) * 1.4, u.call(tw[2]) - i * 2, 2, c)
		if lit and k > 0.5: px.rect(x + half - 1, top + u.call(tw[1] * 0.3), maxf(2, u.call(3)), maxf(2, u.call(4)), Color("ff3a3a"))
	if lit: px.rect(cx - u.call(8), base - u.call(18), u.call(16), u.call(18), Color("2a0608"))

static func _mode(px: PixelDraw, s: Dictionary, w: int, top: int, gy: int, field_b: int) -> void:
	var crypt: bool = s.mode == "dungeon"
	var bands := ["0c0a12", "100c18", "140f1e", "181224", "1c142a", "211630", "261836", "2b1a3c", "301c42"] if crypt else ["0f1420", "121826", "151c2c", "182032", "1b2438", "1e283e", "222c44", "26304a", "2a3450"]
	var bh := int(ceil(float(gy - top) / bands.size()))
	for i in bands.size(): px.rect(0, top + i * bh, w, bh, Color(bands[i]))
	var off := floorf(s.scroll * 0.25)
	for k in range(-1, 5):
		var i := floorf(off / 110.0) + k
		var x := i * 110 - off + 20 + noise01(i + 9) * 40
		var ww := 26 + noise01(i + 5) * 22
		px.rect(x, top, ww, gy - top, Color("17121f") if crypt else Color("1a2236"))
		px.rect(x, top, 2, gy - top, Color("241c30") if crypt else Color("2a3450"))
		px.rect(x + ww / 2 - 3, gy - 80, 6, 10, Color("5a3a7a") if crypt else Color("6a8ac8"))
	var fog := Color(0.59, 0.43, 0.78, 0.1) if crypt else Color(0.47, 0.59, 0.86, 0.1)
	px.rect(0, gy - 32, w, 16, fog)
	px.rect(0, gy - 20, w, 8, fog)
	px.rect(0, gy - 6, w, field_b - gy + 6, Color("2a2430") if crypt else Color("2a3040"))

## The hero's ember runes light the road once dusk falls.
static func _torch(px: PixelDraw, s: Dictionary, knight_x: float, gy: int, night: float) -> void:
	if night <= 0: return
	var t: float = s.t
	var x := knight_x - 10
	var y := gy - 40
	var f := 1.0 + sin(t * 13) * 0.04 + sin(t * 7.3) * 0.05
	var r := (82.0 + minf(40.0, s.embers * 2.0)) * f
	for st in [[1.0, 0.03], [0.72, 0.035], [0.46, 0.045], [0.24, 0.06]]:
		px.disc(x, y, roundi(r * st[0]), Color(1, 0.51, 0.2, st[1] * night))

## Petals, fireflies, ash or embers by zone; zi -1 is the crypt or trial.
static func _motes(px: PixelDraw, s: Dictionary, w: int, top: int, field_b: int, zi: int) -> void:
	var t: float = s.t
	var n := 10 + mini(30, s.embers * 2) + (20 if zi == 3 else 0)
	for i in n:
		if zi == 1 and int(t * 2 + i) % 3 == 0: continue
		var p := fmod(t * (12 + noise01(i) * 18) + noise01(i + 50) * 400, 280)
		var fall := zi == 0
		var x := fposmod(noise01(i + 7) * w + sin(t + i) * 8 - (t * 20 if fall else 0.0), w)
		var y := top + p if fall else field_b - p
		if y < top or y > field_b: continue
		var c: Color
		if zi < 0: c = Color(0.75, 0.55, 1, 0.5) if s.mode == "dungeon" else Color(0.6, 0.7, 1, 0.5)
		else: c = Color(ZONES[zi].mote if i % 3 != 0 else ZONES[zi].mote2)
		px.rect(x, y, 2, 2, c)
