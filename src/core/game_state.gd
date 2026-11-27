## The whole game's state and rules: the road, the party, gear, skills, the crypt,
## ranks, spirits, rebirth and the reasons to come back (idle chest, daily orders,
## attendance, achievements). Autoloaded as `Game`. Rendering only reads from here.
##
## Every gameplay number comes from `assets/data/balance.json` through `tune()`.
## Design record: design/game-brief.md.
extends Node

signal toasted(message: String, color: Color)
signal popped(title: String, lines: PackedStringArray, color: Color)
signal sound(name: String)
signal results_reached

const BALANCE_PATH := "res://assets/data/balance.json"
const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 3

## Colours the rules hand to the renderer for toasts, popups and numbers.
const C_INK := Color("f3e6cc")
const C_MUTED := Color("c4ad8a")
const C_GOLD := Color("f6c453")
const C_TORCH := Color("ff9a3c")
const C_TORCH_HI := Color("ffd27a")
const C_THREAT := Color("e04848")
const C_EMBER := Color("ff6a2a")
const C_HOLY := Color("ffe9a6")
const C_GEM := Color("5fb6ff")
const C_SOUL := Color("c084ff")
const C_SCROLL := Color("e8d3a8")
const C_TRIM_HI := Color("ffe08a")
const C_GOOD := Color("8ee27a")

const HEROES := [
	{"id": "knight", "name": "카인", "role": "검사 · 탭", "cost": "knightCost", "dps": "knightDps", "every": "knightInterval"},
	{"id": "archer", "name": "리라", "role": "엘프 궁수 · 연사", "cost": "archerCost", "dps": "archerDps", "every": "archerInterval"},
	{"id": "cleric", "name": "엘린", "role": "사제 · 아군 강화", "cost": "clericCost", "dps": "clericDps", "every": "clericInterval"},
	{"id": "pyro", "name": "노아", "role": "마법사 · 폭발", "cost": "pyroCost", "dps": "pyroDps", "every": "pyroInterval"},
]
const ENEMIES := [
	{"id": "skeleton", "name": "해골 전사", "fly": false}, {"id": "ghoul", "name": "굶주린 구울", "fly": false},
	{"id": "bat", "name": "흡혈 박쥐", "fly": true}, {"id": "cultist", "name": "뿔가면 광신도", "fly": false},
]
const BOSSES := [
	{"id": "boss_rider", "name": "뼈의 기수", "fly": false}, {"id": "boss_priest", "name": "역병 사제", "fly": false},
	{"id": "boss_lord", "name": "잿불의 군주", "fly": false},
]
const CRYPT := [{"id": "boss_warden", "name": "지하묘지 간수", "fly": false}, {"id": "boss_wyrm", "name": "뼈의 비룡", "fly": false}]
const EXAMINER := {"id": "boss_examiner", "name": "기사단 시험관", "fly": false}
const SKILLS := [
	{"id": "slash", "name": "잿불 베기", "icon": "icon_slash", "cd": "slashCd", "unlock": "slashUnlock"},
	{"id": "rain", "name": "화살비", "icon": "icon_rain", "cd": "rainCd", "unlock": "rainUnlock"},
	{"id": "sanct", "name": "성역의 빛", "icon": "icon_sanct", "cd": "sanctCd", "unlock": "sanctUnlock"},
	{"id": "storm", "name": "화염 폭풍", "icon": "icon_storm", "cd": "stormCd", "unlock": "stormUnlock"},
	{"id": "cry", "name": "전투의 함성", "icon": "icon_cry", "cd": "cryCd", "unlock": "cryUnlock"},
	{"id": "gold", "name": "황금의 손길", "icon": "icon_gold", "cd": "goldCd", "unlock": "goldUnlock"},
]
const SPIRITS := [
	{"id": "fire", "sprite": "spirit_fire", "name": "불씨 정령", "rank": 1},
	{"id": "frost", "sprite": "spirit_frost", "name": "서리 정령", "rank": 2},
	{"id": "light", "sprite": "spirit_light", "name": "빛 정령", "rank": 3},
]
const RANKS := ["견습 기사", "종자", "정기사", "기사장", "성기사", "잿불 성기사"]
const RARITY := [
	{"name": "일반", "color": Color("d8d2c6"), "k": "gearCommon"}, {"name": "희귀", "color": Color("5fb6ff"), "k": "gearRare"},
	{"name": "영웅", "color": Color("c97cff"), "k": "gearEpic"}, {"name": "전설", "color": Color("ffb02e"), "k": "gearLegend"},
]
const GEAR_NAMES := {
	"weapon": ["녹슨 장검", "기사의 장검", "흑철 대검", "잿불 군주살해자"],
	"armor": ["누더기 사슬갑옷", "순례자의 흉갑", "흑철 판금", "잿불 성갑"],
}
const MILESTONES := [25, 50, 100, 200, 400]
const ZONE_KEYS := ["zoneForest", "zoneVillage", "zoneWaste", "zoneCastle"]
const ZONE_NAMES := ["푸른 초원", "어둠의 숲", "무너진 마을", "잿빛 황야", "마왕성"]
const DAILY := [
	{"id": "kills", "name": "몬스터 처치", "need": "dailyKills", "reward": {"stones": 30}},
	{"id": "taps", "name": "직접 베기 (탭)", "need": "dailyTaps", "reward": {"scrolls": 3}},
	{"id": "ups", "name": "동료 강화", "need": "dailyUps", "reward": {"souls": 3}},
	{"id": "casts", "name": "스킬 사용", "need": "dailyCasts", "reward": {"stones": 20}},
	{"id": "dungeons", "name": "지하묘지 돌파", "need": "dailyDungeons", "reward": {"keys": 1, "scrolls": 2}},
]
const DAILY_BONUS := {"souls": 5, "stones": 50}
const ATTEND := [{"stones": 20}, {"scrolls": 3}, {"keys": 2}, {"souls": 5}, {"stones": 60}, {"scrolls": 6}, {"souls": 15, "stones": 100}]
## Achievement chains: each tier pays once; `reward` is per tier index.
const ACH := [
	{"id": "stage", "name": "최고 스테이지", "tiers": [10, 20, 30, 50, 80], "reward": "souls", "per": 5},
	{"id": "boss", "name": "보스 처치", "tiers": [3, 10, 30, 100], "reward": "scrolls", "per": 3},
	{"id": "kills", "name": "몬스터 처치", "tiers": [500, 2000, 10000, 50000], "reward": "stones", "per": 40},
	{"id": "rebirth", "name": "환생", "tiers": [1, 3, 10], "reward": "souls", "per": 10},
	{"id": "rank", "name": "기사단 서열", "tiers": [1, 2, 3, 4, 5], "reward": "scrolls", "per": 4},
	{"id": "crypt", "name": "지하묘지 층", "tiers": [3, 6, 10, 20], "reward": "stones", "per": 80},
]
const RES_NAMES := {"stones": "강화석", "scrolls": "두루마리", "souls": "영혼석", "keys": "열쇠", "gold": "금화"}
## Saved across rebirth.
const KEEP := ["embers", "rebirths", "gear", "stash", "stones", "scrolls", "souls", "keys", "keyT", "rank", "stars", "skillLv",
	"slots", "spirit", "spiritLv", "floor", "bestStage", "beatGoal", "playTime", "autoSkill", "daily", "attend", "ach", "stats"]

