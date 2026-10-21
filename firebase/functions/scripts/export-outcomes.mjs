// Haftalık okuma sonuçlarını araştırma ajanının gelen kutusuna indirir.
//
//   cd firebase/functions && node scripts/export-outcomes.mjs [--weeks 4] [--out <klasör>]
//
// Firestore'a uygulama varsayılan kimlik bilgileriyle bağlanır (gcloud auth application-default login).
// Yalnızca outcomeAggregates belgelerini okur: tek tek okuma olayı, kullanıcı ya da çocuk bilgisi yoktur.
// Varsayılan hedef: MagicPaper-research/Research/BookIntelligence/inbox/usage/ (git'e girmez).
// Sonra araştırma tarafında: python3 Research/BookIntelligence/book_agent.py cycle
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { inboxDocument } from '../src/outcomes.js';

const args = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : fallback;
};
const weeks = Number(opt('weeks', '4'));
const out = resolve(opt('out', '../../../MagicPaper-research/Research/BookIntelligence/inbox/usage'));

initializeApp();
const snap = await getFirestore().collection('outcomeAggregates').orderBy('periodEnd', 'desc').limit(weeks).get();
mkdirSync(out, { recursive: true });
for (const d of snap.docs) {
  const doc = inboxDocument(d.data());
  writeFileSync(join(out, `${doc.periodEnd}.json`), JSON.stringify(doc, null, 2) + '\n');
  console.log(`→ ${doc.periodEnd}: ${doc.cells.length} hücre`);
}
console.log(snap.empty ? 'outcomeAggregates boş (fonksiyon henüz çalışmadı mı?)' : `${snap.size} dönem → ${out}`);
