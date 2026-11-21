import { THEATER_PALETTES, TILE_SIZE, VETERANCY_RANKS } from './constants';
import { Bridge, CommandHQ, MapData, OilRig, Unit, Vec2 } from './types';
import { WarFrontSimulation } from './simulation';

export interface CameraState {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface RenderOverlayState {
  selectionBox: { x1: number; y1: number; x2: number; y2: number } | null;
  hoverWorld: Vec2 | null;
}

export class WarFrontRenderer {
  private terrainCanvas: HTMLCanvasElement | null = null;
  private minimapCacheCanvas: HTMLCanvasElement | null = null;
  private cachedMapKey = '';

  private ensureTerrainCache(map: MapData) {
    const key = `${map.theater}_${map.seed}`;
    if (this.terrainCanvas && this.cachedMapKey === key) return;

    const canvas = document.createElement('canvas');
    canvas.width = map.width;
    canvas.height = map.height;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const pal = THEATER_PALETTES[map.theater];
    const ts = map.tileSize;

    // Seeded deterministic pixel texture helper
    const hash = (x: number, y: number) => {
      const n = Math.sin(x * 127.1 + y * 311.7 + map.seed * 0.13) * 43758.5453;
      return n - Math.floor(n);
    };

    for (let r = 0; r < map.rows; r++) {
      for (let c = 0; c < map.cols; c++) {
        const tile = map.tiles[r * map.cols + c];
        const x = c * ts;
        const y = r * ts;
        const h = hash(c, r);

        if (tile === 'water' || tile === 'bridge') {
          ctx.fillStyle = h > 0.5 ? pal.waterDeep : pal.waterShallow;
          ctx.fillRect(x, y, ts, ts);
          // Riverbank shoreline edge next to ground
          const leftTile = c > 0 ? map.tiles[r * map.cols + (c - 1)] : 'water';
          const rightTile = c < map.cols - 1 ? map.tiles[r * map.cols + (c + 1)] : 'water';
          if (leftTile !== 'water' && leftTile !== 'bridge') {
            ctx.fillStyle = pal.groundDetail;
            ctx.fillRect(x, y, 6, ts);
            ctx.fillStyle = pal.waterFoam;
            ctx.fillRect(x + 6, y, 3, ts);
          }
          if (rightTile !== 'water' && rightTile !== 'bridge') {
            ctx.fillStyle = pal.groundDetail;
            ctx.fillRect(x + ts - 6, y, 6, ts);
            ctx.fillStyle = pal.waterFoam;
            ctx.fillRect(x + ts - 9, y, 3, ts);
          }
        } else if (tile === 'road') {
          ctx.fillStyle = pal.roadEdge;
          ctx.fillRect(x, y, ts, ts);
          ctx.fillStyle = pal.roadAsphalt;
          ctx.fillRect(x + 4, y + 4, ts - 8, ts - 8);
          // Connect asphalt seamlessly to neighboring road/bridge/concrete tiles
          const isRoadLike = (cc: number, rr: number) => {
            if (cc < 0 || cc >= map.cols || rr < 0 || rr >= map.rows) return false;
            const t = map.tiles[rr * map.cols + cc];
            return t === 'road' || t === 'bridge' || t === 'concrete';
          };
          if (isRoadLike(c - 1, r)) ctx.fillRect(x, y + 4, 6, ts - 8);
          if (isRoadLike(c + 1, r)) ctx.fillRect(x + ts - 6, y + 4, 6, ts - 8);
          if (isRoadLike(c, r - 1)) ctx.fillRect(x + 4, y, ts - 8, 6);
          if (isRoadLike(c, r + 1)) ctx.fillRect(x + 4, y + ts - 6, ts - 8, 6);

          // Subtle pixel-art dashed yellow road markings
          ctx.fillStyle = pal.roadStripe;
          if (isRoadLike(c - 1, r) || isRoadLike(c + 1, r)) {
            ctx.fillRect(x + 8, y + ts / 2 - 1, 10, 2);
            ctx.fillRect(x + 28, y + ts / 2 - 1, 10, 2);
          }
          if (isRoadLike(c, r - 1) || isRoadLike(c, r + 1)) {
            ctx.fillRect(x + ts / 2 - 1, y + 8, 2, 10);
            ctx.fillRect(x + ts / 2 - 1, y + 28, 2, 10);
          }
        } else if (tile === 'concrete') {
          ctx.fillStyle = pal.concrete;
          ctx.fillRect(x, y, ts, ts);
          ctx.strokeStyle = 'rgba(20, 20, 18, 0.25)';
          ctx.lineWidth = 1;
          ctx.strokeRect(x + 0.5, y + 0.5, ts - 1, ts - 1);
          // Corner rivets / slab seam
          ctx.fillStyle = 'rgba(255,255,255,0.08)';
          ctx.fillRect(x + 2, y + 2, ts - 4, 2);
        } else if (tile === 'oilfield') {
          ctx.fillStyle = pal.oilfield;
          ctx.fillRect(x, y, ts, ts);
          // Dark crude oil puddles
          ctx.fillStyle = '#1d1a16';
          ctx.fillRect(x + 6 + Math.floor(h * 14), y + 8 + Math.floor(h * 12), 14, 8);
          ctx.fillStyle = 'rgba(130, 110, 75, 0.25)';
          ctx.fillRect(x + 4, y + 4, 8, 4);
        } else {
          // Organic pixel-art terrain shading (no rigid checkerboard)
          const blob =
            Math.sin(c * 0.42 + map.seed * 0.01) * Math.cos(r * 0.37) +
            (h - 0.5) * 0.65;
          ctx.fillStyle = blob > 0.15 ? pal.groundA : pal.groundB;
          ctx.fillRect(x, y, ts, ts);

          // Crisp pixel-art sub-blocks (4x4 / 8x4 ridges, pebbles, dune shadows)
          if (h > 0.55) {
            ctx.fillStyle = pal.groundDetail;
            ctx.fillRect(x + Math.floor(h * 28), y + Math.floor(((h * 19) % 1) * 32), 8, 4);
            ctx.fillRect(x + Math.floor(((h * 11) % 1) * 34), y + Math.floor(h * 24), 4, 4);
          }
          if (h < 0.22) {
            ctx.fillStyle = 'rgba(255, 240, 200, 0.12)';
            ctx.fillRect(x + 8 + Math.floor(h * 40), y + 16, 14, 3);
            ctx.fillRect(x + 12 + Math.floor(h * 30), y + 20, 8, 2);
          }
          if (h > 0.86) {
            // Small rocky outcrop or desert scrub pixel cluster
            ctx.fillStyle = '#3d3a2c';
            ctx.fillRect(x + 18, y + 18, 6, 6);
            ctx.fillStyle = '#5c5840';
            ctx.fillRect(x + 18, y + 16, 4, 3);
          }
        }
      }
    }

    // Subtle tactical sector gridlines (very faint)
    ctx.strokeStyle = 'rgba(15, 16, 12, 0.06)';
    ctx.lineWidth = 1;
    for (let x = 0; x < map.width; x += ts * 4) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, map.height);
      ctx.stroke();
    }
    for (let y = 0; y < map.height; y += ts * 4) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(map.width, y);
      ctx.stroke();
    }

    this.terrainCanvas = canvas;
    this.minimapCacheCanvas = null;
    this.cachedMapKey = key;
  }

  public render(
    ctx: CanvasRenderingContext2D,
    sim: WarFrontSimulation,
    cam: CameraState,
    overlay: RenderOverlayState
  ) {
    this.ensureTerrainCache(sim.map);
    const pal = THEATER_PALETTES[sim.map.theater];

    ctx.save();
    ctx.imageSmoothingEnabled = false;

    // Camera trauma shake (trauma * trauma)
    const shakeMag = sim.cameraTrauma * sim.cameraTrauma * 12;
    const shakeX = shakeMag > 0.1 ? (Math.random() * 2 - 1) * shakeMag : 0;
    const shakeY = shakeMag > 0.1 ? (Math.random() * 2 - 1) * shakeMag : 0;

    ctx.fillStyle = '#11130e';
    ctx.fillRect(0, 0, cam.width, cam.height);

    ctx.translate(Math.round(-cam.x + shakeX), Math.round(-cam.y + shakeY));

    // 1. Cached pixel-art terrain (clipped strictly to visible viewport for fast rendering)
    if (this.terrainCanvas) {
      const sx = Math.max(0, Math.floor(cam.x - 16));
      const sy = Math.max(0, Math.floor(cam.y - 16));
      const sw = Math.min(sim.map.width - sx, Math.ceil(cam.width + 32));
      const sh = Math.min(sim.map.height - sy, Math.ceil(cam.height + 32));
      if (sw > 0 && sh > 0) {
        ctx.drawImage(this.terrainCanvas, sx, sy, sw, sh, sx, sy, sw, sh);
      }
    }

    // 2. Animated water wave glints (only visible river tiles)
    this.drawWaterRipples(ctx, sim.map, cam, sim.simTime, pal.waterFoam);

    // 3. Battle craters & crude oil slicks
    for (const c of sim.craters) {
      ctx.fillStyle = c.oilSlick ? 'rgba(16, 14, 12, 0.72)' : 'rgba(28, 22, 16, 0.55)';
      ctx.beginPath();
      ctx.ellipse(c.x, c.y, c.radius, c.radius * 0.72, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = 'rgba(0,0,0,0.35)';
      ctx.lineWidth = 2;
      ctx.stroke();
    }

    // 4. Destructible steel bridges
    for (const b of sim.map.bridges) {
      this.drawBridge(ctx, b, pal, sim.buildMode === 'rebuild_bridge', sim.simTime);
    }

    // 5. Burning ambient oil wellheads (Iraq theater signature)
    for (const w of sim.map.burningWells) {
      this.drawBurningWell(ctx, w, sim.simTime);
    }

    // 6. Oil Rigs (pumpjacks + barrel silos + capture rings)
    for (const rig of sim.map.rigs) {
      this.drawOilRig(ctx, rig);
    }

    // 7. Command HQs
    this.drawHQ(ctx, sim.map.playerHQ);
    this.drawHQ(ctx, sim.map.enemyHQ);

    // 8. Artillery windup telegraph rings (visible warning before rocket impact)
    for (const u of sim.units) {
      if (u.alive && u.windupTimer > 0 && u.windupTarget) {
        const progress = 1 - u.windupTimer / 0.52;
        ctx.save();
        ctx.strokeStyle = u.faction === 'enemy' ? 'rgba(239, 68, 68, 0.9)' : 'rgba(245, 180, 65, 0.85)';
        ctx.lineWidth = 2.5;
        ctx.setLineDash([6, 4]);
        ctx.beginPath();
        ctx.arc(u.windupTarget.x, u.windupTarget.y, 58 * (1 - progress * 0.25), 0, Math.PI * 2);
        ctx.stroke();
        ctx.fillStyle = u.faction === 'enemy' ? 'rgba(239, 68, 68, 0.16)' : 'rgba(245, 180, 65, 0.14)';
        ctx.fill();
        ctx.restore();
      }
    }

    // 9. Right-click order pulse
    if (sim.orderPulse) {
      const p = sim.orderPulse;
      const t = 1 - p.timer / 0.55;
      ctx.save();
      ctx.strokeStyle = p.color;
      ctx.globalAlpha = Math.max(0, 1 - t);
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.arc(p.x, p.y, 8 + t * 22, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    }

    // 10. Units (sorted gently so trucks & armor layer cleanly)
    for (const u of sim.units) {
      this.drawUnit(ctx, u, sim.simTime);
    }

    // 11. Projectiles
    for (const pr of sim.projectiles) {
      ctx.save();
      if (pr.kind === 'bullet') {
        ctx.strokeStyle = '#ffe58f';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(pr.x, pr.y);
        ctx.lineTo(pr.x - pr.vx * 0.025, pr.y - pr.vy * 0.025);
        ctx.stroke();
      } else if (pr.kind === 'shell') {
        ctx.fillStyle = '#fff0b3';
        ctx.fillRect(pr.x - 3, pr.y - 3, 6, 6);
        ctx.strokeStyle = '#ff922b';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(pr.x, pr.y);
        ctx.lineTo(pr.x - pr.vx * 0.035, pr.y - pr.vy * 0.035);
        ctx.stroke();
      } else {
        // Rocket projectile with glowing tail
        const a = Math.atan2(pr.vy, pr.vx);
        ctx.translate(pr.x, pr.y);
        ctx.rotate(a);
        ctx.fillStyle = '#e8e2d5';
        ctx.fillRect(-7, -2.5, 12, 5);
        ctx.fillStyle = '#ff6b22';
        ctx.fillRect(-12, -2, 5, 4);
      }
      ctx.restore();
    }

    // 12. Pooled Particles (smoke, explosions, oil splashes, shock rings)
    for (const pt of sim.particles) {
      if (!pt.active) continue;
      const t = 1 - pt.life / pt.maxLife;
      const curSize = pt.size + (pt.endSize - pt.size) * t;
      ctx.save();
      ctx.globalAlpha = pt.alpha * (pt.kind === 'smoke' ? 0.65 : 0.92);
      if (pt.kind === 'ring') {
        ctx.strokeStyle = pt.color;
        ctx.lineWidth = 3 * pt.alpha;
        ctx.beginPath();
        ctx.arc(pt.x, pt.y, curSize, 0, Math.PI * 2);
        ctx.stroke();
      } else {
        ctx.fillStyle = pt.color;
        const s = Math.max(2, Math.round(curSize));
        ctx.fillRect(Math.round(pt.x - s / 2), Math.round(pt.y - s / 2), s, s);
      }
      ctx.restore();
    }

    // 13. Turret placement ghost preview
    if (sim.phase === 'playing' && sim.buildMode === 'turret' && overlay.hoverWorld) {
      const { x, y } = overlay.hoverWorld;
      const valid = sim.canPlaceTurretAt(x, y);
      ctx.save();
      ctx.strokeStyle = valid ? 'rgba(139, 212, 106, 0.85)' : 'rgba(239, 83, 80, 0.85)';
      ctx.fillStyle = valid ? 'rgba(139, 212, 106, 0.14)' : 'rgba(239, 83, 80, 0.14)';
      ctx.lineWidth = 2;
      ctx.setLineDash([6, 4]);
      ctx.beginPath();
      ctx.arc(x, y, 255, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.fillStyle = valid ? '#7bc950' : '#ef5350';
      ctx.fillRect(x - 14, y - 14, 28, 28);
      ctx.restore();
    }

    // 14. World-space floating oil delivery popups
    for (const fp of sim.floatingPopups) {
      const alpha = Math.min(1, fp.life / (fp.maxLife * 0.45));
      ctx.save();
      ctx.globalAlpha = alpha;
      ctx.font = '700 15px "JetBrains Mono", monospace';
      ctx.textAlign = 'center';
      ctx.lineWidth = 3;
      ctx.strokeStyle = '#11130e';
      ctx.strokeText(fp.text, fp.x, fp.y);
      ctx.fillStyle = fp.color;
      ctx.fillText(fp.text, fp.x, fp.y);
      ctx.restore();
    }

    // 15. Marquee drag selection box
    if (overlay.selectionBox) {
      const { x1, y1, x2, y2 } = overlay.selectionBox;
      const bx = Math.min(x1, x2);
      const by = Math.min(y1, y2);
      const bw = Math.abs(x2 - x1);
      const bh = Math.abs(y2 - y1);
      ctx.save();
      ctx.fillStyle = 'rgba(155, 224, 114, 0.14)';
      ctx.strokeStyle = '#a5e87c';
      ctx.lineWidth = 1.5;
      ctx.fillRect(bx, by, bw, bh);
      ctx.strokeRect(bx, by, bw, bh);
      ctx.restore();
    }

    ctx.restore();

    // Subtle theater atmospheric tint
    ctx.fillStyle = pal.ambientTint;
    ctx.fillRect(0, 0, cam.width, cam.height);
  }

  private drawWaterRipples(
    ctx: CanvasRenderingContext2D,
    map: MapData,
    cam: CameraState,
    time: number,
    foamColor: string
  ) {
    const startCol = Math.max(0, Math.floor(cam.x / TILE_SIZE));
    const endCol = Math.min(map.cols - 1, Math.ceil((cam.x + cam.width) / TILE_SIZE));
    const startRow = Math.max(0, Math.floor(cam.y / TILE_SIZE));
    const endRow = Math.min(map.rows - 1, Math.ceil((cam.y + cam.height) / TILE_SIZE));

    ctx.fillStyle = foamColor;
    ctx.globalAlpha = 0.25;
    for (let r = startRow; r <= endRow; r++) {
      for (let c = startCol; c <= endCol; c++) {
        if (map.tiles[r * map.cols + c] === 'water') {
          const shift = Math.floor(((time * 16 + r * 11 + c * 7) % 34));
          ctx.fillRect(c * TILE_SIZE + 8 + (shift % 22), r * TILE_SIZE + 14 + ((r * 7) % 18), 10, 2);
        }
      }
    }
    ctx.globalAlpha = 1;
  }

  private drawBridge(
    ctx: CanvasRenderingContext2D,
    b: Bridge,
    pal: (typeof THEATER_PALETTES)['kirkuk'],
    highlightRebuild: boolean,
    time: number
  ) {
    const left = Math.round(b.x - b.width / 2);
    const top = Math.round(b.y - b.height / 2);

    ctx.save();
    if (b.status === 'intact') {
      // Water drop shadow
      ctx.fillStyle = 'rgba(0, 0, 0, 0.38)';
      ctx.fillRect(left + 4, top + 8, b.width, b.height);

      // Deck & tarmac
      ctx.fillStyle = b.hitFlash > 0 ? '#fff5dc' : pal.bridgeDeck;
      ctx.fillRect(left, top, b.width, b.height);

      // Road asphalt center
      ctx.fillStyle = b.hitFlash > 0 ? '#ffdfa0' : pal.roadAsphalt;
      ctx.fillRect(left, top + 9, b.width, b.height - 18);

      // Steel truss rails top & bottom
      ctx.fillStyle = pal.bridgeSteel;
      ctx.fillRect(left - 4, top, b.width + 8, 7);
      ctx.fillRect(left - 4, top + b.height - 7, b.width + 8, 7);

      // Crossbeam ribs
      ctx.fillStyle = '#302e2a';
      for (let x = left + 12; x < left + b.width - 8; x += 26) {
        ctx.fillRect(x, top + 1, 4, 5);
        ctx.fillRect(x, top + b.height - 6, 4, 5);
      }

      // Dashed highway stripes
      ctx.fillStyle = pal.roadStripe;
      for (let x = left + 14; x < left + b.width - 14; x += 28) {
        ctx.fillRect(x, b.y - 1, 14, 2);
      }

      // Damage cracks & HP bar when below 100%
      if (b.hp < b.maxHp) {
        const pct = Math.max(0, b.hp / b.maxHp);
        const bw = 64;
        ctx.fillStyle = 'rgba(12, 14, 10, 0.85)';
        ctx.fillRect(b.x - bw / 2 - 1, top - 13, bw + 2, 7);
        ctx.fillStyle = pct > 0.5 ? '#eab308' : '#ef4444';
        ctx.fillRect(b.x - bw / 2, top - 12, Math.round(bw * pct), 5);
      }
    } else {
      // Blown bridge: broken bank abutments + sunken debris in river
      ctx.fillStyle = pal.bridgeDeck;
      ctx.fillRect(left - 4, top + 4, 22, b.height - 8);
      ctx.fillRect(left + b.width - 18, top + 4, 22, b.height - 8);

      // Jagged broken edges
      ctx.fillStyle = '#252320';
      ctx.fillRect(left + 14, top + 8, 7, 14);
      ctx.fillRect(left + 12, top + 28, 10, 14);
      ctx.fillRect(left + b.width - 21, top + 10, 8, 16);
      ctx.fillRect(left + b.width - 24, top + 30, 9, 14);

      // Submerged steel girders + foaming water
      ctx.fillStyle = 'rgba(22, 26, 28, 0.6)';
      ctx.fillRect(b.x - 42, b.y - 10, 30, 8);
      ctx.fillRect(b.x + 8, b.y + 4, 34, 7);
      ctx.fillStyle = 'rgba(165, 218, 232, 0.45)';
      ctx.fillRect(b.x - 44, b.y - 12 + Math.sin(time * 4) * 2, 34, 3);
      ctx.fillRect(b.x + 6, b.y + 11 + Math.cos(time * 4) * 2, 36, 3);

      // Red "CUT" crosshair or Gold "REBUILD" frame
      if (highlightRebuild) {
        ctx.strokeStyle = '#f5c249';
        ctx.lineWidth = 2.5;
        ctx.setLineDash([8, 5]);
        ctx.strokeRect(left - 4, top - 4, b.width + 8, b.height + 8);
        ctx.setLineDash([]);
      } else {
        ctx.strokeStyle = 'rgba(239, 83, 80, 0.75)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(b.x - 10, b.y - 10);
        ctx.lineTo(b.x + 10, b.y + 10);
        ctx.moveTo(b.x + 10, b.y - 10);
        ctx.lineTo(b.x - 10, b.y + 10);
        ctx.stroke();
      }
    }
    ctx.restore();
  }

  private drawBurningWell(ctx: CanvasRenderingContext2D, pos: Vec2, time: number) {
    const flicker = 0.85 + Math.sin(time * 17 + pos.x) * 0.15;
    ctx.save();
    // Warm fire glow on desert sand
    const grad = ctx.createRadialGradient(pos.x, pos.y, 4, pos.x, pos.y, 46 * flicker);
    grad.addColorStop(0, 'rgba(255, 130, 30, 0.32)');
    grad.addColorStop(1, 'rgba(255, 90, 10, 0)');
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, 46 * flicker, 0, Math.PI * 2);
    ctx.fill();

    // Wellhead pipe
    ctx.fillStyle = '#1c1a18';
    ctx.fillRect(pos.x - 7, pos.y - 7, 14, 14);
    ctx.fillStyle = '#ff8a24';
    ctx.fillRect(pos.x - 4, pos.y - 5, 8, 8);
    ctx.fillStyle = '#ffe585';
    ctx.fillRect(pos.x - 2, pos.y - 3, 4, 4);
    ctx.restore();
  }

  private drawOilRig(ctx: CanvasRenderingContext2D, rig: OilRig) {
    const ownerColor =
      rig.owner === 'player' ? '#6cc758' : rig.owner === 'enemy' ? '#e5534b' : '#cbb986';

    ctx.save();
    ctx.translate(Math.round(rig.x), Math.round(rig.y));

    // Concrete oil pad
    ctx.fillStyle = '#2d2b27';
    ctx.fillRect(-26, -24, 52, 48);
    ctx.strokeStyle = ownerColor;
    ctx.lineWidth = 2;
    ctx.strokeRect(-26, -24, 52, 48);

    // Oil barrel tank with live fill indicator
    ctx.fillStyle = '#181715';
    ctx.fillRect(8, -16, 13, 30);
    const fillH = Math.round((rig.storedBarrels / rig.maxBarrels) * 26);
    ctx.fillStyle = '#e6a838';
    ctx.fillRect(10, 12 - fillH, 9, fillH);

    // Derrick steel frame
    ctx.fillStyle = '#4e4b45';
    ctx.fillRect(-18, -16, 20, 32);
    ctx.fillStyle = '#24221f';
    ctx.fillRect(-14, -12, 12, 24);

    // Animated rocking pumpjack beam
    const rock = Math.sin(rig.pumpPhase) * 6;
    ctx.fillStyle = '#9e9788';
    ctx.fillRect(-22, -4 + Math.round(rock * 0.4), 28, 6);
    ctx.fillStyle = ownerColor;
    ctx.fillRect(-22, -6 + Math.round(rock * 0.4), 7, 10);

    // Capture progress arc when contested / partially captured
    const absCap = Math.abs(rig.captureProgress);
    if (absCap > 2 && absCap < 100) {
      ctx.strokeStyle = rig.captureProgress > 0 ? '#78d464' : '#ef5350';
      ctx.lineWidth = 3.5;
      ctx.beginPath();
      ctx.arc(0, 0, 35, -Math.PI / 2, -Math.PI / 2 + (absCap / 100) * Math.PI * 2);
      ctx.stroke();
    }

    ctx.restore();
  }

  private drawHQ(ctx: CanvasRenderingContext2D, hq: CommandHQ) {
    const isPlayer = hq.faction === 'player';
    const primary = isPlayer ? '#589e47' : '#c9453e';
    const accent = isPlayer ? '#9ee386' : '#ff8c85';

    ctx.save();
    ctx.translate(Math.round(hq.x), Math.round(hq.y));

    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.4)';
    ctx.fillRect(-38, -32, 82, 72);

    // Fortified bunker base
    ctx.fillStyle = hq.hitFlash > 0 ? '#ffffff' : '#3a3b36';
    ctx.fillRect(-40, -36, 80, 72);
    ctx.strokeStyle = primary;
    ctx.lineWidth = 3;
    ctx.strokeRect(-40, -36, 80, 72);

    // Refinery twin oil silos
    ctx.fillStyle = '#22211e';
    ctx.beginPath();
    ctx.arc(-20, -14, 12, 0, Math.PI * 2);
    ctx.arc(-20, 14, 12, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = '#d49a35';
    ctx.lineWidth = 2;
    ctx.stroke();

    // Command tower roof
    ctx.fillStyle = primary;
    ctx.fillRect(0, -24, 30, 48);
    ctx.fillStyle = '#252622';
    ctx.fillRect(6, -18, 18, 36);

    // Rotating radar dish
    ctx.save();
    ctx.translate(15, 0);
    ctx.rotate(hq.radarAngle);
    ctx.fillStyle = accent;
    ctx.fillRect(-2, -11, 4, 22);
    ctx.fillRect(2, -4, 6, 8);
    ctx.restore();

    // HQ HP Bar
    const pct = Math.max(0, hq.hp / hq.maxHp);
    ctx.fillStyle = 'rgba(10, 12, 8, 0.9)';
    ctx.fillRect(-42, -50, 84, 8);
    ctx.fillStyle = isPlayer ? '#67c754' : '#e5534b';
    ctx.fillRect(-41, -49, Math.round(82 * pct), 6);

    ctx.restore();
  }

  private drawUnit(ctx: CanvasRenderingContext2D, u: Unit, time: number) {
    const isPlayer = u.faction === 'player';
    const bodyMain = isPlayer ? '#5d8a47' : '#b8423b';
    const bodyDark = isPlayer ? '#375429' : '#732622';
    const bodyLight = isPlayer ? '#8ac26b' : '#e3726b';

    ctx.save();
    ctx.translate(Math.round(u.x), Math.round(u.y));

    // KO wreckage dissolve transition
    if (!u.alive) {
      ctx.globalAlpha = Math.max(0, u.koTimer / 0.42);
      ctx.fillStyle = '#221e1b';
      ctx.fillRect(-12, -10, 24, 20);
      ctx.fillStyle = '#ff7b24';
      ctx.fillRect(-6, -6, 12, 12);
      ctx.restore();
      return;
    }

    // Selection tactical brackets
    if (u.selected) {
      const r = u.radius + 7;
      ctx.strokeStyle = '#a8f07e';
      ctx.lineWidth = 2;
      // Four crisp corner brackets
      const k = 6;
      ctx.beginPath();
      ctx.moveTo(-r, -r + k); ctx.lineTo(-r, -r); ctx.lineTo(-r + k, -r);
      ctx.moveTo(r - k, -r); ctx.lineTo(r, -r); ctx.lineTo(r, -r + k);
      ctx.moveTo(r, r - k); ctx.lineTo(r, r); ctx.lineTo(r - k, r);
      ctx.moveTo(-r + k, r); ctx.lineTo(-r, r); ctx.lineTo(-r, r - k);
      ctx.stroke();
    }

    // Ground shadow
    ctx.fillStyle = 'rgba(0, 0, 0, 0.34)';
    ctx.beginPath();
    ctx.ellipse(3, 5, u.radius + 1, u.radius * 0.78, 0, 0, Math.PI * 2);
    ctx.fill();

    // Unit chassis rotated to movement heading
    ctx.save();
    if (u.kind !== 'turret') {
      ctx.rotate(u.angle);
    }
    const flash = u.hitFlash > 0;

    if (u.kind === 'truck') {
      // Physical Oil Supply Truck
      ctx.fillStyle = '#181816';
      ctx.fillRect(-15, -10, 30, 20); // outer silhouette
      // Flatbed cargo bay
      ctx.fillStyle = flash ? '#fff' : '#42403b';
      ctx.fillRect(-13, -8, 17, 16);
      // Cab
      ctx.fillStyle = flash ? '#fff' : bodyMain;
      ctx.fillRect(5, -8, 9, 16);
      ctx.fillStyle = '#8cc0d4';
      ctx.fillRect(9, -6, 3, 12); // windshield

      // Visible oil barrels in the cargo bed (glow golden-amber when loaded!)
      const loaded = (u.cargoOil ?? 0) > 0;
      ctx.fillStyle = loaded ? '#e8aa35' : '#2b2a27';
      for (let bx = -11; bx <= -1; bx += 5) {
        ctx.fillRect(bx, -6, 4, 5);
        ctx.fillRect(bx, 1, 4, 5);
      }
    } else if (u.kind === 'scout') {
      // Fast Recon Humvee
      ctx.fillStyle = '#141512';
      ctx.fillRect(-12, -9, 24, 18);
      ctx.fillStyle = flash ? '#fff' : bodyMain;
      ctx.fillRect(-10, -7, 20, 14);
      ctx.fillStyle = bodyLight;
      ctx.fillRect(3, -5, 5, 10);
    } else if (u.kind === 'tank') {
      // Main Battle Tank treads + sloped hull
      ctx.fillStyle = '#1b1b18';
      ctx.fillRect(-16, -13, 32, 6);
      ctx.fillRect(-16, 7, 32, 6);
      ctx.fillStyle = flash ? '#fff' : bodyDark;
      ctx.fillRect(-14, -9, 28, 18);
      ctx.fillStyle = flash ? '#fff' : bodyMain;
      ctx.fillRect(-11, -7, 22, 14);
    } else if (u.kind === 'artillery') {
      // MLRS Rocket Truck
      ctx.fillStyle = '#171715';
      ctx.fillRect(-16, -11, 32, 22);
      ctx.fillStyle = flash ? '#fff' : bodyDark;
      ctx.fillRect(-14, -9, 28, 18);
      ctx.fillStyle = bodyMain;
      ctx.fillRect(6, -8, 7, 16);
    } else if (u.kind === 'engineer') {
      // Combat Engineer Vehicle with yellow/black hazard stripe
      ctx.fillStyle = '#161614';
      ctx.fillRect(-12, -9, 24, 18);
      ctx.fillStyle = flash ? '#fff' : bodyMain;
      ctx.fillRect(-10, -7, 20, 14);
      ctx.fillStyle = '#f0be3d';
      ctx.fillRect(5, -7, 4, 14);
      ctx.fillStyle = '#1a1a18';
      ctx.fillRect(5, -3, 4, 3);
      ctx.fillRect(5, 3, 4, 3);
    } else if (u.kind === 'turret') {
      // Stationary Concrete Pillbox
      ctx.fillStyle = '#22241f';
      ctx.fillRect(-15, -15, 30, 30);
      ctx.fillStyle = flash ? '#fff' : '#575952';
      ctx.fillRect(-12, -12, 24, 24);
      ctx.strokeStyle = bodyMain;
      ctx.lineWidth = 2;
      ctx.strokeRect(-12, -12, 24, 24);
    }
    ctx.restore();

    // Independent rotating turret / weapon mount
    if (u.kind !== 'truck') {
      ctx.save();
      ctx.rotate(u.turretAngle);
      const kick = Math.round(u.recoil * 4);
      if (u.kind === 'tank') {
        ctx.fillStyle = '#151613';
        ctx.fillRect(4 - kick, -3, 18, 6);
        ctx.fillStyle = bodyLight;
        ctx.fillRect(5 - kick, -2, 16, 4);
        ctx.fillStyle = bodyDark;
        ctx.fillRect(-8, -7, 15, 14);
        ctx.fillStyle = bodyMain;
        ctx.fillRect(-6, -5, 11, 10);
      } else if (u.kind === 'artillery') {
        ctx.fillStyle = '#2b2b27';
        ctx.fillRect(-12 - kick, -7, 18, 14);
        ctx.fillStyle = '#d98f32';
        ctx.fillRect(-10 - kick, -5, 14, 3);
        ctx.fillRect(-10 - kick, -1, 14, 3);
        ctx.fillRect(-10 - kick, 3, 14, 3);
      } else if (u.kind === 'scout') {
        ctx.fillStyle = '#252622';
        ctx.fillRect(0 - kick, -2, 12, 4);
        ctx.fillStyle = bodyLight;
        ctx.fillRect(-4, -4, 8, 8);
      } else if (u.kind === 'turret') {
        ctx.fillStyle = '#1a1b18';
        ctx.fillRect(2 - kick, -4, 15, 3);
        ctx.fillRect(2 - kick, 1, 15, 3);
        ctx.fillStyle = bodyMain;
        ctx.fillRect(-7, -7, 14, 14);
      }
      ctx.restore();
    }

    // Stranded supply truck hazard indicator (when bridge is blown!)
    if (u.kind === 'truck' && u.truckState === 'stranded') {
      const bob = Math.sin(time * 7) * 2;
      ctx.fillStyle = '#1a120a';
      ctx.fillRect(-8, -28 + bob, 16, 15);
      ctx.strokeStyle = '#f59e0b';
      ctx.lineWidth = 1.5;
      ctx.strokeRect(-8, -28 + bob, 16, 15);
      ctx.fillStyle = '#f59e0b';
      ctx.fillRect(-1.5, -25 + bob, 3, 6);
      ctx.fillRect(-1.5, -17 + bob, 3, 3);
    }

    // Promotion glow pulse ring
    if (u.promoFlash > 0) {
      ctx.save();
      ctx.strokeStyle = '#ffd659';
      ctx.globalAlpha = Math.min(1, u.promoFlash / 0.7);
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.arc(0, 0, u.radius + 9 + (1 - u.promoFlash / 0.7) * 8, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    }

    // Compact unit HP bar (always shown when damaged or selected)
    if (u.hp < u.maxHp || u.selected) {
      const pct = Math.max(0, u.hp / u.maxHp);
      const bw = 26;
      ctx.fillStyle = 'rgba(10, 12, 8, 0.85)';
      ctx.fillRect(-bw / 2 - 1, -u.radius - 11, bw + 2, 5);
      ctx.fillStyle = isPlayer ? '#73d65e' : '#ef5350';
      ctx.fillRect(-bw / 2, -u.radius - 10, Math.round(bw * pct), 3);

      // Selected unit XP progress bar toward next veterancy rank
      if (u.selected && u.kind !== 'truck' && u.rank < 3) {
        const curFloor = VETERANCY_RANKS[u.rank].xpRequired;
        const nextReq = VETERANCY_RANKS[u.rank + 1].xpRequired;
        const xpPct = Math.max(0, Math.min(1, (u.xp - curFloor) / Math.max(1, nextReq - curFloor)));
        ctx.fillStyle = 'rgba(10, 12, 8, 0.85)';
        ctx.fillRect(-bw / 2 - 1, -u.radius - 6, bw + 2, 3);
        ctx.fillStyle = '#f2be42';
        ctx.fillRect(-bw / 2, -u.radius - 5, Math.round(bw * xpPct), 1.5);
      }
    }

    // Military Veterancy Rank Badge (1 Chevron / 2 Chevrons / Ace Gold Star)
    if (u.rank !== 0) {
      this.drawRankBadge(ctx, u.radius + 2, -u.radius - 10, u.rank);
    }

    ctx.restore();
  }

  private drawRankBadge(ctx: CanvasRenderingContext2D, bx: number, by: number, rank: 1 | 2 | 3) {
    ctx.save();
    ctx.translate(Math.round(bx), Math.round(by));

    // Dark military insignia plate with brass/gold rim
    const w = 15;
    const h = 14;
    ctx.fillStyle = '#14170f';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = rank === 3 ? '#ffd95e' : rank === 2 ? '#e6ad38' : '#b88b3a';
    ctx.lineWidth = 1.5;
    ctx.strokeRect(0.5, 0.5, w - 1, h - 1);

    if (rank === 1) {
      // Rank 1 (Veteran): Single upward bronze-gold chevron
      ctx.strokeStyle = '#e5b145';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(3, 9.5);
      ctx.lineTo(7.5, 4.5);
      ctx.lineTo(12, 9.5);
      ctx.stroke();
    } else if (rank === 2) {
      // Rank 2 (Elite): Twin stacked gold chevrons
      ctx.strokeStyle = '#f7ca4d';
      ctx.lineWidth = 1.8;
      ctx.beginPath();
      ctx.moveTo(3, 7);
      ctx.lineTo(7.5, 3);
      ctx.lineTo(12, 7);
      ctx.moveTo(3, 11);
      ctx.lineTo(7.5, 7);
      ctx.lineTo(12, 11);
      ctx.stroke();
    } else {
      // Rank 3 (Hero / Ace): 5-point gold star
      ctx.fillStyle = '#ffe066';
      const cx = 7.5;
      const cy = 7.2;
      const outerR = 5;
      const innerR = 2.1;
      ctx.beginPath();
      for (let i = 0; i < 10; i++) {
        const angle = -Math.PI / 2 + (i * Math.PI) / 5;
        const r = i % 2 === 0 ? outerR : innerR;
        const px = cx + Math.cos(angle) * r;
        const py = cy + Math.sin(angle) * r;
        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.closePath();
      ctx.fill();
    }

    ctx.restore();
  }

  public renderMinimap(
    ctx: CanvasRenderingContext2D,
    sim: WarFrontSimulation,
    cam: CameraState,
    w: number,
    h: number
  ) {
    const map = sim.map;
    const sx = w / map.width;
    const sy = h / map.height;
    const pal = THEATER_PALETTES[map.theater];

    // Pre-cache static minimap terrain once per map for ultra-fast 60fps rendering
    if (!this.minimapCacheCanvas || this.minimapCacheCanvas.width !== w || this.minimapCacheCanvas.height !== h) {
      const cache = document.createElement('canvas');
      cache.width = w;
      cache.height = h;
      const cctx = cache.getContext('2d');
      if (cctx) {
        cctx.fillStyle = pal.groundB;
        cctx.fillRect(0, 0, w, h);
        const ts = map.tileSize;
        for (let r = 0; r < map.rows; r++) {
          for (let c = 0; c < map.cols; c++) {
            const t = map.tiles[r * map.cols + c];
            if (t === 'water') {
              cctx.fillStyle = pal.waterDeep;
              cctx.fillRect(c * ts * sx, r * ts * sy, Math.ceil(ts * sx), Math.ceil(ts * sy));
            } else if (t === 'road') {
              cctx.fillStyle = '#5a564d';
              cctx.fillRect(c * ts * sx, r * ts * sy, Math.ceil(ts * sx), Math.ceil(ts * sy));
            }
          }
        }
      }
      this.minimapCacheCanvas = cache;
    }

    ctx.drawImage(this.minimapCacheCanvas, 0, 0);

    // Bridges (bright green intact, red blown)
    for (const b of map.bridges) {
      ctx.fillStyle = b.status === 'intact' ? '#9be876' : '#ef4444';
      ctx.fillRect(
        (b.x - b.width / 2) * sx,
        (b.y - b.height / 2) * sy - 1,
        Math.max(6, b.width * sx),
        Math.max(4, b.height * sy + 2)
      );
    }

    // Oil Rigs
    for (const rig of map.rigs) {
      ctx.fillStyle =
        rig.owner === 'player' ? '#7ce063' : rig.owner === 'enemy' ? '#ef5350' : '#f0c45c';
      ctx.fillRect(rig.x * sx - 3, rig.y * sy - 3, 6, 6);
    }

    // HQs
    ctx.fillStyle = '#62d94e';
    ctx.fillRect(map.playerHQ.x * sx - 4, map.playerHQ.y * sy - 4, 8, 8);
    ctx.fillStyle = '#f2554e';
    ctx.fillRect(map.enemyHQ.x * sx - 4, map.enemyHQ.y * sy - 4, 8, 8);

    // Units
    for (const u of sim.units) {
      if (!u.alive) continue;
      if (u.kind === 'truck') {
        ctx.fillStyle = '#f5c249';
        ctx.fillRect(u.x * sx - 1.5, u.y * sy - 1.5, 3, 3);
      } else {
        ctx.fillStyle = u.faction === 'player' ? '#b7ff9e' : '#ff8c85';
        ctx.fillRect(u.x * sx - 1.5, u.y * sy - 1.5, 3, 3);
      }
    }

    // Camera viewport box
    ctx.strokeStyle = 'rgba(245, 238, 218, 0.9)';
    ctx.lineWidth = 1.25;
    ctx.strokeRect(cam.x * sx, cam.y * sy, cam.width * sx, cam.height * sy);
  }
}
