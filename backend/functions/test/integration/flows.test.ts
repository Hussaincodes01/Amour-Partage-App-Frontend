import functionsTest from 'firebase-functions-test';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { auth, db, rtdb } from '../../src/admin.js';
import * as fns from '../../src/index.js';
import { ensureSpark } from '../../src/sparks.js';

// Runs inside `firebase emulators:exec --only auth,firestore,database`.
const t = functionsTest({ projectId: 'demo-amour-partage' });

type Callable = { run?: unknown };
// Calls an onCall function as [uid] would from the app.
function call<T = Record<string, unknown>>(fn: Callable, uid: string | null, data: unknown = {}): Promise<T> {
  const wrapped = t.wrap(fn as never) as unknown as (req: unknown) => Promise<T>;
  return wrapped({ data, auth: uid ? { uid, token: {} } : undefined, rawRequest: {} });
}

const key = (n: number) => Buffer.alloc(32, n).toString('base64');

async function resetData() {
  const project = 'demo-amour-partage';
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  await fetch(`http://${host}/emulator/v1/projects/${project}/databases/(default)/documents`, { method: 'DELETE' });
  await rtdb().ref().set(null);
}

async function user(uid: string, name: string) {
  await db.collection('users').doc(uid).set({ name, publicKey: key(uid.length) });
}

async function pair(a = 'alice', b = 'bob') {
  await user(a, 'Alice');
  await user(b, 'Bob');
  const invite = await call<{ code: string }>(fns.createInvite, a, { publicKey: key(1) });
  const { coupleId } = await call<{ coupleId: string }>(fns.acceptInvite, b, { code: invite.code, publicKey: key(2) });
  return coupleId;
}

beforeEach(resetData);
afterAll(() => t.cleanup());

