import test from 'node:test';
import assert from 'node:assert/strict';
import { generateMap } from './mapGen';
import { findRoadPath } from './pathfinding';
import { WarFrontSimulation } from './simulation';
import { BRIDGE_REBUILD_COST, STARTING_PLAYER_OIL, UNIT_SPECS } from './constants';

test('campaign and procedural map generation produce valid connected road graphs and bridges', () => {
  for (const theater of ['kirkuk', 'suez', 'newyork', 'procedural'] as const) {
    const map = generateMap(theater, 991337);
    assert.ok(map.bridges.length >= 2, `${theater} should have at least 2 bridges`);
    assert.equal(map.rigs.length, 6, `${theater} should have 6 oil rigs`);

    const crossPath = findRoadPath(map, map.playerHQ.roadNodeId, map.enemyHQ.roadNodeId);
    assert.ok(crossPath && crossPath.length > 3, `${theater} should connect HQs across intact bridges`);

    const homeRig = map.rigs.find((r) => r.owner === 'player');
    assert.ok(homeRig, `${theater} should include a starter player oil rig`);
    const rigPath = findRoadPath(map, map.playerHQ.roadNodeId, homeRig!.roadNodeId);
    assert.ok(rigPath && rigPath.length >= 2, `${theater} should connect player HQ to starter rig`);
  }
});

test('blowing up all bridges completely severs cross-river oil supply routes and rebuilding restores them', () => {
  const sim = new WarFrontSimulation('suez', 229403);
  sim.phase = 'playing';

  // Route from player HQ to an east-bank rig works while bridges are intact
  const eastRig = sim.map.rigs.find((r) => r.x > sim.map.width * 0.55)!;
  assert.ok(findRoadPath(sim.map, sim.map.playerHQ.roadNodeId, eastRig.roadNodeId));

  // Blow up every bridge on the map
  for (const b of sim.map.bridges) {
    sim.damageBridge(b, b.maxHp + 50, 'player');
    assert.equal(b.status, 'destroyed');
  }

  // Cross-river road path is now severed (null)
  assert.equal(findRoadPath(sim.map, sim.map.playerHQ.roadNodeId, eastRig.roadNodeId), null);

  // Rebuilding one bridge deducts oil and immediately restores cross-river logistics
  const oilBefore = sim.playerOil;
  const rebuilt = sim.rebuildBridge(sim.map.bridges[0].id, 'player');
  assert.equal(rebuilt, true);
  assert.equal(sim.playerOil, oilBefore - BRIDGE_REBUILD_COST);
  assert.equal(sim.map.bridges[0].status, 'intact');
  assert.ok(findRoadPath(sim.map, sim.map.playerHQ.roadNodeId, eastRig.roadNodeId));
});

test('physical oil supply trucks drive to captured rigs, load barrels, and deliver oil to HQ', () => {
  const sim = new WarFrontSimulation('kirkuk', 104729);
  sim.phase = 'playing';
  const startOil = sim.playerOil;

  // Advance simulation for 30 seconds in 50ms steps so starter truck completes a full round trip
  for (let i = 0; i < 600; i++) {
    sim.step(0.05);
  }

  assert.ok(
    sim.playerOilDelivered > 0,
    `Expected physical truck to deliver oil barrels, got ${sim.playerOilDelivered}`
  );
  assert.ok(sim.playerOil > startOil, 'Player oil reserve should increase from delivered barrels');
  assert.ok(sim.map.playerHQ.hp > 0, 'Player HQ must survive opening seconds with no input');
});

test('training units deducts oil and spawning works cleanly', () => {
  const sim = new WarFrontSimulation('kirkuk', 104729);
  sim.phase = 'playing';
  const beforeUnits = sim.units.length;
  const ok = sim.trainPlayerUnit('tank');
  assert.equal(ok, true);
  assert.equal(sim.playerOil, STARTING_PLAYER_OIL - UNIT_SPECS.tank.cost);
  assert.equal(sim.units.length, beforeUnits + 1);
});

