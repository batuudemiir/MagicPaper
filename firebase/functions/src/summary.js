// Haftalık özet (FAZ 18): ailenin son yedi günü, sakin bir dille.
//
// Girdi ailenin eşitleme kayıtları (uygulamanın kendi modelleri, JSON metin).
// Çıktıda masal metni yok; yalnızca çocuğun adı ve sayılar. Hiçbir şey
// okunmadıysa e-posta gönderilmez: "geri gel" demek yok (CLAUDE.md ilke 7).

const APPLE_EPOCH_OFFSET = 978307200; // 2001-01-01 ile 1970-01-01 arası, saniye
const WEEK_MS = 7 * 86400 * 1000;

/** Swift JSONEncoder'ın varsayılan tarihi: 2001'den beri saniye. */
export function appleDate(value) {
  if (typeof value === 'number') return new Date((value + APPLE_EPOCH_OFFSET) * 1000);
  if (typeof value === 'string') { const d = new Date(value); return isNaN(d) ? null : d; }
  return null;
}

function parse(payload) {
  try { return JSON.parse(payload); } catch { return null; }
}

/**
 * @param records {children, stories, progress, badges}: her biri [{id, payload}] (silinmişler hariç)
 * @param now Date
 * @returns [{name, read, written, badges}] — yalnızca bu hafta bir şey olan çocuklar
 */
export function buildWeeklySummary(records, now = new Date()) {
  const since = now.getTime() - WEEK_MS;
  const inWeek = (date) => date && date.getTime() > since && date.getTime() <= now.getTime();

  const children = new Map();
  for (const { id, payload } of records.children || []) {
    const child = parse(payload);
    const name = child?.profile?.name;
    if (name) children.set(id.toUpperCase(), { name, read: 0, written: 0, badges: 0 });
  }

  const storyChild = new Map();
  for (const { id, payload } of records.stories || []) {
    const story = parse(payload);
    if (!story) continue;
    const childID = (story.childProfileID || '').toUpperCase();
    storyChild.set(id.toUpperCase(), childID);
    const entry = children.get(childID);
    if (entry && inWeek(appleDate(story.createdAt))) entry.written += 1;
  }

  for (const { id, payload } of records.progress || []) {
    const progress = parse(payload);
    const entry = children.get(storyChild.get(id.toUpperCase()));
    if (entry && inWeek(appleDate(progress?.lastReadAt))) entry.read += 1;
  }

  for (const { id, payload } of records.badges || []) {
    const ledger = parse(payload);
    const entry = children.get(id.toUpperCase());
    if (!entry || !ledger?.earned) continue;
    // Swift sözlüğü JSON'da [anahtar, değer, anahtar, değer…] dizisi ya da nesne olabilir.
    const dates = Array.isArray(ledger.earned)
      ? ledger.earned.filter((_, i) => i % 2 === 1)
      : Object.values(ledger.earned);
    entry.badges += dates.filter((d) => inWeek(appleDate(d))).length;
  }

  return [...children.values()].filter((c) => c.read + c.written + c.badges > 0);
}

const escapeHTML = (s) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

/** Bir çocuğun satırı: "İrem ile bu hafta 4 masal okudunuz, 2 yeni masal yazıldı." */
export function childLine({ name, read, written, badges }) {
  const parts = [];
  if (read > 0) parts.push(`${name} ile bu hafta ${read} masal okudunuz`);
  if (written > 0) parts.push(`${written} yeni masal yazıldı`);
  if (badges > 0) parts.push(`${badges} yeni rozet kazanıldı`);
  if (read === 0) parts[0] = `${name} için ${parts[0]}`;
  return parts.join(', ') + '.';
}

/**
 * @returns {subject, text, html} ya da özet boşsa null
 */
export function renderWeeklyEmail(summary, unsubscribeURL) {
  if (!summary.length) return null;
  const lines = summary.map(childLine);
  const subject = 'Bu haftanın masalları';
  const footer = 'Bu e-postayı MagicPaper ayarlarında haftalık özeti açtığın için aldın.';
  const text = [
    'Merhaba,',
    '',
    ...lines,
    '',
    'Okuma yolculuğunuz devam ediyor.',
    '',
    footer,
    `Almak istemezsen: ${unsubscribeURL}`,
  ].join('\n');
  const html = `<!doctype html><html lang="tr"><body style="margin:0;background:#FFF8EE;color:#2E1E3E;font-family:Nunito,Helvetica,Arial,sans-serif">
<div style="max-width:560px;margin:0 auto;padding:32px 20px;font-size:17px;line-height:1.6">
<p lang="en" style="font-size:13px;font-weight:800;letter-spacing:.06em;text-transform:uppercase;color:#6E6478;margin:0 0 8px">MagicPaper</p>
<h1 style="font-size:24px;line-height:1.25;margin:0 0 20px">${subject}</h1>
${lines.map((l) => `<p style="margin:0 0 12px">${escapeHTML(l)}</p>`).join('\n')}
<p style="margin:20px 0 0">Okuma yolculuğunuz devam ediyor.</p>
<p style="margin:32px 0 0;font-size:13px;color:#6E6478">${footer}<br><a href="${escapeHTML(unsubscribeURL)}" style="color:#6A47B8">Haftalık özeti kapat</a></p>
</div></body></html>`;
  return { subject, text, html };
}