var balance: Dictionary = {}
var state: Dictionary = {}
var rng := RandomNumberGenerator.new()
var results_pending := 0.0

func _ready() -> void:
	load_balance()
	reset()

## Reads every tuning value. Missing file means the game cannot be balanced: fail loudly.
func load_balance() -> void:
	var f := FileAccess.open(BALANCE_PATH, FileAccess.READ)
	assert(f != null, "balance.json missing")
	balance = JSON.parse_string(f.get_as_text())

## A tuning value by its key in balance.json.
func tune(key: String) -> float:
	return float(balance.get(key, 0.0))

# ---- State ------------------------------------------------------------------------------

func fresh_run(keep: Dictionary = {}) -> Dictionary:
	var s := {
		"t": 0.0, "gold": 0.0, "stage": 1, "kills": 0, "maxStage": 1, "bestStage": 1,
		"embers": 0, "rebirths": 0,
		"lv": {"knight": 1, "archer": 0, "cleric": 0, "pyro": 0}, "stars": {"knight": 0, "archer": 0, "cleric": 0, "pyro": 0},
		"gear": {"weapon": null, "armor": null}, "drop": null, "stash": {"weapon": [0, 0, 0, 0], "armor": [0, 0, 0, 0]},
		"stones": 0, "scrolls": 0, "souls": 0, "keys": int(tune("keysStart")), "keyT": 0.0,
		"rank": 0, "skillLv": {"slash": 1}, "slots": ["slash", null, null], "autoSkill": true, "skillCd": {}, "selSkill": "slash",
		"spirit": null, "spiritLv": {"fire": 0, "frost": 0, "light": 0}, "floor": 1,
		"buffs": {"sanct": 0.0, "cry": 0.0, "gold": 0.0, "burn": 0.0}, "rain": null, "cryTap": 0.0,
		"mode": "stage", "modeT": 0.0, "modeIdx": 0, "modeLoot": null, "ret": null,
		"farming": false, "bossT": 0.0, "enemy": null, "march": 0.0, "scroll": 0.0,
		"cd": {"knight": 0.0, "archer": 0.3, "cleric": 0.6, "pyro": 0.9}, "anim": {"knight": 0.0, "archer": 0.0, "cleric": 0.0, "pyro": 0.0},
		"floats": [], "shots": [], "sparks": [], "fx": [], "tab": "party", "taps": 0, "confirm": 0.0,
		"beatGoal": false, "playTime": 0.0, "saveT": 0.0, "dayT": 0.0, "away": null, "questView": "daily",
		"daily": {"day": "", "prog": {}, "claimed": {}, "bonus": false}, "attend": {"last": "", "idx": 0}, "ach": {},
		"stats": {"kills": 0, "bossKills": 0, "taps": 0, "ups": 0, "casts": 0, "dungeons": 0},
	}
	for k in KEEP:
		if keep.has(k) and keep[k] != null:
			s[k] = keep[k]
	return s

func reset() -> void:
	rng.seed = int(tune("seed"))
	state = fresh_run()
	check_day()
	spawn_enemy(true)

func toast(msg: String, color: Color = C_INK) -> void:
	toasted.emit(msg, color)

func popup(title: String, lines: Array, color: Color = C_TORCH_HI) -> void:
	popped.emit(title, PackedStringArray(lines), color)

func sfx(name: String) -> void:
	sound.emit(name)

# ---- Rules: pure functions of state ------------------------------------------------------

func is_boss_stage(s: int) -> bool: return s % int(tune("bossEvery")) == 0
func boss_index(s: int) -> int: return int(s / int(tune("bossEvery"))) - 1
func stage_hp(s: float) -> float: return tune("hpBase") * pow(tune("hpGrowth"), s - 1.0)
func enemy_hp(s: int, boss: bool) -> float:
	return stage_hp(s) * (tune("bossHpMult") + tune("bossHpMultStep") * boss_index(s)) if boss else stage_hp(s)
func dungeon_hp(f: int) -> float: return stage_hp(tune("dungeonStage") + f * tune("dungeonFloorStep")) * tune("dungeonHpMult")
func rank_req(r: int) -> int: return r * int(tune("rankReqStep"))
func trial_hp(r: int) -> float: return stage_hp(rank_req(r)) * tune("trialHpMult")
func ember_mult() -> float: return 1.0 + state.embers * tune("emberBonus")
func spirit_lv(id: String) -> int: return int(state.spiritLv.get(id, 0))
func spirit_on(id: String) -> bool: return state.spirit == id and spirit_lv(id) > 0
func fire_bonus() -> float: return tune("fireBase") + tune("fireLv") * (spirit_lv("fire") - 1) if spirit_on("fire") else 0.0
func frost_bonus() -> float: return tune("frostBase") + tune("frostLv") * (spirit_lv("frost") - 1) if spirit_on("frost") else 0.0
func light_bonus() -> float: return tune("lightBase") + tune("lightLv") * (spirit_lv("light") - 1) if spirit_on("light") else 0.0

