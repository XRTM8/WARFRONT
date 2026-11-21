import {
  BRIDGE_MAX_HP,
  BRIDGE_REBUILD_COST,
  STARTING_ENEMY_OIL,
  STARTING_PLAYER_OIL,
  TRUCK_CARGO_CAPACITY,
  UNIT_SPECS,
} from './constants';
import { generateMap } from './mapGen';
import {
  findNearestIntactBridge,
  findRoadPath,
  getBridgeAtWorld,
  isOppositeRiverSide,
  isPointPassableForLand,
} from './pathfinding';
import {
  Bridge,
  Crater,
  Faction,
  GameOutcome,
  GamePhase,
  HudSnapshot,
  MapData,
  OilRig,
  Particle,
  Projectile,
  TheaterId,
  Unit,
  UnitKind,
  Vec2,
} from './types';

export interface SimulationAudioCallbacks {
  onMgShot?: () => void;
  onCannon?: () => void;
  onRocket?: () => void;
  onExplosion?: (heavy: boolean) => void;
  onOilDeposit?: () => void;
  onCapture?: (friendly: boolean) => void;
  onUnitReady?: () => void;
  onVictory?: () => void;
  onDefeat?: () => void;
}

const MAX_PARTICLES = 420;
const BEST_SCORE_KEY = 'warfront_best_score_v1';

export class WarFrontSimulation {
  public map: MapData;
  public phase: GamePhase = 'title';
  public outcome: GameOutcome = 'none';
  public theater: TheaterId = 'kirkuk';
  public seed = 104729;

  public playerOil = STARTING_PLAYER_OIL;
  public enemyOil = STARTING_ENEMY_OIL;
  public playerOilDelivered = 0;

  public units: Unit[] = [];
  public projectiles: Projectile[] = [];
  public craters: Crater[] = [];
  public particles: Particle[] = [];
  private particleCursor = 0;

  public nextUnitId = 1;
  public nextProjectileId = 1;

  // World-space floating popups (e.g., +55 oil delivery at HQ)
  public floatingPopups: Array<{ x: number; y: number; text: string; color: string; life: number; maxLife: number }> = [];

  // Juice & timing
  public elapsedSeconds = 0;
  public simTime = 0;
  public hitstopTimer = 0;
  public cameraTrauma = 0;
  public defeatDelayTimer = 0;

  // Stats & UI feedback
  public bridgesDestroyedByPlayer = 0;
  public enemyTrucksDestroyed = 0;
  public buildMode: 'none' | 'turret' | 'rebuild_bridge' = 'none';
  public eventBanner: { key: string; tone: 'info' | 'warn' | 'good'; id: number; timer: number } | null = null;
  private eventSeq = 1;
  public bestScore = 0;

  // Order marker visual pulse
  public orderPulse: { x: number; y: number; color: string; timer: number } | null = null;

  // AI state
  private aiDecisionTimer = 3.5;
  private aiWaveCount = 0;
  private hqAlertCooldown = 0;
  private enemyStarveBannerCooldown = 0;
  private smokeEmitTimer = 0;

  public audio: SimulationAudioCallbacks;

  constructor(theater: TheaterId = 'kirkuk', seed = 104729, audio: SimulationAudioCallbacks = {}) {
    this.theater = theater;
    this.seed = seed;
    this.audio = audio;
    this.bestScore = this.loadBestScore();

    for (let i = 0; i < MAX_PARTICLES; i++) {
      this.particles.push({
        active: false,
        kind: 'smoke',
        x: 0,
        y: 0,
        vx: 0,
        vy: 0,
        size: 4,
        endSize: 12,
        life: 0,
        maxLife: 1,
        color: '#222',
        alpha: 1,
      });
    }

    this.map = generateMap(theater, seed);
    this.setupInitialForces();
  }

  private loadBestScore(): number {
    try {
      if (typeof window !== 'undefined' && window.localStorage) {
        const raw = window.localStorage.getItem(BEST_SCORE_KEY);
        return raw ? Math.max(0, parseInt(raw, 10) || 0) : 0;
      }
    } catch {
      // ignore storage errors
    }
    return 0;
  }

  private saveBestScore(score: number) {
    if (score > this.bestScore) {
      this.bestScore = score;
      try {
        if (typeof window !== 'undefined' && window.localStorage) {
          window.localStorage.setItem(BEST_SCORE_KEY, String(score));
        }
      } catch {
        // ignore storage errors
      }
    }
  }

  public reset(theater: TheaterId = this.theater, seed: number = this.seed, startPhase: GamePhase = 'playing') {
    this.theater = theater;
    this.seed = seed;
    this.phase = startPhase;
    this.outcome = 'none';
    this.playerOil = STARTING_PLAYER_OIL;
    this.enemyOil = STARTING_ENEMY_OIL;
    this.playerOilDelivered = 0;
    this.units = [];
    this.projectiles = [];
    this.craters = [];
    this.floatingPopups = [];
    for (const p of this.particles) p.active = false;
    this.particleCursor = 0;
    this.nextUnitId = 1;
    this.nextProjectileId = 1;
    this.elapsedSeconds = 0;
    this.simTime = 0;
    this.hitstopTimer = 0;
    this.cameraTrauma = 0;
    this.defeatDelayTimer = 0;
    this.bridgesDestroyedByPlayer = 0;
    this.enemyTrucksDestroyed = 0;
    this.buildMode = 'none';
    this.eventBanner = null;
    this.orderPulse = null;
    this.aiDecisionTimer = 6.5; // Fair opening grace window
    this.aiWaveCount = 0;
    this.hqAlertCooldown = 0;
    this.enemyStarveBannerCooldown = 0;

    this.map = generateMap(theater, seed);
    this.setupInitialForces();
  }

  private setupInitialForces() {
    const pHQ = this.map.playerHQ;
    const eHQ = this.map.enemyHQ;

    // Player starter battlegroup — positioned clearly in front of HQ on open concrete/road
    this.spawnUnit('player', 'tank', pHQ.x + 92, pHQ.y - 38);
    this.spawnUnit('player', 'scout', pHQ.x + 115, pHQ.y + 34);
    this.spawnUnit('player', 'engineer', pHQ.x + 82, pHQ.y + 62);
    // Starter defense turret guarding player HQ entrance
    this.spawnUnit('player', 'turret', pHQ.x + 150, pHQ.y - 78);

    // Enemy starter garrison on the east bank
    this.spawnUnit('enemy', 'tank', eHQ.x - 105, eHQ.y + 30);
    this.spawnUnit('enemy', 'scout', eHQ.x - 125, eHQ.y - 45);
    this.spawnUnit('enemy', 'turret', eHQ.x - 155, eHQ.y + 72);

    // Spawn 1 active physical oil supply truck per owned rig immediately so logistics are live at t=0
    for (const rig of this.map.rigs) {
      if (rig.owner === 'player' || rig.owner === 'enemy') {
        this.spawnTruckForRig(rig.owner, rig);
      }
    }
  }

  public spawnUnit(faction: 'player' | 'enemy', kind: UnitKind, x: number, y: number): Unit {
    const spec = UNIT_SPECS[kind];
    const unit: Unit = {
      id: this.nextUnitId++,
      faction,
      kind,
      x,
      y,
      vx: 0,
      vy: 0,
      angle: faction === 'player' ? 0 : Math.PI,
      turretAngle: faction === 'player' ? 0 : Math.PI,
      hp: spec.hp,
      maxHp: spec.hp,
      speed: spec.speed,
      radius: spec.radius,
      range: spec.range,
      damage: spec.damage,
      fireRate: spec.fireRate,
      cooldown: 0,
      selected: false,
      targetPos: null,
      targetEntityId: null,
      targetBridgeId: null,
      targetHqFaction: null,
      stance: 'idle',
      hitFlash: 0,
      recoil: 0,
      gaitPhase: 0,
      koTimer: 0,
      alive: true,
      windupTimer: 0,
      windupTarget: null,
    };
    this.units.push(unit);
    return unit;
  }

