// Okuma sonuçları tablosu: saf modül, bağımlılık gerekmez (`npm test`).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { aggregateOutcomes, outcomeWeights, outcomeDocument, posteriorMean, MIN_EVENTS } from '../src/outcomes.js';

const day = (n) => `2026-10-${String(n).padStart(2, '0')}`;
function events(blueprintID, { n, finished, reread = 0, mode = 'adventure', ageBand = '5-6', days = 10 }) {
  return Array.from({ length: n }, (_, i) => ({
    schemaVersion: 1, blueprintID, mode, ageBand, contentIDs: { setting: 's', companion: 'c', discovery: 'd' },
    pageReached: 8, pageCount: 8, finished: i < finished, reread: i < reread, day: day(1 + (i % days)),
  }));
}

test('küçük hücreler yayımlanmaz: okuma sayısı ya da gün yayılımı yetmezse', () => {
  const few = events('bp_a', { n: MIN_EVENTS - 1, finished: 10 });
  const oneWeekend = events('bp_b', { n: 80, finished: 40, days: 2 });
  const enough = events('bp_c', { n: 60, finished: 30 });
  const { cells, suppressed } = aggregateOutcomes([...few, ...oneWeekend, ...enough]);
  assert.deepEqual(cells.map((c) => c.blueprintID), ['bp_c']);
  assert.equal(suppressed, 2);
});

test('çıktıda satır ya da kişi izi yok, yalnızca sayılar', () => {
  const { cells } = aggregateOutcomes(events('bp_c', { n: 60, finished: 30, reread: 5 }));
  assert.deepEqual(Object.keys(cells[0]).sort(),
    ['abandoned', 'ageBand', 'blueprintID', 'completions', 'mode', 'readingDays', 'rereads', 'starts']);
  assert.deepEqual(cells[0], { blueprintID: 'bp_c', ageBand: '5-6', mode: 'adventure', starts: 60,
    completions: 30, rereads: 5, abandoned: 30, readingDays: 10 });
});

test('bozuk olay sayılmaz ama hücreyi bozmaz', () => {
  const { cells, rejected } = aggregateOutcomes([...events('bp_c', { n: 60, finished: 30 }), { blueprintID: 'bp_c' }, null]);
  assert.equal(rejected, 2);
  assert.equal(cells[0].starts, 60);
});

test('uyku öncesinde yarıda bırakmak ceza değildir', () => {
  const finishesButNoRereads = { mode: 'bedtime', starts: 100, completions: 90, rereads: 0 };
  const neverFinishesButRereads = { mode: 'bedtime', starts: 100, completions: 10, rereads: 40 };
  assert.ok(posteriorMean(neverFinishesButRereads) > posteriorMean(finishesButNoRereads));
});

test('ağırlıklar bant×mod içinde göreli, [0.6, 1.8] aralığında ve deterministik', () => {
  const cells = aggregateOutcomes([
    ...events('bp_good', { n: 200, finished: 190 }),
    ...events('bp_poor', { n: 200, finished: 20 }),
    ...events('bp_bed', { n: 200, finished: 50, reread: 60, mode: 'bedtime' }),
  ]).cells;
  const w = outcomeWeights(cells);
  assert.ok(w.bp_good > 1 && w.bp_good <= 1.8);
  assert.ok(w.bp_poor < 1 && w.bp_poor >= 0.6);
  assert.equal(w.bp_bed, 1, 'tek başına kalan bant×mod grubu nötr');
  assert.deepEqual(outcomeWeights(cells), w);
});

test('araştırmaya giden belge eşikleri ve bastırılan hücre sayısını taşır', () => {
  const doc = outcomeDocument(events('bp_c', { n: 60, finished: 30 }), { periodStart: day(1), periodEnd: day(28) });
  assert.equal(doc.schemaVersion, 1);
  assert.deepEqual(doc.thresholds, { minEvents: 50, minDays: 7 });
  assert.equal(doc.cells.length, 1);
  assert.equal(doc.weights.bp_c, 1);
});

test('gelen kutusu belgesi: yalnızca createdAt metne döner, gerisi aynı kalır', async () => {
  const { inboxDocument } = await import('../src/outcomes.js');
  const doc = outcomeDocument(events('bp_c', { n: 60, finished: 30 }), { periodStart: '2026-10-01', periodEnd: '2026-10-28' });
  const stamp = { toDate: () => new Date('2026-10-28T01:00:00Z') };
  const inbox = inboxDocument({ ...doc, createdAt: stamp });
  assert.equal(inbox.createdAt, '2026-10-28T01:00:00.000Z');
  assert.deepEqual({ ...inbox, createdAt: undefined }, { ...doc, createdAt: undefined });
  assert.deepEqual(inboxDocument(doc), doc);
});
