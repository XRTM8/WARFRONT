import { Lang, TheaterId, UnitKind } from './types';

export interface Translations {
  subtitle: string;
  startMission: string;
  selectTheater: string;
  newSeed: string;
  controlsHint: string;
  oil: string;
  rigs: string;
  trucks: string;
  bridges: string;
  hq: string;
  enemyHq: string;
  stranded: string;
  selectAll: string;
  centerHq: string;
  rebuildBridge: string;
  rebuildBridgeRole: string;
  cancelPlacement: string;
  placeTurretHint: string;
  rebuildBridgeHint: string;
  paused: string;
  resume: string;
  restart: string;
  mainMenu: string;
  victoryTitle: string;
  victoryDesc: string;
  defeatTitle: string;
  defeatDesc: string;
  playAgain: string;
  nextTheater: string;
  statOilDelivered: string;
  statBridgesCut: string;
  statTrucksAmbush: string;
  statTime: string;
  statScore: string;
  muteLabel: string;
  pauseLabel: string;
  restartLabel: string;
  minimapLabel: string;
  theaters: Record<TheaterId, { name: string; region: string }>;
  units: Record<UnitKind, { name: string; role: string }>;
  events: Record<string, string>;
}

const AR: Translations = {
  subtitle: 'النفط هو العملة الوحيدة · اقطع الجسور لتجويع جيش العدو',
  startMission: 'بدء المعركة',
  selectTheater: 'مسرح العمليات',
  newSeed: 'خريطة عشوائية جديدة',
  controlsHint: 'سحب يسار: تحديد · نقر يمين: تحرك / هجوم / تدمير جسر · WASD: تحريك الكاميرا · 1-5: إنتاج · P: إيقاف',
  oil: 'النفط',
  rigs: 'الآبار',
  trucks: 'الشاحنات',
  bridges: 'الجسور',
  hq: 'القيادة',
  enemyHq: 'قيادة العدو',
  stranded: 'عالق',
  selectAll: 'كل الوحدات',
  centerHq: 'القيادة',
  rebuildBridge: 'إصلاح جسر',
  rebuildBridgeRole: 'ترميم طريق الإمداد',
  cancelPlacement: 'إلغاء (Esc)',
  placeTurretHint: 'انقر على الخريطة لبناء برج رشاش دفاعي',
  rebuildBridgeHint: 'انقر على جسر مدمّر لإعادة بنائه (110 نفط)',
  paused: 'المعركة متوقفة',
  resume: 'متابعة القتال',
  restart: 'إعادة المهمة',
  mainMenu: 'القائمة الرئيسية',
  victoryTitle: 'انتصار حاسم',
  victoryDesc: 'تم شل خطوط إمداد العدو وتدمير مقره القيادي بالكامل.',
  defeatTitle: 'سقط المقر القيادي',
  defeatDesc: 'انهارت خطوط الإمداد واجتاحت قوات العدو القاعدة.',
  playAgain: 'العب مجدداً',
  nextTheater: 'المسرح التالي',
  statOilDelivered: 'النفط المسلّم',
  statBridgesCut: 'جسور مدمّرة',
  statTrucksAmbush: 'شاحنات أُبيدت',
  statTime: 'مدة المعركة',
  statScore: 'التقييم',
  muteLabel: 'كتم الصوت',
  pauseLabel: 'إيقاف مؤقت',
  restartLabel: 'إعادة المهمة',
  minimapLabel: 'الخريطة التكتيكية',
  theaters: {
    kirkuk: { name: 'آبار كركوك', region: 'حقول النفط المشتعلة · العراق' },
    suez: { name: 'عبور القناة', region: 'الجسور التوأم الاستراتيجية' },
    newyork: { name: 'ميناء نيويورك', region: 'الأرصفة الساحلية والطرق الحضرية' },
    procedural: { name: 'مناوشة عشوائية', region: 'خريطة مولّدة إجرائياً' },
  },
  units: {
    truck: { name: 'شاحنة نفط', role: 'نقل البراميل عبر الطرق' },
    scout: { name: 'همفي استطلاع', role: 'سريع · صيد الشاحنات' },
    tank: { name: 'دبابة قتالية', role: 'درع ثقيل · خط أمامي' },
    artillery: { name: 'راجمة صواريخ', role: 'قصف بعيد · تدمير الجسور' },
    engineer: { name: 'مهندس قتالي', role: 'سيطرة سريعة · تفجير وبناء الجسور' },
    turret: { name: 'برج دفاعي', role: 'حماية الطرق والآبار' },
  },
  events: {
    bridge_destroyed: 'تم نسف الجسر! انقطع خط إمداد النفط.',
    bridge_rebuilt: 'أُعيد بناء الجسر وعادت الشاحنات للحركة.',
    rig_captured: 'تمت السيطرة على بئر نفط جديد!',
    rig_lost: 'استولى العدو على أحد آبار النفط!',
    truck_ambushed: 'تم تدمير شاحنة إمداد معادية!',
    enemy_starving: 'شاحنات العدو محاصرة بلا جسر عبور!',
    hq_under_attack: 'تحذير: المقر القيادي يتعرض للقصف!',
    not_enough_oil: 'لا يوجد نفط كافٍ — احمِ شاحناتك!',
  },
};