  public spawnTruckForRig(faction: 'player' | 'enemy', rig: OilRig): Unit | null {
    const hq = faction === 'player' ? this.map.playerHQ : this.map.enemyHQ;
    const path = findRoadPath(this.map, hq.roadNodeId, rig.roadNodeId);
    const truck = this.spawnUnit(faction, 'truck', hq.x + (faction === 'player' ? 32 : -32), hq.y);
    truck.assignedRigId = rig.id;
    truck.cargoOil = 0;
    truck.loadTimer = 0;
    if (path && path.length > 0) {
      truck.truckState = 'to_rig';
      truck.roadPath = path;
      truck.roadPathIndex = 1;
    } else {
      truck.truckState = 'stranded';
      truck.roadPath = [];
      truck.roadPathIndex = 0;
    }
    return truck;
  }

  public pushEvent(key: string, tone: 'info' | 'warn' | 'good') {
    this.eventBanner = { key, tone, id: this.eventSeq++, timer: 3.8 };
  }

  public trainPlayerUnit(kind: UnitKind): boolean {
    if (this.phase !== 'playing') return false;
    if (kind === 'turret') {
      this.buildMode = this.buildMode === 'turret' ? 'none' : 'turret';
      return true;
    }
    const spec = UNIT_SPECS[kind];
    if (this.playerOil < spec.cost) {
      this.pushEvent('not_enough_oil', 'warn');
      return false;
    }
    this.playerOil -= spec.cost;
    const pHQ = this.map.playerHQ;
    const offsetAngle = (this.nextUnitId * 1.15) % (Math.PI * 2);
    const sx = pHQ.x + 88 + Math.cos(offsetAngle) * 26;
    const sy = pHQ.y + Math.sin(offsetAngle) * 52;
    const u = this.spawnUnit('player', kind, sx, sy);
    // Rally slightly east of HQ so units don't stack
    u.targetPos = { x: pHQ.x + 170 + Math.cos(offsetAngle) * 32, y: pHQ.y + Math.sin(offsetAngle) * 58 };
    u.stance = 'move';
    this.spawnBurst(sx, sy, 'smoke', 6, '#b8aa8f', 45);
    this.audio.onUnitReady?.();
    return true;
  }

  public canPlaceTurretAt(x: number, y: number): boolean {
    if (!isPointPassableForLand(this.map, x, y)) return false;
    const tileCol = Math.floor(x / this.map.tileSize);
    const tileRow = Math.floor(y / this.map.tileSize);
    const tile = this.map.tiles[tileRow * this.map.cols + tileCol];
    if (tile === 'bridge' || tile === 'water') return false;
    if (Math.hypot(x - this.map.enemyHQ.x, y - this.map.enemyHQ.y) < 340) return false;
    for (const u of this.units) {
      if (u.alive && u.kind === 'turret' && Math.hypot(u.x - x, u.y - y) < 42) return false;
    }
    return true;
  }

  public placePlayerTurret(x: number, y: number): boolean {
    if (this.phase !== 'playing') return false;
    const cost = UNIT_SPECS.turret.cost;
    if (this.playerOil < cost) {
      this.pushEvent('not_enough_oil', 'warn');
      this.buildMode = 'none';
      return false;
    }
    if (!this.canPlaceTurretAt(x, y)) return false;
    this.playerOil -= cost;
    this.spawnUnit('player', 'turret', x, y);
    this.spawnBurst(x, y, 'spark', 10, '#f3c363', 70);
    this.audio.onUnitReady?.();
    this.buildMode = 'none';
    return true;
  }

  public rebuildBridge(bridgeId: string, faction: 'player' | 'enemy' = 'player'): boolean {
    const bridge = this.map.bridges.find((b) => b.id === bridgeId);
    if (!bridge || bridge.status === 'intact') return false;
    if (faction === 'player') {
      if (this.playerOil < BRIDGE_REBUILD_COST) {
        this.pushEvent('not_enough_oil', 'warn');
        return false;
      }
      this.playerOil -= BRIDGE_REBUILD_COST;
      this.buildMode = 'none';
    } else {
      if (this.enemyOil < BRIDGE_REBUILD_COST) return false;
      this.enemyOil -= BRIDGE_REBUILD_COST;
    }
    bridge.status = 'intact';
    bridge.hp = bridge.maxHp;
    bridge.rebuildProgress = 0;
    this.spawnBurst(bridge.x, bridge.y, 'spark', 18, '#f0c45c', 120);
    this.spawnBurst(bridge.x, bridge.y, 'smoke', 10, '#c2bab0', 75);
    this.audio.onCapture?.(faction === 'player');
    if (faction === 'player') {
      this.pushEvent('bridge_rebuilt', 'good');
    }
    // Immediately re-evaluate any stranded trucks so logistics resume!
    this.rerouteStrandedTrucks();
    return true;
  }

  public selectUnitsInBox(x1: number, y1: number, x2: number, y2: number, additive = false): number {
    const minX = Math.min(x1, x2);
    const maxX = Math.max(x1, x2);
    const minY = Math.min(y1, y2);
    const maxY = Math.max(y1, y2);
    const isClick = maxX - minX < 10 && maxY - minY < 10;

    if (!additive) {
      for (const u of this.units) u.selected = false;
    }

    let count = 0;
    if (isClick) {
      const cx = (x1 + x2) * 0.5;
      const cy = (y1 + y2) * 0.5;
      let nearest: Unit | null = null;
      let bestD = 30;
      for (const u of this.units) {
        if (!u.alive || u.faction !== 'player' || u.kind === 'truck' || u.kind === 'turret') continue;
        const d = Math.hypot(u.x - cx, u.y - cy);
        if (d < bestD) {
          bestD = d;
          nearest = u;
        }
      }
      if (nearest) {
        nearest.selected = true;
        count = 1;
      }
    } else {
      for (const u of this.units) {
        if (!u.alive || u.faction !== 'player' || u.kind === 'truck' || u.kind === 'turret') continue;
        if (u.x >= minX && u.x <= maxX && u.y >= minY && u.y <= maxY) {
          u.selected = true;
          count++;
        }
      }
    }
    return count;
  }

  public selectAllCombatUnits(): number {
    let count = 0;
    for (const u of this.units) {
      if (u.alive && u.faction === 'player' && u.kind !== 'truck' && u.kind !== 'turret') {
        u.selected = true;
        count++;
      } else {
        u.selected = false;
      }
    }
    return count;
  }

