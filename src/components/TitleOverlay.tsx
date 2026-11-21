import React from 'react';
import { getT } from '../game/i18n';
import { Lang, TheaterId } from '../game/types';
import { WarFrontLogoSvg } from './WarFrontEmblem';

interface TitleOverlayProps {
  lang: Lang;
  theater: TheaterId;
  seed: number;
  onSelectTheater: (t: TheaterId) => void;
  onRerollSeed: () => void;
  onToggleLang: () => void;
  onStart: () => void;
}

const THEATER_ORDER: TheaterId[] = ['kirkuk', 'suez', 'newyork', 'procedural'];

export const TitleOverlay: React.FC<TitleOverlayProps> = ({
  lang,
  theater,
  seed,
  onSelectTheater,
  onRerollSeed,
  onToggleLang,
  onStart,
}) => {
  const t = getT(lang);
  const isRtl = lang === 'ar';

  return (
    <div
      dir={isRtl ? 'rtl' : 'ltr'}
      className="fixed inset-0 z-20 flex flex-col justify-between pointer-events-none"
      style={{
        background: isRtl
          ? 'linear-gradient(270deg, rgba(16,19,13,0.92) 0%, rgba(16,19,13,0.78) 38%, rgba(16,19,13,0.18) 72%, rgba(16,19,13,0.08) 100%)'
          : 'linear-gradient(90deg, rgba(16,19,13,0.92) 0%, rgba(16,19,13,0.78) 38%, rgba(16,19,13,0.18) 72%, rgba(16,19,13,0.08) 100%)',
      }}
    >
      {/* Top corner minimal language switch */}
      <div className="flex justify-end p-5 pointer-events-none">
        <button
          type="button"
          onClick={(e) => {
            e.currentTarget.blur();
            onToggleLang();
          }}
          className="pointer-events-auto px-3 py-1.5 text-xs font-bold tracking-wider bg-[#1d2217] text-[#e6dfd0] border border-[#4a543c] hover:border-[#d89f38] hover:text-[#f5c249] transition-colors cursor-pointer whitespace-nowrap"
          aria-label={lang === 'ar' ? 'Switch to English' : 'التبديل إلى العربية'}
        >
          {lang === 'ar' ? 'EN' : 'عربي'}
        </button>
      </div>

      {/* Asymmetric Command Column over calm negative space */}
      <div className="px-6 sm:px-12 md:px-16 max-w-xl pointer-events-auto">
        <div dir="ltr" className="mb-3">
          <WarFrontLogoSvg className="w-full max-w-[380px] h-auto" />
        </div>

        <p className="text-sm sm:text-base text-[#d5ccb6] font-medium mb-7 leading-relaxed max-w-md hud-text-stroke">
          {t.subtitle}
        </p>

        {/* Theater Selector */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold tracking-wider text-[#b7ae96]">
              {t.selectTheater}
            </span>
            {theater === 'procedural' && (
              <button
                type="button"
                onClick={(e) => {
                  e.currentTarget.blur();
                  onRerollSeed();
                }}
                className="text-xs font-semibold text-[#e6a838] hover:text-[#ffd275] underline underline-offset-4 cursor-pointer"
              >
                {t.newSeed} #{seed % 10000}
              </button>
            )}
          </div>

          <div className="grid grid-cols-2 gap-2">
            {THEATER_ORDER.map((id) => {
              const active = theater === id;
              const info = t.theaters[id];
              return (
                <button
                  key={id}
                  type="button"
                  onClick={(e) => {
                    e.currentTarget.blur();
                    onSelectTheater(id);
                  }}
                  aria-pressed={active}
                  className={`text-start px-3.5 py-2.5 border transition-colors cursor-pointer ${
                    active
                      ? 'bg-[#2a3120] border-[#e6a838] text-[#f5eedb]'
                      : 'bg-[#171b13]/90 border-[#343c2a] text-[#b4ab96] hover:border-[#626e52] hover:text-[#f5eedb]'
                  }`}
                >
                  <div className="text-sm font-bold leading-tight whitespace-nowrap truncate">
                    {info.name}
                  </div>
                  <div className="text-[11px] text-[#9c947f] mt-0.5 truncate">
                    {info.region}
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Primary Start CTA */}
        <div className="flex items-center gap-4">
          <button
            type="button"
            data-start="true"
            onClick={(e) => {
              e.currentTarget.blur();
              onStart();
            }}
            className="px-8 py-3.5 bg-[#d89f38] hover:bg-[#e8b14a] active:translate-y-px text-[#14170f] font-extrabold text-base tracking-wide border-2 border-[#f2cd7c] shadow-[0_4px_0_#7d5818] transition-transform cursor-pointer whitespace-nowrap"
          >
            {t.startMission}
          </button>
        </div>
      </div>

      {/* Single flat borderless control-hint line in bottom safe margin */}
      <div className="px-6 sm:px-12 md:px-16 pb-5 pt-3">
        <p className="text-xs text-[#b7ae96]/90 hud-text-stroke truncate">
          {t.controlsHint}
        </p>
      </div>
    </div>
  );
};
