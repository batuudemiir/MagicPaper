// Tek tıkla abonelikten çıkma (FAZ 18): bağlantı ailenin kimliğini HMAC ile
// imzalar; imzasız ya da değiştirilmiş bağlantı hiçbir şeyi kapatmaz.
import { createHmac, timingSafeEqual } from 'node:crypto';

const b64url = (buf) => buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

export function signFamily(familyID, secret) {
  return b64url(createHmac('sha256', secret).update(`weeklyEmail:${familyID}`).digest());
}

export function verifyFamily(familyID, signature, secret) {
  if (typeof familyID !== 'string' || typeof signature !== 'string' || !familyID || !signature) return false;
  const expected = Buffer.from(signFamily(familyID, secret));
  const given = Buffer.from(signature);
  return expected.length === given.length && timingSafeEqual(expected, given);
}

export function unsubscribeURL(base, familyID, secret) {
  const url = new URL(base);
  url.searchParams.set('f', familyID);
  url.searchParams.set('s', signFamily(familyID, secret));
  return url.toString();
}