  public issuePlayerCommand(worldX: number, worldY: number): boolean {
    if (this.phase !== 'playing') return false;
    const selected = this.units.filter(
      (u) => u.alive && u.faction === 'player' && u.selected && u.kind !== 'truck' && u.kind !== 'turret'
    );
    if (selected.length === 0) return false;

    // 1. Clicked Enemy HQ?
    if (Math.hypot(worldX - this.map.enemyHQ.x, worldY - this.map.enemyHQ.y) < 52) {
      for (const u of selected) {
        u.targetHqFaction = 'enemy';
        u.targetEntityId = null;
        u.targetBridgeId = null;
        u.targetPos = { x: this.map.enemyHQ.x, y: this.map.enemyHQ.y };
        u.stance = 'attack';
      }
      this.orderPulse = { x: this.map.enemyHQ.x, y: this.map.enemyHQ.y, color: '#ef5350', timer: 0.55 };
      return true;
    }

    // 2. Clicked an enemy unit?
    let clickedEnemy: Unit | null = null;
    let bestD = 32;
    for (const u of this.units) {
      if (!u.alive || u.faction !== 'enemy') continue;
      const d = Math.hypot(u.x - worldX, u.y - worldY);
      if (d < bestD) {
        bestD = d;
        clickedEnemy = u;
      }
    }
    if (clickedEnemy) {
      for (const u of selected) {
        u.targetEntityId = clickedEnemy.id;
        u.targetBridgeId = null;
        u.targetHqFaction = null;
        u.targetPos = { x: clickedEnemy.x, y: clickedEnemy.y };
        u.stance = 'attack';
      }
      this.orderPulse = { x: clickedEnemy.x, y: clickedEnemy.y, color: '#ef5350', timer: 0.55 };
      return true;
    }

    // 3. Clicked a bridge? If intact -> Demolish bridge! If destroyed & player can afford -> hint/rebuild
    const clickedBridge = getBridgeAtWorld(this.map, worldX, worldY, 16);
    if (clickedBridge) {
      if (clickedBridge.status === 'intact') {
        for (const u of selected) {
          u.targetBridgeId = clickedBridge.id;
          u.targetEntityId = null;
          u.targetHqFaction = null;
          u.targetPos = { x: clickedBridge.x, y: clickedBridge.y };
          u.stance = 'demolish';
        }
        this.orderPulse = { x: clickedBridge.x, y: clickedBridge.y, color: '#f59e0b', timer: 0.6 };
        return true;
      } else {
        // Clicking a blown bridge with an engineer or rebuild mode repairs it
        const hasEngineer = selected.some((u) => u.kind === 'engineer');
        if (hasEngineer) {
          this.rebuildBridge(clickedBridge.id, 'player');
          return true;
        }
      }
    }

    // 4. Move formation order (spread slightly so units don't overlap)
    const count = selected.length;
    selected.forEach((u, idx) => {
      const col = idx % 3;
      const row = Math.floor(idx / 3);
      const offsetX = count === 1 ? 0 : (col - 1) * 32;
      const offsetY = count === 1 ? 0 : (row - Math.floor((count - 1) / 6)) * 32;
      u.targetPos = {
        x: Math.max(36, Math.min(this.map.width - 36, worldX + offsetX)),
        y: Math.max(36, Math.min(this.map.height - 36, worldY + offsetY)),
      };
      u.targetEntityId = null;
      u.targetBridgeId = null;
      u.targetHqFaction = null;
      u.stance = 'move';
    });
    this.orderPulse = { x: worldX, y: worldY, color: '#8bd46a', timer: 0.5 };
    return true;
  }

  public step(rawDt: number) {
    const dt = Math.min(Math.max(rawDt, 0), 0.05);
    if (this.phase === 'paused' || this.phase === 'gameover') {
      return;
    }

    // Visual-only timers always tick in real dt
    this.cameraTrauma = Math.max(0, this.cameraTrauma - dt * 2.1);
    if (this.orderPulse) {
      this.orderPulse.timer -= dt;
      if (this.orderPulse.timer <= 0) this.orderPulse = null;
    }
    if (this.eventBanner) {
      this.eventBanner.timer -= dt;
      if (this.eventBanner.timer <= 0) this.eventBanner = null;
    }
    for (const fp of this.floatingPopups) {
      fp.life -= dt;
      fp.y -= 28 * dt;
    }
    if (this.floatingPopups.length > 0) {
      this.floatingPopups = this.floatingPopups.filter((fp) => fp.life > 0);
    }
    this.updateParticles(dt);

    // Hitstop pauses gameplay physics briefly on heavy impacts while particles/shake tick
    if (this.hitstopTimer > 0) {
      this.hitstopTimer = Math.max(0, this.hitstopTimer - dt);
      return;
    }

    // Victory / Defeat beat delay
    if (this.defeatDelayTimer > 0) {
      this.defeatDelayTimer -= dt;
      if (this.defeatDelayTimer <= 0) {
        this.finalizeMatch();
      }
      return;
    }

    this.simTime += dt;
    if (this.phase === 'playing') {
      this.elapsedSeconds += dt;
    }

    this.hqAlertCooldown = Math.max(0, this.hqAlertCooldown - dt);
    this.enemyStarveBannerCooldown = Math.max(0, this.enemyStarveBannerCooldown - dt);

    // Ambient burning Iraqi oil wells & HQ radar sweep
    this.map.playerHQ.radarAngle += dt * 1.4;
    this.map.enemyHQ.radarAngle -= dt * 1.4;
    this.map.playerHQ.hitFlash = Math.max(0, this.map.playerHQ.hitFlash - dt);
    this.map.enemyHQ.hitFlash = Math.max(0, this.map.enemyHQ.hitFlash - dt);

    for (const b of this.map.bridges) {
      b.hitFlash = Math.max(0, b.hitFlash - dt);
    }

    this.smokeEmitTimer -= dt;
    if (this.smokeEmitTimer <= 0) {
      this.smokeEmitTimer = 0.14;
      for (const well of this.map.burningWells) {
        this.spawnParticle('fire', well.x + (Math.random() - 0.5) * 6, well.y - 4, (Math.random() - 0.5) * 10, -24 - Math.random() * 14, 5, 2, 0.45, '#ff8d29');
        this.spawnParticle('smoke', well.x + (Math.random() - 0.5) * 8, well.y - 10, 14 + Math.random() * 10, -26 - Math.random() * 12, 7, 22, 1.4, '#1b1a18');
      }
      for (const b of this.map.bridges) {
        if (b.status === 'destroyed') {
          this.spawnParticle('smoke', b.x + (Math.random() - 0.5) * 44, b.y + (Math.random() - 0.5) * 14, 8, -18, 6, 16, 1.0, '#2a2826');
        }
      }
    }

    this.updateOilRigs(dt);
    this.updateUnits(dt);
    this.updateProjectiles(dt);

    if (this.phase === 'playing') {
      this.updateEnemyAI(dt);
      this.checkWinLoss();
    } else if (this.phase === 'title') {
      this.updateTitleDemo(dt);
    }

    // Prune fully expired KO units
    this.units = this.units.filter((u) => u.alive || u.koTimer > 0);
  }

  private updateTitleDemo(dt: number) {
    // Keep title-screen live battlefield vibrant without ever destroying HQs
    this.map.playerHQ.hp = this.map.playerHQ.maxHp;
    this.map.enemyHQ.hp = this.map.enemyHQ.maxHp;
    this.aiDecisionTimer -= dt;
    if (this.aiDecisionTimer <= 0) {
      this.aiDecisionTimer = 3.2;
      const midBridge = this.map.bridges[Math.floor(this.map.bridges.length / 2)];
      if (midBridge) {
        for (const u of this.units) {
          if (u.alive && u.kind !== 'truck' && u.kind !== 'turret' && !u.targetPos) {
            const sideOffset = u.faction === 'player' ? -90 : 90;
            u.targetPos = { x: midBridge.x + sideOffset, y: midBridge.y + (Math.random() - 0.5) * 140 };
            u.stance = 'move';
          }
        }
      }
    }
  }