describe('pairing', () => {
  it('creates an invite and pairs both people with their public keys', async () => {
    await user('alice', 'Alice');
    await user('bob', 'Bob');
    const invite = await call<{ code: string; expiresAt: number }>(fns.createInvite, 'alice', { publicKey: key(1) });
    expect(invite.code).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}$/);
    expect(invite.expiresAt).toBeGreaterThan(Date.now());

    const { coupleId } = await call<{ coupleId: string }>(fns.acceptInvite, 'bob', { code: invite.code.toLowerCase(), publicKey: key(2) });
    const couple = (await db.collection('couples').doc(coupleId).get()).data()!;
    expect(couple.members).toEqual(['alice', 'bob']);
    expect(couple.status).toBe('active');
    expect(couple.keys).toEqual({ alice: key(1), bob: key(2) });
    expect(couple.names).toEqual({ alice: 'Alice', bob: 'Bob' });
    expect((await db.collection('users').doc('alice').get()).get('coupleId')).toBe(coupleId);
    expect((await db.collection('users').doc('bob').get()).get('coupleId')).toBe(coupleId);
    expect((await rtdb().ref(`members/${coupleId}`).get()).val()).toEqual({ alice: true, bob: true });
    // The invite is single-use.
    await expect(call(fns.acceptInvite, 'carol', { code: invite.code, publicKey: key(3) })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('keeps one live invite per person', async () => {
    await user('alice', 'Alice');
    const first = await call<{ code: string }>(fns.createInvite, 'alice', { publicKey: key(1) });
    const second = await call<{ code: string }>(fns.createInvite, 'alice', { publicKey: key(1) });
    expect(first.code).not.toBe(second.code);
    const live = await db.collection('invites').where('inviter', '==', 'alice').get();
    expect(live.size).toBe(1);
  });

  it('rejects bad codes, own invites, mismatched keys and double pairing', async () => {
    await user('alice', 'Alice');
    await user('bob', 'Bob');
    await expect(call(fns.createInvite, null, { publicKey: key(1) })).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(call(fns.createInvite, 'alice', { publicKey: 'nope' })).rejects.toMatchObject({ code: 'invalid-argument' });
    const invite = await call<{ code: string }>(fns.createInvite, 'alice', { publicKey: key(1) });
    await expect(call(fns.acceptInvite, 'alice', { code: invite.code, publicKey: key(1) })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call(fns.acceptInvite, 'bob', { code: 'ZZZZ-ZZZZ', publicKey: key(2) })).rejects.toMatchObject({ code: 'not-found' });
    // A QR scanned in person carries the inviter's key; a swapped key is refused.
    await expect(call(fns.acceptInvite, 'bob', { code: invite.code, publicKey: key(2), expectedInviterKey: key(9) })).rejects.toMatchObject({ code: 'permission-denied' });
    await call(fns.acceptInvite, 'bob', { code: invite.code, publicKey: key(2), expectedInviterKey: key(1) });
    await user('carol', 'Carol');
    const carol = await call<{ code: string }>(fns.createInvite, 'carol', { publicKey: key(3) });
    await expect(call(fns.acceptInvite, 'bob', { code: carol.code, publicKey: key(2) })).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('expired invites are refused', async () => {
    await user('alice', 'Alice');
    await user('bob', 'Bob');
    const invite = await call<{ code: string }>(fns.createInvite, 'alice', { publicKey: key(1) });
    await db.collection('invites').doc(invite.code.replace('-', '')).update({ expiresAt: new Date(Date.now() - 1000) });
    await expect(call(fns.acceptInvite, 'bob', { code: invite.code, publicKey: key(2) })).rejects.toMatchObject({ code: 'deadline-exceeded' });
  });
});

describe('unlinking', () => {
  it('closes the space for both, and pairing again within 24 h restores it', async () => {
    const coupleId = await pair();
    await db.collection('couples').doc(coupleId).collection('messages').doc('m1').set({ ct: 'x', n: 'y', sender: 'alice' });
    await call(fns.unlinkCouple, 'bob');
    const closed = (await db.collection('couples').doc(coupleId).get()).data()!;
    expect(closed.status).toBe('unlinked');
    expect(closed.purgeAt.toMillis()).toBeGreaterThan(Date.now() + 23 * 3600_000);
    expect((await db.collection('users').doc('alice').get()).get('coupleId')).toBeUndefined();
    expect((await rtdb().ref(`members/${coupleId}`).get()).exists()).toBe(false);

    const again = await pair();
    expect(again).toBe(coupleId);
    expect((await db.collection('couples').doc(coupleId).collection('messages').doc('m1').get()).exists).toBe(true);
  });
});

describe('calls', () => {
  it('ring, answer and hang up with LiveKit tokens for the couple’s room', async () => {
    const coupleId = await pair();
    const started = await call<{ callId: string; token: string; url: string }>(fns.startCall, 'alice', { video: true });
    expect(started.url).toBe(process.env.LIVEKIT_URL);
    expect(started.token.split('.')).toHaveLength(3);
    const ref = db.collection('couples').doc(coupleId).collection('calls').doc(started.callId);
    expect((await ref.get()).data()).toMatchObject({ caller: 'alice', video: true, state: 'ringing' });

    await expect(call(fns.joinCall, 'alice', { callId: started.callId })).rejects.toMatchObject({ code: 'not-found' });
    const joined = await call<{ token: string }>(fns.joinCall, 'bob', { callId: started.callId });
    expect(joined.token).toBeTruthy();
    expect((await ref.get()).get('state')).toBe('active');

    await call(fns.endCall, 'bob', { callId: started.callId });
    expect((await ref.get()).get('state')).toBe('ended');
    await expect(call(fns.joinCall, 'bob', { callId: started.callId })).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('declining marks the call declined; a new call replaces a ringing one', async () => {
    const coupleId = await pair();
    const first = await call<{ callId: string }>(fns.startCall, 'alice', { video: false });
    const second = await call<{ callId: string }>(fns.startCall, 'alice', { video: false });
    const calls = db.collection('couples').doc(coupleId).collection('calls');
    expect((await calls.doc(first.callId).get()).get('state')).toBe('missed');
    await call(fns.endCall, 'bob', { callId: second.callId, reason: 'declined' });
    expect((await calls.doc(second.callId).get()).get('state')).toBe('declined');
  });

  it('needs a couple', async () => {
    await user('solo', 'Solo');
    await expect(call(fns.startCall, 'solo', { video: true })).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});

describe('daily question', () => {
  it('is created once per day and revealed when both answer', async () => {
    const coupleId = await pair();
    const today = await call<{ id: string; prompt: string }>(fns.ensureTodaySpark, 'alice');
    expect(today.prompt).toMatch(/\?$/);
    expect(await call(fns.ensureTodaySpark, 'bob')).toEqual(today);

    const sparkRef = db.collection('couples').doc(coupleId).collection('sparks').doc(today.id);
    const answered = t.wrap(fns.onSparkAnswered as never) as unknown as (e: unknown) => Promise<void>;
    const answer = async (uid: string) => {
      const ref = sparkRef.collection('answers').doc(uid);
      await ref.set({ ct: 'x', n: 'y' });
      await answered({ data: await ref.get(), params: { coupleId, day: today.id, uid } });
    };
    await answer('alice');
    expect((await sparkRef.get()).get('answered')).toEqual({ alice: true });
    expect((await sparkRef.get()).get('revealedAt')).toBeUndefined();
    await answer('bob');
    expect((await sparkRef.get()).get('answered')).toEqual({ alice: true, bob: true });
    expect((await sparkRef.get()).get('revealedAt')).toBeDefined();
  });

  it('uses queued AI questions before the curated deck', async () => {
    const coupleId = await pair();
    await db.collection('couples').doc(coupleId).update({ promptQueue: ['What would you name our boat?'] });
    const spark = await ensureSpark(coupleId, '2030-01-01');
    expect(spark.prompt).toBe('What would you name our boat?');
    expect((await db.collection('couples').doc(coupleId).get()).get('promptQueue')).toEqual([]);
  });
});

describe('account deletion', () => {
  it('removes the account, the shared space and the sign-in', async () => {
    await auth().createUser({ uid: 'alice' });
    const coupleId = await pair();
    await db.collection('users').doc('alice').collection('devices').doc('d1').set({ fcmToken: 'x' });
    await call(fns.deleteAccount, 'alice');
    expect((await db.collection('users').doc('alice').get()).exists).toBe(false);
    expect((await db.collection('users').doc('alice').collection('devices').get()).empty).toBe(true);
    expect((await db.collection('couples').doc(coupleId).get()).exists).toBe(false);
    expect((await db.collection('users').doc('bob').get()).get('coupleId')).toBeUndefined();
    await expect(auth().getUser('alice')).rejects.toMatchObject({ code: 'auth/user-not-found' });
  });
});
