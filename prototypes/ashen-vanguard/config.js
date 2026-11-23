// PROTOTYPE - NOT FOR PRODUCTION
// Question: 탭에서 자동 전투로 넘어가고, 동료가 늘고, 환생해서 다시 더 빨리 오르는 흐름이 15~20분 동안 '한 번만 더 강화'를 부르는가?
// Date: 2026-11-23
// Every tuning value lives here, each with value, min, max and step. The game reads them live
// through tune.<name> (index.html); the tweak panel, an add-on, writes them back here.
window.CONFIG = {
  seed: 1, // every gameplay random call reads rng(), seeded from this (or ?seed= in the address)
  volume: { value: 0.5, min: 0, max: 1, step: 0.05 },

  // ---- Enemies and stages (idle-genre starting values: hp grows ~1.4x a stage) ----
  hpBase:        { value: 8,    min: 1,    max: 100,  step: 1 },    // stage 1 enemy hp
  hpGrowth:      { value: 1.39, min: 1.1,  max: 2,    step: 0.01 }, // hp multiplier per stage
  killsPerStage: { value: 10,   min: 1,    max: 30,   step: 1 },    // kills to clear a normal stage
  bossEvery:     { value: 10,   min: 5,    max: 25,   step: 1 },    // a boss stage every N stages
  bossHpMult:    { value: 6,    min: 1,    max: 30,   step: 0.5 },  // boss hp x normal hp at the first boss
  bossHpMultStep:{ value: 1,    min: 0,    max: 5,    step: 0.5 },  // +this boss hp multiplier per later boss
  bossTime:      { value: 30,   min: 5,    max: 120,  step: 1 },    // seconds to kill a boss
  goalStage:     { value: 30,   min: 10,   max: 100,  step: 10 },   // the slice's goal boss stage
  enemyWalkIn:   { value: 0.45, min: 0.1,  max: 2,    step: 0.05 }, // seconds a new enemy walks in
  marchTime:     { value: 0.5,  min: 0.1,  max: 2,    step: 0.05 }, // seconds the party marches between kills

  // ---- Gold ----
  goldRatio:     { value: 0.3,  min: 0.05, max: 2,    step: 0.05 }, // gold per kill = hp x this
  bossGoldMult:  { value: 5,    min: 1,    max: 20,   step: 1 },    // boss gold x normal

  // ---- Tapping (knight) ----
  tapBase:       { value: 2,    min: 1,    max: 20,   step: 1 },    // tap damage at knight lv 0
  tapPerLevel:   { value: 1,    min: 0.1,  max: 10,   step: 0.1 },  // tap damage per knight level
  tapDpsShare:   { value: 0.05, min: 0,    max: 0.5,  step: 0.01 }, // a tap also deals this x party dps
  autoUnlockLevel:{ value: 3,   min: 1,    max: 20,   step: 1 },    // knight level that starts auto attack

  // ---- Party (cost = base x growth^level; dps = perLevel x level x milestones x party bonus) ----
  costGrowth:    { value: 1.075, min: 1.01, max: 1.3, step: 0.005 },
  knightCost:    { value: 5,    min: 1,    max: 100,  step: 1 },
  knightDps:     { value: 1,    min: 0.1,  max: 50,   step: 0.1 },
  knightInterval:{ value: 1.0,  min: 0.2,  max: 3,    step: 0.05 }, // seconds per swing
  archerCost:    { value: 50,   min: 5,    max: 1000, step: 5 },
  archerDps:     { value: 5,    min: 0.5,  max: 200,  step: 0.5 },
  archerInterval:{ value: 0.7,  min: 0.2,  max: 3,    step: 0.05 },
  clericCost:    { value: 800,  min: 50,   max: 20000, step: 50 },
  clericDps:     { value: 30,   min: 1,    max: 1000, step: 1 },
  clericInterval:{ value: 1.4,  min: 0.2,  max: 4,    step: 0.05 },
  clericAura:    { value: 0.01, min: 0,    max: 0.1,  step: 0.005 }, // +party dps per cleric level
  pyroCost:      { value: 12000, min: 500, max: 500000, step: 500 },
  pyroDps:       { value: 200,  min: 10,   max: 10000, step: 10 },
  pyroInterval:  { value: 1.8,  min: 0.3,  max: 5,    step: 0.05 },
  milestoneMult: { value: 2,    min: 1,    max: 5,    step: 0.5 },   // x dps at hero level 25, 50, 100, 200

  // ---- Gear (pct = stage x rarity factor) ----
  dropChance:    { value: 0.08, min: 0,    max: 1,    step: 0.01 },  // per normal kill; bosses always drop
  rareChance:    { value: 0.28, min: 0,    max: 1,    step: 0.01 },
  epicChance:    { value: 0.10, min: 0,    max: 1,    step: 0.01 },
  legendChance:  { value: 0.02, min: 0,    max: 1,    step: 0.01 },
  gearCommon:    { value: 2,    min: 0.5,  max: 20,   step: 0.5 },   // % per stage
  gearRare:      { value: 4,    min: 0.5,  max: 40,   step: 0.5 },
  gearEpic:      { value: 8,    min: 0.5,  max: 80,   step: 0.5 },
  gearLegend:    { value: 15,   min: 0.5,  max: 150,  step: 0.5 },

  // ---- Prestige (embers) ----
  prestigeMinStage: { value: 20, min: 5,   max: 100,  step: 5 },     // furthest stage needed to rebirth
  emberDiv:      { value: 5,    min: 1,    max: 20,   step: 1 },     // embers = floor((maxStage / div) ^ pow)
  emberPow:      { value: 1.5,  min: 1,    max: 3,    step: 0.1 },
  emberBonus:    { value: 0.25, min: 0.05, max: 1,    step: 0.05 },  // +all dps and gold per ember

  // ---- Away earnings ----
  offlineRate:   { value: 0.5,  min: 0,    max: 1,    step: 0.05 },  // share of the awake gold rate
  offlineCapHours:{ value: 8,   min: 1,    max: 48,   step: 1 },
  saveEvery:     { value: 5,    min: 1,    max: 60,   step: 1 },     // seconds between saves

  // ---- Skills (잿불 기술): cooldown in seconds, power as multiples of party dps ----
  skillLvStep:   { value: 0.2,  min: 0.05, max: 1,    step: 0.05 },  // +effect per skill level
  slashCd:       { value: 8,    min: 1,    max: 60,   step: 1 },
  slashPower:    { value: 6,    min: 1,    max: 50,   step: 0.5 },   // x party dps, plus 5 taps
  rainCd:        { value: 14,   min: 1,    max: 60,   step: 1 },
  rainPower:     { value: 1.2,  min: 0.1,  max: 10,   step: 0.1 },   // x party dps, per arrow (6 arrows)
  sanctCd:       { value: 22,   min: 1,    max: 90,   step: 1 },
  sanctBoost:    { value: 0.5,  min: 0.1,  max: 3,    step: 0.05 },  // +party dps while it lasts
  sanctTime:     { value: 8,    min: 1,    max: 30,   step: 1 },
  stormCd:       { value: 18,   min: 1,    max: 90,   step: 1 },
  stormPower:    { value: 15,   min: 1,    max: 80,   step: 1 },
  cryCd:         { value: 25,   min: 1,    max: 90,   step: 1 },
  cryTime:       { value: 8,    min: 1,    max: 30,   step: 1 },
  cryTaps:       { value: 6,    min: 1,    max: 20,   step: 1 },     // automatic taps a second while it lasts
  goldCd:        { value: 40,   min: 5,    max: 120,  step: 1 },
  goldTime:      { value: 12,   min: 1,    max: 60,   step: 1 },
  slashUnlock:   { value: 1,    min: 1,    max: 100,  step: 1 },     // furthest stage that unlocks each skill
  rainUnlock:    { value: 5,    min: 1,    max: 100,  step: 1 },
  sanctUnlock:   { value: 12,   min: 1,    max: 100,  step: 1 },
  stormUnlock:   { value: 18,   min: 1,    max: 100,  step: 1 },
  cryUnlock:     { value: 25,   min: 1,    max: 100,  step: 1 },
  goldUnlock:    { value: 30,   min: 1,    max: 100,  step: 1 },

  // ---- Dungeon (무너진 성 지하묘지) ----
  keysStart:     { value: 2,    min: 0,    max: 10,   step: 1 },
  keysMax:       { value: 3,    min: 1,    max: 10,   step: 1 },
  keyRegen:      { value: 240,  min: 30,   max: 3600, step: 30 },    // seconds of play per new key
  dungeonTime:   { value: 40,   min: 10,   max: 120,  step: 5 },
  dungeonStage:  { value: 4,    min: 1,    max: 50,   step: 1 },     // floor 1 hp = this stage's hp ...
  dungeonFloorStep:{ value: 5,  min: 1,    max: 20,   step: 1 },     // ... plus this many stages per floor
  dungeonHpMult: { value: 4,    min: 1,    max: 30,   step: 0.5 },
  dungeonStones: { value: 10,   min: 1,    max: 100,  step: 1 },     // per boss, x floor
  dungeonScrolls:{ value: 1,    min: 0,    max: 10,   step: 1 },     // per boss, + floor / 2

  // ---- Promotion (기사단 서열) ----
  rankBonus:     { value: 1.5,  min: 1.1,  max: 3,    step: 0.05 },  // x all damage per rank
  rankReqStep:   { value: 10,   min: 5,    max: 30,   step: 5 },     // rank n needs best stage n x this
  trialHpMult:   { value: 8,    min: 1,    max: 40,   step: 0.5 },
  trialTime:     { value: 25,   min: 5,    max: 90,   step: 1 },

  // ---- Companion evolution (stars) ----
  bossSouls:     { value: 2,    min: 0,    max: 20,   step: 1 },     // soul stones per stage boss (+1 per later boss)
  evoSouls:      { value: 3,    min: 1,    max: 50,   step: 1 },     // souls for star n = this x n
  evoLevel:      { value: 20,   min: 1,    max: 200,  step: 1 },     // hero level for star n = this x 2^(n-1)
  starMult:      { value: 1.6,  min: 1.1,  max: 4,    step: 0.1 },   // x that hero's damage per star

  // ---- Gear enhance and merge ----
  enhPct:        { value: 0.12, min: 0.01, max: 0.5,  step: 0.01 },  // +item effect per enhance level
  enhCost:       { value: 8,    min: 1,    max: 100,  step: 1 },     // stones for +1; grows ^enhPow
  enhPow:        { value: 1.3,  min: 1,    max: 3,    step: 0.1 },
  enhMax:        { value: 15,   min: 1,    max: 50,   step: 1 },
  mergeNeed:     { value: 3,    min: 2,    max: 10,   step: 1 },     // stored items of one rarity to merge up

  // ---- Spirits (정령) ----
  fireBase:      { value: 0.3,  min: 0,    max: 3,    step: 0.05 },  // +party damage
  fireLv:        { value: 0.1,  min: 0,    max: 1,    step: 0.01 },
  frostBase:     { value: 5,    min: 0,    max: 30,   step: 1 },     // +seconds on boss, trial and dungeon timers
  frostLv:       { value: 1,    min: 0,    max: 10,   step: 0.5 },
  lightBase:     { value: 0.4,  min: 0,    max: 3,    step: 0.05 },  // +gold
  lightLv:       { value: 0.15, min: 0,    max: 1,    step: 0.01 },
  spiritCost:    { value: 15,   min: 1,    max: 200,  step: 1 },     // stones for level 2; grows ^spiritPow
  spiritPow:     { value: 1.4,  min: 1,    max: 3,    step: 0.1 },

  // ---- Zones: the road from the meadow to the demon castle (first stage of each zone) ----
  zoneForest:    { value: 7,    min: 2,    max: 200,  step: 1 },
  zoneVillage:   { value: 13,   min: 3,    max: 200,  step: 1 },
  zoneWaste:     { value: 19,   min: 4,    max: 200,  step: 1 },
  zoneCastle:    { value: 25,   min: 5,    max: 200,  step: 1 },

  // ---- Coming back: the idle chest, daily orders, attendance, achievements ----
  chestStones:   { value: 12,   min: 0,    max: 200,  step: 1 },     // per hour away, x crypt floor
  chestScrolls:  { value: 2,    min: 0,    max: 20,   step: 0.5 },   // per hour away
  chestSouls:    { value: 1,    min: 0,    max: 20,   step: 0.5 },   // per hour away
  dailyKills:    { value: 200,  min: 10,   max: 5000, step: 10 },
  dailyTaps:     { value: 150,  min: 10,   max: 5000, step: 10 },
  dailyUps:      { value: 25,   min: 1,    max: 500,  step: 1 },
  dailyCasts:    { value: 30,   min: 1,    max: 500,  step: 1 },
  dailyDungeons: { value: 1,    min: 1,    max: 10,   step: 1 },
  rewardScale:   { value: 1,    min: 0.1,  max: 10,   step: 0.1 },   // x every daily, attendance and achievement reward
};