  private updateOilRigs(dt: number) {
    for (const rig of this.map.rigs) {
      rig.pumpPhase += dt * (rig.owner === 'neutral' ? 1.1 : 2.8);

      // Capture zone logic: combat units within 88px capture/contest rig (Engineers capture 2x faster)
      let playerPower = 0;
      let enemyPower = 0;
      for (const u of this.units) {
        if (!u.alive || u.kind === 'truck' || u.kind === 'turret') continue;
        if (Math.hypot(u.x - rig.x, u.y - rig.y) <= 88) {
          const weight = u.kind === 'engineer' ? 2.1 : 1.0;
          if (u.faction === 'player') playerPower += weight;
          else enemyPower += weight;
        }
      }

      if (playerPower > 0 && enemyPower === 0) {
        rig.captureProgress = Math.min(100, rig.captureProgress + dt * (22 + playerPower * 10));
        if (rig.captureProgress >= 100 && rig.owner !== 'player') {
          rig.owner = 'player';
          rig.captureFaction = 'player';
          this.audio.onCapture?.(true);
          if (this.phase === 'playing') this.pushEvent('rig_captured', 'good');
          this.ensureTruckForRig('player', rig);
        }
      } else if (enemyPower > 0 && playerPower === 0) {
        rig.captureProgress = Math.max(-100, rig.captureProgress - dt * (22 + enemyPower * 10));
        if (rig.captureProgress <= -100 && rig.owner !== 'enemy') {
          const wasPlayer = rig.owner === 'player';
          rig.owner = 'enemy';
          rig.captureFaction = 'enemy';
          if (wasPlayer) {
            this.audio.onCapture?.(false);
            if (this.phase === 'playing') this.pushEvent('rig_lost', 'warn');
          }
          this.ensureTruckForRig('enemy', rig);
        }
      }

      // Owned rigs pump physical oil barrels & maintain 1 active supply truck per rig
      if (rig.owner === 'player' || rig.owner === 'enemy') {
        rig.storedBarrels = Math.min(rig.maxBarrels, rig.storedBarrels + dt * 9.5);
        rig.truckCooldown = Math.max(0, rig.truckCooldown - dt);
        if (rig.truckCooldown <= 0) {
          this.ensureTruckForRig(rig.owner, rig);
          rig.truckCooldown = 7.5;
        }
      }
    }
  }

  private ensureTruckForRig(faction: 'player' | 'enemy', rig: OilRig) {
    const existing = this.units.find(
      (u) => u.alive && u.kind === 'truck' && u.faction === faction && u.assignedRigId === rig.id
    );
    if (!existing) {
      this.spawnTruckForRig(faction, rig);
    }
  }

  public rerouteStrandedTrucks() {
    for (const u of this.units) {
      if (!u.alive || u.kind !== 'truck') continue;
      const hq = u.faction === 'player' ? this.map.playerHQ : this.map.enemyHQ;
      const rig = this.map.rigs.find((r) => r.id === u.assignedRigId);
      if (!rig || rig.owner !== u.faction) continue;

      const nearestNode = this.findNearestRoadNode(u.x, u.y);
      const goalNode = (u.cargoOil ?? 0) > 0 ? hq.roadNodeId : rig.roadNodeId;
      const newPath = findRoadPath(this.map, nearestNode, goalNode);
      if (newPath && newPath.length > 0) {
        u.roadPath = newPath;
        u.roadPathIndex = 0;
        u.truckState = (u.cargoOil ?? 0) > 0 ? 'to_hq' : 'to_rig';
      } else {
        u.truckState = 'stranded';
      }
    }
  }

  private findNearestRoadNode(x: number, y: number): string {
    let bestId = 'hq_player';
    let bestD = Infinity;
    for (const node of Object.values(this.map.roadNodes)) {
      if (node.bridgeId) {
        const b = this.map.bridges.find((br) => br.id === node.bridgeId);
        if (b && b.status !== 'intact') continue;
      }
      const d = Math.hypot(node.x - x, node.y - y);
      if (d < bestD) {
        bestD = d;
        bestId = node.id;
      }
    }
    return bestId;
  }

  private updateUnits(dt: number) {
    for (const u of this.units) {
      u.hitFlash = Math.max(0, u.hitFlash - dt);
      u.recoil = Math.max(0, u.recoil - dt * 7);

      if (!u.alive) {
        u.koTimer = Math.max(0, u.koTimer - dt);
        continue;
      }

      if (u.kind === 'truck') {
        this.updateSupplyTruck(u, dt);
        continue;
      }

      u.cooldown = Math.max(0, u.cooldown - dt);

      // Artillery windup telegraph execution
      if (u.windupTimer > 0) {
        u.windupTimer -= dt;
        if (u.windupTimer <= 0 && u.windupTarget) {
          this.fireProjectile(u, u.windupTarget.x, u.windupTarget.y);
          u.windupTarget = null;
          u.cooldown = u.fireRate;
        }
        continue;
      }

      if (u.kind === 'turret') {
        this.updateTurret(u, dt);
        continue;
      }

      this.updateCombatUnit(u, dt);
    }

    // Soft separation between mobile units so squads stay crisp and readable
    for (let i = 0; i < this.units.length; i++) {
      const a = this.units[i];
      if (!a.alive || a.kind === 'turret' || a.kind === 'truck') continue;
      for (let j = i + 1; j < this.units.length; j++) {
        const b = this.units[j];
        if (!b.alive || b.kind === 'turret' || b.kind === 'truck') continue;
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const dist = Math.hypot(dx, dy);
        const minDist = a.radius + b.radius + 4;
        if (dist > 0.01 && dist < minDist) {
          const push = (minDist - dist) * 0.35;
          const nx = dx / dist;
          const ny = dy / dist;
          if (isPointPassableForLand(this.map, a.x - nx * push, a.y - ny * push)) {
            a.x -= nx * push;
            a.y -= ny * push;
          }
          if (isPointPassableForLand(this.map, b.x + nx * push, b.y + ny * push)) {
            b.x += nx * push;
            b.y += ny * push;
          }
        }
      }
    }
  }