func spirit_desc(id: String, lv: int) -> String:
	match id:
		"fire": return "파티 피해 +%d%%" % roundi((tune("fireBase") + tune("fireLv") * (lv - 1)) * 100)
		"frost": return "제한 시간 +%s초" % fmt(tune("frostBase") + tune("frostLv") * (lv - 1))
		_: return "금화 +%d%%" % roundi((tune("lightBase") + tune("lightLv") * (lv - 1)) * 100)

func gear_pct(slot: String) -> int:
	var g = state.gear[slot]
	if g == null: return 0
	return roundi(g.pct * (1.0 + g.get("plus", 0) * tune("enhPct")))

func skill_k(id: String) -> float: return 1.0 + tune("skillLvStep") * (int(state.skillLv.get(id, 1)) - 1)

func party_mult() -> float:
	return (1.0 + gear_pct("weapon") / 100.0) * ember_mult() * (1.0 + state.lv.cleric * tune("clericAura")) \
		* pow(tune("rankBonus"), state.rank) * (1.0 + fire_bonus()) \
		* ((1.0 + tune("sanctBoost") * skill_k("sanct")) if state.buffs.sanct > 0 else 1.0)

func gold_mult() -> float:
	return (1.0 + gear_pct("armor") / 100.0) * ember_mult() * (1.0 + light_bonus()) * ((1.0 + skill_k("gold")) if state.buffs.gold > 0 else 1.0)

func milestone_mult(lv: int) -> float:
	var m := 1.0
	for t in MILESTONES:
		if lv >= t: m *= tune("milestoneMult")
	return m

func next_milestone(lv: int) -> int:
	for t in MILESTONES:
		if lv < t: return t
	return 0

func star_mult(id: String) -> float: return pow(tune("starMult"), int(state.stars.get(id, 0)))
func hero_cost(h: Dictionary) -> float: return ceil(tune(h.cost) * pow(tune("costGrowth"), state.lv[h.id]))

func hero_dps(h: Dictionary, lv: int = -1) -> float:
	if lv < 0: lv = state.lv[h.id]
	if lv <= 0: return 0.0
	if h.id == "knight" and lv < tune("autoUnlockLevel"): return 0.0
	return tune(h.dps) * lv * milestone_mult(lv) * star_mult(h.id) * party_mult()

func total_dps() -> float:
	var t := 0.0
	for h in HEROES: t += hero_dps(h)
	return t

func tap_damage() -> float:
	var lv: int = state.lv.knight
	var base := (tune("tapBase") + lv * tune("tapPerLevel")) * milestone_mult(lv) * star_mult("knight") * party_mult() + total_dps() * tune("tapDpsShare")
	return base * 3.0 * skill_k("cry") if state.buffs.cry > 0 else base

func kill_gold(s: int, boss: bool) -> float:
	return max(1.0, ceil(stage_hp(s) * tune("goldRatio") * (tune("bossGoldMult") if boss else 1.0) * gold_mult()))

func embers_for(max_stage: int) -> int:
	if max_stage < tune("prestigeMinStage"): return 0
	return int(floor(pow(max_stage / tune("emberDiv"), tune("emberPow"))))

func evo_need(id: String) -> Dictionary:
	var s: int = int(state.stars.get(id, 0)) + 1
	return {"lv": int(tune("evoLevel") * pow(2, s - 1)), "souls": int(tune("evoSouls") * s), "star": s}

func can_evolve(id: String) -> bool:
	var n := evo_need(id)
	return n.star <= 5 and state.lv[id] >= n.lv and state.souls >= n.souls

func enh_cost(g: Dictionary) -> int: return int(ceil(tune("enhCost") * pow(g.get("plus", 0) + 1, tune("enhPow"))))
func spirit_cost(id: String) -> int: return int(ceil(tune("spiritCost") * pow(max(1, spirit_lv(id)), tune("spiritPow"))))
func slots_open() -> int: return mini(3, 1 + int(state.rank))
func skill_unlocked(sk: Dictionary) -> bool: return state.bestStage >= tune(sk.unlock)
func skill_by_id(id: String) -> Dictionary:
	for sk in SKILLS:
		if sk.id == id: return sk
	return {}

func skill_desc(id: String, k: float) -> String:
	match id:
		"slash": return "적 하나에 파티 피해 x%s + 탭 5회" % fmt(tune("slashPower") * k)
		"rain": return "화살 6발, 각각 파티 피해 x%s" % fmt(tune("rainPower") * k)
		"sanct": return "%d초 동안 파티 피해 +%d%%" % [int(tune("sanctTime")), roundi(tune("sanctBoost") * k * 100)]
		"storm": return "파티 피해 x%s 폭발 + 3초 화상" % fmt(tune("stormPower") * k)
		"cry": return "%d초 동안 탭 x%s, 초당 %d회 자동 탭" % [int(tune("cryTime")), fmt(3 * k), int(tune("cryTaps"))]
		_: return "%d초 동안 금화 x%s" % [int(tune("goldTime")), fmt(1 + k)]

func zone_index(stage: int) -> int:
	var z := 0
	for i in ZONE_KEYS.size():
		if stage >= tune(ZONE_KEYS[i]): z = i + 1
	return z

# ---- Numbers ------------------------------------------------------------------------------

const UNITS := ["", "K", "M", "B", "T"]

