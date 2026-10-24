import { readFileSync } from 'node:fs';

import { assertFails, assertSucceeds, initializeTestEnvironment, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { get, ref, set } from 'firebase/database';
import { Timestamp, deleteField, doc, getDoc, serverTimestamp, setDoc, updateDoc, collection, getDocs, query, where } from 'firebase/firestore';
import { getBytes, ref as fileRef, uploadBytes } from 'firebase/storage';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

const KEY_A = Buffer.alloc(32, 1).toString('base64');
const KEY_B = Buffer.alloc(32, 2).toString('base64');
const sealed = { ct: 'Y2lwaGVydGV4dA==', n: Buffer.alloc(24, 3).toString('base64') };

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-amour-partage',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
    database: { rules: readFileSync('database.rules.json', 'utf8') },
    storage: { rules: readFileSync('storage.rules', 'utf8') },
  });
});

afterAll(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearDatabase();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'couples/c1'), {
      members: ['alice', 'bob'],
      status: 'active',
      names: { alice: 'Alice', bob: 'Bob' },
      keys: { alice: KEY_A, bob: KEY_B },
      verifiedKeys: {},
      lastRead: {},
      since: Timestamp.now(),
    });
    await setDoc(doc(db, 'couples/c2'), { members: ['carol', 'dave'], status: 'unlinked', names: {}, keys: {}, verifiedKeys: {}, lastRead: {} });
    await setDoc(doc(db, 'users/alice'), { name: 'Alice', coupleId: 'c1', publicKey: KEY_A });
    await setDoc(doc(db, 'users/bob'), { name: 'Bob', coupleId: 'c1', publicKey: KEY_B });
    await setDoc(doc(db, 'users/eve'), { name: 'Eve' });
    await setDoc(doc(db, 'couples/c1/sparks/2026-10-24'), { prompt: 'Q?', answered: {} });
    await setDoc(doc(db, 'couples/c1/messages/m1'), { ...sealed, sender: 'bob', kind: 'text', createdAt: Timestamp.now() });
    await setDoc(doc(db, 'couples/c2/messages/m1'), { ...sealed, sender: 'carol', kind: 'text', createdAt: Timestamp.now() });
    await set(ref(ctx.database(), 'members/c1'), { alice: true, bob: true });
  });
});

const as = (uid: string) => env.authenticatedContext(uid);
const fs = (uid: string) => as(uid).firestore();

describe('couples', () => {
  it('members read their couple; others cannot', async () => {
    await assertSucceeds(getDoc(doc(fs('alice'), 'couples/c1')));
    await assertFails(getDoc(doc(fs('eve'), 'couples/c1')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'couples/c1')));
  });

  it('members change only their own entries', async () => {
    await assertSucceeds(updateDoc(doc(fs('alice'), 'couples/c1'), { 'names.alice': 'Ali' }));
    await assertFails(updateDoc(doc(fs('alice'), 'couples/c1'), { 'names.bob': 'Bobby' }));
    await assertSucceeds(updateDoc(doc(fs('alice'), 'couples/c1'), { 'lastRead.alice': serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(fs('alice'), 'couples/c1'), { 'verifiedKeys.alice': KEY_B }));
    await assertFails(updateDoc(doc(fs('alice'), 'couples/c1'), { 'keys.bob': KEY_A }));
    await assertFails(updateDoc(doc(fs('alice'), 'couples/c1'), { status: 'unlinked' }));
    await assertFails(updateDoc(doc(fs('alice'), 'couples/c1'), { members: ['alice', 'eve'] }));
  });

  it('nobody but Cloud Functions creates couples or invites', async () => {
    await assertFails(setDoc(doc(fs('eve'), 'couples/c3'), { members: ['eve', 'alice'], status: 'active' }));
    await assertFails(getDoc(doc(fs('alice'), 'invites/ABCD2345')));
    await assertFails(setDoc(doc(fs('alice'), 'invites/ABCD2345'), { inviter: 'alice' }));
  });

  it('a user cannot join a couple by editing their profile', async () => {
    await assertFails(updateDoc(doc(fs('eve'), 'users/eve'), { coupleId: 'c1' }));
    await assertSucceeds(updateDoc(doc(fs('eve'), 'users/eve'), { name: 'Eva' }));
    await assertSucceeds(getDoc(doc(fs('alice'), 'users/bob')));
    await assertFails(getDoc(doc(fs('eve'), 'users/bob')));
  });
});

