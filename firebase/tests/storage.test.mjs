// MagicPaper Storage kuralları (FAZ 18): ailenin ses kayıtları ve sesli paylaşım.
// Kurallar Firestore'daki üyelik ve paylaşım belgelerine bakar; ikisi de emülatörde.

import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject, listAll } from 'firebase/storage';

let env;
const OWNER = 'owner';
const MURAT = 'murat';   // ebeveyn
const NINE = 'nine';     // sadece okuma
const STRANGER = 'stranger';
const STORY = '6F1B2C3D-0000-4000-8000-000000000001';
const TOKEN = 'k3Jx9QpL2vR8sT1uW4yZ6a';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-magicpaper',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
    storage: { rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8') },
  });
});

after(async () => { await env.cleanup(); });

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'families', OWNER, 'members', MURAT), { role: 'parent', displayName: 'Murat' });
    await setDoc(doc(db, 'families', OWNER, 'members', NINE), { role: 'reader', displayName: 'Nine' });
  });
});

const storage = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).storage();
const audio = new Uint8Array([0, 0, 0, 24, 102, 116, 121, 112]);
const asAudio = { contentType: 'audio/mp4' };
const voicePath = (page = 0) => `families/${OWNER}/voice/${STORY}/${page}.m4a`;

async function seedVoice(page = 0) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), voicePath(page)), audio, asAudio);
  });
}

async function seedShare(extra = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'shares', TOKEN), {
      familyID: OWNER, childName: 'İrem', stories: [{ title: 'X', pages: ['a'], audio: [0] }],
      voice: true, expiresAt: Timestamp.fromMillis(Date.now() + 86_400_000), createdAt: Timestamp.now(), ...extra,
    });
  });
}

// --- Ailenin sesi -------------------------------------------------------------

test('kurucu ve ebeveyn kaydeder; sadece okuma ve yabancı kaydedemez', async () => {
  await assertSucceeds(uploadBytes(ref(storage(OWNER), voicePath(0)), audio, asAudio));
  await assertSucceeds(uploadBytes(ref(storage(MURAT), voicePath(1)), audio, asAudio));
  await assertFails(uploadBytes(ref(storage(NINE), voicePath(2)), audio, asAudio));
  await assertFails(uploadBytes(ref(storage(STRANGER), voicePath(3)), audio, asAudio));
  await assertFails(uploadBytes(ref(storage(null), voicePath(4)), audio, asAudio));
});

test('ailenin her üyesi dinler; yabancı ve giriş yapmamış dinleyemez', async () => {
  await seedVoice();
  await assertSucceeds(getBytes(ref(storage(OWNER), voicePath())));
  await assertSucceeds(getBytes(ref(storage(NINE), voicePath())));
  await assertFails(getBytes(ref(storage(STRANGER), voicePath())));
  await assertFails(getBytes(ref(storage(null), voicePath())));
});

test('yalnızca ses dosyası, sayfa adıyla, sınırlı boyutta', async () => {
  await assertFails(uploadBytes(ref(storage(OWNER), voicePath(0)), audio, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(ref(storage(OWNER), `families/${OWNER}/voice/${STORY}/kapak.m4a`), audio, asAudio));
  const big = new Uint8Array(4 * 1024 * 1024 + 1);
  await assertFails(uploadBytes(ref(storage(OWNER), voicePath(0)), big, asAudio));
});

test('ebeveyn siler, sadece okuma silemez; kurucu klasörü listeleyip boşaltır', async () => {
  await seedVoice(0);
  await seedVoice(1);
  await assertFails(deleteObject(ref(storage(NINE), voicePath(0))));
  await assertSucceeds(deleteObject(ref(storage(MURAT), voicePath(0))));
  const listing = await assertSucceeds(listAll(ref(storage(OWNER), `families/${OWNER}/voice`)));
  for (const prefix of listing.prefixes) {
    const inner = await listAll(prefix);
    for (const item of inner.items) await assertSucceeds(deleteObject(item));
  }
  await assertFails(listAll(ref(storage(STRANGER), `families/${OWNER}/voice`)));
});

test('başka bir ailenin klasörü kapalı', async () => {
  await assertFails(uploadBytes(ref(storage(MURAT), `families/${STRANGER}/voice/${STORY}/0.m4a`), audio, asAudio));
});

// --- Sesli paylaşım ------------------------------------------------------------

test('sesli bağlantının sesi süresi dolana kadar herkese açık', async () => {
  await seedShare();
  await assertSucceeds(uploadBytes(ref(storage(OWNER), `shares/${TOKEN}/0/0.m4a`), audio, asAudio));
  await assertSucceeds(getBytes(ref(storage(null), `shares/${TOKEN}/0/0.m4a`)));
  await assertFails(listAll(ref(storage(null), `shares/${TOKEN}`)));
});

test('süresi dolmuş ya da sessiz bağlantının sesi açılmaz', async () => {
  await seedShare({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), `shares/${TOKEN}/0/0.m4a`), audio, asAudio);
  });
  await assertFails(getBytes(ref(storage(null), `shares/${TOKEN}/0/0.m4a`)));

  await seedShare({ voice: false });
  await assertFails(getBytes(ref(storage(null), `shares/${TOKEN}/0/0.m4a`)));
  await assertFails(uploadBytes(ref(storage(OWNER), `shares/${TOKEN}/0/1.m4a`), audio, asAudio));
});

test('paylaşım sesini yalnızca ailenin yazabilenleri koyar', async () => {
  await seedShare();
  await assertFails(uploadBytes(ref(storage(NINE), `shares/${TOKEN}/0/0.m4a`), audio, asAudio));
  await assertFails(uploadBytes(ref(storage(STRANGER), `shares/${TOKEN}/0/0.m4a`), audio, asAudio));
  await assertFails(uploadBytes(ref(storage(null), `shares/${TOKEN}/0/0.m4a`), audio, asAudio));
  await assertSucceeds(uploadBytes(ref(storage(MURAT), `shares/${TOKEN}/0/0.m4a`), audio, asAudio));
  await assertSucceeds(deleteObject(ref(storage(MURAT), `shares/${TOKEN}/0/0.m4a`)));
});