## Short big numbers: 1.23K, 45.6M, then aa, ab... after T.
static func fmt(n: float) -> String:
	if is_inf(n) or is_nan(n): return "∞"
	if n < 1000.0:
		return ("%.1f" % n) if (n < 10.0 and fmod(n, 1.0) != 0.0) else str(int(floor(n)))
	var u := 0
	while n >= 1000.0 and u < 60:
		n /= 1000.0
		u += 1
	var name: String = UNITS[u] if u < UNITS.size() else char(97 + int((u - 5) / 26)) + char(97 + (u - 5) % 26)
	if n < 10.0: return "%.2f%s" % [n, name]
	if n < 100.0: return "%.1f%s" % [n, name]
	return "%d%s" % [int(n), name]

static func fmt_time(secs: float) -> String:
	var s := int(secs)
	var h := s / 3600
	var m := (s / 60) % 60
	if h > 0: return "%d시간 %d분" % [h, m]
	if m > 0: return "%d분 %d초" % [m, s % 60]
	return "%d초" % s

# ---- Enemies: the road, the crypt or the trial --------------------------------------------

func spawn_enemy(instant: bool) -> void:
	var kind: Dictionary
	var hp: float
	var boss := true
	if state.mode == "dungeon":
		kind = CRYPT[state.modeIdx]
		hp = dungeon_hp(state.floor) * (1.0 + state.modeIdx * 0.5)
	elif state.mode == "trial":
		kind = EXAMINER
		hp = trial_hp(state.rank + 1)
	else:
		var s: int = state.stage
		boss = is_boss_stage(s) and not state.farming
		kind = BOSSES[boss_index(s) % BOSSES.size()] if boss else ENEMIES[rng.randi_range(0, ENEMIES.size() - 1)]
		hp = enemy_hp(s, boss)
		if boss:
			state.bossT = tune("bossTime") + frost_bonus()
			toast("보스 출현: %s" % kind.name, C_THREAT)
			sfx("boss")
	state.enemy = {"kind": kind, "boss": boss, "hp": hp, "max": hp, "x": 0.0 if instant else 1.0, "flash": 0.0, "dead": 0.0, "lunge": 0.0}

func targetable() -> bool:
	var e = state.enemy
	return e != null and e.dead == 0.0 and e.x <= 0.05

## Deals damage to the current enemy and pops a number at `at_x`.
func damage(n: float, crit: bool, color: Color, at_x: float) -> void:
	if not targetable(): return
	var e: Dictionary = state.enemy
	e.hp -= n
	e.flash = 0.08
	state.floats.append({"txt": fmt(n), "x": at_x + rng.randf_range(-15, 15), "y": -(110.0 if e.boss else 62.0), "t": 0.0, "color": color, "big": crit})
	if e.hp <= 0: kill_enemy(at_x)

func kill_enemy(at_x: float) -> void:
	var e: Dictionary = state.enemy
	e.dead = 0.001
	for i in 8:
		state.sparks.append({"x": at_x, "y": -30.0, "vx": rng.randf_range(-27, 63), "vy": -60.0 - rng.randf() * 90.0, "t": 0.0, "gold": true})
	count("kills")
	if e.boss: count("bossKills")
	if state.mode == "dungeon": return kill_in_dungeon(at_x)
	if state.mode == "trial": return win_trial()
	var g := kill_gold(state.stage, e.boss)
	state.gold += g
	state.floats.append({"txt": "+" + fmt(g), "x": at_x, "y": -90.0, "t": 0.0, "color": C_GOLD, "big": false})
	sfx("kill_boss" if e.boss else "kill")
	roll_drop(e.boss)
	if e.boss:
		var souls := int(tune("bossSouls")) + boss_index(state.stage)
		state.souls += souls
		state.scrolls += 1
		state.keys = mini(int(tune("keysMax")), state.keys + 1)
		toast("%s 처치! 영혼석 +%d · 두루마리 +1 · 열쇠 +1" % [e.kind.name, souls], C_TORCH_HI)
		if state.stage >= tune("goalStage") and not state.beatGoal:
			state.beatGoal = true
			results_pending = 1.2
		advance_stage()
	else:
		state.kills += 1
		if state.kills >= tune("killsPerStage"):
			if state.farming: state.kills = 0
			else: advance_stage()

func advance_stage() -> void:
	state.stage += 1
	state.kills = 0
	state.maxStage = max(state.maxStage, state.stage)
	var before: int = state.bestStage
	state.bestStage = max(state.bestStage, state.stage)
	for sk in SKILLS:
		if before < tune(sk.unlock) and state.bestStage >= tune(sk.unlock):
			state.skillLv[sk.id] = state.skillLv.get(sk.id, 1)
			for i in slots_open():
				if state.slots[i] == null:
					state.slots[i] = sk.id
					break
			popup("새 스킬 해금", [sk.name, skill_desc(sk.id, 1.0)])
	if zone_index(state.stage) != zone_index(state.stage - 1):
		popup("지역: " + ZONE_NAMES[zone_index(state.stage)], ["마왕성의 문 앞에 섰다" if zone_index(state.stage) == 4 else "마왕성이 조금 더 가까워졌다"], C_TRIM_HI)
	if state.bestStage == rank_req(state.rank + 1) and state.rank < RANKS.size() - 1:
		toast("승급 시험을 볼 수 있다 (모험 탭)", C_TRIM_HI)

func fail_boss() -> void:
	toast("보스에게 밀려났다… 파밍 후 재도전", C_THREAT)
	sfx("fail")
	state.stage = max(1, state.stage - 1)
	state.kills = 0
	state.farming = true
	state.enemy = null
	state.march = tune("marchTime")

func challenge_boss() -> void:
	if not state.farming or state.mode != "stage": return
	state.farming = false
	state.stage += 1
	state.kills = 0
	state.enemy = null
	state.march = tune("marchTime")

# ---- Dungeon: the crypt under the castle --------------------------------------------------

