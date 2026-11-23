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
};