  private updateSupplyTruck(truck: Unit, dt: number) {
    const hq = truck.faction === 'player' ? this.map.playerHQ : this.map.enemyHQ;
    const rig = this.map.rigs.find((r) => r.id === truck.assignedRigId);

    // If rig was captured by opponent, return to HQ or idle
    if (!rig || rig.owner !== truck.faction) {
      if ((truck.cargoOil ?? 0) > 0) {
        truck.assignedRigId = null;
      } else {
        const altRig = this.map.rigs.find((r) => r.owner === truck.faction);
        if (altRig) {
          truck.assignedRigId = altRig.id;
          const start = this.findNearestRoadNode(truck.x, truck.y);
          const path = findRoadPath(this.map, start, altRig.roadNodeId);
          truck.roadPath = path ?? [];
          truck.roadPathIndex = 0;
          truck.truckState = path ? 'to_rig' : 'stranded';
        }
        return;
      }
    }

    if (truck.truckState === 'loading' && rig) {
      truck.loadTimer = (truck.loadTimer ?? 0) + dt;
      if (truck.loadTimer >= 1.1) {
        const taken = Math.max(25, Math.min(TRUCK_CARGO_CAPACITY, Math.round(rig.storedBarrels)));
        rig.storedBarrels = Math.max(0, rig.storedBarrels - taken);
        truck.cargoOil = taken;
        truck.loadTimer = 0;
        const pathBack = findRoadPath(this.map, rig.roadNodeId, hq.roadNodeId);
        if (pathBack) {
          truck.roadPath = pathBack;
          truck.roadPathIndex = 1;
          truck.truckState = 'to_hq';
        } else {
          truck.truckState = 'stranded';
          if (truck.faction === 'enemy' && this.enemyStarveBannerCooldown <= 0 && this.phase === 'playing') {
            this.pushEvent('enemy_starving', 'good');
            this.enemyStarveBannerCooldown = 14;
          }
        }
      }
      return;
    }

    if (truck.truckState === 'stranded') {
      // Periodically retry path in case a bridge was rebuilt
      truck.loadTimer = (truck.loadTimer ?? 0) + dt;
      if (truck.loadTimer >= 1.8) {
        truck.loadTimer = 0;
        const goalNode = (truck.cargoOil ?? 0) > 0 ? hq.roadNodeId : rig?.roadNodeId;
        if (goalNode) {
          const start = this.findNearestRoadNode(truck.x, truck.y);
          const p = findRoadPath(this.map, start, goalNode);
          if (p && p.length > 0) {
            truck.roadPath = p;
            truck.roadPathIndex = 0;
            truck.truckState = (truck.cargoOil ?? 0) > 0 ? 'to_hq' : 'to_rig';
          }
        }
      }
      return;
    }

    const path = truck.roadPath ?? [];
    const idx = truck.roadPathIndex ?? 0;

    if (idx >= path.length) {
      if (truck.truckState === 'to_rig' && rig) {
        truck.truckState = 'loading';
        truck.loadTimer = 0;
      } else if (truck.truckState === 'to_hq') {
        const delivered = truck.cargoOil ?? 0;
        if (delivered > 0) {
          if (truck.faction === 'player') {
            this.playerOil += delivered;
            this.playerOilDelivered += delivered;
            this.floatingPopups.push({
              x: hq.x,
              y: hq.y - 44,
              text: `+${delivered}`,
              color: '#f5c249',
              life: 1.35,
              maxLife: 1.35,
            });
            this.audio.onOilDeposit?.();
          } else {
            this.enemyOil += delivered;
          }
          truck.cargoOil = 0;
          this.spawnBurst(hq.x, hq.y - 12, 'spark', 5, '#e8b648', 42);
        }
        if (rig && rig.owner === truck.faction) {
          const nextPath = findRoadPath(this.map, hq.roadNodeId, rig.roadNodeId);
          if (nextPath) {
            truck.roadPath = nextPath;
            truck.roadPathIndex = 1;
            truck.truckState = 'to_rig';
          } else {
            truck.truckState = 'stranded';
          }
        }
      }
      return;
    }

    const targetNodeId = path[idx];
    const targetNode = this.map.roadNodes[targetNodeId];
    if (!targetNode) {
      truck.truckState = 'stranded';
      return;
    }

    // Dynamic check: did the bridge ahead just get blown up?
    if (targetNode.bridgeId) {
      const b = this.map.bridges.find((br) => br.id === targetNode.bridgeId);
      if (b && b.status !== 'intact') {
        const goalNode = truck.truckState === 'to_hq' ? hq.roadNodeId : rig?.roadNodeId ?? hq.roadNodeId;
        const start = this.findNearestRoadNode(truck.x, truck.y);
        const altPath = findRoadPath(this.map, start, goalNode);
        if (altPath) {
          truck.roadPath = altPath;
          truck.roadPathIndex = 0;
        } else {
          truck.truckState = 'stranded';
          if (truck.faction === 'enemy' && this.enemyStarveBannerCooldown <= 0 && this.phase === 'playing') {
            this.pushEvent('enemy_starving', 'good');
            this.enemyStarveBannerCooldown = 14;
          }
        }
        return;
      }
    }

    const dx = targetNode.x - truck.x;
    const dy = targetNode.y - truck.y;
    const dist = Math.hypot(dx, dy);
    if (dist < 10) {
      truck.roadPathIndex = idx + 1;
      return;
    }

    const step = Math.min(dist, truck.speed * dt);
    const nx = truck.x + (dx / dist) * step;
    const ny = truck.y + (dy / dist) * step;
    truck.x = nx;
    truck.y = ny;
    truck.angle = Math.atan2(dy, dx);
    truck.turretAngle = truck.angle;
    truck.gaitPhase += step * 0.12;
  }

  private updateTurret(u: Unit, _dt: number) {
    const enemy = this.findNearestHostileUnit(u, u.range);
    if (enemy) {
      u.turretAngle = Math.atan2(enemy.y - u.y, enemy.x - u.x);
      if (u.cooldown <= 0) {
        this.fireProjectile(u, enemy.x, enemy.y);
        u.cooldown = u.fireRate;
      }
    }
  }

  private updateCombatUnit(u: Unit, dt: number) {
    // 1. Check explicit bridge demolition order
    if (u.targetBridgeId) {
      const bridge = this.map.bridges.find((b) => b.id === u.targetBridgeId);
      if (!bridge || bridge.status !== 'intact') {
        u.targetBridgeId = null;
        u.stance = 'idle';
      } else {
        const dist = Math.hypot(bridge.x - u.x, bridge.y - u.y);
        const attackDist = u.range + 22;
        if (dist <= attackDist) {
          u.turretAngle = Math.atan2(bridge.y - u.y, bridge.x - u.x);
          if (u.cooldown <= 0) {
            this.triggerAttack(u, bridge.x, bridge.y);
          }
          return;
        } else {
          this.moveUnitToward(u, bridge.x, bridge.y, dt);
          return;
        }
      }
    }

    // 2. Check explicit HQ attack order
    if (u.targetHqFaction) {
      const hq = u.targetHqFaction === 'player' ? this.map.playerHQ : this.map.enemyHQ;
      const dist = Math.hypot(hq.x - u.x, hq.y - u.y);
      if (dist <= u.range + 28) {
        u.turretAngle = Math.atan2(hq.y - u.y, hq.x - u.x);
        if (u.cooldown <= 0) {
          this.triggerAttack(u, hq.x, hq.y);
        }
        return;
      } else {
        this.moveUnitToward(u, hq.x, hq.y, dt);
        return;
      }
    }

    // 3. Check explicit unit target
    let explicitTarget: Unit | null = null;
    if (u.targetEntityId !== null) {
      explicitTarget = this.units.find((t) => t.id === u.targetEntityId && t.alive) ?? null;
      if (!explicitTarget) {
        u.targetEntityId = null;
      }
    }

    if (explicitTarget) {
      const dist = Math.hypot(explicitTarget.x - u.x, explicitTarget.y - u.y);
      if (dist <= u.range) {
        u.turretAngle = Math.atan2(explicitTarget.y - u.y, explicitTarget.x - u.x);
        if (u.cooldown <= 0) {
          this.triggerAttack(u, explicitTarget.x, explicitTarget.y);
        }
        return;
      } else {
        this.moveUnitToward(u, explicitTarget.x, explicitTarget.y, dt);
        return;
      }
    }

    // 4. Opportunistic fire while moving or holding ground
    const nearestHostile = this.findNearestHostileUnit(u, u.range);
    const oppHq = u.faction === 'player' ? this.map.enemyHQ : this.map.playerHQ;
    const hqDist = Math.hypot(oppHq.x - u.x, oppHq.y - u.y);

    if (nearestHostile) {
      u.turretAngle = Math.atan2(nearestHostile.y - u.y, nearestHostile.x - u.x);
      if (u.cooldown <= 0) {
        this.triggerAttack(u, nearestHostile.x, nearestHostile.y);
      }
    } else if (hqDist <= u.range + 24) {
      u.turretAngle = Math.atan2(oppHq.y - u.y, oppHq.x - u.x);
      if (u.cooldown <= 0) {
        this.triggerAttack(u, oppHq.x, oppHq.y);
      }
    }

    // 5. Move toward destination if assigned (artillery stops when in range of target)
    if (u.targetPos) {
      const dist = Math.hypot(u.targetPos.x - u.x, u.targetPos.y - u.y);
      if (dist < 14) {
        u.targetPos = null;
        u.stance = 'idle';
      } else if (!(u.kind === 'artillery' && nearestHostile)) {
        this.moveUnitToward(u, u.targetPos.x, u.targetPos.y, dt);
      }
    }
  }

