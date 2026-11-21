import { Bridge, MapData, TileKind } from './types';

/**
 * Shortest-path routing along the road network for physical oil supply trucks.
 * Crucially, any node lying on a destroyed bridge is impassable — embodying
 * WarFront's core rule: "A blown bridge starves an army faster than any tank."
 */
export function findRoadPath(
  map: MapData,
  startNodeId: string,
  goalNodeId: string
): string[] | null {
  if (startNodeId === goalNodeId) return [startNodeId];
  const nodes = map.roadNodes;
  if (!nodes[startNodeId] || !nodes[goalNodeId]) return null;

  const bridgeById = new Map<string, Bridge>();
  for (const b of map.bridges) bridgeById.set(b.id, b);

  const isPassableNode = (nodeId: string): boolean => {
    const node = nodes[nodeId];
    if (!node) return false;
    if (node.bridgeId) {
      const bridge = bridgeById.get(node.bridgeId);
      if (bridge && bridge.status !== 'intact') return false;
    }
    return true;
  };

  if (!isPassableNode(startNodeId) || !isPassableNode(goalNodeId)) {
    return null;
  }

  // Dijkstra over road graph using Euclidean distances
  const dist = new Map<string, number>();
  const prev = new Map<string, string>();
  const visited = new Set<string>();
  const open: string[] = [startNodeId];
  dist.set(startNodeId, 0);

  while (open.length > 0) {
    let bestIdx = 0;
    let bestDist = dist.get(open[0]) ?? Infinity;
    for (let i = 1; i < open.length; i++) {
      const d = dist.get(open[i]) ?? Infinity;
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }

    const current = open.splice(bestIdx, 1)[0];
    if (visited.has(current)) continue;
    visited.add(current);

    if (current === goalNodeId) {
      const path: string[] = [];
      let cur: string | undefined = goalNodeId;
      while (cur) {
        path.push(cur);
        cur = prev.get(cur);
      }
      path.reverse();
      return path;
    }

    const curNode = nodes[current];
    for (const nextId of curNode.neighbors) {
      if (visited.has(nextId) || !isPassableNode(nextId)) continue;
      const nextNode = nodes[nextId];
      const stepDist = Math.hypot(nextNode.x - curNode.x, nextNode.y - curNode.y);
      const cand = bestDist + stepDist;
      if (cand < (dist.get(nextId) ?? Infinity)) {
        dist.set(nextId, cand);
        prev.set(nextId, current);
        open.push(nextId);
      }
    }
  }

  return null;
}

export function getTileAtWorld(map: MapData, x: number, y: number): TileKind {
  const col = Math.floor(x / map.tileSize);
  const row = Math.floor(y / map.tileSize);
  if (col < 0 || col >= map.cols || row < 0 || row >= map.rows) return 'water';
  return map.tiles[row * map.cols + col];
}

export function getBridgeAtWorld(map: MapData, x: number, y: number, pad = 6): Bridge | null {
  for (const b of map.bridges) {
    if (
      Math.abs(x - b.x) <= b.width / 2 + pad &&
      Math.abs(y - b.y) <= b.height / 2 + pad
    ) {
      return b;
    }
  }
  return null;
}

export function isPointPassableForLand(map: MapData, x: number, y: number): boolean {
  if (x < 24 || x > map.width - 24 || y < 24 || y > map.height - 24) return false;
  const tile = getTileAtWorld(map, x, y);
  if (tile === 'water') return false;
  if (tile === 'bridge') {
    const bridge = getBridgeAtWorld(map, x, y, 4);
    if (bridge && bridge.status !== 'intact') return false;
  }
  return true;
}

/**
 * Finds the nearest intact bridge to help land units route around the river
 * when ordered to move to the opposite bank.
 */
export function findNearestIntactBridge(map: MapData, fromX: number, fromY: number, toX: number, toY: number): Bridge | null {
  let best: Bridge | null = null;
  let bestCost = Infinity;
  for (const b of map.bridges) {
    if (b.status !== 'intact') continue;
    const cost = Math.hypot(b.x - fromX, b.y - fromY) + Math.hypot(toX - b.x, toY - b.y);
    if (cost < bestCost) {
      bestCost = cost;
      best = b;
    }
  }
  return best;
}

export function isOppositeRiverSide(map: MapData, x1: number, x2: number): boolean {
  const mid = map.width * 0.5;
  return (x1 < mid - 60 && x2 > mid + 60) || (x1 > mid + 60 && x2 < mid - 60);
}
