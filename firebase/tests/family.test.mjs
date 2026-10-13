// MagicPaper Firestore kuralları: aile özellikleri (FAZ 18).
// Üyeler ve roller, davet, paylaşım bağlantısı, haftalık özet ayarı.
// Çalıştırma: `npm test` (rules.test.mjs ile birlikte, sırayla).

import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, setDoc, getDoc, getDocs, updateDoc, deleteDoc, collection, query, where,
  serverTimestamp, writeBatch, Timestamp,
} from 'firebase/firestore';

let env;
const OWNER = 'owner';      // ailenin kurucusu, familyID == OWNER
const MURAT = 'murat';      // ebeveyn rolüyle katılır
const NINE = 'nine';        // sadece okuma rolüyle katılır
const STRANGER = 'stranger';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-magicpaper',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

const db = (uid, token) => (uid ? env.authenticatedContext(uid, token) : env.unauthenticatedContext()).firestore();
const days = (n) => Timestamp.fromMillis(Date.now() + n * 86_400_000);

const record = (payload) => ({
  payload, deleted: false, updatedAt: 1759780000000, serverUpdatedAt: serverTimestamp(), schemaVersion: 1,
});

const invite = (role, extra = {}) => ({
  familyID: OWNER, role, inviterName: 'Sen', expiresAt: days(7), createdAt: serverTimestamp(), ...extra,
});

async function createInvite(code, role) {
  await assertSucceeds(setDoc(doc(db(OWNER), 'invites', code), invite(role)));
}

/** Uygulamanın kabul yazımı: üye satırı + üyelik + davetin silinmesi, tek seferde. */
function accept(uid, code, role, name = 'Murat') {
  const store = db(uid);
  const batch = writeBatch(store);
  batch.set(doc(store, 'families', OWNER, 'members', uid),
    { role, displayName: name, joinedAt: serverTimestamp(), invite: code });
  batch.set(doc(store, 'memberships', uid), { familyID: OWNER, joinedAt: serverTimestamp() });
  batch.delete(doc(store, 'invites', code));
  return batch.commit();
}

async function join(uid, code, role) {
  await createInvite(code, role);
  await assertSucceeds(accept(uid, code, role));
}

// --- Kurucu ve davet -------------------------------------------------------

test('kurucu kendi satırını yalnızca yönetici olarak yazar', async () => {
  const owner = db(OWNER);
  await assertFails(setDoc(doc(owner, 'families', OWNER, 'members', OWNER),
    { role: 'parent', displayName: 'Batu', joinedAt: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(owner, 'families', OWNER, 'members', OWNER),
    { role: 'admin', displayName: 'Batu', joinedAt: serverTimestamp() }));
});

test('yalnızca kurucu davet yazar; kod biçimi, rol ve süre sınırlı', async () => {
  await assertFails(setDoc(doc(db(STRANGER), 'invites', 'ABCDEFGH'), invite('parent')));
  await assertFails(setDoc(doc(db(OWNER), 'invites', 'abc'), invite('parent')));
  await assertFails(setDoc(doc(db(OWNER), 'invites', 'ABCDEFGH'), invite('admin')));
  await assertFails(setDoc(doc(db(OWNER), 'invites', 'ABCDEFGH'), invite('parent', { expiresAt: days(30) })));
  await assertFails(setDoc(doc(db(OWNER), 'invites', 'ABCDEFGH'), invite('parent', { childName: 'İrem' })));
  await assertSucceeds(setDoc(doc(db(OWNER), 'invites', 'ABCDEFGH'), invite('parent')));
});

test('kodu bilen giriş yapmış kişi daveti okur; liste yalnızca kurucuya', async () => {
  await createInvite('ABCDEFGH', 'reader');
  await assertSucceeds(getDoc(doc(db(NINE), 'invites', 'ABCDEFGH')));
  await assertFails(getDoc(doc(db(null), 'invites', 'ABCDEFGH')));
  await assertFails(getDocs(collection(db(NINE), 'invites')));
  await assertSucceeds(getDocs(query(collection(db(OWNER), 'invites'), where('familyID', '==', OWNER))));
});

test('davetle katılım tek yazımda olur ve davet tek kullanımlık', async () => {
  await createInvite('ABCDEFGH', 'parent');
  await assertSucceeds(accept(MURAT, 'ABCDEFGH', 'parent'));
  // Aynı kodla ikinci kişi katılamaz.
  await assertFails(accept(NINE, 'ABCDEFGH', 'parent'));
});

test('davetteki rolden başka rolle ya da daveti silmeden katılınamaz', async () => {
  await createInvite('ABCDEFGH', 'reader');
  await assertFails(accept(NINE, 'ABCDEFGH', 'parent'));
  await assertFails(setDoc(doc(db(NINE), 'families', OWNER, 'members', NINE),
    { role: 'reader', displayName: 'Nine', joinedAt: serverTimestamp(), invite: 'ABCDEFGH' }));
});

test('süresi dolmuş davetle katılınamaz', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'invites', 'ABCDEFGH'), invite('parent', { expiresAt: days(-1), createdAt: days(-8) }));
  });
  await assertFails(accept(MURAT, 'ABCDEFGH', 'parent'));
});

