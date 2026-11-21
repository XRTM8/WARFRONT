import { useCallback, useEffect, useRef, useState } from 'react';
import { GameHud } from './components/GameHud';
import { StatusModal } from './components/StatusModal';
import { TitleOverlay } from './components/TitleOverlay';
import { SoundEngine } from './game/audio';
import { getBridgeAtWorld } from './game/pathfinding';
import { CameraState, RenderOverlayState, WarFrontRenderer } from './game/renderer';
import { WarFrontSimulation } from './game/simulation';
import { HudSnapshot, Lang, TheaterId, UnitKind } from './game/types';

const THEATER_CYCLE: TheaterId[] = ['kirkuk', 'suez', 'newyork', 'procedural'];

export default function App() {
  const [lang, setLang] = useState<Lang>('ar');
  const [muted, setMuted] = useState(false);

  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const minimapRef = useRef<HTMLCanvasElement | null>(null);
  const soundRef = useRef<SoundEngine | null>(null);
  const simRef = useRef<WarFrontSimulation | null>(null);
  const rendererRef = useRef<WarFrontRenderer | null>(null);

  const camRef = useRef<CameraState>({ x: 0, y: 0, width: 1440, height: 900 });
  const keysHeldRef = useRef<Set<string>>(new Set());
  const overlayRef = useRef<RenderOverlayState>({ selectionBox: null, hoverWorld: null });
  const draggingSelectRef = useRef<{ active: boolean; startX: number; startY: number }>({
    active: false,
    startX: 0,
    startY: 0,
  });

  // Lazily create engine singletons once
  if (!soundRef.current) {
    soundRef.current = new SoundEngine();
  }
  if (!simRef.current) {
    const sfx = soundRef.current;
    simRef.current = new WarFrontSimulation('kirkuk', 104729, {
      onMgShot: () => sfx.playMgShot(),
      onCannon: () => sfx.playCannon(),
      onRocket: () => sfx.playRocketLaunch(),
      onExplosion: (heavy) => sfx.playExplosion(heavy),
      onOilDeposit: () => sfx.playOilDeposit(),
      onCapture: (friendly) => sfx.playCapture(friendly),
      onUnitReady: () => sfx.playUnitReady(),
      onPromotion: () => sfx.playPromotion(),
      onVictory: () => sfx.playVictory(),
      onDefeat: () => sfx.playDefeat(),
    });
  }
  if (!rendererRef.current) {
    rendererRef.current = new WarFrontRenderer();
  }

  const [hud, setHud] = useState<HudSnapshot>(() => simRef.current!.getHudSnapshot());

  const syncHudImmediate = useCallback(() => {
    const sim = simRef.current;
    if (!sim) return;
    const snap = sim.getHudSnapshot();
    document.body.dataset.state = snap.phase;
    setHud(snap);
  }, []);

  const clampCamera = useCallback((x: number, y: number) => {
    const sim = simRef.current;
    const cam = camRef.current;
    if (!sim) return;
    const maxX = Math.max(0, sim.map.width - cam.width);
    const maxY = Math.max(0, sim.map.height - cam.height);
    cam.x = Math.max(0, Math.min(maxX, x));
    cam.y = Math.max(0, Math.min(maxY, y));
  }, []);

  const centerCameraOnPlayerHQ = useCallback(() => {
    const sim = simRef.current;
    const cam = camRef.current;
    if (!sim) return;
    // Frame Player HQ on the west with clear sightline toward starter rig & bridges
    clampCamera(sim.map.playerHQ.x - cam.width * 0.22, sim.map.playerHQ.y - cam.height * 0.5);
  }, [clampCamera]);

  const startMission = useCallback(
    (theaterOverride?: TheaterId, seedOverride?: number) => {
      const sim = simRef.current;
      if (!sim) return;
      const targetTheater = theaterOverride ?? sim.theater;
      const targetSeed = seedOverride ?? sim.seed;
      keysHeldRef.current.clear();
      overlayRef.current.selectionBox = null;
      draggingSelectRef.current.active = false;
      sim.reset(targetTheater, targetSeed, 'playing');
      centerCameraOnPlayerHQ();
      document.body.dataset.state = 'playing';
      canvasRef.current?.focus();
      syncHudImmediate();
    },
    [centerCameraOnPlayerHQ, syncHudImmediate]
  );

  const handleSelectTheater = useCallback(
    (theater: TheaterId) => {
      const sim = simRef.current;
      if (!sim) return;
      const nextSeed = theater === 'procedural' ? Math.floor(100000 + Math.random() * 899999) : sim.seed;
      sim.reset(theater, nextSeed, 'title');
      syncHudImmediate();
    },
    [syncHudImmediate]
  );

  const handleRerollSeed = useCallback(() => {
    const sim = simRef.current;
    if (!sim) return;
    const nextSeed = Math.floor(100000 + Math.random() * 899999);
    sim.reset('procedural', nextSeed, 'title');
    syncHudImmediate();
  }, [syncHudImmediate]);

  const handleTogglePause = useCallback(() => {
    const sim = simRef.current;
    if (!sim) return;
    if (sim.phase === 'playing') {
      sim.phase = 'paused';
      keysHeldRef.current.clear();
      syncHudImmediate();
    } else if (sim.phase === 'paused') {
      sim.phase = 'playing';
      keysHeldRef.current.clear();
      canvasRef.current?.focus();
      syncHudImmediate();
    }
  }, [syncHudImmediate]);

  const handleReturnTitle = useCallback(() => {
    const sim = simRef.current;
    if (!sim) return;
    keysHeldRef.current.clear();
    sim.reset(sim.theater, sim.seed, 'title');
    syncHudImmediate();
  }, [syncHudImmediate]);

  const handleNextTheater = useCallback(() => {
    const sim = simRef.current;
    if (!sim) return;
    const idx = THEATER_CYCLE.indexOf(sim.theater);
    const next = THEATER_CYCLE[(idx + 1) % THEATER_CYCLE.length];
    const seed = next === 'procedural' ? Math.floor(100000 + Math.random() * 899999) : sim.seed;
    startMission(next, seed);
  }, [startMission]);

  const handleToggleMute = useCallback(() => {
    if (!soundRef.current) return;
    const next = soundRef.current.toggleMute();
    setMuted(next);
  }, []);

  const handleTrainUnit = useCallback(
    (kind: UnitKind) => {
      const sim = simRef.current;
      if (!sim || sim.phase !== 'playing') return;
      sim.trainPlayerUnit(kind);
      syncHudImmediate();
    },
    [syncHudImmediate]
  );

  const handleToggleRebuildBridge = useCallback(() => {
    const sim = simRef.current;
    if (!sim || sim.phase !== 'playing') return;
    sim.buildMode = sim.buildMode === 'rebuild_bridge' ? 'none' : 'rebuild_bridge';
    syncHudImmediate();
  }, [syncHudImmediate]);

  const handleCancelBuildMode = useCallback(() => {
    const sim = simRef.current;
    if (!sim) return;
    sim.buildMode = 'none';
    syncHudImmediate();
  }, [syncHudImmediate]);

  const handleSelectAll = useCallback(() => {
    const sim = simRef.current;
    if (!sim || sim.phase !== 'playing') return;
    sim.selectAllCombatUnits();
    soundRef.current?.playOrderClick();
    syncHudImmediate();
  }, [syncHudImmediate]);

  const screenToWorld = useCallback((clientX: number, clientY: number) => {
    const canvas = canvasRef.current;
    if (!canvas) return { x: 0, y: 0 };
    const rect = canvas.getBoundingClientRect();
    const cam = camRef.current;
    return {
      x: clientX - rect.left + cam.x,
      y: clientY - rect.top + cam.y,
    };
  }, []);

  const handleMinimapPointer = useCallback(
    (clientX: number, clientY: number) => {
      const mm = minimapRef.current;
      const sim = simRef.current;
      if (!mm || !sim) return;
      const rect = mm.getBoundingClientRect();
      const nx = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
      const ny = Math.max(0, Math.min(1, (clientY - rect.top) / rect.height));
      const cam = camRef.current;
      clampCamera(nx * sim.map.width - cam.width * 0.5, ny * sim.map.height - cam.height * 0.5);
    },
    [clampCamera]
  );

  // Keep <html dir> aligned with active language
  useEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
  }, [lang]);

  // Mount isolated 60fps loop, ResizeObserver, ?autostart=1, and global input hygiene once
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const handleResize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const w = window.innerWidth;
      const h = window.innerHeight;
      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      camRef.current.width = w;
      camRef.current.height = h;
      clampCamera(camRef.current.x, camRef.current.y);
    };

    handleResize();
    window.addEventListener('resize', handleResize);

    // Check ?autostart=1 for instant gameplay launch
    const params = new URLSearchParams(window.location.search);
    if (params.get('autostart') === '1') {
      startMission();
    } else {
      document.body.dataset.state = 'title';
      // Start title camera centered over the river bridges & oil fields
      const sim = simRef.current!;
      clampCamera(sim.map.width * 0.3, sim.map.height * 0.25);
    }

    const onKeyDown = (e: KeyboardEvent) => {
      const sim = simRef.current;
      if (!sim) return;
      const code = e.code;

      if (sim.phase === 'title') {
        if (code === 'Enter' || code === 'Space') {
          e.preventDefault();
          startMission();
        }
        return;
      }

      if (code === 'Escape') {
        e.preventDefault();
        if (sim.buildMode !== 'none') {
          sim.buildMode = 'none';
          syncHudImmediate();
        } else if (sim.phase === 'playing' || sim.phase === 'paused') {
          handleTogglePause();
        }
        return;
      }

      if (code === 'KeyP') {
        e.preventDefault();
        handleTogglePause();
        return;
      }

      if (code === 'KeyM') {
        e.preventDefault();
        handleToggleMute();
        return;
      }

      if (code === 'KeyR' && (sim.phase === 'playing' || sim.phase === 'paused')) {
        e.preventDefault();
        startMission();
        return;
      }

      if (sim.phase !== 'playing') return;

      // Held camera pan keys
      if (
        code === 'KeyW' ||
        code === 'KeyA' ||
        code === 'KeyS' ||
        code === 'KeyD' ||
        code === 'ArrowUp' ||
        code === 'ArrowDown' ||
        code === 'ArrowLeft' ||
        code === 'ArrowRight'
      ) {
        // 'KeyA' selects all units ONLY if Shift/Ctrl or single press? Keep WASD pure camera pan, and KeyQ / Button [A] for select all?
        // Wait: RTS players use WASD to pan AND 'A' was shown for Select All! Let's bind Arrow keys + WASD cleanly:
        // Use Arrow keys + W/A/S/D for camera pan, and Ctrl+A or Space/E for Select All, OR wait: if A pans left, don't conflict!
        // Let's keep WASD + Arrows for smooth camera pan, and bind 'KeyE' / 'Tab' / button for Select All, plus support Shift+A!
        if (code === 'KeyA' && (e.ctrlKey || e.metaKey || e.shiftKey)) {
          e.preventDefault();
          handleSelectAll();
          return;
        }
        keysHeldRef.current.add(code);
        return;
      }

      if (e.repeat) return;

      if (code === 'Digit1') handleTrainUnit('scout');
      else if (code === 'Digit2') handleTrainUnit('tank');
      else if (code === 'Digit3') handleTrainUnit('artillery');
      else if (code === 'Digit4') handleTrainUnit('engineer');
      else if (code === 'Digit5') handleTrainUnit('turret');
      else if (code === 'KeyB') handleToggleRebuildBridge();
      else if (code === 'KeyH') centerCameraOnPlayerHQ();
      else if (code === 'KeyQ') handleSelectAll();
    };

    const onKeyUp = (e: KeyboardEvent) => {
      keysHeldRef.current.delete(e.code);
    };

    const clearInputs = () => {
      keysHeldRef.current.clear();
      draggingSelectRef.current.active = false;
      overlayRef.current.selectionBox = null;
    };

    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);
    window.addEventListener('blur', clearInputs);
    document.addEventListener('visibilitychange', clearInputs);

    let rafId = 0;
    let lastTime = performance.now();
    let hudSyncAccum = 0;
    let minimapAccum = 0;
    let lastHudKey = '';

    const frame = (now: number) => {
      const rawDt = (now - lastTime) / 1000;
      lastTime = now;
      const dt = Math.min(Math.max(rawDt, 0), 0.05);

      const sim = simRef.current!;
      const renderer = rendererRef.current!;
      const cam = camRef.current;

      // Update camera movement
      if (sim.phase === 'title') {
        // Atmospheric Live World Camera Tour framing west oil rigs, rolling fuel trucks & central river bridges
        const t = now * 0.00016;
        const maxX = Math.max(0, sim.map.width - cam.width);
        const maxY = Math.max(0, sim.map.height - cam.height);
        cam.x = maxX * (0.28 + 0.16 * Math.sin(t));
        cam.y = maxY * (0.46 + 0.24 * Math.cos(t * 0.85));
      } else if (sim.phase === 'playing') {
        const panSpeed = 540 * dt;
        const keys = keysHeldRef.current;
        let dx = 0;
        let dy = 0;
        if (keys.has('KeyA') || keys.has('ArrowLeft')) dx -= panSpeed;
        if (keys.has('KeyD') || keys.has('ArrowRight')) dx += panSpeed;
        if (keys.has('KeyW') || keys.has('ArrowUp')) dy -= panSpeed;
        if (keys.has('KeyS') || keys.has('ArrowDown')) dy += panSpeed;
        if (dx !== 0 || dy !== 0) {
          clampCamera(cam.x + dx, cam.y + dy);
        }
      }

      sim.step(dt);
      renderer.render(ctx, sim, cam, overlayRef.current);

      // Update live tactical minimap at ~12Hz to keep main thread crisp
      minimapAccum += dt;
      const mmCanvas = minimapRef.current;
      if (mmCanvas && sim.phase === 'playing' && minimapAccum >= 0.08) {
        minimapAccum = 0;
        const mmCtx = mmCanvas.getContext('2d');
        if (mmCtx) {
          renderer.renderMinimap(mmCtx, sim, cam, mmCanvas.width, mmCanvas.height);
        }
      }

      // Only trigger React HUD reconciliation when discrete displayed HUD values actually change
      hudSyncAccum += dt;
      if (hudSyncAccum >= 0.12 || document.body.dataset.state !== sim.phase) {
        hudSyncAccum = 0;
        const snap = sim.getHudSnapshot();
        const key = `${snap.phase}|${snap.outcome}|${snap.playerOil}|${snap.playerRigs}|${snap.playerTrucks}|${snap.strandedPlayerTrucks}|${snap.bridgesIntact}|${snap.playerVeterans}|${snap.selectedCount}|${snap.playerHqHp}|${snap.enemyHqHp}|${snap.buildMode}|${snap.eventBanner?.id ?? 0}|${snap.theater}|${snap.seed}`;
        if (key !== lastHudKey) {
          lastHudKey = key;
          document.body.dataset.state = snap.phase;
          setHud(snap);
        }
      }

      rafId = requestAnimationFrame(frame);
    };

    rafId = requestAnimationFrame(frame);

    return () => {
      cancelAnimationFrame(rafId);
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('keydown', onKeyDown);
      window.removeEventListener('keyup', onKeyUp);
      window.removeEventListener('blur', clearInputs);
      document.removeEventListener('visibilitychange', clearInputs);
    };
  }, [
    centerCameraOnPlayerHQ,
    clampCamera,
    handleSelectAll,
    handleToggleMute,
    handleTogglePause,
    handleToggleRebuildBridge,
    handleTrainUnit,
    startMission,
    syncHudImmediate,
  ]);

  // Canvas pointer handlers (Left-click / Drag select, Right-click command, Build mode placement)
  const handleCanvasMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const sim = simRef.current;
    if (!sim || sim.phase !== 'playing') return;
    const world = screenToWorld(e.clientX, e.clientY);

    if (e.button === 2) {
      e.preventDefault();
      if (sim.buildMode !== 'none') {
        sim.buildMode = 'none';
        syncHudImmediate();
        return;
      }
      if (sim.issuePlayerCommand(world.x, world.y)) {
        soundRef.current?.playOrderClick();
        syncHudImmediate();
      }
      return;
    }

    if (e.button === 0) {
      if (sim.buildMode === 'turret') {
        if (sim.placePlayerTurret(world.x, world.y)) {
          syncHudImmediate();
        }
        return;
      }
      if (sim.buildMode === 'rebuild_bridge') {
        const bridge = getBridgeAtWorld(sim.map, world.x, world.y, 28);
        if (bridge && bridge.status === 'destroyed') {
          sim.rebuildBridge(bridge.id, 'player');
          syncHudImmediate();
        }
        return;
      }

      draggingSelectRef.current = { active: true, startX: world.x, startY: world.y };
      overlayRef.current.selectionBox = {
        x1: world.x,
        y1: world.y,
        x2: world.x,
        y2: world.y,
      };
    }
  };

  const handleCanvasMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const world = screenToWorld(e.clientX, e.clientY);
    overlayRef.current.hoverWorld = world;
    if (draggingSelectRef.current.active && overlayRef.current.selectionBox) {
      overlayRef.current.selectionBox.x2 = world.x;
      overlayRef.current.selectionBox.y2 = world.y;
    }
  };

  const handleCanvasMouseUp = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const sim = simRef.current;
    if (!sim || sim.phase !== 'playing') return;
    if (e.button === 0 && draggingSelectRef.current.active) {
      const world = screenToWorld(e.clientX, e.clientY);
      const { startX, startY } = draggingSelectRef.current;
      draggingSelectRef.current.active = false;
      overlayRef.current.selectionBox = null;

      const selectedCount = sim.selectUnitsInBox(startX, startY, world.x, world.y, e.shiftKey);
      if (selectedCount > 0) {
        soundRef.current?.playOrderClick();
      }
      syncHudImmediate();
    }
  };

  return (
    <main className="relative w-screen h-screen overflow-hidden bg-[#11130e]">
      {/* Isolated Full-Viewport Pixel-Art Battlefield Canvas */}
      <canvas
        ref={canvasRef}
        tabIndex={0}
        data-testid="warfront-canvas"
        onMouseDown={handleCanvasMouseDown}
        onMouseMove={handleCanvasMouseMove}
        onMouseUp={handleCanvasMouseUp}
        onContextMenu={(e) => e.preventDefault()}
        className="block w-full h-full outline-none cursor-crosshair"
      />

      {/* Game Shell Overlays driven cleanly by GamePhase */}
      {hud.phase === 'title' && (
        <TitleOverlay
          lang={lang}
          theater={hud.theater}
          seed={hud.seed}
          onSelectTheater={handleSelectTheater}
          onRerollSeed={handleRerollSeed}
          onToggleLang={() => setLang((l) => (l === 'ar' ? 'en' : 'ar'))}
          onStart={() => startMission()}
        />
      )}

      {hud.phase === 'playing' && (
        <GameHud
          hud={hud}
          lang={lang}
          muted={muted}
          minimapRef={minimapRef}
          onTrainUnit={handleTrainUnit}
          onToggleRebuildBridge={handleToggleRebuildBridge}
          onCancelBuildMode={handleCancelBuildMode}
          onSelectAll={handleSelectAll}
          onCenterHq={centerCameraOnPlayerHQ}
          onToggleMute={handleToggleMute}
          onTogglePause={handleTogglePause}
          onRestart={() => startMission()}
          onToggleLang={() => setLang((l) => (l === 'ar' ? 'en' : 'ar'))}
          onMinimapPointer={handleMinimapPointer}
        />
      )}

      {(hud.phase === 'paused' || hud.phase === 'gameover') && (
        <StatusModal
          hud={hud}
          lang={lang}
          onResume={handleTogglePause}
          onRestart={() => startMission()}
          onNextTheater={handleNextTheater}
          onReturnTitle={handleReturnTitle}
        />
      )}
    </main>
  );
}