func enter_dungeon() -> void:
	if state.mode != "stage" or state.keys <= 0:
		sfx("deny")
		return
	state.keys -= 1
	state.ret = {"stage": state.stage, "kills": state.kills, "farming": state.farming}
	state.mode = "dungeon"
	state.modeIdx = 0
	state.modeT = tune("dungeonTime") + frost_bonus()
	state.modeLoot = {"stones": 0, "scrolls": 0}
	state.enemy = null
	state.march = 0.6
	popup("지하묘지 B%d" % state.floor, ["제한 시간 안에 보스 둘을 쓰러뜨려라"], C_SOUL)
	sfx("dungeon")

func kill_in_dungeon(at_x: float) -> void:
	var f: int = state.floor
	var st := int(tune("dungeonStones")) * f
	var sc := int(tune("dungeonScrolls")) + f / 2
	state.modeLoot.stones += st
	state.modeLoot.scrolls += sc
	state.stones += st
	state.scrolls += sc
	state.floats.append({"txt": "강화석 +%d" % st, "x": at_x, "y": -120.0, "t": 0.0, "color": C_GEM, "big": false})
	sfx("loot")
	state.modeIdx += 1
	if state.modeIdx >= CRYPT.size():
		state.floor += 1
		count("dungeons")
		leave_mode(true)

func leave_mode(won: bool) -> void:
	var was: String = state.mode
	var loot = state.modeLoot
	var r: Dictionary = state.ret if state.ret != null else {"stage": state.stage, "kills": 0, "farming": false}
	state.mode = "stage"
	state.stage = r.stage
	state.kills = r.kills
	state.farming = r.farming
	state.enemy = null
	state.march = tune("marchTime")
	state.ret = null
	if was == "dungeon":
		popup("지하묘지 돌파! 다음은 B%d" % state.floor if won else "시간이 다 됐다",
			["강화석 +%d · 두루마리 +%d" % [loot.stones, loot.scrolls]], C_GOOD if won else C_MUTED)

# ---- Promotion: a duel with the order's examiner -------------------------------------------

func start_trial() -> void:
	var next: int = state.rank + 1
	if state.mode != "stage" or next >= RANKS.size() or state.bestStage < rank_req(next):
		sfx("deny")
		return
	state.ret = {"stage": state.stage, "kills": state.kills, "farming": state.farming}
	state.mode = "trial"
	state.modeT = tune("trialTime") + frost_bonus()
	state.enemy = null
	state.march = 0.6
	popup("승급 시험", ["%s의 자격을 증명하라" % RANKS[next]], C_TRIM_HI)
	sfx("trial")

func win_trial() -> void:
	state.rank += 1
	leave_mode(true)
	var lines := ["모든 피해 x%s" % fmt(tune("rankBonus"))]
	if state.rank <= 2: lines.append("스킬 슬롯 %d칸" % slots_open())
	for sp in SPIRITS:
		if sp.rank == state.rank:
			state.spiritLv[sp.id] = max(1, spirit_lv(sp.id))
			if state.spirit == null: state.spirit = sp.id
			lines.append(sp.name + " 합류")
	popup("승급! " + RANKS[state.rank], lines, C_TRIM_HI)
	sfx("rankup")

# ---- Gear: drops, enhance, store and merge -------------------------------------------------

func make_item(slot: String, r: int) -> Dictionary:
	var pct := maxi(1, roundi(state.bestStage * tune(RARITY[r].k) * rng.randf_range(0.8, 1.2)))
	return {"slot": slot, "r": r, "pct": pct, "plus": 0, "name": GEAR_NAMES[slot][r]}

func offer_item(item: Dictionary, why: String) -> void:
	if state.gear[item.slot] == null:
		state.gear[item.slot] = item
		toast("%s %s 장착!" % [RARITY[item.r].name, item.name], RARITY[item.r].color)
		return
	if state.drop != null:
		var d: Dictionary = state.drop
		var worse := d if item.pct - gear_pct(item.slot) > d.pct - gear_pct(d.slot) else item
		if worse == d: state.drop = item
		state.stash[worse.slot][worse.r] += 1
		if worse == item: return
	else:
		state.drop = item
	toast("%s 장비 %s (장비 탭)" % [RARITY[item.r].name, why], RARITY[item.r].color)
	sfx("drop")

func roll_drop(boss: bool) -> void:
	if not boss and rng.randf() >= tune("dropChance"): return
	var roll := rng.randf()
	var r := 0
	if roll < tune("legendChance"): r = 3
	elif roll < tune("legendChance") + tune("epicChance"): r = 2
	elif roll < tune("legendChance") + tune("epicChance") + tune("rareChance"): r = 1
	if boss: r = maxi(r, 1)
	offer_item(make_item("weapon" if rng.randf() < 0.5 else "armor", r), "획득")

func equip_drop() -> void:
	var d = state.drop
	if d == null: return
	var old = state.gear[d.slot]
	if old != null: state.stash[old.slot][old.r] += 1
	state.gear[d.slot] = d
	state.drop = null
	sfx("equip")

func store_drop() -> void:
	var d = state.drop
	if d == null: return
	state.stash[d.slot][d.r] += 1
	state.drop = null
	sfx("click")

func enhance(slot: String) -> void:
	var g = state.gear[slot]
	if g == null or g.plus >= tune("enhMax"): return
	var c := enh_cost(g)
	if state.stones < c:
		sfx("deny")
		return
	state.stones -= c
	g.plus += 1
	toast("%s +%d!" % [g.name, g.plus], RARITY[g.r].color)
	sfx("enhance")

func merge_target(slot: String) -> int:
	var st: Array = state.stash[slot]
	for r in 3:
		if st[r] >= tune("mergeNeed"): return r
	return -1

func merge(slot: String) -> void:
	var r := merge_target(slot)
	if r < 0:
		sfx("deny")
		return
	state.stash[slot][r] -= int(tune("mergeNeed"))
	sfx("merge")
	offer_item(make_item(slot, r + 1), "합성")

# ---- Party: hire, level, evolve -------------------------------------------------------------

