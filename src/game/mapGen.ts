import { BRIDGE_MAX_HP, HQ_MAX_HP, MAP_COLS, MAP_ROWS, TILE_SIZE } from './constants';
import { Bridge, CommandHQ, MapData, OilRig, RoadNode, TheaterId, TileKind, Vec2 } from './types';

function createRng(seed: number): () => number {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function tileCenter(col: number, row: number): Vec2 {
  return {
    x: col * TILE_SIZE + TILE_SIZE / 2,
    y: row * TILE_SIZE + TILE_SIZE / 2,
  };
}

function setTile(tiles: TileKind[], col: number, row: number, kind: TileKind) {
  if (col >= 0 && col < MAP_COLS && row >= 0 && row < MAP_ROWS) {
    tiles[row * MAP_COLS + col] = kind;
  }
}

function paintRoadSegment(
  tiles: TileKind[],
  c0: number,
  r0: number,
  c1: number,
  r1: number
) {
  let c = c0;
  let r = r0;
  const maxSteps = MAP_COLS + MAP_ROWS + 10;
  let steps = 0;
  while ((c !== c1 || r !== r1) && steps < maxSteps) {
    steps++;
    const idx = r * MAP_COLS + c;
    if (tiles[idx] !== 'water' && tiles[idx] !== 'bridge') {
      tiles[idx] = 'road';
    }
    if (c !== c1) {
      c += c < c1 ? 1 : -1;
    } else if (r !== r1) {
      r += r < r1 ? 1 : -1;
    }
  }
  const endIdx = r1 * MAP_COLS + c1;
  if (tiles[endIdx] !== 'water' && tiles[endIdx] !== 'bridge') {
    tiles[endIdx] = 'road';
  }
}

export function generateMap(theater: TheaterId, seed = 104729): MapData {
  const effectiveSeed =
    theater === 'kirkuk'
      ? 104729
      : theater === 'suez'
        ? 229403
        : theater === 'newyork'
          ? 778121
          : seed;
  const rng = createRng(effectiveSeed);

  const tiles: TileKind[] = new Array(MAP_COLS * MAP_ROWS).fill('ground');
  const width = MAP_COLS * TILE_SIZE;
  const height = MAP_ROWS * TILE_SIZE;

  // River center column varies gently by row (1 central river separating west & east banks)
  const riverCols: number[] = new Array(MAP_ROWS).fill(Math.floor(MAP_COLS / 2));
  const riverHalfWidth = theater === 'suez' ? 2 : 2;
  const bendAmp = theater === 'suez' ? 1.0 : theater === 'newyork' ? 2.2 : 2.6;
  const phase = rng() * Math.PI * 2;

  for (let r = 0; r < MAP_ROWS; r++) {
    const t = r / MAP_ROWS;
    const offset = Math.round(Math.sin(t * Math.PI * 2 + phase) * bendAmp);
    const centerCol = Math.floor(MAP_COLS / 2) + offset;
    riverCols[r] = centerCol;
    for (let dc = -riverHalfWidth; dc <= riverHalfWidth; dc++) {
      setTile(tiles, centerCol + dc, r, 'water');
    }
  }

  // Decide bridge rows (3 bridges in Kirkuk / NewYork / Procedural, 2 heavy canal bridges in Suez)
  const bridgeRows =
    theater === 'suez'
      ? [9, 22]
      : theater === 'procedural'
        ? [
            5 + Math.floor(rng() * 3),
            14 + Math.floor(rng() * 4),
            24 + Math.floor(rng() * 3),
          ]
        : [6, 16, 25];

  const bridges: Bridge[] = [];
  const roadNodes: Record<string, RoadNode> = {};

  const addNode = (id: string, col: number, row: number, bridgeId?: string): RoadNode => {
    const pos = tileCenter(col, row);
    const node: RoadNode = { id, x: pos.x, y: pos.y, neighbors: [], bridgeId };
    roadNodes[id] = node;
    return node;
  };

  const linkNodes = (aId: string, bId: string, paint = true) => {
    const a = roadNodes[aId];
    const b = roadNodes[bId];
    if (!a || !b) return;
    if (!a.neighbors.includes(bId)) a.neighbors.push(bId);
    if (!b.neighbors.includes(aId)) b.neighbors.push(aId);
    if (paint) {
      const ac = Math.floor(a.x / TILE_SIZE);
      const ar = Math.floor(a.y / TILE_SIZE);
      const bc = Math.floor(b.x / TILE_SIZE);
      const br = Math.floor(b.y / TILE_SIZE);
      paintRoadSegment(tiles, ac, ar, bc, br);
    }
  };

  // Player HQ (West bank) and Enemy HQ (East bank)
  const playerHqCol = 5;
  const playerHqRow = theater === 'newyork' ? 16 : 15;
  const enemyHqCol = MAP_COLS - 6;
  const enemyHqRow = theater === 'newyork' ? 15 : 16;

  // Concrete aprons around both HQs
  for (let dr = -2; dr <= 2; dr++) {
    for (let dc = -2; dc <= 2; dc++) {
      setTile(tiles, playerHqCol + dc, playerHqRow + dr, 'concrete');
      setTile(tiles, enemyHqCol + dc, enemyHqRow + dr, 'concrete');
    }
  }

  // New York Harbor adds urban concrete docks along both riverbanks
  if (theater === 'newyork') {
    for (let r = 2; r < MAP_ROWS - 2; r++) {
      const rc = riverCols[r];
      setTile(tiles, rc - riverHalfWidth - 1, r, 'concrete');
      setTile(tiles, rc + riverHalfWidth + 1, r, 'concrete');
    }
  }

  addNode('hq_player', playerHqCol, playerHqRow);
  addNode('hq_enemy', enemyHqCol, enemyHqRow);

  // West & East spine highway junctions aligned with bridge rows
  const westSpineCol = 14;
  const eastSpineCol = MAP_COLS - 15;

  for (let i = 0; i < bridgeRows.length; i++) {
    const br = bridgeRows[i];
    const rc = riverCols[br];
    const westCol = rc - riverHalfWidth - 1;
    const eastCol = rc + riverHalfWidth + 1;
    const bridgeId = `bridge_${i}`;

    const bridgeTiles: Array<{ col: number; row: number }> = [];
    for (let c = rc - riverHalfWidth; c <= rc + riverHalfWidth; c++) {
      setTile(tiles, c, br, 'bridge');
      setTile(tiles, c, br - 1, 'water');
      setTile(tiles, c, br + 1, 'water');
      bridgeTiles.push({ col: c, row: br });
    }

    const leftX = (rc - riverHalfWidth) * TILE_SIZE;
    const bridgeW = (riverHalfWidth * 2 + 1) * TILE_SIZE;
    const centerY = br * TILE_SIZE + TILE_SIZE / 2;

    bridges.push({
      id: bridgeId,
      name: i === 0 ? 'North Crossing' : i === bridgeRows.length - 1 ? 'South Crossing' : 'Central Span',
      x: leftX + bridgeW / 2,
      y: centerY,
      width: bridgeW,
      height: TILE_SIZE + 12,
      orientation: 'horizontal',
      hp: BRIDGE_MAX_HP,
      maxHp: BRIDGE_MAX_HP,
      status: 'intact',
      rebuildProgress: 0,
      hitFlash: 0,
      tiles: bridgeTiles,
    });

    addNode(`w_spine_${i}`, westSpineCol, br);
    addNode(`b_west_${i}`, westCol, br);
    addNode(`b_mid_${i}`, rc, br, bridgeId);
    addNode(`b_east_${i}`, eastCol, br);
    addNode(`e_spine_${i}`, eastSpineCol, br);

    linkNodes(`w_spine_${i}`, `b_west_${i}`);
    linkNodes(`b_west_${i}`, `b_mid_${i}`, false);
    linkNodes(`b_mid_${i}`, `b_east_${i}`, false);
    linkNodes(`b_east_${i}`, `e_spine_${i}`);

    if (i > 0) {
      linkNodes(`w_spine_${i - 1}`, `w_spine_${i}`);
      linkNodes(`e_spine_${i - 1}`, `e_spine_${i}`);
    }
  }

  // Connect HQs to nearest spine hub
  const midHub = Math.floor(bridgeRows.length / 2);
  addNode('w_hq_junc', westSpineCol, playerHqRow);
  addNode('e_hq_junc', eastSpineCol, enemyHqRow);
  linkNodes('hq_player', 'w_hq_junc');
  linkNodes('w_hq_junc', `w_spine_${midHub}`);
  if (bridgeRows.length === 2) {
    linkNodes('w_hq_junc', 'w_spine_0');
    linkNodes('w_hq_junc', 'w_spine_1');
  }
  linkNodes('hq_enemy', 'e_hq_junc');
  linkNodes('e_hq_junc', `e_spine_${midHub}`);
  if (bridgeRows.length === 2) {
    linkNodes('e_hq_junc', 'e_spine_0');
    linkNodes('e_hq_junc', 'e_spine_1');
  }

  // Place 6 Oil Rigs:
  // 1 Starter Player Rig (West safe), 1 Starter Enemy Rig (East safe),
  // 2 Contested West-Bank Rigs (near north/south bridges), 2 Contested East-Bank Rigs (enemy supply hubs!)
  const rigs: OilRig[] = [];
  const rigConfigs: Array<{
    id: string;
    col: number;
    row: number;
    owner: 'player' | 'enemy' | 'neutral';
    connectTo: string;
  }> = [
    {
      id: 'rig_p_home',
      col: 9,
      row: Math.max(4, bridgeRows[0] + 1),
      owner: 'player',
      connectTo: 'w_spine_0',
    },
    {
      id: 'rig_p_south',
      col: 18,
      row: Math.min(MAP_ROWS - 5, bridgeRows[bridgeRows.length - 1] - 1),
      owner: 'neutral',
      connectTo: `w_spine_${bridgeRows.length - 1}`,
    },
    {
      id: 'rig_w_mid',
      col: riverCols[bridgeRows[0]] - riverHalfWidth - 4,
      row: Math.max(3, bridgeRows[0] - 2),
      owner: 'neutral',
      connectTo: 'b_west_0',
    },
    {
      id: 'rig_e_mid',
      col: riverCols[bridgeRows[bridgeRows.length - 1]] + riverHalfWidth + 4,
      row: Math.min(MAP_ROWS - 4, bridgeRows[bridgeRows.length - 1] + 2),
      owner: 'neutral',
      connectTo: `b_east_${bridgeRows.length - 1}`,
    },
    {
      id: 'rig_e_north',
      col: MAP_COLS - 19,
      row: Math.max(4, bridgeRows[0] + 1),
      owner: 'enemy',
      connectTo: 'e_spine_0',
    },
    {
      id: 'rig_e_home',
      col: MAP_COLS - 10,
      row: Math.min(MAP_ROWS - 5, bridgeRows[bridgeRows.length - 1] - 1),
      owner: 'enemy',
      connectTo: `e_spine_${bridgeRows.length - 1}`,
    },
  ];

  // For procedural skirmish, add slight deterministic variation to neutral rig positions
  if (theater === 'procedural') {
    rigConfigs[1].col += Math.floor((rng() - 0.5) * 3);
    rigConfigs[2].row = Math.max(3, Math.min(MAP_ROWS - 4, rigConfigs[2].row + Math.floor((rng() - 0.5) * 3)));
    rigConfigs[3].row = Math.max(3, Math.min(MAP_ROWS - 4, rigConfigs[3].row + Math.floor((rng() - 0.5) * 3)));
  }

  for (const cfg of rigConfigs) {
    // Clamp away from water
    let col = Math.max(3, Math.min(MAP_COLS - 4, cfg.col));
    const row = Math.max(3, Math.min(MAP_ROWS - 4, cfg.row));
    if (tiles[row * MAP_COLS + col] === 'water' || tiles[row * MAP_COLS + col] === 'bridge') {
      col = col < MAP_COLS / 2 ? col - 3 : col + 3;
    }

    for (let dr = -1; dr <= 1; dr++) {
      for (let dc = -1; dc <= 1; dc++) {
        const idx = (row + dr) * MAP_COLS + (col + dc);
        if (tiles[idx] === 'ground') {
          tiles[idx] = 'oilfield';
        }
      }
    }

    const nodeId = `node_${cfg.id}`;
    addNode(nodeId, col, row);
    linkNodes(nodeId, cfg.connectTo);

    const pos = tileCenter(col, row);
    rigs.push({
      id: cfg.id,
      x: pos.x,
      y: pos.y,
      owner: cfg.owner,
      captureProgress: cfg.owner === 'player' ? 100 : cfg.owner === 'enemy' ? -100 : 0,
      captureFaction: cfg.owner,
      storedBarrels: cfg.owner === 'neutral' ? 20 : 40,
      maxBarrels: 80,
      pumpPhase: rng() * Math.PI * 2,
      roadNodeId: nodeId,
      truckCooldown: cfg.owner === 'player' ? 0.5 : 2.5,
      isBurning: theater === 'kirkuk' && rng() < 0.35,
    });
  }

  // Atmospheric burning oil wells (signature WarFront Iraq aesthetic!)
  const burningWells: Vec2[] = [];
  const wellCount = theater === 'kirkuk' ? 7 : theater === 'procedural' ? 4 : 2;
  for (let i = 0; i < wellCount; i++) {
    const col = 3 + Math.floor(rng() * (MAP_COLS - 6));
    const row = 2 + Math.floor(rng() * (MAP_ROWS - 4));
    if (tiles[row * MAP_COLS + col] === 'ground') {
      const pos = tileCenter(col, row);
      burningWells.push(pos);
      tiles[row * MAP_COLS + col] = 'oilfield';
    }
  }

  const pPos = tileCenter(playerHqCol, playerHqRow);
  const ePos = tileCenter(enemyHqCol, enemyHqRow);

  const playerHQ: CommandHQ = {
    faction: 'player',
    x: pPos.x,
    y: pPos.y,
    hp: HQ_MAX_HP,
    maxHp: HQ_MAX_HP,
    roadNodeId: 'hq_player',
    radarAngle: 0,
    hitFlash: 0,
  };

  const enemyHQ: CommandHQ = {
    faction: 'enemy',
    x: ePos.x,
    y: ePos.y,
    hp: HQ_MAX_HP,
    maxHp: HQ_MAX_HP,
    roadNodeId: 'hq_enemy',
    radarAngle: Math.PI,
    hitFlash: 0,
  };

  return {
    theater,
    seed: effectiveSeed,
    cols: MAP_COLS,
    rows: MAP_ROWS,
    tileSize: TILE_SIZE,
    width,
    height,
    tiles,
    roadNodes,
    bridges,
    rigs,
    playerHQ,
    enemyHQ,
    burningWells,
  };
}
