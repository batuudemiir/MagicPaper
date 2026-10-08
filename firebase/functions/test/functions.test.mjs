// Haftalık özet ve abonelikten çıkma: saf modüller (FAZ 18).
// Çalıştırma: firebase/functions içinde `npm test` (bağımlılık gerekmez).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { appleDate, buildWeeklySummary, childLine, renderWeeklyEmail } from '../src/summary.js';
import { signFamily, verifyFamily, unsubscribeURL } from '../src/unsubscribe.js';
import { sendWithResend, RESEND_ENDPOINT } from '../src/resend.js';

const NOW = new Date('2026-10-11T06:00:00Z');
const apple = (date) => date.getTime() / 1000 - 978307200;
const daysAgo = (n) => apple(new Date(NOW.getTime() - n * 86400000));
const CHILD = 'AAAAAAAA-0000-4000-8000-000000000001';

const child = { id: CHILD, payload: JSON.stringify({ profile: { name: 'İrem' }, avatarColor: 2 }) };
const story = (id, created) => ({ id, payload: JSON.stringify({ title: `Masal ${id}`, childProfileID: CHILD, createdAt: created, pages: [{ text: 'gizli metin' }] }) });
const progress = (id, read) => ({ id, payload: JSON.stringify({ lastReadPage: 3, lastReadAt: read }) });

test('Swift tarihi 2001 başlangıçlı saniyeden okunur', () => {
  assert.equal(appleDate(0).toISOString(), '2001-01-01T00:00:00.000Z');
  assert.equal(appleDate('bozuk'), null);
});

test('yalnızca son yedi günün okumaları, yazılanları ve rozetleri sayılır', () => {
  const summary = buildWeeklySummary({
    children: [child],
    stories: [story('S1', daysAgo(2)), story('S2', daysAgo(20)), story('S3', daysAgo(1))],
    progress: [progress('S1', daysAgo(1)), progress('S2', daysAgo(3)), progress('S3', daysAgo(9))],
    badges: [{ id: CHILD, payload: JSON.stringify({ earned: ['ilkMasal', daysAgo(2), 'onMasal', daysAgo(30)] }) }],
  }, NOW);
  assert.deepEqual(summary, [{ name: 'İrem', read: 2, written: 2, badges: 1 }]);
});

test('hiçbir şey olmayan hafta e-posta üretmez', () => {
  const summary = buildWeeklySummary({ children: [child], stories: [story('S2', daysAgo(20))], progress: [], badges: [] }, NOW);
  assert.deepEqual(summary, []);
  assert.equal(renderWeeklyEmail(summary, 'https://x'), null);
});

test('e-posta sakin dilde, masal metni ve baskı içermez', () => {
  const email = renderWeeklyEmail([{ name: 'İrem', read: 4, written: 1, badges: 0 }], 'https://u.example/unsub?f=a&s=b');
  assert.equal(email.subject, 'Bu haftanın masalları');
  assert.match(email.text, /İrem ile bu hafta 4 masal okudunuz, 1 yeni masal yazıldı\./);
  assert.match(email.text, /Okuma yolculuğunuz devam ediyor\./);
  assert.doesNotMatch(email.text + email.html, /gizli metin|kaçırma|hemen|son şans|geri dön/i);
  assert.match(email.html, /u\.example\/unsub\?f=a&amp;s=b/);
});

test('okuma yoksa satır yine ad ile başlar', () => {
  assert.equal(childLine({ name: 'Ada', read: 0, written: 2, badges: 0 }), 'Ada için 2 yeni masal yazıldı.');
});

test('çocuk adı HTML olarak kaçırılır', () => {
  const email = renderWeeklyEmail([{ name: '<b>Ada</b>', read: 1, written: 0, badges: 0 }], 'https://x');
  assert.doesNotMatch(email.html, /<b>Ada<\/b>/);
});

test('abonelikten çıkma bağlantısı imzalı; değiştirilen kimlik reddedilir', () => {
  const secret = 'test-secret';
  const signature = signFamily('family-1', secret);
  assert.ok(verifyFamily('family-1', signature, secret));
  assert.equal(verifyFamily('family-2', signature, secret), false);
  assert.equal(verifyFamily('family-1', signature, 'other'), false);
  assert.equal(verifyFamily('family-1', '', secret), false);
  const url = new URL(unsubscribeURL('https://example.com/unsubscribe', 'family-1', secret));
  assert.equal(url.searchParams.get('f'), 'family-1');
  assert.ok(verifyFamily('family-1', url.searchParams.get('s'), secret));
});

test('Resend isteği tek alıcıya, tek tık çıkış başlığıyla gider', async () => {
  let call;
  const fakeFetch = async (url, init) => { call = { url, init }; return { ok: true, json: async () => ({ id: 'm1' }) }; };
  await sendWithResend({ apiKey: 'k', from: 'MagicPaper <a@b.c>', to: 'veli@example.com', subject: 's', text: 't', html: 'h',
    unsubscribe: 'https://u' }, fakeFetch);
  assert.equal(call.url, RESEND_ENDPOINT);
  assert.equal(call.init.headers.Authorization, 'Bearer k');
  const body = JSON.parse(call.init.body);
  assert.deepEqual(body.to, ['veli@example.com']);
  assert.equal(body.headers['List-Unsubscribe'], '<https://u>');
  assert.equal(body.headers['List-Unsubscribe-Post'], 'List-Unsubscribe=One-Click');
});

test('Resend hatası yalnızca durum koduyla döner', async () => {
  const fakeFetch = async () => ({ ok: false, status: 422, json: async () => ({ message: 'veli@example.com geçersiz' }) });
  await assert.rejects(sendWithResend({ apiKey: 'k', from: 'f', to: 'veli@example.com', subject: 's', text: 't', html: 'h', unsubscribe: 'u' }, fakeFetch),
    (error) => error.message === 'resend 422');
});