test('davetsiz kimse kendini üye yazamaz', async () => {
  await assertFails(setDoc(doc(db(STRANGER), 'families', OWNER, 'members', STRANGER),
    { role: 'parent', displayName: 'X', joinedAt: serverTimestamp(), invite: 'NOPENOPE' }));
  await assertFails(setDoc(doc(db(STRANGER), 'memberships', STRANGER), { familyID: OWNER, joinedAt: serverTimestamp() }));
});

// --- Roller ----------------------------------------------------------------

test('ebeveyn rolü aile kayıtlarını okur ve yazar', async () => {
  await join(MURAT, 'ABCDEFGH', 'parent');
  const ref = doc(db(MURAT), 'families', OWNER, 'stories', 's1');
  await assertSucceeds(setDoc(ref, record('{"t":1}')));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(setDoc(doc(db(MURAT), 'families', OWNER, 'recordings', 's1'), record('{"pages":{}}')));
});

test('sadece okuma rolü okur ama yazamaz, silemez', async () => {
  await assertSucceeds(setDoc(doc(db(OWNER), 'families', OWNER, 'stories', 's1'), record('{"t":1}')));
  await join(NINE, 'ABCDEFGH', 'reader');
  const ref = doc(db(NINE), 'families', OWNER, 'stories', 's1');
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(getDocs(collection(db(NINE), 'families', OWNER, 'stories')));
  await assertFails(setDoc(doc(db(NINE), 'families', OWNER, 'stories', 's2'), record('{"t":2}')));
  await assertFails(deleteDoc(ref));
});

test('üyeler ailenin onayını okur, yazamaz', async () => {
  await join(MURAT, 'ABCDEFGH', 'parent');
  await assertSucceeds(getDoc(doc(db(MURAT), 'families', OWNER, 'consents', '2026-10-06')));
  await assertFails(setDoc(doc(db(MURAT), 'families', OWNER, 'consents', 'v9'),
    { version: 'v9', acceptedAt: serverTimestamp(), clientAcceptedAt: 1, shareUsageData: false }));
});

test('kurucu rolü değiştirir; üye kendi rolünü yükseltemez', async () => {
  await join(NINE, 'ABCDEFGH', 'reader');
  await assertFails(updateDoc(doc(db(NINE), 'families', OWNER, 'members', NINE), { role: 'parent' }));
  await assertSucceeds(updateDoc(doc(db(NINE), 'families', OWNER, 'members', NINE), { displayName: 'Ayşe Nine' }));
  await assertFails(updateDoc(doc(db(OWNER), 'families', OWNER, 'members', NINE), { role: 'admin' }));
  await assertSucceeds(updateDoc(doc(db(OWNER), 'families', OWNER, 'members', NINE), { role: 'parent' }));
  await assertSucceeds(setDoc(doc(db(NINE), 'families', OWNER, 'stories', 's1'), record('{"t":1}')));
});