  private moveUnitToward(u: Unit, destX: number, destY: number, dt: number) {
    let goalX = destX;
    let goalY = destY;

    // If destination is across the river, steer toward the nearest intact bridge
    if (isOppositeRiverSide(this.map, u.x, destX)) {
      const bridge = findNearestIntactBridge(this.map, u.x, u.y, destX, destY);
      if (bridge) {
        const distToBridge = Math.hypot(bridge.x - u.x, bridge.y - u.y);
        if (distToBridge > 44) {
          goalX = bridge.x;
          goalY = bridge.y;
        }
      }
    }

    const dx = goalX - u.x;
    const dy = goalY - u.y;
    const dist = Math.hypot(dx, dy);
    if (dist < 1) return;

    const dirX = dx / dist;
    const dirY = dy / dist;
    const step = Math.min(dist, u.speed * dt);

    const candX = u.x + dirX * step;
    const candY = u.y + dirY * step;

    if (isPointPassableForLand(this.map, candX, candY)) {
      u.x = candX;
      u.y = candY;
      u.angle = Math.atan2(dirY, dirX);
      u.gaitPhase += step * 0.14;
    } else if (isPointPassableForLand(this.map, u.x, candY)) {
      u.y = candY;
      u.angle = Math.atan2(dirY, 0);
      u.gaitPhase += step * 0.1;
    } else if (isPointPassableForLand(this.map, candX, u.y)) {
      u.x = candX;
      u.angle = Math.atan2(0, dirX);
      u.gaitPhase += step * 0.1;
    }
  }

  private findNearestHostileUnit(u: Unit, maxRange: number): Unit | null {
    let best: Unit | null = null;
    let bestScore = Infinity;
    for (const other of this.units) {
      if (!other.alive || other.faction === u.faction) continue;
      const d = Math.hypot(other.x - u.x, other.y - u.y);
      if (d <= maxRange) {
        // Raiders (scouts) prioritize oil trucks slightly; tanks prioritize combat threats
        const priorityBias = u.kind === 'scout' && other.kind === 'truck' ? 0.65 : 1.0;
        const score = d * priorityBias;
        if (score < bestScore) {
          bestScore = score;
          best = other;
        }
      }
    }
    return best;
  }

  private triggerAttack(u: Unit, targetX: number, targetY: number) {
    // Artillery uses a clear 0.52s windup telegraph (target ring visible before rocket lands)
    if (u.kind === 'artillery') {
      u.windupTimer = 0.52;
      u.windupTarget = { x: targetX, y: targetY };
      u.turretAngle = Math.atan2(targetY - u.y, targetX - u.x);
      return;
    }
    this.fireProjectile(u, targetX, targetY);
    u.cooldown = u.fireRate;
  }

  private fireProjectile(u: Unit, targetX: number, targetY: number) {
    const spec = UNIT_SPECS[u.kind];
    const angle = Math.atan2(targetY - u.y, targetX - u.x);
    u.turretAngle = angle;
    u.recoil = u.kind === 'tank' || u.kind === 'artillery' ? 1.0 : 0.45;

    const muzzleX = u.x + Math.cos(angle) * (u.radius + 6);
    const muzzleY = u.y + Math.sin(angle) * (u.radius + 6);
    const dist = Math.max(10, Math.hypot(targetX - muzzleX, targetY - muzzleY));

    const kind: Projectile['kind'] =
      u.kind === 'artillery' ? 'rocket' : u.kind === 'tank' || u.kind === 'engineer' ? 'shell' : 'bullet';

    const speed = kind === 'bullet' ? 560 : kind === 'shell' ? 420 : 280;
    const travelTime = dist / speed;

    this.projectiles.push({
      id: this.nextProjectileId++,
      faction: u.faction,
      kind,
      x: muzzleX,
      y: muzzleY,
      startX: muzzleX,
      startY: muzzleY,
      targetX,
      targetY,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      damage: spec.damage,
      splashRadius: kind === 'rocket' ? 62 : kind === 'shell' ? 28 : 0,
      bridgeMultiplier: spec.bridgeBonus,
      travelTime,
      elapsed: 0,
      alive: true,
    });

    this.spawnParticle('fire', muzzleX, muzzleY, Math.cos(angle) * 35, Math.sin(angle) * 35, 5, 2, 0.14, '#ffd97a');
    if (kind === 'bullet') this.audio.onMgShot?.();
    else if (kind === 'shell') this.audio.onCannon?.();
    else this.audio.onRocket?.();
  }

  private updateProjectiles(dt: number) {
    for (const p of this.projectiles) {
      if (!p.alive) continue;
      p.elapsed += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;

      if (p.kind === 'rocket') {
        this.spawnParticle('smoke', p.x, p.y, (Math.random() - 0.5) * 14, (Math.random() - 0.5) * 14, 4, 11, 0.38, '#d4cdc0');
      }

      // Direct hit check for bullets/shells before reaching target
      if (p.kind !== 'rocket') {
        for (const u of this.units) {
          if (!u.alive || u.faction === p.faction) continue;
          if (Math.hypot(u.x - p.x, u.y - p.y) <= u.radius + 5) {
            this.detonateProjectile(p);
            break;
          }
        }
      }

      if (p.alive && p.elapsed >= p.travelTime) {
        this.detonateProjectile(p);
      }
    }

    this.projectiles = this.projectiles.filter((p) => p.alive);
  }

  private detonateProjectile(p: Projectile) {
    p.alive = false;
    const radius = Math.max(24, p.splashRadius);

    // 1. Damage hostile units in blast radius
    for (const u of this.units) {
      if (!u.alive || u.faction === p.faction) continue;
      const d = Math.hypot(u.x - p.x, u.y - p.y);
      if (d <= radius + u.radius) {
        const falloff = p.splashRadius > 0 ? Math.max(0.45, 1 - d / (radius + u.radius + 10)) : 1;
        this.damageUnit(u, p.damage * falloff);
      }
    }

    // 2. Damage opposing HQ
    const oppHq = p.faction === 'player' ? this.map.enemyHQ : this.map.playerHQ;
    if (Math.hypot(oppHq.x - p.x, oppHq.y - p.y) <= radius + 40) {
      oppHq.hp = Math.max(0, oppHq.hp - p.damage);
      oppHq.hitFlash = 0.08;
      if (oppHq.faction === 'player' && this.hqAlertCooldown <= 0 && this.phase === 'playing') {
        this.pushEvent('hq_under_attack', 'warn');
        this.hqAlertCooldown = 10;
      }
    }

    // 3. Damage intact bridges if shell/rocket lands on bridge span
    const hitBridge = getBridgeAtWorld(this.map, p.x, p.y, radius * 0.65);
    if (hitBridge && hitBridge.status === 'intact') {
      this.damageBridge(hitBridge, p.damage * p.bridgeMultiplier, p.faction);
    }

    // Visual impact burst
    if (p.kind === 'rocket') {
      this.spawnBurst(p.x, p.y, 'fire', 14, '#ff7a22', 110);
      this.spawnBurst(p.x, p.y, 'smoke', 10, '#2a2622', 65);
      this.spawnParticle('ring', p.x, p.y, 0, 0, 10, 66, 0.32, '#ffbe55');
      this.addCrater(p.x, p.y, 18, false);
      this.cameraTrauma = Math.min(1, this.cameraTrauma + 0.35);
      this.audio.onExplosion?.(false);
    } else if (p.kind === 'shell') {
      this.spawnBurst(p.x, p.y, 'fire', 7, '#ffaa38', 70);
      this.spawnBurst(p.x, p.y, 'spark', 5, '#ffe399', 90);
      this.addCrater(p.x, p.y, 10, false);
    } else {
      this.spawnBurst(p.x, p.y, 'spark', 3, '#ffe28a', 55);
    }
  }