const EN: Translations = {
  subtitle: 'Oil is the only currency · Blow bridges to starve the enemy army',
  startMission: 'Deploy Forces',
  selectTheater: 'Theater of War',
  newSeed: 'New Map Seed',
  controlsHint: 'Left Drag: Select · Right Click: Move / Attack / Blow Bridge · WASD: Pan · 1-5: Deploy · P: Pause',
  oil: 'OIL',
  rigs: 'RIGS',
  trucks: 'TRUCKS',
  bridges: 'BRIDGES',
  hq: 'HQ',
  enemyHq: 'ENEMY HQ',
  stranded: 'CUT OFF',
  selectAll: 'All Units',
  centerHq: 'Base',
  rebuildBridge: 'Rebuild Bridge',
  rebuildBridgeRole: 'Restore supply crossing',
  cancelPlacement: 'Cancel (Esc)',
  placeTurretHint: 'Click valid ground to deploy Defense Turret',
  rebuildBridgeHint: 'Click any blown bridge to rebuild it (110 Oil)',
  paused: 'Battle Paused',
  resume: 'Resume Command',
  restart: 'Restart Mission',
  mainMenu: 'Title Screen',
  victoryTitle: 'Decisive Victory',
  victoryDesc: 'Enemy supply arteries severed and Command HQ neutralized.',
  defeatTitle: 'Command HQ Lost',
  defeatDesc: 'Your oil logistics collapsed under hostile assault.',
  playAgain: 'Play Again',
  nextTheater: 'Next Theater',
  statOilDelivered: 'Oil Delivered',
  statBridgesCut: 'Bridges Blown',
  statTrucksAmbush: 'Trucks Ambushed',
  statTime: 'Mission Time',
  statScore: 'Score',
  muteLabel: 'Toggle Sound',
  pauseLabel: 'Pause Game',
  restartLabel: 'Restart Match',
  minimapLabel: 'Tactical Minimap',
  theaters: {
    kirkuk: { name: 'Kirkuk Oil Wells', region: 'Burning Fields · Iraq' },
    suez: { name: 'Canal Crossings', region: 'Twin Choke Bridges' },
    newyork: { name: 'New York Harbor', region: 'Coastal Piers & Bridges' },
    procedural: { name: 'Procedural Skirmish', region: 'Dynamic Generated Map' },
  },
  units: {
    truck: { name: 'Oil Truck', role: 'Hauls barrels along roads' },
    scout: { name: 'Recon Humvee', role: 'Fast · Convoy Hunter' },
    tank: { name: 'Battle Tank', role: 'Heavy Armor · Frontline' },
    artillery: { name: 'MLRS Rocket', role: 'Long-Range · Bridge Buster' },
    engineer: { name: 'Combat Engineer', role: 'Fast Capture · Bridge Ops' },
    turret: { name: 'Gun Turret', role: 'Defends roads & rigs' },
  },
  events: {
    bridge_destroyed: 'Bridge blown! Oil convoy line severed.',
    bridge_rebuilt: 'Bridge repaired — supply trucks rolling.',
    rig_captured: 'Oil rig secured! Dispatching fuel truck.',
    rig_lost: 'Warning: Enemy captured an oil rig!',
    truck_ambushed: 'Enemy oil tanker destroyed!',
    enemy_starving: 'Enemy supply trucks stranded behind blown bridge!',
    hq_under_attack: 'Alert: Command HQ under fire!',
    not_enough_oil: 'Insufficient oil — protect your supply trucks!',
  },
};

export function getT(lang: Lang): Translations {
  return lang === 'ar' ? AR : EN;
}