test('ebeveyn başka üyeyi çıkaramaz; kurucu çıkarır, üye ayrılır', async () => {
  await join(MURAT, 'ABCDEFGH', 'parent');
  await join(NINE, 'HJKLMNPQ', 'reader');
  await assertFails(deleteDoc(doc(db(MURAT), 'families', OWNER, 'members', NINE)));
  await assertSucceeds(deleteDoc(doc(db(OWNER), 'families', OWNER, 'members', NINE)));
  await assertSucceeds(deleteDoc(doc(db(OWNER), 'memberships', NINE)));
  await assertSucceeds(deleteDoc(doc(db(MURAT), 'families', OWNER, 'members', MURAT)));
  await assertSucceeds(deleteDoc(doc(db(MURAT), 'memberships', MURAT)));
  // Ayrılan artık okuyamaz.
  await assertFails(getDoc(doc(db(MURAT), 'families', OWNER, 'stories', 's1')));
});

test('üye aile belgesini silemez; yalnızca kurucu', async () => {
  await join(MURAT, 'ABCDEFGH', 'parent');
  await assertFails(deleteDoc(doc(db(MURAT), 'families', OWNER)));
  await assertFails(deleteDoc(doc(db(MURAT), 'families', OWNER, 'consents', '2026-10-06')));
});

test('ses rızası kişi başına; sadece okuma rolü veremez', async () => {
  await join(MURAT, 'ABCDEFGH', 'parent');
  await join(NINE, 'HJKLMNPQ', 'reader');
  const consent = { version: 'voice-2026-10', acceptedAt: serverTimestamp(), clientAcceptedAt: 1 };
  await assertSucceeds(setDoc(doc(db(MURAT), 'families', OWNER, 'voiceConsents', MURAT), consent));
  await assertFails(setDoc(doc(db(MURAT), 'families', OWNER, 'voiceConsents', OWNER), consent));
  await assertFails(setDoc(doc(db(NINE), 'families', OWNER, 'voiceConsents', NINE), consent));
  await assertSucceeds(deleteDoc(doc(db(MURAT), 'families', OWNER, 'voiceConsents', MURAT)));
});

// --- Aileyle paylaş ----------------------------------------------------------

const TOKEN = 'k3Jx9QpL2vR8sT1uW4yZ6a';

const share = (extra = {}) => ({
  familyID: OWNER,
  childName: 'İrem',
  stories: [{ title: 'Şehri Kurtaran Gün', pages: ['Bir sabah…', 'Sonra…'], audio: [] }],
  voice: false,
  expiresAt: days(7),
  createdAt: serverTimestamp(),
  ...extra,
});

test('paylaşım bağlantısı giriş yapmadan okunur, listelenemez', async () => {
  await assertSucceeds(setDoc(doc(db(OWNER), 'shares', TOKEN), share()));
  await assertSucceeds(getDoc(doc(db(null), 'shares', TOKEN)));
  await assertFails(getDocs(collection(db(null), 'shares')));
  await assertFails(getDocs(collection(db(STRANGER), 'shares')));
});

test('süresi dolan bağlantı okunmaz', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'shares', TOKEN), share({ expiresAt: days(-1), createdAt: days(-8) }));
  });
  await assertFails(getDoc(doc(db(null), 'shares', TOKEN)));
});

test('bağlantı yalnızca ad ve masal metni taşır', async () => {
  const owner = db(OWNER);
  await assertFails(setDoc(doc(owner, 'shares', TOKEN), share({ age: 8 })));
  await assertFails(setDoc(doc(owner, 'shares', TOKEN), share({ childProfileID: 'p1' })));
  await assertFails(setDoc(doc(owner, 'shares', TOKEN), share({
    stories: [{ title: 'X', pages: ['a'], audio: [], childAge: 8 }],
  })));
  const many = Array.from({ length: 5 }, (_, i) => ({ title: `M${i}`, pages: ['a'], audio: [] }));
  many.push({ title: 'son', pages: ['a'], audio: [], storyID: 'B3F1' });
  await assertFails(setDoc(doc(owner, 'shares', TOKEN), share({ stories: many })));
});

test('bağlantı süresi en çok 31 gün; kısa kimlik kabul edilmez', async () => {
  await assertFails(setDoc(doc(db(OWNER), 'shares', TOKEN), share({ expiresAt: days(40) })));
  await assertFails(setDoc(doc(db(OWNER), 'shares', 'short'), share()));
});