  public damageUnit(u: Unit, amount: number) {
    if (!u.alive) return;
    u.hp -= amount;
    u.hitFlash = 0.065;
    if (u.hp <= 0) {
      u.hp = 0;
      u.alive = false;
      u.selected = false;
      u.koTimer = 0.42;

      const isOilTruck = u.kind === 'truck';
      const isHeavy = u.kind === 'tank' || u.kind === 'artillery' || isOilTruck;

      if (isOilTruck) {
        // Oil trucks erupt in a huge fiery oil slick explosion!
        this.spawnBurst(u.x, u.y, 'fire', 22, '#ff6818', 135);
        this.spawnBurst(u.x, u.y, 'oil', 14, '#141210', 95);
        this.spawnParticle('ring', u.x, u.y, 0, 0, 8, 56, 0.38, '#ff9c33');
        this.addCrater(u.x, u.y, 20, true);
        if (u.faction === 'enemy') {
          this.enemyTrucksDestroyed++;
          if (this.phase === 'playing') this.pushEvent('truck_ambushed', 'good');
        }
      } else {
        this.spawnBurst(u.x, u.y, 'fire', isHeavy ? 16 : 9, '#ff8628', 105);
        this.spawnBurst(u.x, u.y, 'smoke', isHeavy ? 10 : 6, '#262422', 65);
        this.addCrater(u.x, u.y, isHeavy ? 15 : 10, false);
      }

      if (isHeavy) {
        this.hitstopTimer = 0.045;
        this.cameraTrauma = Math.min(1, this.cameraTrauma + 0.45);
        this.audio.onExplosion?.(true);
      } else {
        this.audio.onExplosion?.(false);
      }
    }
  }

  public damageBridge(bridge: Bridge, amount: number, attacker: 'player' | 'enemy') {
    if (bridge.status !== 'intact') return;
    bridge.hp -= amount;
    bridge.hitFlash = 0.08;
    if (bridge.hp <= 0) {
      bridge.hp = 0;
      bridge.status = 'destroyed';
      if (attacker === 'player') {
        this.bridgesDestroyedByPlayer++;
      }

      // Any land unit standing right on the collapsing bridge falls into the river!
      for (const u of this.units) {
        if (!u.alive || u.kind === 'turret') continue;
        if (
          Math.abs(u.x - bridge.x) <= bridge.width * 0.5 &&
          Math.abs(u.y - bridge.y) <= bridge.height * 0.5
        ) {
          this.damageUnit(u, u.maxHp + 50);
          this.spawnBurst(u.x, u.y, 'splash', 10, '#8cc8db', 80);
        }
      }

      // Huge demolition blast + hitstop + shake
      this.hitstopTimer = 0.07;
      this.cameraTrauma = Math.min(1, this.cameraTrauma + 0.78);
      this.spawnBurst(bridge.x, bridge.y, 'fire', 28, '#ff6d1f', 155);
      this.spawnBurst(bridge.x, bridge.y, 'debris', 22, '#69645b', 140);
      this.spawnBurst(bridge.x, bridge.y, 'splash', 16, '#8ac7da', 120);
      this.spawnParticle('ring', bridge.x, bridge.y, 0, 0, 14, 96, 0.45, '#ffc152');
      this.audio.onExplosion?.(true);

      if (this.phase === 'playing') {
        this.pushEvent('bridge_destroyed', attacker === 'player' ? 'good' : 'warn');
      }

      // Immediately recalculate supply truck routes so starvation takes effect!
      this.rerouteStrandedTrucks();
    }
  }

  private addCrater(x: number, y: number, radius: number, oilSlick: boolean) {
    this.craters.push({ x, y, radius, oilSlick });
    if (this.craters.length > 65) {
      this.craters.shift();
    }
  }

  private updateEnemyAI(dt: number) {
    this.aiDecisionTimer -= dt;
    if (this.aiDecisionTimer > 0) return;

    // Multi-knob difficulty ramp: faster decisions and heavier mixes as match progresses
    const ramp = Math.min(1, this.elapsedSeconds / 180);
    this.aiDecisionTimer = 4.6 - ramp * 1.9;
    this.aiWaveCount++;

    const eHQ = this.map.enemyHQ;
    const enemyCombat = this.units.filter(
      (u) => u.alive && u.faction === 'enemy' && u.kind !== 'truck' && u.kind !== 'turret'
    );

    // 1. If all bridges are cut and AI has enough oil, repair one to restore supply lines
    const intactBridges = this.map.bridges.filter((b) => b.status === 'intact');
    if (intactBridges.length === 0 && this.enemyOil >= BRIDGE_REBUILD_COST + 40) {
      const broken = this.map.bridges[0];
      if (broken) {
        this.rebuildBridge(broken.id, 'enemy');
        return;
      }
    }

    // 2. Spend real enemy oil (so starving the enemy genuinely halts their army!)
    if (enemyCombat.length < 7 + Math.floor(ramp * 4)) {
      let desired: UnitKind = 'scout';
      const roll = this.aiWaveCount % 4;
      if (roll === 0) desired = 'scout'; // Convoy raider
      else if (roll === 1) desired = 'tank'; // Armored frontliner
      else if (roll === 2) desired = this.elapsedSeconds > 28 ? 'artillery' : 'engineer';
      else desired = 'tank';

      const cost = UNIT_SPECS[desired].cost;
      if (this.enemyOil >= cost) {
        this.enemyOil -= cost;
        const spread = ((this.aiWaveCount * 47) % 90) - 45;
        this.spawnUnit('enemy', desired, eHQ.x - 86, eHQ.y + spread);
      }
    }

    // 3. Assign distinct tactical behaviors per archetype
    const neutralOrPlayerRig =
      this.map.rigs.find((r) => r.owner === 'neutral') ??
      this.map.rigs.find((r) => r.owner === 'player');
    const playerTruck = this.units.find((u) => u.alive && u.faction === 'player' && u.kind === 'truck');

    for (const u of enemyCombat) {
      if (u.stance !== 'idle' && u.targetPos) continue;

      if (u.kind === 'scout') {
        // Archetype 1: Flanker/Raider — grabs neutral rigs early, then hunts player oil trucks
        if (playerTruck && intactBridges.length > 0 && this.elapsedSeconds > 18 && Math.random() < 0.6) {
          u.targetEntityId = playerTruck.id;
          u.targetPos = { x: playerTruck.x, y: playerTruck.y };
          u.stance = 'attack';
        } else if (neutralOrPlayerRig) {
          u.targetPos = { x: neutralOrPlayerRig.x, y: neutralOrPlayerRig.y };
          u.stance = 'move';
        }
      } else if (u.kind === 'artillery') {
        // Archetype 2: Siege Standoff — targets player turrets or pushes behind armor
        const playerTurret = this.units.find((p) => p.alive && p.faction === 'player' && p.kind === 'turret');
        if (playerTurret && intactBridges.length > 0) {
          u.targetEntityId = playerTurret.id;
          u.targetPos = { x: playerTurret.x, y: playerTurret.y };
          u.stance = 'attack';
        } else if (intactBridges.length > 0) {
          u.targetHqFaction = 'player';
          u.targetPos = { x: this.map.playerHQ.x, y: this.map.playerHQ.y };
          u.stance = 'attack';
        }
      } else if (u.kind === 'engineer') {
        // Archetype 3: Objective Capturer
        if (neutralOrPlayerRig) {
          u.targetPos = { x: neutralOrPlayerRig.x, y: neutralOrPlayerRig.y };
          u.stance = 'move';
        }
      } else {
        // Archetype 4: Tank Armored Push — assaults across intact bridges toward player rigs / HQ
        if (intactBridges.length > 0 && this.elapsedSeconds > 16) {
          if (Math.random() < 0.55) {
            u.targetHqFaction = 'player';
            u.targetPos = { x: this.map.playerHQ.x, y: this.map.playerHQ.y };
            u.stance = 'attack';
          } else if (neutralOrPlayerRig) {
            u.targetPos = { x: neutralOrPlayerRig.x, y: neutralOrPlayerRig.y };
            u.stance = 'move';
          }
        } else {
          // Hold defensive bridgehead on east bank if bridges are blown
          const b = this.map.bridges[0];
          if (b) {
            u.targetPos = { x: b.x + 150, y: b.y + (Math.random() - 0.5) * 80 };
            u.stance = 'move';
          }
        }
      }
    }
  }

