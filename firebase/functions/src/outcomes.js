// Okuma sonuçları tablosu (FAZ 14 madde 4 + araştırma döngüsü, 13 Ekim 2026).
//
// Girdi: `readingEvents` belgeleri. Ebeveyn "Okuma bilgisini paylaş" açıkken gelir;
// içlerinde kişi, aile ya da cihaz kimliği yok (firestore.rules → validEvent).
// Çıktı: blueprint × yaş bandı × mod hücreleri; yalnızca sayılar.
//
// Mahremiyet kuralları (privacy-safety, exchange p_length_twelve_spreads):
// - Küçük hücre yayımlanmaz: en az MIN_EVENTS okuma ve en az MIN_DAYS farklı gün.
//   Olaylarda kişi kimliği olmadığı için "kişi başına gün" sayılamaz; eşik okuma
//   sayısı ve takvim günü yayılımıdır. Bastırılan hücre sayısı dışında iz kalmaz.
// - Satır değil yalnızca toplam çıkar; çocuk ya da aile bazında hiçbir şey yok.
// - Uyku öncesinde yarıda bırakmak başarısızlık sayılmaz: o modda ağırlık yalnızca
//   tekrar okumadan gelir (motorun ModeSuccessRule'u ile aynı ilke).
// - Ağırlık seçimi yalnızca dürter: [0.6, 1.8] aralığına kıstırılır (UsageLearner ile aynı).

export const MIN_EVENTS = 50;
export const MIN_DAYS = 7;
export const WEIGHT_FLOOR = 0.6;
export const WEIGHT_CEILING = 1.8;
const DAY = /^\d{4}-\d{2}-\d{2}$/;

/** Sakin modlar: yarıda bırakmak ceza değil. */
const ABANDON_NOT_PENALTY = new Set(['bedtime']);

function cellKey(e) {
  return `${e.blueprintID}|${e.ageBand || 'unknown'}|${e.mode || 'unknown'}`;
}

/**
 * @param events okuma olayları (Firestore belgelerinin verisi)
 * @returns {cells, suppressed, rejected}
 */
export function aggregateOutcomes(events, { minEvents = MIN_EVENTS, minDays = MIN_DAYS } = {}) {
  const tally = new Map();
  let rejected = 0;
  for (const e of events) {
    if (!e || typeof e.blueprintID !== 'string' || !DAY.test(e.day || '') || typeof e.finished !== 'boolean') {
      rejected += 1;
      continue;
    }
    const key = cellKey(e);
    const cell = tally.get(key) || { blueprintID: e.blueprintID, ageBand: e.ageBand || 'unknown',
      mode: e.mode || 'unknown', starts: 0, completions: 0, rereads: 0, abandoned: 0, days: new Set() };
    cell.starts += 1;
    if (e.finished) cell.completions += 1; else cell.abandoned += 1;
    if (e.reread) cell.rereads += 1;
    cell.days.add(e.day);
    tally.set(key, cell);
  }
  const cells = [];
  let suppressed = 0;
  for (const cell of [...tally.values()].sort((a, b) => cellKey(a).localeCompare(cellKey(b)))) {
    if (cell.starts < minEvents || cell.days.size < minDays) { suppressed += 1; continue; }
    const { days, ...counts } = cell;
    cells.push({ ...counts, readingDays: days.size });
  }
  return { cells, suppressed, rejected };
}

/**
 * Bir hücrenin "başarı" sayısı, modun kuralına göre ve her okuma en çok bir kez:
 * çoğu modda bitirilen okuma; uyku öncesinde tekrar okuma (bitirmemek orada ceza değil).
 */
export function successes(cell) {
  return ABANDON_NOT_PENALTY.has(cell.mode) ? cell.rereads : cell.completions;
}

/** Beta(1+s, 1+n−s) ortalaması, n = okuma sayısı. */
export function posteriorMean(cell) {
  const s = Math.min(successes(cell), cell.starts);
  return (1 + s) / (2 + cell.starts);
}

/**
 * Blueprint ağırlıkları: hücrenin posterior ortalaması / aynı bant×mod hücrelerinin ortalaması.
 * Deterministik (sabit tohumlu Thompson çekilişi yerine ortalama): aynı tablo her zaman
 * aynı kataloğu verir; motorun belirlenimciliği korunur.
 */
export function outcomeWeights(cells) {
  const groups = new Map();
  for (const cell of cells) {
    const group = `${cell.ageBand}|${cell.mode}`;
    groups.set(group, [...(groups.get(group) || []), cell]);
  }
  const weights = {};
  for (const members of groups.values()) {
    const mean = members.reduce((sum, c) => sum + posteriorMean(c), 0) / members.length;
    for (const cell of members) {
      const ratio = mean > 0 ? posteriorMean(cell) / mean : 1;
      const w = Math.min(WEIGHT_CEILING, Math.max(WEIGHT_FLOOR, ratio));
      // Bir blueprint birden çok bant/modda okunabilir: en temkinli (en küçük) ağırlık geçer.
      weights[cell.blueprintID] = Math.min(weights[cell.blueprintID] ?? Infinity, Math.round(w * 1000) / 1000);
    }
  }
  return weights;
}

/** Araştırmanın içe aktardığı belge (book-agent usage import). */
export function outcomeDocument(events, { periodStart, periodEnd, ...options }) {
  const { cells, suppressed, rejected } = aggregateOutcomes(events, options);
  return {
    schemaVersion: 1,
    periodStart,
    periodEnd,
    thresholds: { minEvents: options.minEvents ?? MIN_EVENTS, minDays: options.minDays ?? MIN_DAYS },
    cells,
    suppressedCells: suppressed,
    rejectedEvents: rejected,
    weights: outcomeWeights(cells),
  };
}