test('sadece okuma rolü ve yabancı paylaşamaz; ebeveyn paylaşır ve kapatır', async () => {
  await join(MURAT, 'ABCDEFGH', 'parent');
  await join(NINE, 'HJKLMNPQ', 'reader');
  await assertFails(setDoc(doc(db(NINE), 'shares', TOKEN), share()));
  await assertFails(setDoc(doc(db(STRANGER), 'shares', TOKEN), share()));
  await assertSucceeds(setDoc(doc(db(MURAT), 'shares', TOKEN), share()));
  await assertFails(updateDoc(doc(db(MURAT), 'shares', TOKEN), { expiresAt: days(30) }));
  await assertFails(deleteDoc(doc(db(NINE), 'shares', TOKEN)));
  await assertSucceeds(deleteDoc(doc(db(MURAT), 'shares', TOKEN)));
});

test('paylaşım listesi ailede kalır; alıcı etiketi açık belgeye girmez', async () => {
  const meta = { recipient: 'Ayşe Nine', storyCount: 1, voice: false, expiresAt: days(7),
                 createdAt: serverTimestamp(), createdBy: OWNER };
  await assertSucceeds(setDoc(doc(db(OWNER), 'families', OWNER, 'shares', TOKEN), meta));
  await assertFails(getDoc(doc(db(STRANGER), 'families', OWNER, 'shares', TOKEN)));
  await assertFails(setDoc(doc(db(OWNER), 'shares', TOKEN), share({ recipient: 'Ayşe Nine' })));
});

// --- Haftalık özet ------------------------------------------------------------

const EMAIL = { email: 'batu@example.com', email_verified: true };

const weekly = (extra = {}) => ({
  enabled: true, email: 'batu@example.com', timezone: 'Europe/Istanbul', updatedAt: serverTimestamp(), ...extra,
});

test('haftalık özet yalnızca hesabın doğrulanmış e-postasına', async () => {
  const ref = (uid, token) => doc(db(uid, token), 'families', OWNER, 'settings', 'weeklyEmail');
  await assertSucceeds(setDoc(ref(OWNER, EMAIL), weekly()));
  await assertFails(setDoc(ref(OWNER, EMAIL), weekly({ email: 'baska@example.com' })));
  await assertFails(setDoc(ref(OWNER, { email: 'batu@example.com', email_verified: false }), weekly()));
  await assertFails(setDoc(ref(OWNER, {}), weekly()));
  await assertFails(setDoc(doc(db(OWNER, EMAIL), 'families', OWNER, 'settings', 'other'), weekly()));
  await assertSucceeds(setDoc(ref(OWNER, EMAIL), weekly({ enabled: false })));
});

test('üyeler haftalık özet ayarını göremez, değiştiremez', async () => {
  await assertSucceeds(setDoc(doc(db(OWNER, EMAIL), 'families', OWNER, 'settings', 'weeklyEmail'), weekly()));
  await join(MURAT, 'ABCDEFGH', 'parent');
  const asMurat = doc(db(MURAT, { email: 'murat@example.com', email_verified: true }), 'families', OWNER, 'settings', 'weeklyEmail');
  await assertFails(getDoc(asMurat));
  await assertFails(setDoc(asMurat, weekly({ email: 'murat@example.com' })));
});

// --- Aile silme ---------------------------------------------------------------

test('kurucu üyeleri, üyelikleri, davetleri ve paylaşımları silebilir', async () => {
  await join(MURAT, 'ABCDEFGH', 'parent');
  await createInvite('HJKLMNPQ', 'reader');
  await assertSucceeds(setDoc(doc(db(OWNER), 'shares', TOKEN), share()));
  await assertSucceeds(setDoc(doc(db(OWNER, EMAIL), 'families', OWNER, 'settings', 'weeklyEmail'), weekly()));

  const owner = db(OWNER);
  await assertSucceeds(deleteDoc(doc(owner, 'memberships', MURAT)));
  await assertSucceeds(deleteDoc(doc(owner, 'families', OWNER, 'members', MURAT)));
  await assertSucceeds(deleteDoc(doc(owner, 'invites', 'HJKLMNPQ')));
  await assertSucceeds(deleteDoc(doc(owner, 'shares', TOKEN)));
  await assertSucceeds(deleteDoc(doc(owner, 'families', OWNER, 'settings', 'weeklyEmail')));
});
