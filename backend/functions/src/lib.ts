import { createHash, randomInt } from 'node:crypto';

import { HttpsError, type CallableRequest } from 'firebase-functions/https';

import { db } from './admin.js';

/** Unambiguous characters for invite codes (no 0/O, 1/I/L). */
export const INVITE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const INVITE_LENGTH = 8;
export const INVITE_TTL_MS = 15 * 60 * 1000;
export const UNLINK_GRACE_MS = 24 * 60 * 60 * 1000;

export function newInviteCode(random: (max: number) => number = randomInt): string {
  let code = '';
  for (let i = 0; i < INVITE_LENGTH; i++) code += INVITE_ALPHABET[random(INVITE_ALPHABET.length)];
  return code;
}

/** "ABCD2345" → "ABCD-2345". */
export function formatInviteCode(code: string): string {
  return `${code.slice(0, 4)}-${code.slice(4)}`;
}

/** Accepts "abcd-2345", "ABCD 2345"… Returns null if it can't be a code. */
export function normalizeInviteCode(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  const code = input.toUpperCase().replace(/[^A-Z0-9]/g, '');
  if (code.length !== INVITE_LENGTH) return null;
  return [...code].every((c) => INVITE_ALPHABET.includes(c)) ? code : null;
}

/** X25519 public key: 32 bytes, base64 (44 characters with padding). */
export function isPublicKey(value: unknown): value is string {
  if (typeof value !== 'string' || !/^[A-Za-z0-9+/]{43}=$/.test(value)) return false;
  return Buffer.from(value, 'base64').length === 32;
}

/** UTC calendar day, used as the daily question id. */
export function dayKey(date = new Date()): string {
  return date.toISOString().slice(0, 10);
}

/** Stable pseudo-random index for (couple, day), so retries pick the same prompt. */
export function stableIndex(seed: string, length: number): number {
  const digest = createHash('sha256').update(seed).digest();
  return digest.readUInt32BE(0) % length;
}

export function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Please sign in again.');
  return uid;
}

export interface CoupleRef {
  id: string;
  data: FirebaseFirestore.DocumentData;
  partner: string;
}

/** The caller's active couple, or an error the app can show. */
export async function requireCouple(uid: string): Promise<CoupleRef> {
  const user = await db.collection('users').doc(uid).get();
  const coupleId = user.get('coupleId') as string | undefined;
  if (!coupleId) throw new HttpsError('failed-precondition', 'Pair with your partner first.');
  const couple = await db.collection('couples').doc(coupleId).get();
  const data = couple.data();
  if (!data || data.status !== 'active' || !(data.members as string[]).includes(uid)) {
    throw new HttpsError('failed-precondition', 'Pair with your partner first.');
  }
  const partner = (data.members as string[]).find((m) => m !== uid)!;
  return { id: couple.id, data, partner };
}

export function nameOf(couple: FirebaseFirestore.DocumentData, uid: string): string {
  const names = (couple.names ?? {}) as Record<string, string>;
  return names[uid] ?? 'Your partner';
}

/**
 * Small fixed-window rate limit stored on a document field, e.g.
 * `rateLimit(userRef, 'invites', 10, 3600_000)`.
 */
export async function rateLimit(ref: FirebaseFirestore.DocumentReference, key: string, max: number, windowMs: number): Promise<void> {
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const bucket = (snap.get(`limits.${key}`) ?? {}) as { start?: number; count?: number };
    const fresh = !bucket.start || now - bucket.start > windowMs;
    const count = fresh ? 0 : (bucket.count ?? 0);
    if (count >= max) throw new HttpsError('resource-exhausted', 'Too many tries. Please wait a little and try again.');
    tx.set(ref, { limits: { [key]: { start: fresh ? now : bucket.start, count: count + 1 } } }, { merge: true });
  });
}
