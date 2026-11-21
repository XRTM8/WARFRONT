import { TheaterId, UnitKind, UnitSpec } from './types';

export const TILE_SIZE = 48;
export const MAP_COLS = 54;
export const MAP_ROWS = 32;

export const STARTING_PLAYER_OIL = 260;
export const STARTING_ENEMY_OIL = 220;
export const BRIDGE_REBUILD_COST = 110;
export const BRIDGE_MAX_HP = 420;
export const HQ_MAX_HP = 1600;
export const TRUCK_CARGO_CAPACITY = 55;

export const UNIT_SPECS: Record<UnitKind, UnitSpec> = {
  truck: {
    kind: 'truck',
    hotkey: '',
    cost: 0,
    hp: 110,
    speed: 138,
    radius: 14,
    range: 0,
    damage: 0,
    fireRate: 0,
    bridgeBonus: 1,
  },
  scout: {
    kind: 'scout',
    hotkey: '1',
    cost: 60,
    hp: 115,
    speed: 132,
    radius: 14,
    range: 175,
    damage: 11,
    fireRate: 0.34,
    bridgeBonus: 0.65,
  },
  tank: {
    kind: 'tank',
    hotkey: '2',
    cost: 140,
    hp: 290,
    speed: 74,
    radius: 17,
    range: 220,
    damage: 44,
    fireRate: 1.35,
    bridgeBonus: 1.35,
  },
  artillery: {
    kind: 'artillery',
    hotkey: '3',
    cost: 185,
    hp: 155,
    speed: 62,
    radius: 16,
    range: 365,
    damage: 78,
    fireRate: 2.65,
    bridgeBonus: 2.3,
  },
  engineer: {
    kind: 'engineer',
    hotkey: '4',
    cost: 95,
    hp: 130,
    speed: 98,
    radius: 13,
    range: 135,
    damage: 18,
    fireRate: 0.85,
    bridgeBonus: 3.1,
  },
  turret: {
    kind: 'turret',
    hotkey: '5',
    cost: 120,
    hp: 340,
    speed: 0,
    radius: 16,
    range: 255,
    damage: 24,
    fireRate: 0.62,
    bridgeBonus: 1,
  },
};

export const BUILDABLE_UNITS: UnitKind[] = ['scout', 'tank', 'artillery', 'engineer', 'turret'];

export interface VeterancyRankSpec {
  rank: 0 | 1 | 2 | 3;
  xpRequired: number;
  damageMultiplier: number;
  hpMultiplier: number;
  healPerSec: number;
  badgeLabel: string;
}

export const VETERANCY_RANKS: readonly VeterancyRankSpec[] = [
  { rank: 0, xpRequired: 0, damageMultiplier: 1.0, hpMultiplier: 1.0, healPerSec: 0, badgeLabel: '' },
  { rank: 1, xpRequired: 100, damageMultiplier: 1.18, hpMultiplier: 1.15, healPerSec: 0, badgeLabel: 'VET' },
  { rank: 2, xpRequired: 240, damageMultiplier: 1.38, hpMultiplier: 1.32, healPerSec: 1.5, badgeLabel: 'ELITE' },
  { rank: 3, xpRequired: 450, damageMultiplier: 1.6, hpMultiplier: 1.55, healPerSec: 3.5, badgeLabel: 'ACE' },
] as const;

export const XP_PER_DAMAGE = 0.28;
export const XP_KILL_LIGHT = 65;
export const XP_KILL_HEAVY = 115;
export const XP_BRIDGE_DEMOLISH = 135;
export const XP_RIG_CAPTURE = 60;

export interface TheaterPalette {
  groundA: string;
  groundB: string;
  groundDetail: string;
  concrete: string;
  oilfield: string;
  waterDeep: string;
  waterShallow: string;
  waterFoam: string;
  roadAsphalt: string;
  roadEdge: string;
  roadStripe: string;
  bridgeDeck: string;
  bridgeSteel: string;
  ambientTint: string;
}

export const THEATER_PALETTES: Record<TheaterId, TheaterPalette> = {
  kirkuk: {
    groundA: '#9d8258',
    groundB: '#8e744c',
    groundDetail: '#7a613c',
    concrete: '#777166',
    oilfield: '#4d4132',
    waterDeep: '#224a5e',
    waterShallow: '#2d5f74',
    waterFoam: '#6397a8',
    roadAsphalt: '#3b3936',
    roadEdge: '#5b5244',
    roadStripe: '#c9a45c',
    bridgeDeck: '#5e5a52',
    bridgeSteel: '#8d877a',
    ambientTint: 'rgba(255, 145, 50, 0.05)',
  },
  suez: {
    groundA: '#b4986a',
    groundB: '#a68b5e',
    groundDetail: '#8c7249',
    concrete: '#827e74',
    oilfield: '#584c3a',
    waterDeep: '#175267',
    waterShallow: '#1f6c82',
    waterFoam: '#6bb0bf',
    roadAsphalt: '#3e3d3b',
    roadEdge: '#6b604e',
    roadStripe: '#d4b46b',
    bridgeDeck: '#63605a',
    bridgeSteel: '#9ea39d',
    ambientTint: 'rgba(255, 200, 110, 0.04)',
  },
  newyork: {
    groundA: '#54614d',
    groundB: '#4a5743',
    groundDetail: '#3c4736',
    concrete: '#696d70',
    oilfield: '#3e4244',
    waterDeep: '#1c364d',
    waterShallow: '#264863',
    waterFoam: '#6288a3',
    roadAsphalt: '#323539',
    roadEdge: '#52575e',
    roadStripe: '#d4b44b',
    bridgeDeck: '#525963',
    bridgeSteel: '#8d99a6',
    ambientTint: 'rgba(130, 175, 215, 0.04)',
  },
  procedural: {
    groundA: '#8b7b56',
    groundB: '#7d6e4b',
    groundDetail: '#695b3d',
    concrete: '#706e67',
    oilfield: '#484134',
    waterDeep: '#1f495c',
    waterShallow: '#295e73',
    waterFoam: '#6498aa',
    roadAsphalt: '#393937',
    roadEdge: '#575247',
    roadStripe: '#ccab60',
    bridgeDeck: '#5c5953',
    bridgeSteel: '#8f8b81',
    ambientTint: 'rgba(220, 160, 75, 0.04)',
  },
};
