import React from 'react';
import { BRIDGE_REBUILD_COST, BUILDABLE_UNITS, UNIT_SPECS } from '../game/constants';
import { getT } from '../game/i18n';
import { HudSnapshot, Lang, UnitKind } from '../game/types';
import {
  BridgeIcon,
  OilBarrelIcon,
  OilRigIcon,
  TruckIcon,
  UnitGlyphIcon,
} from './WarFrontEmblem';

interface GameHudProps {
  hud: HudSnapshot;
  lang: Lang;
  muted: boolean;
  minimapRef: React.RefObject<HTMLCanvasElement | null>;
  onTrainUnit: (kind: UnitKind) => void;
  onToggleRebuildBridge: () => void;
  onCancelBuildMode: () => void;
  onSelectAll: () => void;
  onCenterHq: () => void;
  onToggleMute: () => void;
  onTogglePause: () => void;
  onRestart: () => void;
  onToggleLang: () => void;
  onMinimapPointer: (clientX: number, clientY: number) => void;
}

export const GameHud: React.FC<GameHudProps> = ({
  hud,
  lang,
  muted,
  minimapRef,
  onTrainUnit,
  onToggleRebuildBridge,
  onCancelBuildMode,
  onSelectAll,
  onCenterHq,
  onToggleMute,
  onTogglePause,
  onRestart,
  onToggleLang,
  onMinimapPointer,
}) => {
  const t = getT(lang);
  const isRtl = lang === 'ar';
  const hasBlownBridge = hud.bridgesIntact < hud.bridgesTotal;
  const playerHqPct = Math.max(0, Math.min(100, Math.round((hud.playerHqHp / hud.playerHqMaxHp) * 100)));
  const enemyHqPct = Math.max(0, Math.min(100, Math.round((hud.enemyHqHp / hud.enemyHqMaxHp) * 100)));

  return (
    <div
      dir={isRtl ? 'rtl' : 'ltr'}
      className="fixed inset-0 z-10 pointer-events-none flex flex-col justify-between p-3 sm:p-4"
    >
      {/* TOP BAR: Compact Corner Clusters keeping >= 85% viewport unobstructed */}
      <div className="flex items-start justify-between gap-3">
        {/* Top-Start Logistics Cluster: Hero Oil Barrel Count + Rigs / Trucks / Bridges */}
        <div className="pointer-events-auto flex flex-wrap items-center gap-4 bg-[#171b13]/92 border border-[#444e38] px-3.5 py-2 shadow-[0_3px_0_rgba(8,10,6,0.75)]">
          {/* Hero Oil Readout */}
          <div className="flex items-center gap-2">
            <OilBarrelIcon className="w-6 h-6 shrink-0" />
            <div className="leading-none">
              <div className="text-[10px] font-bold tracking-wider text-[#b5ac94] uppercase">
                {t.oil}
              </div>
              <div
                data-testid="hud-oil"
                className="font-mono-num text-2xl font-bold text-[#f4c04e] leading-tight hud-text-stroke"
              >
                {hud.playerOil}
              </div>
            </div>
          </div>

          <div className="h-7 w-px bg-[#363f2c]" aria-hidden="true" />

          {/* Rigs Held */}
          <div className="flex items-center gap-1.5">
            <OilRigIcon className="w-4 h-4 shrink-0" />
            <div className="leading-tight">
              <div className="text-[10px] font-semibold text-[#9e9681]">{t.rigs}</div>
              <div data-testid="hud-rigs" className="font-mono-num text-sm font-bold text-[#e9e3d2]">
                {hud.playerRigs}/{hud.totalRigs}
              </div>
            </div>
          </div>

          {/* Active Supply Trucks */}
          <div className="flex items-center gap-1.5">
            <TruckIcon className="w-4 h-4 shrink-0" />
            <div className="leading-tight">
              <div className="text-[10px] font-semibold text-[#9e9681]">{t.trucks}</div>
              <div className="font-mono-num text-sm font-bold text-[#e9e3d2] flex items-center gap-1">
                <span>{hud.playerTrucks}</span>
                {hud.strandedPlayerTrucks > 0 && (
                  <span className="text-[11px] text-[#f59e0b]">
                    ({hud.strandedPlayerTrucks} {t.stranded})
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Bridges Status */}
          <div className="flex items-center gap-1.5">
            <BridgeIcon className="w-4 h-4 shrink-0" broken={hasBlownBridge} />
            <div className="leading-tight">
              <div className="text-[10px] font-semibold text-[#9e9681]">{t.bridges}</div>
              <div
                data-testid="hud-bridges"
                className={`font-mono-num text-sm font-bold ${
                  hasBlownBridge ? 'text-[#f0a83a]' : 'text-[#8bd46a]'
                }`}
              >
                {hud.bridgesIntact}/{hud.bridgesTotal}
              </div>
            </div>
          </div>

          {/* Promoted Veterans Counter */}
          {hud.playerVeterans > 0 && (
            <div className="flex items-center gap-1.5">
              <svg viewBox="0 0 24 24" className="w-4 h-4 shrink-0" fill="none" aria-hidden="true">
                <path
                  d="M12 3L14.7 8.5L20.8 9.4L16.4 13.7L17.4 19.8L12 16.9L6.6 19.8L7.6 13.7L3.2 9.4L9.3 8.5L12 3Z"
                  fill="#f5c94c"
                  stroke="#141710"
                  strokeWidth="1.5"
                />
              </svg>
              <div className="leading-tight">
                <div className="text-[10px] font-semibold text-[#9e9681]">{t.veterans}</div>
                <div data-testid="hud-veterans" className="font-mono-num text-sm font-bold text-[#ffd659]">
                  {hud.playerVeterans}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Top-Center: Compact HQ Integrity Bars + Radio Alert */}
        <div className="hidden md:flex flex-col items-center gap-1.5 min-w-[260px]">
          <div className="flex items-center gap-3 bg-[#171b13]/88 border border-[#3a432f] px-3 py-1.5 text-xs">
            <div className="flex items-center gap-2">
              <span className="font-bold text-[#8bd46a] whitespace-nowrap">{t.hq}</span>
              <div className="w-20 h-2 bg-[#252a1f] border border-[#414c35]">
                <div
                  className="h-full bg-[#68c254] transition-[width] duration-150"
                  style={{ width: `${playerHqPct}%` }}
                />
              </div>
              <span className="font-mono-num text-[11px] text-[#d6ceb9]">{playerHqPct}%</span>
            </div>

            <span className="text-[#5e6850]" aria-hidden="true">·</span>

            <div className="flex items-center gap-2">
              <span className="font-bold text-[#ea6862] whitespace-nowrap">{t.enemyHq}</span>
              <div className="w-20 h-2 bg-[#252a1f] border border-[#414c35]">
                <div
                  className="h-full bg-[#db4f48] transition-[width] duration-150"
                  style={{ width: `${enemyHqPct}%` }}
                />
              </div>
              <span className="font-mono-num text-[11px] text-[#d6ceb9]">{enemyHqPct}%</span>
            </div>
          </div>

          {hud.eventBanner && (
            <div
              role="status"
              className={`px-3 py-1 text-xs font-bold border shadow-sm whitespace-nowrap ${
                hud.eventBanner.tone === 'good'
                  ? 'bg-[#1c2b18]/95 border-[#6ac456] text-[#c7f2ba]'
                  : hud.eventBanner.tone === 'warn'
                    ? 'bg-[#2e1c16]/95 border-[#e36c42] text-[#ffd0bf]'
                    : 'bg-[#1d2218]/95 border-[#d89f38] text-[#f5e3ba]'
              }`}
            >
              {t.events[hud.eventBanner.key] ?? hud.eventBanner.key}
            </div>
          )}
        </div>

        {/* Top-End Utility Controls: Square Icon Buttons */}
        <div className="pointer-events-auto flex items-center gap-1.5">
          <button
            type="button"
            tabIndex={-1}
            onClick={(e) => {
              e.currentTarget.blur();
              onToggleLang();
            }}
            aria-label={lang === 'ar' ? 'Switch to English' : 'التبديل إلى العربية'}
            className="h-9 px-2.5 bg-[#171b13]/92 border border-[#444e38] hover:border-[#d89f38] text-[#e6dfd0] text-xs font-bold cursor-pointer"
          >
            {lang === 'ar' ? 'EN' : 'عربي'}
          </button>

          <button
            type="button"
            tabIndex={-1}
            onClick={(e) => {
              e.currentTarget.blur();
              onToggleMute();
            }}
            aria-label={t.muteLabel}
            title={`${t.muteLabel} [M]`}
            className="w-9 h-9 flex items-center justify-center bg-[#171b13]/92 border border-[#444e38] hover:border-[#d89f38] text-[#e6dfd0] cursor-pointer"
          >
            <svg viewBox="0 0 24 24" className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M11 5L6 9H2V15H6L11 19V5Z" />
              {muted ? (
                <path d="M22 9L16 15M16 9L22 15" stroke="#ef5350" />
              ) : (
                <path d="M15.5 8.5C16.8 9.8 16.8 14.2 15.5 15.5M18.5 5.5C21.2 8.2 21.2 15.8 18.5 18.5" />
              )}
            </svg>
          </button>

          <button
            type="button"
            tabIndex={-1}
            onClick={(e) => {
              e.currentTarget.blur();
              onTogglePause();
            }}
            aria-label={t.pauseLabel}
            title={`${t.pauseLabel} [P]`}
            className="w-9 h-9 flex items-center justify-center bg-[#171b13]/92 border border-[#444e38] hover:border-[#d89f38] text-[#e6dfd0] cursor-pointer"
          >
            <svg viewBox="0 0 24 24" className="w-4 h-4" fill="currentColor">
              <rect x="6" y="5" width="4" height="14" />
              <rect x="14" y="5" width="4" height="14" />
            </svg>
          </button>

          <button
            type="button"
            tabIndex={-1}
            onClick={(e) => {
              e.currentTarget.blur();
              onRestart();
            }}
            aria-label={t.restartLabel}
            title={`${t.restartLabel} [R]`}
            className="w-9 h-9 flex items-center justify-center bg-[#171b13]/92 border border-[#444e38] hover:border-[#d89f38] text-[#e6dfd0] cursor-pointer"
          >
            <svg viewBox="0 0 24 24" className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M3 12a9 9 0 1 0 3-6.7L3 8" />
              <path d="M3 3v5h5" />
            </svg>
          </button>
        </div>
      </div>

      {/* Placement / Bridge Rebuild contextual banner */}
      {hud.buildMode !== 'none' && (
        <div className="self-center pointer-events-auto flex items-center gap-3 bg-[#1d2217]/95 border border-[#e6a838] px-4 py-1.5 text-xs font-bold text-[#f7dca0]">
          <span>
            {hud.buildMode === 'turret' ? t.placeTurretHint : t.rebuildBridgeHint}
          </span>
          <button
            type="button"
            tabIndex={-1}
            onClick={(e) => {
              e.currentTarget.blur();
              onCancelBuildMode();
            }}
            className="px-2 py-0.5 bg-[#332a1b] border border-[#b68938] text-[#ffe1a1] hover:bg-[#473923] cursor-pointer"
          >
            {t.cancelPlacement}
          </button>
        </div>
      )}

      {/* BOTTOM BAR: Interactive Tactical Minimap + Unified Command Dock */}
      <div className="flex items-end justify-between gap-3">
        {/* Tactical Minimap */}
        <div
          className="hidden sm:flex flex-col pointer-events-auto bg-[#141810]/94 border border-[#48523b] p-1.5 shadow-[0_3px_0_rgba(8,10,6,0.8)]"
          aria-label={t.minimapLabel}
        >
          <canvas
            ref={minimapRef}
            width={186}
            height={110}
            className="block cursor-crosshair pixel-canvas border border-[#2c3324]"
            onMouseDown={(e) => onMinimapPointer(e.clientX, e.clientY)}
            onMouseMove={(e) => {
              if (e.buttons === 1) onMinimapPointer(e.clientX, e.clientY);
            }}
          />
          <div className="flex items-center justify-between mt-1 px-0.5 text-[10px] text-[#a79f89]">
            <button
              type="button"
              tabIndex={-1}
              onClick={(e) => {
                e.currentTarget.blur();
                onSelectAll();
              }}
              className="hover:text-[#f4c04e] font-bold cursor-pointer"
            >
              [Q] {t.selectAll} ({hud.selectedCount})
            </button>
            <button
              type="button"
              tabIndex={-1}
              onClick={(e) => {
                e.currentTarget.blur();
                onCenterHq();
              }}
              className="hover:text-[#f4c04e] font-bold cursor-pointer"
            >
              [H] {t.centerHq}
            </button>
          </div>
        </div>

        {/* Unified Military Production & Logistics Command Dock */}
        <div className="pointer-events-auto mx-auto flex items-stretch gap-1.5 bg-[#161a12]/94 border border-[#444e38] p-1.5 shadow-[0_4px_0_rgba(8,10,6,0.85)] overflow-x-auto max-w-full">
          {BUILDABLE_UNITS.map((kind) => {
            const spec = UNIT_SPECS[kind];
            const info = t.units[kind];
            const canAfford = hud.playerOil >= spec.cost;
            const activeMode = kind === 'turret' && hud.buildMode === 'turret';

            return (
              <button
                key={kind}
                type="button"
                tabIndex={-1}
                disabled={!canAfford && !activeMode}
                onClick={(e) => {
                  e.currentTarget.blur();
                  onTrainUnit(kind);
                }}
                aria-label={`${info.name} (${spec.cost} ${t.oil}) [${spec.hotkey}]`}
                className={`relative flex flex-col items-start justify-between w-[108px] sm:w-[118px] px-2.5 py-2 border text-start transition-colors shrink-0 ${
                  activeMode
                    ? 'bg-[#333c24] border-[#f4c04e] text-[#fff6df] cursor-pointer'
                    : canAfford
                      ? 'bg-[#202619] border-[#424d36] hover:border-[#d89f38] hover:bg-[#272f1f] text-[#f2ebd9] cursor-pointer'
                      : 'bg-[#171a13] border-[#2b3024] text-[#6d6a5e] opacity-65 cursor-not-allowed'
                }`}
              >
                <div className="w-full flex items-center justify-between gap-1 mb-1">
                  <UnitGlyphIcon kind={kind} className="w-6 h-6 shrink-0" />
                  <span className="font-mono-num text-[11px] font-bold text-[#9c9582]">
                    [{spec.hotkey}]
                  </span>
                </div>

                <div className="text-xs font-bold leading-tight truncate w-full">
                  {info.name}
                </div>
                <div className="text-[10px] text-[#9b947f] leading-tight truncate w-full mt-0.5">
                  {info.role}
                </div>

                <div className="w-full flex items-center justify-between mt-1.5 pt-1 border-t border-[#313828]">
                  <span className="font-mono-num text-xs font-bold text-[#f0b946]">
                    {spec.cost}
                  </span>
                  <span className="text-[10px] text-[#9b947f]">{t.oil}</span>
                </div>
              </button>
            );
          })}

          {/* Contextual Bridge Rebuild Slot */}
          <button
            type="button"
            tabIndex={-1}
            disabled={!hasBlownBridge || hud.playerOil < BRIDGE_REBUILD_COST}
            onClick={(e) => {
              e.currentTarget.blur();
              onToggleRebuildBridge();
            }}
            aria-label={`${t.rebuildBridge} (${BRIDGE_REBUILD_COST} ${t.oil}) [B]`}
            className={`relative flex flex-col items-start justify-between w-[108px] sm:w-[116px] px-2.5 py-2 border text-start transition-colors shrink-0 ${
              hud.buildMode === 'rebuild_bridge'
                ? 'bg-[#382f19] border-[#f4c04e] text-[#fff6df] cursor-pointer'
                : hasBlownBridge && hud.playerOil >= BRIDGE_REBUILD_COST
                  ? 'bg-[#2a2315] border-[#c48d31] hover:border-[#f4c04e] text-[#f7e7c1] cursor-pointer'
                  : 'bg-[#171a13] border-[#2b3024] text-[#6d6a5e] opacity-55 cursor-not-allowed'
            }`}
          >
            <div className="w-full flex items-center justify-between gap-1 mb-1">
              <BridgeIcon className="w-5 h-5 shrink-0" broken={hasBlownBridge} />
              <span className="font-mono-num text-[11px] font-bold text-[#9c9582]">[B]</span>
            </div>
            <div className="text-xs font-bold leading-tight truncate w-full">
              {t.rebuildBridge}
            </div>
            <div className="text-[10px] text-[#9b947f] leading-tight truncate w-full mt-0.5">
              {t.rebuildBridgeRole}
            </div>
            <div className="w-full flex items-center justify-between mt-1.5 pt-1 border-t border-[#313828]">
              <span className="font-mono-num text-xs font-bold text-[#f0b946]">
                {BRIDGE_REBUILD_COST}
              </span>
              <span className="text-[10px] text-[#9b947f]">{t.oil}</span>
            </div>
          </button>
        </div>

        {/* Spacer on desktop to balance minimap width */}
        <div className="hidden lg:block w-[120px] shrink-0" aria-hidden="true" />
      </div>
    </div>
  );
};
