import { HttpsError, onCall } from 'firebase-functions/https';
import { defineSecret, defineString } from 'firebase-functions/params';
import { AccessToken } from 'livekit-server-sdk';

import { FieldValue, db } from './admin.js';
import { nameOf, rateLimit, requireCouple, requireUid } from './lib.js';
import { pushToUser } from './push.js';

const livekitUrl = defineString('LIVEKIT_URL', { description: 'LiveKit server URL, e.g. wss://your-project.livekit.cloud' });
const livekitKey = defineSecret('LIVEKIT_API_KEY');
const livekitSecret = defineSecret('LIVEKIT_API_SECRET');

/** A two-person room per couple; the token lasts long enough for a long call. */
export async function callToken(coupleId: string, uid: string, name: string, key: string, secret: string): Promise<string> {
  const token = new AccessToken(key, secret, { identity: uid, name, ttl: '4h' });
  token.addGrant({ room: `couple_${coupleId}`, roomJoin: true, canPublish: true, canSubscribe: true, canPublishData: true });
  return token.toJwt();
}

function grantFor(coupleId: string, uid: string, name: string) {
  const url = livekitUrl.value();
  if (!url || !livekitKey.value() || !livekitSecret.value()) {
    throw new HttpsError('failed-precondition', 'Calls aren’t set up on the server yet.');
  }
  return callToken(coupleId, uid, name, livekitKey.value(), livekitSecret.value()).then((token) => ({ url, token }));
}

const secrets = { secrets: [livekitKey, livekitSecret] };

/** Starts a call: creates the ringing call and rings the partner's phone. */
export const startCall = onCall<{ video?: unknown }>(secrets, async (request) => {
  const uid = requireUid(request);
  const couple = await requireCouple(uid);
  await rateLimit(db.collection('users').doc(uid), 'calls', 30, 60 * 60 * 1000);
  const video = request.data?.video === true;
  const calls = db.collection('couples').doc(couple.id).collection('calls');
  // Only one call rings at a time.
  const ringing = await calls.where('state', '==', 'ringing').get();
  const batch = db.batch();
  ringing.docs.forEach((d) => batch.update(d.ref, { state: 'missed', endedAt: FieldValue.serverTimestamp() }));
  const callRef = calls.doc();
  batch.set(callRef, { caller: uid, video, state: 'ringing', createdAt: FieldValue.serverTimestamp() });
  await batch.commit();

  const name = nameOf(couple.data, uid);
  const grant = await grantFor(couple.id, uid, name);
  await pushToUser(couple.partner, {
    kind: 'call',
    title: name,
    body: video ? 'Incoming video call' : 'Incoming call',
    data: { callId: callRef.id, video: String(video) },
    tag: 'call',
  });
  return { callId: callRef.id, ...grant };
});

/** Answers a ringing call from the partner. */
export const joinCall = onCall<{ callId?: unknown }>(secrets, async (request) => {
  const uid = requireUid(request);
  const couple = await requireCouple(uid);
  const callId = request.data?.callId;
  if (typeof callId !== 'string' || callId.length === 0) throw new HttpsError('invalid-argument', 'Missing call.');
  const ref = db.collection('couples').doc(couple.id).collection('calls').doc(callId);
  await db.runTransaction(async (tx) => {
    const call = await tx.get(ref);
    if (!call.exists || call.get('caller') === uid) throw new HttpsError('not-found', 'That call has ended.');
    if (call.get('state') !== 'ringing') throw new HttpsError('failed-precondition', 'That call has ended.');
    tx.update(ref, { state: 'active', answeredAt: FieldValue.serverTimestamp() });
  });
  return grantFor(couple.id, uid, nameOf(couple.data, uid));
});

/** Hangs up, declines or cancels. Safe to call more than once. */
export const endCall = onCall<{ callId?: unknown; reason?: unknown }>(async (request) => {
  const uid = requireUid(request);
  const couple = await requireCouple(uid);
  const callId = request.data?.callId;
  if (typeof callId !== 'string' || callId.length === 0) throw new HttpsError('invalid-argument', 'Missing call.');
  const ref = db.collection('couples').doc(couple.id).collection('calls').doc(callId);
  const snap = await ref.get();
  if (!snap.exists) return { ok: true };
  const state = snap.get('state') as string;
  if (state === 'ringing' || state === 'active') {
    const next = request.data?.reason === 'declined' ? 'declined' : state === 'ringing' ? 'missed' : 'ended';
    await ref.update({ state: next, endedAt: FieldValue.serverTimestamp(), endedBy: uid });
  }
  return { ok: true };
});