describe('messages', () => {
  it('only sealed messages from yourself, stamped by the server', async () => {
    const db = fs('alice');
    await assertSucceeds(setDoc(doc(db, 'couples/c1/messages/a1'), { ...sealed, sender: 'alice', kind: 'text', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'couples/c1/messages/a2'), { ...sealed, sender: 'bob', kind: 'text', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'couples/c1/messages/a3'), { ...sealed, text: 'plain', sender: 'alice', kind: 'text', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'couples/c1/messages/a4'), { ct: 'x', sender: 'alice', kind: 'text', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(fs('eve'), 'couples/c1/messages/e1'), { ...sealed, sender: 'eve', kind: 'text', createdAt: serverTimestamp() }));
  });

  it('hearts are per person; only the sender unsends', async () => {
    await assertSucceeds(updateDoc(doc(fs('alice'), 'couples/c1/messages/m1'), { 'hearts.alice': true }));
    await assertFails(updateDoc(doc(fs('alice'), 'couples/c1/messages/m1'), { 'hearts.bob': true }));
    await assertFails(updateDoc(doc(fs('alice'), 'couples/c1/messages/m1'), { ct: 'tampered' }));
    await assertSucceeds(updateDoc(doc(fs('alice'), 'couples/c1/messages/m1'), { 'hearts.alice': deleteField() }));
  });

  it('an unlinked couple is closed', async () => {
    await assertFails(getDocs(collection(fs('carol'), 'couples/c2/messages')));
  });
});

describe('daily question', () => {
  const answer = (uid: string) => doc(fs(uid), `couples/c1/sparks/2026-10-24/answers/${uid}`);

  it('hides your partner’s answer until you answer', async () => {
    await assertSucceeds(setDoc(answer('alice'), { ...sealed, createdAt: serverTimestamp() }));
    await assertFails(getDoc(doc(fs('bob'), 'couples/c1/sparks/2026-10-24/answers/alice')));
    await assertSucceeds(setDoc(answer('bob'), { ...sealed, createdAt: serverTimestamp() }));
    await assertSucceeds(getDoc(doc(fs('bob'), 'couples/c1/sparks/2026-10-24/answers/alice')));
  });

  it('answers are yours, once, and final', async () => {
    await assertFails(setDoc(doc(fs('alice'), 'couples/c1/sparks/2026-10-24/answers/bob'), { ...sealed, createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(answer('alice'), { ...sealed, createdAt: serverTimestamp() }));
    await assertFails(setDoc(answer('alice'), { ...sealed, createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(fs('alice'), 'couples/c1/sparks/2026-10-25/answers/alice'), { ...sealed, createdAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(fs('alice'), 'couples/c1/sparks/2026-10-24'), { prompt: 'Mine?' }));
  });
});

describe('location', () => {
  const loc = (uid: string, owner = uid) => doc(fs(uid), `couples/c1/locations/${owner}`);
  const inHours = (h: number) => Timestamp.fromMillis(Date.now() + h * 3600_000);

  it('is time-boxed and only written by its owner', async () => {
    await assertSucceeds(setDoc(loc('alice'), { ...sealed, updatedAt: serverTimestamp(), expiresAt: inHours(1) }));
    await assertSucceeds(setDoc(loc('alice'), { ...sealed, updatedAt: serverTimestamp(), expiresAt: inHours(8) }));
    await assertFails(setDoc(loc('alice'), { ...sealed, updatedAt: serverTimestamp(), expiresAt: inHours(24) }));
    await assertFails(setDoc(loc('alice', 'bob'), { ...sealed, updatedAt: serverTimestamp(), expiresAt: inHours(1) }));
    await assertFails(setDoc(loc('alice'), { lat: 48.85, lng: 2.35, updatedAt: serverTimestamp(), expiresAt: inHours(1) }));
    await assertSucceeds(getDoc(doc(fs('bob'), 'couples/c1/locations/alice')));
    await assertFails(getDoc(doc(fs('eve'), 'couples/c1/locations/alice')));
  });
});

describe('server-only data', () => {
  it('calls and sparks can be read, not written', async () => {
    await assertSucceeds(getDocs(query(collection(fs('bob'), 'couples/c1/calls'), where('state', '==', 'ringing'))));
    await assertFails(setDoc(doc(fs('bob'), 'couples/c1/calls/x'), { caller: 'bob', state: 'ringing' }));
    await assertFails(setDoc(doc(fs('bob'), 'couples/c1/sparks/2026-10-30'), { prompt: 'Q?' }));
  });
});

describe('realtime database', () => {
  const rt = (uid: string) => as(uid).database();

  it('presence and typing: your own entry, couple members only', async () => {
    await assertSucceeds(set(ref(rt('alice'), 'couples/c1/presence/alice'), { online: true, lastSeen: Date.now() }));
    await assertFails(set(ref(rt('alice'), 'couples/c1/presence/bob'), { online: true, lastSeen: Date.now() }));
    await assertSucceeds(set(ref(rt('alice'), 'couples/c1/typing/alice'), true));
    await assertFails(get(ref(rt('eve'), 'couples/c1')));
    await assertSucceeds(get(ref(rt('bob'), 'couples/c1')));
  });

  it('playback writes must move seq forward and name the writer', async () => {
    const state = (seq: number, by = 'alice') => ({ mediaId: 'abc', playing: true, positionMs: 0, at: Date.now(), by, seq, buffering: false });
    await assertSucceeds(set(ref(rt('alice'), 'couples/c1/playback'), state(1)));
    await assertSucceeds(set(ref(rt('bob'), 'couples/c1/playback'), state(2, 'bob')));
    await assertFails(set(ref(rt('alice'), 'couples/c1/playback'), state(2)));
    await assertFails(set(ref(rt('alice'), 'couples/c1/playback'), state(3, 'bob')));
    await assertFails(set(ref(rt('alice'), 'couples/c1/playback'), { ...state(4), extra: 1 }));
  });
});

describe('storage', () => {
  const bytes = new Uint8Array([1, 2, 3]);

  it('couple members upload and read encrypted media', async () => {
    const path = 'couples/c1/media/photo.img';
    await assertSucceeds(uploadBytes(fileRef(as('alice').storage(), path), bytes, { contentType: 'application/octet-stream' }));
    await assertSucceeds(getBytes(fileRef(as('bob').storage(), path)));
    await assertFails(getBytes(fileRef(as('eve').storage(), path)));
    await assertFails(uploadBytes(fileRef(as('alice').storage(), 'couples/c1/media/plain.jpg'), bytes, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(fileRef(as('eve').storage(), 'couples/c1/media/x.img'), bytes, { contentType: 'application/octet-stream' }));
  });
});