test('destroying enemy HQ triggers victory and destroying player HQ triggers defeat', () => {
  const winSim = new WarFrontSimulation('kirkuk', 104729);
  winSim.phase = 'playing';
  winSim.map.enemyHQ.hp = 0;
  for (let i = 0; i < 20; i++) winSim.step(0.05);
  assert.equal(winSim.outcome, 'victory');
  assert.equal(winSim.phase, 'gameover');

  const loseSim = new WarFrontSimulation('kirkuk', 104729);
  loseSim.phase = 'playing';
  loseSim.map.playerHQ.hp = 0;
  for (let i = 0; i < 20; i++) loseSim.step(0.05);
  assert.equal(loseSim.outcome, 'defeat');
  assert.equal(loseSim.phase, 'gameover');
});

test('units gain veterancy XP from successful engagements, boosting attack power and max health across ranks 1-3', () => {
  const sim = new WarFrontSimulation('kirkuk', 104729);
  sim.phase = 'playing';

  const tank = sim.spawnUnit('player', 'tank', 400, 400);
  const baseDamage = UNIT_SPECS.tank.damage;
  const baseHp = UNIT_SPECS.tank.hp;
  assert.equal(tank.rank, 0);
  assert.equal(tank.damage, baseDamage);
  assert.equal(tank.maxHp, baseHp);

  // Engage and destroy an enemy tank -> earns damage XP + heavy kill bonus -> promotes to Rank 1
  const enemyTank = sim.spawnUnit('enemy', 'tank', 520, 400);
  sim.damageUnit(enemyTank, enemyTank.maxHp, tank);
  assert.equal(tank.kills, 1);
  assert.equal(tank.rank, 1);
  assert.ok(tank.damage > baseDamage, 'Rank 1 veteran should have increased attack power');
  assert.ok(tank.maxHp > baseHp, 'Rank 1 veteran should have increased max health');
  assert.ok(sim.floatingPopups.some((p) => p.text.includes('VET')));
  assert.equal(sim.getHudSnapshot().playerVeterans, 1);

  // Further engagements promote to Rank 2 (Elite) and Rank 3 (Ace), capping cleanly at Rank 3
  const enemy2 = sim.spawnUnit('enemy', 'artillery', 540, 400);
  sim.damageUnit(enemy2, enemy2.maxHp, tank);
  assert.equal(tank.rank, 2);
  const rank2Damage = tank.damage;
  const rank2Hp = tank.maxHp;

  const enemy3 = sim.spawnUnit('enemy', 'tank', 560, 400);
  const enemy4 = sim.spawnUnit('enemy', 'tank', 580, 400);
  sim.damageUnit(enemy3, enemy3.maxHp, tank);
  sim.damageUnit(enemy4, enemy4.maxHp, tank);
  assert.equal(tank.rank, 3);
  assert.ok(tank.damage > rank2Damage, 'Rank 3 Ace should exceed Rank 2 attack power');
  assert.ok(tank.maxHp > rank2Hp, 'Rank 3 Ace should exceed Rank 2 max health');

  // Extra XP beyond Ace caps cleanly at Rank 3
  sim.awardUnitXp(tank, 500);
  assert.equal(tank.rank, 3);

  // Supply trucks never gain combat veterancy
  const truck = sim.units.find((u) => u.kind === 'truck')!;
  assert.equal(sim.awardUnitXp(truck, 300), false);
  assert.equal(truck.rank, 0);
});

test('destroying a bridge awards demolition XP and promotes the attacking engineer', () => {
  const sim = new WarFrontSimulation('kirkuk', 104729);
  sim.phase = 'playing';

  const eng = sim.spawnUnit('player', 'engineer', 500, 500);
  const bridge = sim.map.bridges[0];
  sim.damageBridge(bridge, bridge.maxHp, 'player', eng);

  assert.equal(bridge.status, 'destroyed');
  assert.ok(eng.rank >= 1, 'Engineer should promote after blowing up a bridge');
  assert.ok(eng.damage > UNIT_SPECS.engineer.damage);
});

