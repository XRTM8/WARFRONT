export type Lang = 'ar' | 'en';

export type GamePhase = 'title' | 'playing' | 'paused' | 'gameover';

export type GameOutcome = 'none' | 'victory' | 'defeat';

export type Faction = 'player' | 'enemy' | 'neutral';

export type TheaterId = 'kirkuk' | 'suez' | 'newyork' | 'procedural';

export type UnitKind = 'truck' | 'scout' | 'tank' | 'artillery' | 'engineer' | 'turret';

export type TileKind = 'ground' | 'road' | 'water' | 'bridge' | 'oilfield' | 'concrete';

export interface Vec2 {
  x: number;
  y: number;
}

export interface RoadNode {
  id: string;
  x: number;
  y: number;
  neighbors: string[];
  bridgeId?: string;
}

export interface Bridge {
  id: string;
  name: string;
  x: number;
  y: number;
  width: number;
  height: number;
  orientation: 'horizontal' | 'vertical';
  hp: number;
  maxHp: number;
  status: 'intact' | 'destroyed';
  rebuildProgress: number;
  hitFlash: number;
  tiles: Array<{ col: number; row: number }>;
}

export interface OilRig {
  id: string;
  x: number;
  y: number;
  owner: Faction;
  captureProgress: number; // -100 (enemy) to +100 (player)
  captureFaction: Faction;
  storedBarrels: number;
  maxBarrels: number;
  pumpPhase: number;
  roadNodeId: string;
  truckCooldown: number;
  isBurning: boolean;
}

export interface CommandHQ {
  faction: 'player' | 'enemy';
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  roadNodeId: string;
  radarAngle: number;
  hitFlash: number;
}

export interface Unit {
  id: number;
  faction: 'player' | 'enemy';
  kind: UnitKind;
  x: number;
  y: number;
  vx: number;
  vy: number;
  angle: number;
  turretAngle: number;
  hp: number;
  maxHp: number;
  speed: number;
  radius: number;
  range: number;
  damage: number;
  fireRate: number;
  cooldown: number;
  selected: boolean;
  // Movement & orders
  targetPos: Vec2 | null;
  targetEntityId: number | null;
  targetBridgeId: string | null;
  targetHqFaction: 'player' | 'enemy' | null;
  stance: 'idle' | 'move' | 'attack' | 'patrol' | 'demolish' | 'repair';
  // Supply truck logistics state
  truckState?: 'to_rig' | 'loading' | 'to_hq' | 'stranded';
  cargoOil?: number;
  assignedRigId?: string | null;
  roadPath?: string[];
  roadPathIndex?: number;
  loadTimer?: number;
  // Animation & juice
  hitFlash: number;
  recoil: number;
  gaitPhase: number;
  koTimer: number; // > 0 means dying/burning wreckage transition
  alive: boolean;
  // Windup telegraph (for artillery / heavy shots)
  windupTimer: number;
  windupTarget: Vec2 | null;
  // Veterancy progression
  xp: number;
  rank: 0 | 1 | 2 | 3;
  kills: number;
  promoFlash: number;
}

export interface Projectile {
  id: number;
  sourceUnitId: number;
  faction: 'player' | 'enemy';
  kind: 'bullet' | 'shell' | 'rocket';
  x: number;
  y: number;
  startX: number;
  startY: number;
  targetX: number;
  targetY: number;
  vx: number;
  vy: number;
  damage: number;
  splashRadius: number;
  bridgeMultiplier: number;
  travelTime: number;
  elapsed: number;
  alive: boolean;
}

export interface Particle {
  active: boolean;
  kind: 'smoke' | 'fire' | 'spark' | 'debris' | 'oil' | 'ring' | 'splash';
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  endSize: number;
  life: number;
  maxLife: number;
  color: string;
  alpha: number;
}

export interface Crater {
  x: number;
  y: number;
  radius: number;
  oilSlick: boolean;
}

export interface UnitSpec {
  kind: UnitKind;
  hotkey: string;
  cost: number;
  hp: number;
  speed: number;
  radius: number;
  range: number;
  damage: number;
  fireRate: number;
  bridgeBonus: number;
}

export interface MapData {
  theater: TheaterId;
  seed: number;
  cols: number;
  rows: number;
  tileSize: number;
  width: number;
  height: number;
  tiles: TileKind[]; // row * cols + col
  roadNodes: Record<string, RoadNode>;
  bridges: Bridge[];
  rigs: OilRig[];
  playerHQ: CommandHQ;
  enemyHQ: CommandHQ;
  burningWells: Vec2[];
}

export interface HudSnapshot {
  phase: GamePhase;
  outcome: GameOutcome;
  theater: TheaterId;
  seed: number;
  playerOil: number;
  enemyOil: number;
  playerOilDelivered: number;
  playerRigs: number;
  enemyRigs: number;
  totalRigs: number;
  playerTrucks: number;
  strandedPlayerTrucks: number;
  strandedEnemyTrucks: number;
  bridgesIntact: number;
  bridgesTotal: number;
  playerUnits: number;
  playerVeterans: number;
  selectedCount: number;
  selectedVeterans: number;
  playerHqHp: number;
  playerHqMaxHp: number;
  enemyHqHp: number;
  enemyHqMaxHp: number;
  bridgesDestroyedByPlayer: number;
  enemyTrucksDestroyed: number;
  elapsedSeconds: number;
  buildMode: 'none' | 'turret' | 'rebuild_bridge';
  eventBanner: { key: string; tone: 'info' | 'warn' | 'good'; id: number } | null;
  bestScore: number;
  score: number;
}

export interface UnitSelectionSummary {
  total: number;
  hasEngineer: boolean;
  hasArtillery: boolean;
}
