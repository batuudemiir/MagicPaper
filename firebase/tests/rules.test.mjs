// MagicPaper Firestore kuralları testi (FAZ 16).
// Çalıştırma: firebase/ içinde `npm install` bir kez, sonra `npm test`
// (Firestore emülatörü Java ister).

import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, setDoc, getDoc, getDocs, updateDoc, deleteDoc, collection, addDoc,
  serverTimestamp, writeBatch,
} from 'firebase/firestore';

let env;
const ALICE = 'alice';
const BOB = 'bob';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-magicpaper',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

const record = (payload, extra = {}) => ({
  payload,
  deleted: false,
  updatedAt: 1759780000000,
  serverUpdatedAt: serverTimestamp(),
  schemaVersion: 1,
  ...extra,
});

const tombstone = () => ({
  deleted: true,
  updatedAt: 1759780000001,
  serverUpdatedAt: serverTimestamp(),
  schemaVersion: 1,
});

const event = (extra = {}) => ({
  schemaVersion: 1,
  mode: 'bedtime',
  blueprintID: 'bp_charge_01',
  contentIDs: { setting: 'setting_forest_001', companion: 'companion_fox_001', discovery: 'disc_01' },
  companionKind: 'tilki',
  familyRelation: 'sibling',
  ageBand: '5-6',
  pageReached: 7,
  pageCount: 8,
  finished: true,
  reread: false,
  day: '2026-10-06',
  ...extra,
});

// --- Aile belgeleri: yalnızca sahibi ---------------------------------------

test('sahibi kendi kaydını yazar ve okur', async () => {
  const ref = doc(db(ALICE), 'families', ALICE, 'children', 'c1');
  await assertSucceeds(setDoc(ref, record('{"name":"Ada"}')));
  await assertSucceeds(getDoc(ref));
});

test('başka bir ebeveyn okuyamaz, yazamaz, silemez', async () => {
  await assertSucceeds(setDoc(doc(db(ALICE), 'families', ALICE, 'stories', 's1'), record('{"t":1}')));
  const asBob = doc(db(BOB), 'families', ALICE, 'stories', 's1');
  await assertFails(getDoc(asBob));
  await assertFails(setDoc(asBob, record('{"t":2}')));
  await assertFails(deleteDoc(asBob));
  await assertFails(getDocs(collection(db(BOB), 'families', ALICE, 'stories')));
});

test('giriş yapmamış biri hiçbir aile belgesine erişemez', async () => {
  await assertFails(getDoc(doc(db(null), 'families', ALICE, 'children', 'c1')));
  await assertFails(setDoc(doc(db(null), 'families', ALICE, 'children', 'c1'), record('{}')));
});

test('bilinmeyen alt koleksiyon kapalı', async () => {
  await assertFails(setDoc(doc(db(ALICE), 'families', ALICE, 'photos', 'p1'), record('{}')));
});

test('kayıt biçimi dışında alan reddedilir', async () => {
  const ref = doc(db(ALICE), 'families', ALICE, 'children', 'c1');
  await assertFails(setDoc(ref, record('{}', { photoURL: 'x' })));
  await assertFails(setDoc(ref, record('{}', { serverUpdatedAt: new Date(0) })));
  await assertFails(setDoc(ref, record('{}', { updatedAt: 'dün' })));
  await assertFails(setDoc(ref, { ...tombstone(), payload: '{"name":"Ada"}' }));
});

test('silinen kayıt içeriksiz bir iz olarak kalır', async () => {
  const ref = doc(db(ALICE), 'families', ALICE, 'children', 'c1');
  await assertSucceeds(setDoc(ref, record('{"name":"Ada"}')));
  await assertSucceeds(setDoc(ref, tombstone()));
  const snap = await getDoc(ref);
  if ('payload' in snap.data()) throw new Error('iz içerik taşıyor');
});

// --- Masal metni değişmez ---------------------------------------------------

test('masal metni değiştirilemez', async () => {
  const ref = doc(db(ALICE), 'families', ALICE, 'stories', 's1');
  await assertSucceeds(setDoc(ref, record('{"pages":["Bir varmış"]}')));
  await assertFails(setDoc(ref, record('{"pages":["Başka bir şey"]}')));
});

test('aynı masal yeniden gönderilebilir ve silinebilir', async () => {
  const ref = doc(db(ALICE), 'families', ALICE, 'stories', 's1');
  await assertSucceeds(setDoc(ref, record('{"pages":["Bir varmış"]}')));
  await assertSucceeds(setDoc(ref, record('{"pages":["Bir varmış"]}', { updatedAt: 1759780000500 })));
  await assertSucceeds(setDoc(ref, tombstone()));
});

test('silinmiş masal geri yazılamaz', async () => {
  const ref = doc(db(ALICE), 'families', ALICE, 'stories', 's1');
  await assertSucceeds(setDoc(ref, record('{"pages":["Bir varmış"]}')));
  await assertSucceeds(setDoc(ref, tombstone()));
  await assertFails(setDoc(ref, record('{"pages":["Bir varmış"]}')));
});

