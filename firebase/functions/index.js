// MagicPaper Cloud Functions (FAZ 18). Bölge europe-west1.
//
// weeklySummary: Pazar 09:00 (Europe/Istanbul), haftalık özeti açmış
//   ailelere Resend ile sakin bir özet. Hiçbir şey okunmadıysa gönderilmez.
// unsubscribe: e-postadaki tek tık bağlantısı (imzalı).
// cleanupShares: süresi dolan paylaşım bağlantılarını ve ses kopyalarını siler.
//
// Log'a e-posta adresi, çocuk adı, masal metni yazılmaz (CLAUDE.md §10).
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions';
import { buildWeeklySummary, renderWeeklyEmail } from './src/summary.js';
import { unsubscribeURL, verifyFamily } from './src/unsubscribe.js';
import { sendWithResend } from './src/resend.js';

initializeApp();
const REGION = 'europe-west1';
const RESEND_API_KEY = defineSecret('RESEND_API_KEY');
const UNSUBSCRIBE_SECRET = defineSecret('UNSUBSCRIBE_SECRET');
const MAIL_FROM = defineString('MAIL_FROM', { default: 'MagicPaper <ozet@magicpaperkids.com>' });

async function records(db, familyID, name) {
  const snapshot = await db.collection('families').doc(familyID).collection(name).get();
  return snapshot.docs
    .filter((d) => d.get('deleted') !== true && typeof d.get('payload') === 'string')
    .map((d) => ({ id: d.id, payload: d.get('payload') }));
}

export const weeklySummary = onSchedule(
  { schedule: 'every sunday 09:00', timeZone: 'Europe/Istanbul', region: REGION, secrets: [RESEND_API_KEY, UNSUBSCRIBE_SECRET] },
  async () => {
    const db = getFirestore();
    const subscribed = await db.collectionGroup('settings').where('enabled', '==', true).get();
    let sent = 0, skipped = 0, failed = 0;
    for (const setting of subscribed.docs) {
      if (setting.id !== 'weeklyEmail') continue;
      const familyID = setting.ref.parent.parent.id;
      try {
        const summary = buildWeeklySummary({
          children: await records(db, familyID, 'children'),
          stories: await records(db, familyID, 'stories'),
          progress: await records(db, familyID, 'progress'),
          badges: await records(db, familyID, 'badges'),
        });
        const link = unsubscribeURL(`https://${REGION}-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/unsubscribe`,
          familyID, UNSUBSCRIBE_SECRET.value());
        const email = renderWeeklyEmail(summary, link);
        if (!email) { skipped += 1; continue; }
        await sendWithResend({ apiKey: RESEND_API_KEY.value(), from: MAIL_FROM.value(), to: setting.get('email'),
          ...email, unsubscribe: link });
        sent += 1;
      } catch (error) {
        failed += 1;
        logger.warn('Haftalık özet gönderilemedi', { reason: String(error.message).slice(0, 80) });
      }
    }
    logger.info('Haftalık özet', { sent, skipped, failed });
  });

const page = (title, body) => '<!doctype html><html lang="tr"><meta charset="utf-8">' +
  '<meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex">' +
  '<body style="font-family:Helvetica,Arial,sans-serif;background:#FFF8EE;color:#2E1E3E;padding:40px 16px;max-width:520px;margin:0 auto">' +
  `<h1 style="font-size:24px">${title}</h1>${body}</body></html>`;

// GET bir onay sayfası gösterir (e-posta tarayıcılarının önizlemesi kimseyi
// çıkarmasın); POST (düğme ya da List-Unsubscribe-Post) kapatır.
export const unsubscribe = onRequest({ region: REGION, secrets: [UNSUBSCRIBE_SECRET] }, async (req, res) => {
  const familyID = String(req.query.f || '');
  const signature = String(req.query.s || '');
  res.set('Content-Type', 'text/html; charset=utf-8');
  if (!verifyFamily(familyID, signature, UNSUBSCRIBE_SECRET.value())) {
    res.status(400).send(page('Bağlantı geçersiz', '<p>Haftalık özeti uygulamanın ayarlarından da kapatabilirsin.</p>'));
    return;
  }
  if (req.method !== 'POST') {
    res.send(page('Haftalık özeti kapat', '<p>Pazar sabahları gelen özet artık gönderilmesin mi?</p>' +
      '<form method="post"><button style="font-size:16px;font-weight:700;padding:14px 24px;border-radius:999px;border:0;background:#6A47B8;color:#fff">Özeti kapat</button></form>'));
    return;
  }
  await getFirestore().collection('families').doc(familyID).collection('settings').doc('weeklyEmail')
    .set({ enabled: false, updatedAt: Timestamp.now() }, { merge: true });
  res.send(page('Haftalık özet kapatıldı',
    '<p>Bir daha gönderilmeyecek. İstersen uygulamanın ayarlarından yeniden açabilirsin.</p>'));
});

export const cleanupShares = onSchedule(
  { schedule: 'every day 04:00', timeZone: 'Europe/Istanbul', region: REGION },
  async () => {
    const db = getFirestore();
    const bucket = getStorage().bucket();
    const expired = await db.collection('shares').where('expiresAt', '<=', Timestamp.now()).limit(500).get();
    for (const share of expired.docs) {
      await bucket.deleteFiles({ prefix: `shares/${share.id}/` }).catch(() => {});
      const familyID = share.get('familyID');
      if (familyID) await db.collection('families').doc(familyID).collection('shares').doc(share.id).delete().catch(() => {});
      await share.ref.delete();
    }
    logger.info('Süresi dolan paylaşımlar silindi', { count: expired.size });
  });