func buy_hero(i: int) -> void:
	if i < 0 or i >= HEROES.size(): return
	var h: Dictionary = HEROES[i]
	var c := hero_cost(h)
	if state.gold < c:
		sfx("deny")
		return
	state.gold -= c
	var before: int = state.lv[h.id]
	state.lv[h.id] += 1
	count("ups")
	if before == 0:
		toast(h.name + " 합류!", C_TORCH_HI)
		sfx("join")
	else:
		sfx("buy")
	if h.id == "knight" and state.lv.knight == int(tune("autoUnlockLevel")):
		toast("기사가 스스로 싸우기 시작한다", C_TORCH_HI)
	if state.lv[h.id] in MILESTONES:
		toast("%s Lv%d: 피해 x%s!" % [h.name, state.lv[h.id], fmt(tune("milestoneMult"))], C_TORCH)
		sfx("milestone")

func evolve(i: int) -> void:
	var h: Dictionary = HEROES[i]
	if not can_evolve(h.id):
		sfx("deny")
		return
	var n := evo_need(h.id)
	state.souls -= n.souls
	state.stars[h.id] = n.star
	popup(h.name + " 진화!", ["별 %d개 · 피해 x%s" % [n.star, fmt(star_mult(h.id))]], C_SOUL)
	sfx("evolve")

# ---- Skills --------------------------------------------------------------------------------

func equip_skill(id: String) -> void:
	var sk := skill_by_id(id)
	if sk.is_empty() or not skill_unlocked(sk): return
	var at: int = state.slots.find(id)
	if at >= 0:
		state.slots[at] = null
		return
	var free := -1
	for i in slots_open():
		if state.slots[i] == null:
			free = i
			break
	if free < 0: free = slots_open() - 1
	state.slots[free] = id
	sfx("click")

func upgrade_skill(id: String) -> void:
	var lv := int(state.skillLv.get(id, 0))
	if lv == 0: return
	if state.scrolls < lv:
		sfx("deny")
		return
	state.scrolls -= lv
	state.skillLv[id] = lv + 1
	toast("%s Lv%d" % [skill_by_id(id).name, lv + 1], C_SCROLL)
	sfx("buy")

## Casts a skill; damage skills wait until a target is in reach. Returns whether it fired.
func cast_skill(id: String, enemy_x: float) -> bool:
	var sk := skill_by_id(id)
	if sk.is_empty() or float(state.skillCd.get(id, 0.0)) > 0.0: return false
	if id in ["slash", "rain", "storm"] and not targetable(): return false
	var k := skill_k(id)
	var dps := maxf(total_dps(), tap_damage())
	state.skillCd[id] = tune(sk.cd)
	count("casts")
	match id:
		"slash":
			damage(dps * tune("slashPower") * k + tap_damage() * 5.0, true, C_TORCH_HI, enemy_x)
			state.fx.append({"kind": "bigslash", "t": 0.0})
		"rain":
			state.rain = {"n": 6, "t": 0.0}
		"sanct":
			state.buffs.sanct = tune("sanctTime")
			state.fx.append({"kind": "sanct", "t": 0.0})
		"storm":
			damage(dps * tune("stormPower") * k, true, C_EMBER, enemy_x)
			state.buffs.burn = 3.0
			state.fx.append({"kind": "storm", "t": 0.0})
		"cry":
			state.buffs.cry = tune("cryTime")
			state.fx.append({"kind": "cry", "t": 0.0})
		"gold":
			state.buffs.gold = tune("goldTime")
			state.fx.append({"kind": "gold", "t": 0.0})
	sfx("skill_" + id)
	return true

func upgrade_spirit(id: String) -> void:
	if spirit_lv(id) == 0: return
	var c := spirit_cost(id)
	if state.stones < c:
		sfx("deny")
		return
	state.stones -= c
	state.spiritLv[id] += 1
	toast("정령 Lv%d" % spirit_lv(id), C_GEM)
	sfx("enhance")

func rebirth() -> void:
	var gain := embers_for(state.maxStage)
	if gain <= 0 or state.mode != "stage": return
	if state.confirm <= 0:
		state.confirm = 3.0
		sfx("click")
		return
	var keep := {}
	for k in KEEP: keep[k] = state[k]
	keep.embers = state.embers + gain
	keep.rebirths = state.rebirths + 1
	state = fresh_run(keep)
	spawn_enemy(true)
	popup("환생!", ["잿불 %d개 · 모든 피해·금화 x%s" % [keep.embers, fmt(ember_mult())], "서열·별·장비·스킬·정령은 그대로"], C_EMBER)
	sfx("rebirth")

# ---- Coming back: daily orders, attendance, achievements -----------------------------------

## Calendar day from the device clock: the only real-time read in the rules.
func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%d-%d-%d" % [d.year, d.month, d.day]

func check_day() -> void:
	var t := today()
	if state.daily.day != t:
		state.daily = {"day": t, "prog": {}, "claimed": {}, "bonus": false}

func count(id: String, n: int = 1) -> void:
	if state.stats.has(id): state.stats[id] += n
	state.daily.prog[id] = int(state.daily.prog.get(id, 0)) + n

func grant(r: Dictionary) -> String:
	var got := []
	for key in r:
		var n := int(r[key]) if key == "keys" else int(ceil(r[key] * tune("rewardScale")))
		if key == "keys": state.keys = mini(int(tune("keysMax")) + 5, state.keys + n)
		else: state[key] += n
		got.append("%s +%s" % [RES_NAMES[key], fmt(n)])
	sfx("reward")
	return " · ".join(got)

func reward_text(r: Dictionary) -> String:
	var parts := []
	for key in r:
		parts.append("%s %d" % [RES_NAMES[key], int(r[key]) if key == "keys" else int(ceil(r[key] * tune("rewardScale")))])
	return " · ".join(parts)

func daily_done(q: Dictionary) -> bool: return int(state.daily.prog.get(q.id, 0)) >= tune(q.need)

func claim_daily(i: int) -> void:
	var q: Dictionary = DAILY[i]
	if state.daily.claimed.get(q.id, false) or not daily_done(q): return
	state.daily.claimed[q.id] = true
	toast("임무 완료! " + grant(q.reward), C_TRIM_HI)

