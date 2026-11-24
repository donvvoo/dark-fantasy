## Pixel drawing helpers shared by the battlefield and the UI: hard-edged rects,
## discs and lines, the Galmuri pixel font at its native sizes, PixelLab sprites
## and nine-sliced PixelLab UI parts. Usage:
##   var px := PixelDraw.new(self)   # self is the CanvasItem whose _draw() calls it
##   px.text("Hi", 180, 20, 11, Color.WHITE)
class_name PixelDraw
extends RefCounted

const SPRITE_DIR := "res://assets/sprites/"
const UI_DIR := "res://assets/ui/"
## Nine-slice borders in source pixels (x, y) for each PixelLab UI part.
const SLICE := {"ui_panel": Vector2i(14, 14), "ui_card": Vector2i(6, 6), "ui_btn": Vector2i(7, 6), "ui_btn_hot": Vector2i(7, 6),
	"ui_btn_off": Vector2i(7, 6), "ui_tab": Vector2i(8, 8), "ui_ribbon": Vector2i(24, 0)}

var ci: CanvasItem
var font: FontFile
var font_bold: FontFile
var tex := {}
## Per sprite: empty rows under the feet and a square face crop, measured once.
var meta := {}

func _init(canvas_item: CanvasItem) -> void:
	ci = canvas_item
	font = _pixel_font("res://assets/fonts/Galmuri11.ttf")
	font_bold = _pixel_font("res://assets/fonts/Galmuri11-Bold.ttf")

func _pixel_font(path: String) -> FontFile:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return f

## A sprite or UI texture by name, cached; measures its feet and face on first use.
func texture(name: String) -> Texture2D:
	if tex.has(name): return tex[name]
	var path := (UI_DIR if name.begins_with("ui_") else SPRITE_DIR + ("anim/" if ("_walk_" in name or "_attack_" in name) else "")) + name + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	tex[name] = t
	if t != null and not name.begins_with("ui_") and not ("_walk_" in name or "_attack_" in name): _measure(name, t)
	return t

func _measure(name: String, t: Texture2D) -> void:
	var img := t.get_image()
	if img == null: return
	var used := img.get_used_rect()
	if used.size.x == 0: return
	var side := int(used.size.y * 0.5)
	var cx := used.position.x + used.size.x / 2
	meta[name] = {"foot": img.get_height() - (used.position.y + used.size.y), "face": Rect2(maxi(0, cx - side / 2 - 2), used.position.y, side, side)}

static func pixel_size(size: float) -> int:
	return 44 if size >= 36 else 22 if size >= 18 else 11

func rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	ci.draw_rect(Rect2(roundf(x), roundf(y), roundf(w), roundf(h)), c)

## Pixel circles are rendered once per radius into a white texture and tinted on draw:
## one draw call instead of one per row.
var _discs := {}

func _disc_texture(r: int) -> Texture2D:
	if _discs.has(r): return _discs[r]
	var size := r * 2 + 1
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for dy in range(-r, r + 1):
		var w := int(floor(sqrt(float(r * r - dy * dy))))
		img.fill_rect(Rect2i(r - w, r + dy, w * 2 + 1, 1), Color.WHITE)
	var t := ImageTexture.create_from_image(img)
	_discs[r] = t
	return t

func disc(cx: float, cy: float, r: int, c: Color) -> void:
	if r <= 0: return
	ci.draw_texture(_disc_texture(r), Vector2(roundf(cx) - r, roundf(cy) - r), c)

func line(x0: float, y0: float, x1: float, y1: float, w: int, c: Color) -> void:
	var n := maxi(maxi(absi(int(x1 - x0)), absi(int(y1 - y0))), 1)
	for i in n + 1:
		ci.draw_rect(Rect2(roundf(x0 + (x1 - x0) * i / n), roundf(y0 + (y1 - y0) * i / n), w, w), c)

func text_width(s: String, size: float, bold: bool = true) -> float:
	return (font_bold if bold else font).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, pixel_size(size)).x