  private checkWinLoss() {
    if (this.outcome !== 'none') return;
    if (this.map.enemyHQ.hp <= 0) {
      this.outcome = 'victory';
      this.defeatDelayTimer = 0.55;
      this.spawnBurst(this.map.enemyHQ.x, this.map.enemyHQ.y, 'fire', 36, '#ff731d', 175);
      this.spawnBurst(this.map.enemyHQ.x, this.map.enemyHQ.y, 'smoke', 24, '#1f1d1b', 110);
      this.cameraTrauma = 1;
      this.audio.onExplosion?.(true);
      this.audio.onVictory?.();
    } else if (this.map.playerHQ.hp <= 0) {
      this.outcome = 'defeat';
      this.defeatDelayTimer = 0.55;
      this.spawnBurst(this.map.playerHQ.x, this.map.playerHQ.y, 'fire', 36, '#ff6818', 175);
      this.spawnBurst(this.map.playerHQ.x, this.map.playerHQ.y, 'smoke', 24, '#1f1d1b', 110);
      this.cameraTrauma = 1;
      this.audio.onExplosion?.(true);
      this.audio.onDefeat?.();
    }
  }

  private finalizeMatch() {
    this.phase = 'gameover';
    const score = this.computeScore();
    this.saveBestScore(score);
  }

  public computeScore(): number {
    const victoryBonus = this.outcome === 'victory' ? 1200 : 0;
    const speedBonus = this.outcome === 'victory' ? Math.max(0, 600 - Math.floor(this.elapsedSeconds * 2)) : 0;
    return (
      victoryBonus +
      speedBonus +
      Math.round(this.playerOilDelivered) +
      this.bridgesDestroyedByPlayer * 220 +
      this.enemyTrucksDestroyed * 140
    );
  }

  public spawnParticle(
    kind: Particle['kind'],
    x: number,
    y: number,
    vx: number,
    vy: number,
    size: number,
    endSize: number,
    maxLife: number,
    color: string
  ) {
    const p = this.particles[this.particleCursor];
    this.particleCursor = (this.particleCursor + 1) % MAX_PARTICLES;
    p.active = true;
    p.kind = kind;
    p.x = x;
    p.y = y;
    p.vx = vx;
    p.vy = vy;
    p.size = size;
    p.endSize = endSize;
    p.life = maxLife;
    p.maxLife = maxLife;
    p.color = color;
    p.alpha = 1;
  }

  public spawnBurst(
    x: number,
    y: number,
    kind: Particle['kind'],
    count: number,
    color: string,
    maxSpeed: number
  ) {
    for (let i = 0; i < count; i++) {
      const a = Math.random() * Math.PI * 2;
      const sp = (0.25 + Math.random() * 0.75) * maxSpeed;
      const size = kind === 'smoke' ? 5 + Math.random() * 5 : 3 + Math.random() * 4;
      const endSize = kind === 'smoke' ? size * 2.5 : size * 0.35;
      const life = kind === 'smoke' ? 0.65 + Math.random() * 0.5 : 0.25 + Math.random() * 0.3;
      this.spawnParticle(kind, x, y, Math.cos(a) * sp, Math.sin(a) * sp, size, endSize, life, color);
    }
  }

  private updateParticles(dt: number) {
    for (const p of this.particles) {
      if (!p.active) continue;
      p.life -= dt;
      if (p.life <= 0) {
        p.active = false;
        continue;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.kind !== 'smoke') {
        p.vx *= 0.94;
        p.vy *= 0.94;
      }
      p.alpha = Math.max(0, p.life / p.maxLife);
    }
  }

  public getHudSnapshot(): HudSnapshot {
    let playerRigs = 0;
    let enemyRigs = 0;
    for (const r of this.map.rigs) {
      if (r.owner === 'player') playerRigs++;
      else if (r.owner === 'enemy') enemyRigs++;
    }

    let playerTrucks = 0;
    let strandedPlayerTrucks = 0;
    let strandedEnemyTrucks = 0;
    let playerUnits = 0;
    let selectedCount = 0;

    for (const u of this.units) {
      if (!u.alive) continue;
      if (u.kind === 'truck') {
        if (u.faction === 'player') {
          playerTrucks++;
          if (u.truckState === 'stranded') strandedPlayerTrucks++;
        } else if (u.truckState === 'stranded') {
          strandedEnemyTrucks++;
        }
      } else if (u.faction === 'player') {
        playerUnits++;
        if (u.selected) selectedCount++;
      }
    }

    const bridgesIntact = this.map.bridges.filter((b) => b.status === 'intact').length;

    return {
      phase: this.phase,
      outcome: this.outcome,
      theater: this.theater,
      seed: this.seed,
      playerOil: Math.round(this.playerOil),
      enemyOil: Math.round(this.enemyOil),
      playerOilDelivered: Math.round(this.playerOilDelivered),
      playerRigs,
      enemyRigs,
      totalRigs: this.map.rigs.length,
      playerTrucks,
      strandedPlayerTrucks,
      strandedEnemyTrucks,
      bridgesIntact,
      bridgesTotal: this.map.bridges.length,
      playerUnits,
      selectedCount,
      playerHqHp: Math.round(this.map.playerHQ.hp),
      playerHqMaxHp: this.map.playerHQ.maxHp,
      enemyHqHp: Math.round(this.map.enemyHQ.hp),
      enemyHqMaxHp: this.map.enemyHQ.maxHp,
      bridgesDestroyedByPlayer: this.bridgesDestroyedByPlayer,
      enemyTrucksDestroyed: this.enemyTrucksDestroyed,
      elapsedSeconds: Math.floor(this.elapsedSeconds),
      buildMode: this.buildMode,
      eventBanner: this.eventBanner
        ? { key: this.eventBanner.key, tone: this.eventBanner.tone, id: this.eventBanner.id }
        : null,
      bestScore: this.bestScore,
      score: this.computeScore(),
    };
  }
}