func all_daily_claimed() -> bool:
	for q in DAILY:
		if not state.daily.claimed.get(q.id, false): return false
	return true

func claim_daily_bonus() -> void:
	if state.daily.bonus or not all_daily_claimed(): return
	state.daily.bonus = true
	popup("오늘의 임무 전부 완료!", [grant(DAILY_BONUS)], C_TRIM_HI)

func can_attend() -> bool: return state.attend.last != today()

func claim_attend() -> void:
	if not can_attend(): return
	var i: int = int(state.attend.idx) % ATTEND.size()
	state.attend = {"last": today(), "idx": int(state.attend.idx) + 1}
	popup("출석 %d일째" % (i + 1), [grant(ATTEND[i])], C_TRIM_HI)

func ach_value(a: Dictionary) -> int:
	match a.id:
		"stage": return state.bestStage
		"boss": return state.stats.bossKills
		"kills": return state.stats.kills
		"rebirth": return state.rebirths
		"rank": return state.rank
		_: return state.floor - 1

func ach_tier(a: Dictionary) -> int: return int(state.ach.get(a.id, 0))
func ach_reward(a: Dictionary, i: int) -> Dictionary: return {a.reward: a.per * (i + 1)}
func ach_ready(a: Dictionary) -> bool:
	var i := ach_tier(a)
	return i < a.tiers.size() and ach_value(a) >= a.tiers[i]

func claim_ach(id: String) -> void:
	for a in ACH:
		if a.id == id and ach_ready(a):
			var i := ach_tier(a)
			state.ach[a.id] = i + 1
			toast("업적: %s %d · %s" % [a.name, a.tiers[i], grant(ach_reward(a, i))], C_TRIM_HI)

func quest_alert() -> bool:
	if can_attend() or (not state.daily.bonus and all_daily_claimed()): return true
	for q in DAILY:
		if daily_done(q) and not state.daily.claimed.get(q.id, false): return true
	for a in ACH:
		if ach_ready(a): return true
	return false

# ---- Saving and the idle chest --------------------------------------------------------------

## Writes the save to user://; the in-flight battle (effects, modes) is not saved.
func save() -> void:
	var s := state.duplicate(true)
	for k in ["floats", "shots", "sparks", "fx"]: s[k] = []
	s.enemy = null
	s.away = null
	if s.mode != "stage" and s.ret != null:
		s.stage = s.ret.stage
		s.kills = s.ret.kills
		s.farming = s.ret.farming
		s.mode = "stage"
		s.ret = null
	s.savedAt = Time.get_unix_time_from_system()
	s.version = SAVE_VERSION
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(s))

func has_save() -> bool: return FileAccess.file_exists(SAVE_PATH)

## Loads the save and fills the idle chest with what the time away earned.
func continue_save() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null: return false
	var s = JSON.parse_string(f.get_as_text())
	if typeof(s) != TYPE_DICTIONARY: return false
	rng.seed = int(tune("seed")) + int(Time.get_unix_time_from_system())
	state = fresh_run()
	for k in s:
		if state.has(k): state[k] = s[k]
	_fix_numbers()
	state.buffs = {"sanct": 0.0, "cry": 0.0, "gold": 0.0, "burn": 0.0}
	state.skillCd = {}
	spawn_enemy(true)
	var gone := minf(Time.get_unix_time_from_system() - float(s.get("savedAt", Time.get_unix_time_from_system())), tune("offlineCapHours") * 3600.0)
	if gone > 60.0:
		var rate := total_dps() / maxf(1.0, enemy_hp(state.stage, false)) * kill_gold(state.stage, false) * tune("offlineRate")
		var hrs := gone / 3600.0
		state.keys = mini(int(tune("keysMax")), state.keys + int(gone / tune("keyRegen")))
		state.away = {"secs": gone, "gold": floor(rate * gone), "stones": int(tune("chestStones") * state.floor * hrs),
			"scrolls": int(tune("chestScrolls") * hrs), "souls": int(tune("chestSouls") * hrs)}
	check_day()
	return true

## JSON brings every number back as a float; counters that index arrays must be ints again.
func _fix_numbers() -> void:
	for k in ["stage", "kills", "maxStage", "bestStage", "embers", "rebirths", "stones", "scrolls", "souls", "keys", "rank", "floor", "taps", "modeIdx"]:
		state[k] = int(state[k])
	for d in ["lv", "stars", "skillLv", "spiritLv", "ach", "stats"]:
		for k in state[d]: state[d][k] = int(state[d][k])
	for slot in ["weapon", "armor"]:
		state.stash[slot] = state.stash[slot].map(func(v): return int(v))
		var g = state.gear[slot]
		if g != null:
			g.r = int(g.r); g.pct = int(g.pct); g.plus = int(g.plus)
	if state.drop != null:
		state.drop.r = int(state.drop.r); state.drop.pct = int(state.drop.pct); state.drop.plus = int(state.drop.plus)
	state.attend.idx = int(state.attend.idx)
	for k in state.daily.prog: state.daily.prog[k] = int(state.daily.prog[k])

func claim_away() -> void:
	var a = state.away
	if a == null: return
	state.gold += a.gold
	state.stones += a.stones
	state.scrolls += a.scrolls
	state.souls += a.souls
	state.away = null
	sfx("reward")
	if can_attend(): toast("출석 보상을 받을 수 있다 (임무 탭)", C_TRIM_HI)

# ---- Fixed-step simulation ----------------------------------------------------------------