test('okuma ilerlemesi ve profil güncellenebilir', async () => {
  const progress = doc(db(ALICE), 'families', ALICE, 'progress', 's1');
  await assertSucceeds(setDoc(progress, record('{"lastReadPage":2}')));
  await assertSucceeds(setDoc(progress, record('{"lastReadPage":5}')));
  const child = doc(db(ALICE), 'families', ALICE, 'children', 'c1');
  await assertSucceeds(setDoc(child, record('{"age":5}')));
  await assertSucceeds(updateDoc(child, { payload: '{"age":6}', updatedAt: 1759780000900, serverUpdatedAt: serverTimestamp() }));
});

// --- Ebeveyn onayı ----------------------------------------------------------

const consent = (version, extra = {}) => ({
  version,
  acceptedAt: serverTimestamp(),
  clientAcceptedAt: 1759780000000,
  shareUsageData: true,
  ...extra,
});

test('onay sürüm başına bir kez yazılır, değiştirilemez', async () => {
  const ref = doc(db(ALICE), 'families', ALICE, 'consents', '2026-10-06');
  await assertSucceeds(setDoc(ref, consent('2026-10-06')));
  await assertFails(setDoc(ref, consent('2026-10-06', { shareUsageData: false })));
  await assertSucceeds(getDoc(ref));
});

test('onay belgesinin sürümü adıyla aynı olmalı ve sunucu saati taşımalı', async () => {
  await assertFails(setDoc(doc(db(ALICE), 'families', ALICE, 'consents', 'v2'), consent('v1')));
  await assertFails(setDoc(doc(db(ALICE), 'families', ALICE, 'consents', 'v3'),
    consent('v3', { acceptedAt: new Date(0) })));
});

test('başkasının onayı okunamaz', async () => {
  await assertSucceeds(setDoc(doc(db(ALICE), 'families', ALICE, 'consents', 'v1'), consent('v1')));
  await assertFails(getDoc(doc(db(BOB), 'families', ALICE, 'consents', 'v1')));
});

// --- Okuma olayları ---------------------------------------------------------

test('giriş yapmış uygulama anonim olay ekler', async () => {
  await assertSucceeds(addDoc(collection(db(ALICE), 'readingEvents'), event()));
  // Seçmeli alanlar olmadan da (eski masal: mod yok, Masal ailem yok).
  const optional = ['mode', 'familyRelation', 'companionKind', 'ageBand'];
  const minimal = Object.fromEntries(Object.entries(event()).filter(([k]) => !optional.includes(k)));
  await assertSucceeds(addDoc(collection(db(ALICE), 'readingEvents'), minimal));
});

test('olay okunamaz, değiştirilemez, silinemez', async () => {
  let id;
  await env.withSecurityRulesDisabled(async (ctx) => {
    id = (await addDoc(collection(ctx.firestore(), 'readingEvents'), event())).id;
  });
  const ref = doc(db(ALICE), 'readingEvents', id);
  await assertFails(getDoc(ref));
  await assertFails(getDocs(collection(db(ALICE), 'readingEvents')));
  await assertFails(updateDoc(ref, { finished: false }));
  await assertFails(deleteDoc(ref));
});

test('olay kimlik ya da kişisel alan taşıyamaz', async () => {
  const events = collection(db(ALICE), 'readingEvents');
  await assertFails(addDoc(events, event({ uid: ALICE })));
  await assertFails(addDoc(events, event({ storyID: 'B3F1-…' })));
  await assertFails(addDoc(events, event({ childName: 'Ada' })));
  await assertFails(addDoc(events, event({ age: 5 })));
  await assertFails(addDoc(events, event({ ageBand: '5' })));
  await assertFails(addDoc(events, event({ familyRelation: 'Ayşe teyze' })));
  await assertFails(addDoc(events, event({ day: '2026-10-06T21:14:00Z' })));
});

test('giriş yapmamış biri olay ekleyemez', async () => {
  await assertFails(addDoc(collection(db(null), 'readingEvents'), event()));
});

// --- Hesap silme ------------------------------------------------------------

test('sahibi bütün aile belgelerini silebilir; geriye bir şey kalmaz', async () => {
  const alice = db(ALICE);
  const collections = ['children', 'avatars', 'family', 'stories', 'progress', 'series'];
  const batch = writeBatch(alice);
  for (const name of collections) {
    for (const id of ['a', 'b']) batch.set(doc(alice, 'families', ALICE, name, id), record(`{"${name}":"${id}"}`));
  }
  await batch.commit();
  await assertSucceeds(setDoc(doc(alice, 'families', ALICE, 'consents', 'v1'), consent('v1')));

  // Uygulamanın yaptığı sırayla: her koleksiyonu oku, sil; sonra aile belgesi.
  for (const name of [...collections, 'consents']) {
    const snap = await getDocs(collection(alice, 'families', ALICE, name));
    for (const d of snap.docs) await assertSucceeds(deleteDoc(d.ref));
  }
  await assertSucceeds(deleteDoc(doc(alice, 'families', ALICE)));

  await env.withSecurityRulesDisabled(async (ctx) => {
    const admin = ctx.firestore();
    for (const name of [...collections, 'consents']) {
      const left = await getDocs(collection(admin, 'families', ALICE, name));
      if (!left.empty) throw new Error(`${name}: ${left.size} belge kaldı`);
    }
  });
});
