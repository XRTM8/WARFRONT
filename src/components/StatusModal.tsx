import React from 'react';
import { getT } from '../game/i18n';
import { HudSnapshot, Lang } from '../game/types';

interface StatusModalProps {
  hud: HudSnapshot;
  lang: Lang;
  onResume: () => void;
  onRestart: () => void;
  onNextTheater: () => void;
  onReturnTitle: () => void;
}

function formatDuration(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

export const StatusModal: React.FC<StatusModalProps> = ({
  hud,
  lang,
  onResume,
  onRestart,
  onNextTheater,
  onReturnTitle,
}) => {
  const t = getT(lang);
  const isRtl = lang === 'ar';
  const isPaused = hud.phase === 'paused';
  const isVictory = hud.phase === 'gameover' && hud.outcome === 'victory';

  return (
    <div
      dir={isRtl ? 'rtl' : 'ltr'}
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-30 flex items-center justify-center p-4"
      style={{ backgroundColor: 'rgba(12, 15, 10, 0.78)' }}
    >
      <div className="w-full max-w-md bg-[#191e14] border-2 border-[#4f5a40] shadow-[0_10px_0_rgba(8,10,6,0.9)] p-6">
        <div className="border-b border-[#343c2a] pb-4 mb-5">
          <h2
            className={`font-display text-2xl font-bold tracking-wide ${
              isPaused
                ? 'text-[#f2ebd9]'
                : isVictory
                  ? 'text-[#87de6b]'
                  : 'text-[#ef665e]'
            }`}
          >
            {isPaused ? t.paused : isVictory ? t.victoryTitle : t.defeatTitle}
          </h2>
          {!isPaused && (
            <p className="text-sm text-[#c7bfa8] mt-1.5 leading-relaxed">
              {isVictory ? t.victoryDesc : t.defeatDesc}
            </p>
          )}
        </div>

        {/* Mission Telemetry Grid (Tabular Numerals) */}
        <div className="grid grid-cols-2 gap-3 mb-6">
          <div className="bg-[#12160e] border border-[#2f3726] px-3 py-2.5">
            <div className="text-[11px] font-semibold text-[#9a937d]">
              {t.statOilDelivered}
            </div>
            <div className="font-mono-num text-xl font-bold text-[#f0b946] mt-0.5">
              {hud.playerOilDelivered}
            </div>
          </div>

          <div className="bg-[#12160e] border border-[#2f3726] px-3 py-2.5">
            <div className="text-[11px] font-semibold text-[#9a937d]">
              {t.statBridgesCut}
            </div>
            <div className="font-mono-num text-xl font-bold text-[#f2ebd9] mt-0.5">
              {hud.bridgesDestroyedByPlayer}
            </div>
          </div>

          <div className="bg-[#12160e] border border-[#2f3726] px-3 py-2.5">
            <div className="text-[11px] font-semibold text-[#9a937d]">
              {t.statTrucksAmbush}
            </div>
            <div className="font-mono-num text-xl font-bold text-[#f2ebd9] mt-0.5">
              {hud.enemyTrucksDestroyed}
            </div>
          </div>

          <div className="bg-[#12160e] border border-[#2f3726] px-3 py-2.5">
            <div className="text-[11px] font-semibold text-[#9a937d]">
              {isPaused ? t.statTime : t.statScore}
            </div>
            <div className="font-mono-num text-xl font-bold text-[#8bd46a] mt-0.5">
              {isPaused ? formatDuration(hud.elapsedSeconds) : hud.score}
            </div>
          </div>
        </div>

        {/* Primary Action CTAs */}
        <div className="flex flex-col gap-2.5">
          {isPaused ? (
            <button
              type="button"
              onClick={(e) => {
                e.currentTarget.blur();
                onResume();
              }}
              className="w-full py-3 bg-[#d89f38] hover:bg-[#e8b14a] text-[#14170f] font-extrabold text-sm tracking-wide border border-[#f2cd7c] cursor-pointer"
            >
              {t.resume}
            </button>
          ) : isVictory ? (
            <button
              type="button"
              data-start="true"
              onClick={(e) => {
                e.currentTarget.blur();
                onNextTheater();
              }}
              className="w-full py-3 bg-[#d89f38] hover:bg-[#e8b14a] text-[#14170f] font-extrabold text-sm tracking-wide border border-[#f2cd7c] cursor-pointer"
            >
              {t.nextTheater}
            </button>
          ) : (
            <button
              type="button"
              data-start="true"
              onClick={(e) => {
                e.currentTarget.blur();
                onRestart();
              }}
              className="w-full py-3 bg-[#d89f38] hover:bg-[#e8b14a] text-[#14170f] font-extrabold text-sm tracking-wide border border-[#f2cd7c] cursor-pointer"
            >
              {t.playAgain}
            </button>
          )}

          <div className="grid grid-cols-2 gap-2.5">
            <button
              type="button"
              onClick={(e) => {
                e.currentTarget.blur();
                onRestart();
              }}
              className="py-2.5 bg-[#23291c] hover:bg-[#2c3423] text-[#e6dfd0] text-xs font-bold border border-[#46513a] cursor-pointer"
            >
              {t.restart}
            </button>

            <button
              type="button"
              onClick={(e) => {
                e.currentTarget.blur();
                onReturnTitle();
              }}
              className="py-2.5 bg-[#23291c] hover:bg-[#2c3423] text-[#e6dfd0] text-xs font-bold border border-[#46513a] cursor-pointer"
            >
              {t.mainMenu}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
