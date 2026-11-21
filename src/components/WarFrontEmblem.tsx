import React from 'react';
import { UnitKind } from '../game/types';

export const WarFrontLogoSvg: React.FC<{ className?: string }> = ({ className = 'w-full max-w-[420px] h-auto' }) => (
  <svg
    viewBox="0 0 460 112"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className={className}
    role="img"
    aria-label="WarFront"
  >
    {/* Tactical brass emblem left of wordmark: Oil Derrick + Crosshair */}
    <g transform="translate(8, 12)">
      <path
        d="M12 4H66L76 14V74L66 84H12L2 74V14L12 4Z"
        fill="#191d14"
        stroke="#d89f38"
        strokeWidth="3"
      />
      <path d="M16 12H62L68 18V70L62 76H16L10 70V18L16 12Z" fill="#23281c" />
      {/* Oil Derrick silhouette */}
      <path
        d="M39 18L26 68H32L35 55H43L46 68H52L39 18ZM36.5 49L39 36L41.5 49H36.5Z"
        fill="#e6a838"
      />
      {/* Oil Flame */}
      <path
        d="M39 8C39 8 44 13 44 17C44 20 41.8 22 39 22C36.2 22 34 20 34 17C34 13 39 8 39 8Z"
        fill="#f06824"
      />
      {/* Crosshair ticks */}
      <rect x="6" y="42" width="10" height="3" fill="#d89f38" />
      <rect x="62" y="42" width="10" height="3" fill="#d89f38" />
    </g>

    {/* Bold Military Stencil Wordmark */}
    <text
      x="104"
      y="68"
      fill="#f5eedb"
      stroke="#141710"
      strokeWidth="6"
      paintOrder="stroke fill"
      fontFamily="'Chakra Petch', sans-serif"
      fontWeight="700"
      fontSize="58"
      letterSpacing="3"
    >
      WARFRONT
    </text>

    {/* Underbar accent & steel rivets */}
    <rect x="104" y="80" width="224" height="5" fill="#d89f38" />
    <rect x="334" y="80" width="52" height="5" fill="#c9473a" />
    <rect x="392" y="80" width="16" height="5" fill="#6b7a58" />
  </svg>
);

export const OilBarrelIcon: React.FC<{ className?: string }> = ({ className = 'w-5 h-5' }) => (
  <svg viewBox="0 0 24 24" className={className} fill="none" aria-hidden="true">
    <rect x="5" y="3" width="14" height="18" rx="1.5" fill="#1b1915" stroke="#e6a838" strokeWidth="2" />
    <line x1="5" y1="8.5" x2="19" y2="8.5" stroke="#e6a838" strokeWidth="1.8" />
    <line x1="5" y1="15.5" x2="19" y2="15.5" stroke="#e6a838" strokeWidth="1.8" />
    <path d="M12 10C12 10 14.5 12.2 14.5 13.6C14.5 14.8 13.4 15.6 12 15.6C10.6 15.6 9.5 14.8 9.5 13.6C9.5 12.2 12 10 12 10Z" fill="#f0b643" />
  </svg>
);

export const OilRigIcon: React.FC<{ className?: string }> = ({ className = 'w-4 h-4' }) => (
  <svg viewBox="0 0 24 24" className={className} fill="none" aria-hidden="true">
    <path d="M12 3L6 21H9L10.5 16H13.5L15 21H18L12 3Z" fill="#77cf61" stroke="#141710" strokeWidth="1.5" />
    <line x1="4" y1="21" x2="20" y2="21" stroke="#d9d1bc" strokeWidth="2" />
  </svg>
);

export const BridgeIcon: React.FC<{ className?: string; broken?: boolean }> = ({
  className = 'w-4 h-4',
  broken = false,
}) => (
  <svg viewBox="0 0 24 24" className={className} fill="none" aria-hidden="true">
    {broken ? (
      <>
        <path d="M2 14H9L7 19H2V14Z" fill="#ef5350" />
        <path d="M22 14H15L17 19H22V14Z" fill="#ef5350" />
        <path d="M10 7L14 11M14 7L10 11" stroke="#f5c249" strokeWidth="2.2" strokeLinecap="square" />
      </>
    ) : (
      <>
        <rect x="2" y="13" width="20" height="4" fill="#d9d1bc" stroke="#141710" strokeWidth="1.2" />
        <path d="M4 13L8 7L12 13L16 7L20 13" stroke="#d89f38" strokeWidth="2" />
        <rect x="4" y="17" width="3" height="4" fill="#8b877c" />
        <rect x="17" y="17" width="3" height="4" fill="#8b877c" />
      </>
    )}
  </svg>
);