## Advances the battle by `dt`. `hero_x` maps a hero id to its x; `enemy_x` is the target's x.
func step(dt: float, hero_x: Callable, enemy_x: float) -> void:
	state.t += dt
	state.playTime += dt
	state.dayT += dt
	if state.dayT > 60.0:
		state.dayT = 0.0
		check_day()
	if state.confirm > 0: state.confirm -= dt
	if state.away != null: return
	if state.keys < tune("keysMax"):
		state.keyT += dt
		if state.keyT >= tune("keyRegen"):
			state.keyT = 0.0
			state.keys += 1
	else:
		state.keyT = 0.0
	for k in state.buffs:
		if state.buffs[k] > 0: state.buffs[k] -= dt
	for k in state.skillCd:
		if state.skillCd[k] > 0: state.skillCd[k] -= dt
	if state.buffs.burn > 0 and targetable(): damage(total_dps() * dt * skill_k("storm"), false, C_EMBER, enemy_x)
	if state.buffs.cry > 0:
		state.cryTap += dt * tune("cryTaps")
		while state.cryTap >= 1.0:
			state.cryTap -= 1.0
			if targetable(): tap_attack(enemy_x, true)
	if state.rain != null:
		state.rain.t -= dt
		if state.rain.t <= 0 and state.rain.n > 0:
			state.rain.t = 0.18
			state.rain.n -= 1
			state.shots.append({"kind": "fall", "x0": enemy_x + rng.randf_range(-30, 30), "y0": -260.0, "x1": enemy_x + rng.randf_range(-10, 10), "y1": -24.0,
				"arc": 0.0, "t": 0.0, "dur": 0.22, "dmg": total_dps() * tune("rainPower") * skill_k("rain"), "color": C_GOOD})
		if state.rain.n <= 0: state.rain = null
	if state.autoSkill:
		for i in slots_open():
			var id = state.slots[i]
			if id != null and float(state.skillCd.get(id, 0.0)) <= 0.0: cast_skill(id, enemy_x)
	# marching between enemies
	var e = state.enemy
	if e == null:
		state.march -= dt
		state.scroll += dt * tune("marchScroll")
		if state.march <= 0: spawn_enemy(false)
	elif e.dead > 0:
		e.dead += dt
		if e.dead > 0.4:
			state.enemy = null
			state.march = tune("marchTime")
	else:
		if e.x > 0:
			e.x = maxf(0.0, e.x - dt / tune("enemyWalkIn"))
			state.scroll += dt * 60.0
		else:
			state.scroll += dt * tune("walkScroll") # the party keeps walking while it fights
		if e.flash > 0: e.flash -= dt
		if e.boss: e.lunge = fmod(e.lunge + dt, 2.2)
		if e.boss and state.mode == "stage":
			state.bossT -= dt
			if state.bossT <= 0: fail_boss()
	if state.mode != "stage":
		state.modeT -= dt
		if state.modeT <= 0:
			if state.mode == "trial":
				leave_mode(false)
				popup("시험 실패", ["더 강해져서 다시 도전하라"], C_MUTED)
			else:
				leave_mode(false)
	# the party attacks on its own clocks
	var target := targetable()
	for h in HEROES:
		state.anim[h.id] = maxf(0.0, state.anim[h.id] - dt)
		var dps := hero_dps(h)
		if dps <= 0: continue
		state.cd[h.id] -= dt
		if state.cd[h.id] > 0 or not target: continue
		state.cd[h.id] += tune(h.every)
		var hit := dps * tune(h.every)
		var x0: float = hero_x.call(h.id)
		match h.id:
			"knight":
				state.anim.knight = tune("attackAnimTime")
				damage(hit, false, C_INK, enemy_x)
				sfx("swing")
			"archer":
				state.anim.archer = tune("attackAnimTime")
				state.shots.append({"kind": "arrow", "x0": x0 + 12, "y0": -34.0, "x1": enemy_x, "y1": -30.0, "arc": 14.0, "t": 0.0, "dur": 0.25, "dmg": hit, "color": C_GOOD})
				sfx("arrow")
			"cleric":
				state.anim.cleric = tune("attackAnimTime")
				state.sparks.append({"x": enemy_x, "y": 0.0, "vx": 0.0, "vy": 0.0, "t": 0.0, "pillar": true})
				damage(hit, false, C_HOLY, enemy_x)
				sfx("holy")
			"pyro":
				state.anim.pyro = tune("attackAnimTime")
				state.shots.append({"kind": "fire", "x0": x0 + 16, "y0": -36.0, "x1": enemy_x, "y1": -28.0, "arc": 40.0, "t": 0.0, "dur": 0.45, "dmg": hit, "color": C_EMBER})
				sfx("fire")
	for s in state.shots:
		s.t += dt
		if s.t >= s.dur and not s.get("done", false):
			s.done = true
			damage(s.dmg, false, s.color, enemy_x)
			if s.kind == "fire":
				for k in 10:
					state.sparks.append({"x": s.x1, "y": s.y1, "vx": rng.randf_range(-70, 70), "vy": -rng.randf() * 120.0, "t": 0.0})
	state.shots = state.shots.filter(func(s): return not s.get("done", false))
	for p in state.sparks:
		p.t += dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 300.0 * dt
	state.sparks = state.sparks.filter(func(p): return p.t < (0.45 if p.get("pillar", false) else 0.2 if p.get("slash", false) else 0.7))
	for f in state.fx: f.t += dt
	state.fx = state.fx.filter(func(f): return f.t < 0.8)
	for f in state.floats: f.t += dt
	state.floats = state.floats.filter(func(f): return f.t < 0.9)
	state.saveT += dt
	if state.saveT >= tune("saveEvery"):
		state.saveT = 0.0
		save()
	if results_pending > 0:
		results_pending -= dt
		if results_pending <= 0:
			save()
			results_reached.emit()

## A tap on the battlefield: the knight strikes, with a chance to crit.
func tap_attack(enemy_x: float, auto: bool = false) -> void:
	state.taps += 1
	if not auto: count("taps")
	var dmg := tap_damage()
	var crit := rng.randf() < 0.08
	damage(dmg * 3.0 if crit else dmg, crit, C_TORCH_HI if crit else C_INK, enemy_x)
	state.anim.knight = tune("attackAnimTime")
	state.sparks.append({"x": enemy_x, "y": -30.0, "vx": 0.0, "vy": 0.0, "t": 0.0, "slash": true})
	sfx("crit" if crit else "tap")