## Text centred vertically on y; align is "left", "center" or "right".
func text(s: String, x: float, y: float, size: float, c: Color, align: String = "center", bold: bool = true) -> void:
	var f := font_bold if bold else font
	var px := pixel_size(size)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var left := x if align == "left" else (x - w if align == "right" else x - w / 2.0)
	var base := y + (f.get_ascent(px) - f.get_descent(px)) / 2.0
	ci.draw_string(f, Vector2(roundf(left), roundf(base)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)

## Text with a 1-pixel dark outline (2 px at 22 and up), as eight offset copies.
func text_outlined(s: String, x: float, y: float, size: float, c: Color, align: String = "center") -> void:
	var o := 2 if pixel_size(size) >= 22 else 1
	var dark := Color("0a0808", c.a)
	for d in [Vector2(-o, 0), Vector2(o, 0), Vector2(0, -o), Vector2(0, o), Vector2(-o, -o), Vector2(o, -o), Vector2(-o, o), Vector2(o, o)]:
		text(s, x + d.x, y + d.y, size, dark, align)
	text(s, x, y, size, c, align)

## Number of frames in an animation (0 if there is none): assets/sprites/anim/<name>_<anim>_<i>.png
var _frame_counts := {}
func frame_count(name: String, anim: String) -> int:
	var key := name + "_" + anim
	if _frame_counts.has(key): return _frame_counts[key]
	var n := 0
	while ResourceLoader.exists(SPRITE_DIR + "anim/%s_%d.png" % [key, n]): n += 1
	_frame_counts[key] = n
	return n

## Draws a sprite with its centre at x and feet on y. Sprites 48 px and wider draw 1:1, smaller ones 2:1.
## opts.anim + opts.frame draw an animation frame instead (feet measured on the base sprite).
func sprite(name: String, x: float, y: float, opts: Dictionary = {}) -> void:
	texture(name) # measures the base sprite's feet
	var t: Texture2D = null
	if opts.has("anim"):
		var n := frame_count(name, opts.anim)
		if n > 0: t = texture("%s_%s_%d" % [name, opts.anim, clampi(int(opts.get("frame", 0)), 0, n - 1)])
	if t == null: t = texture(name)
	if t == null: return
	var sc: float = (1.0 if t.get_width() >= 48 else 2.0) * opts.get("scale", 1.0)
	var w := t.get_width() * sc
	var h := t.get_height() * sc
	var foot: float = meta.get(name, {}).get("foot", 0) * sc
	var mod: Color = opts.get("modulate", Color.WHITE)
	if opts.get("flash", false): mod = Color(1.0, 0.55, 0.5, mod.a)
	if opts.get("dark", false): mod = Color(0.2, 0.2, 0.2, mod.a)
	var rot: float = opts.get("rot", 0.0)
	ci.draw_set_transform(Vector2(roundf(x), roundf(y)), rot, Vector2.ONE)
	ci.draw_texture_rect(t, Rect2(-roundf(w / 2), -h + roundf(foot), w, h), false, mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## A texture at 1:1 with its top-left at x, y (icons).
func icon_tex(name: String, x: float, y: float, dark: bool = false) -> void:
	var t := texture(name)
	if t == null: return
	ci.draw_texture(t, Vector2(roundf(x), roundf(y)), Color(0.3, 0.3, 0.3) if dark else Color.WHITE)

## The head of a sprite at 2x in a 40x40 window (party portraits).
func portrait(name: String, x: float, y: float, dark: bool) -> void:
	var t := texture(name)
	if t == null: return
	var face: Rect2 = meta.get(name, {}).get("face", Rect2(6, 1, 20, 20))
	ci.draw_texture_rect_region(t, Rect2(x, y, 40, 40), face, Color(0.25, 0.25, 0.25) if dark else Color.WHITE)

## A nine-sliced PixelLab UI part: corners whole, edges and centre stretched, pixels hard.
func nine(name: String, x: float, y: float, w: float, h: float, mod: Color = Color.WHITE) -> bool:
	var t := texture(name)
	if t == null: return false
	x = roundf(x); y = roundf(y); w = roundf(w); h = roundf(h)
	var iw := t.get_width()
	var ih := t.get_height()
	var b: Vector2i = SLICE.get(name, Vector2i(8, 8))
	var bx := mini(b.x, mini(int(w / 2), iw / 2 - 1))
	var by := mini(b.y, mini(int(h / 2), ih / 2 - 1))
	var sx := [0, bx, iw - bx, iw]
	var dx := [x, x + bx, x + w - bx, x + w]
	var sy := [0, by, ih - by, ih]
	var dy := [y, y + by, y + h - by, y + h]
	for i in 3:
		for j in 3:
			var src := Rect2(sx[i], sy[j], sx[i + 1] - sx[i], sy[j + 1] - sy[j])
			var dst := Rect2(dx[i], dy[j], dx[i + 1] - dx[i], dy[j + 1] - dy[j])
			if src.size.x > 0 and src.size.y > 0 and dst.size.x > 0 and dst.size.y > 0:
				ci.draw_texture_rect_region(t, dst, src, mod)
	return true

## A pixel bitmap: rows of palette keys ('.' empty), s pixels per dot, top-left at x, y.
func bitmap(rows: Array, x: float, y: float, pal: Dictionary, s: int = 1) -> void:
	for j in rows.size():
		var row: String = rows[j]
		for i in row.length():
			var k := row[i]
			if pal.has(k): ci.draw_rect(Rect2(roundf(x) + i * s, roundf(y) + j * s, s, s), pal[k])