export const TruckIcon: React.FC<{ className?: string }> = ({ className = 'w-4 h-4' }) => (
  <svg viewBox="0 0 24 24" className={className} fill="none" aria-hidden="true">
    <rect x="2" y="7" width="13" height="9" fill="#d89f38" stroke="#141710" strokeWidth="1.5" />
    <path d="M15 9H19.5L22 12.5V16H15V9Z" fill="#73b85e" stroke="#141710" strokeWidth="1.5" />
    <circle cx="6.5" cy="17.5" r="2.2" fill="#23221f" stroke="#d9d1bc" strokeWidth="1.2" />
    <circle cx="17.5" cy="17.5" r="2.2" fill="#23221f" stroke="#d9d1bc" strokeWidth="1.2" />
  </svg>
);

export const UnitGlyphIcon: React.FC<{ kind: UnitKind; className?: string }> = ({
  kind,
  className = 'w-7 h-7',
}) => {
  switch (kind) {
    case 'scout':
      return (
        <svg viewBox="0 0 28 28" className={className} fill="none" aria-hidden="true">
          <rect x="5" y="8" width="18" height="12" fill="#63964d" stroke="#12140f" strokeWidth="2" />
          <rect x="15" y="10" width="5" height="8" fill="#9bd47f" />
          <rect x="12" y="12" width="12" height="4" fill="#262822" />
        </svg>
      );
    case 'tank':
      return (
        <svg viewBox="0 0 28 28" className={className} fill="none" aria-hidden="true">
          <rect x="3" y="5" width="22" height="4" fill="#1e201b" />
          <rect x="3" y="19" width="22" height="4" fill="#1e201b" />
          <rect x="5" y="8" width="18" height="12" fill="#588544" stroke="#12140f" strokeWidth="1.8" />
          <rect x="8" y="10" width="9" height="8" fill="#7cb861" stroke="#12140f" strokeWidth="1.5" />
          <rect x="16" y="12.5" width="10" height="3" fill="#d9d1bc" />
        </svg>
      );
    case 'artillery':
      return (
        <svg viewBox="0 0 28 28" className={className} fill="none" aria-hidden="true">
          <rect x="4" y="7" width="20" height="14" fill="#466937" stroke="#12140f" strokeWidth="2" />
          <rect x="6" y="9" width="12" height="3" fill="#e6a838" />
          <rect x="6" y="13" width="12" height="3" fill="#e6a838" />
          <rect x="6" y="17" width="12" height="2.5" fill="#e6a838" />
          <rect x="19" y="9" width="4" height="10" fill="#82ba6a" />
        </svg>
      );
    case 'engineer':
      return (
        <svg viewBox="0 0 28 28" className={className} fill="none" aria-hidden="true">
          <rect x="5" y="7" width="18" height="14" fill="#5d8a47" stroke="#12140f" strokeWidth="2" />
          <rect x="17" y="7" width="5" height="14" fill="#f0be3d" />
          <rect x="17" y="10" width="5" height="3" fill="#181814" />
          <rect x="17" y="16" width="5" height="3" fill="#181814" />
          <path d="M8 14H14M11 11V17" stroke="#f5eedb" strokeWidth="2" />
        </svg>
      );
    case 'turret':
      return (
        <svg viewBox="0 0 28 28" className={className} fill="none" aria-hidden="true">
          <rect x="5" y="5" width="18" height="18" fill="#5e6159" stroke="#141611" strokeWidth="2" />
          <rect x="9" y="9" width="10" height="10" fill="#6ca353" stroke="#141611" strokeWidth="1.5" />
          <rect x="17" y="10.5" width="9" height="2.5" fill="#d9d1bc" />
          <rect x="17" y="15" width="9" height="2.5" fill="#d9d1bc" />
        </svg>
      );
    default:
      return <TruckIcon className={className} />;
  }
};
