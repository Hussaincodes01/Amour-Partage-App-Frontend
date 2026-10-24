import { HttpsError, onCall } from 'firebase-functions/https';

import { FieldValue, Timestamp, db, rtdb } from './admin.js';
import { INVITE_TTL_MS, formatInviteCode, isPublicKey, newInviteCode, normalizeInviteCode, rateLimit, requireUid } from './lib.js';
import { pushToUser } from './push.js';

/**
 * Creates a pairing invite. The caller shows it as a code and a QR; the QR
 * also carries the caller's public key so an in-person scan can check it.
 *
 * Request: `{ publicKey }` (base64 X25519). Response: `{ code, expiresAt }`.
 */
export const createInvite = onCall<{ publicKey?: unknown }>(async (request) => {
  const uid = requireUid(request);
  const publicKey = request.data?.publicKey;
  if (!isPublicKey(publicKey)) throw new HttpsError('invalid-argument', 'This phone’s encryption key is missing. Restart the app and try again.');
  const userRef = db.collection('users').doc(uid);
  const user = await userRef.get();
  if (user.get('coupleId')) throw new HttpsError('failed-precondition', 'You’re already paired.');
  await rateLimit(userRef, 'invites', 10, 60 * 60 * 1000);

  // One live invite per person.
  const old = await db.collection('invites').where('inviter', '==', uid).get();
  const batch = db.batch();
  old.docs.forEach((d) => batch.delete(d.ref));

  let code = newInviteCode();
  for (let i = 0; i < 5 && (await db.collection('invites').doc(code).get()).exists; i++) code = newInviteCode();
  const expiresAt = Date.now() + INVITE_TTL_MS;
  batch.set(db.collection('invites').doc(code), {
    inviter: uid,
    inviterKey: publicKey,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(expiresAt),
  });
  batch.set(userRef, { publicKey }, { merge: true });
  await batch.commit();
  return { code: formatInviteCode(code), expiresAt };
});

/**
 * Accepts an invite and creates (or, within the 24 h undo window, restores)
 * the couple. Both public keys are stored on the couple document; each phone
 * derives the couple key itself, so the server never sees it.
 *
 * Request: `{ code, publicKey, expectedInviterKey? }`. Response: `{ coupleId }`.
 */
export const acceptInvite = onCall<{ code?: unknown; publicKey?: unknown; expectedInviterKey?: unknown }>(async (request) => {
  const uid = requireUid(request);
  const code = normalizeInviteCode(request.data?.code);
  const publicKey = request.data?.publicKey;
  if (!code) throw new HttpsError('invalid-argument', 'Invite codes have 8 letters and numbers.');
  if (!isPublicKey(publicKey)) throw new HttpsError('invalid-argument', 'This phone’s encryption key is missing. Restart the app and try again.');
  await rateLimit(db.collection('users').doc(uid), 'accept', 20, 60 * 60 * 1000);

  const result = await db.runTransaction(async (tx) => {
    const inviteRef = db.collection('invites').doc(code);
    const invite = await tx.get(inviteRef);
    if (!invite.exists) throw new HttpsError('not-found', 'That code doesn’t exist. Check it and try again.');
    const inviter = invite.get('inviter') as string;
    const inviterKey = invite.get('inviterKey') as string;
    if ((invite.get('expiresAt') as Timestamp).toMillis() < Date.now()) throw new HttpsError('deadline-exceeded', 'That invite expired. Ask for a new one.');
    if (inviter === uid) throw new HttpsError('invalid-argument', 'That’s your own invite. Your partner enters it on their phone.');
    const expected = request.data?.expectedInviterKey;
    if (expected !== undefined && expected !== inviterKey) {
      // The scanned QR and the server disagree on the inviter's key.
      throw new HttpsError('permission-denied', 'The keys don’t match. Pair again side by side.');
    }

    const aRef = db.collection('users').doc(inviter);
    const bRef = db.collection('users').doc(uid);
    const [a, b] = await Promise.all([tx.get(aRef), tx.get(bRef)]);
    if (a.get('coupleId') || b.get('coupleId')) throw new HttpsError('failed-precondition', 'One of you is already paired.');

    // Re-pairing inside the undo window restores the couple and its history.
    const previous = await tx.get(
      db.collection('couples').where('members', 'array-contains', uid).where('status', '==', 'unlinked').limit(10),
    );
    const restore = previous.docs.find((d) => (d.get('members') as string[]).includes(inviter) && (d.get('purgeAt') as Timestamp).toMillis() > Date.now());

    const coupleRef = restore?.ref ?? db.collection('couples').doc();
    const shared = {
      members: [inviter, uid],
      status: 'active',
      names: { [inviter]: a.get('name') ?? 'Partner', [uid]: b.get('name') ?? 'Partner' },
      photos: Object.fromEntries([[inviter, a.get('photoUrl')], [uid, b.get('photoUrl')]].filter(([, p]) => typeof p === 'string')),
      keys: { [inviter]: inviterKey, [uid]: publicKey },
      verifiedKeys: {},
    };
    if (restore) {
      tx.update(coupleRef, { ...shared, unlinkedAt: FieldValue.delete(), unlinkedBy: FieldValue.delete(), purgeAt: FieldValue.delete() });
    } else {
      tx.set(coupleRef, { ...shared, since: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp(), lastRead: {} });
    }
    tx.set(aRef, { coupleId: coupleRef.id }, { merge: true });
    tx.set(bRef, { coupleId: coupleRef.id, publicKey }, { merge: true });
    tx.delete(inviteRef);
    return { coupleId: coupleRef.id, inviter, name: (b.get('name') as string | undefined) ?? 'Your partner' };
  });

  // Realtime Database rules check membership here (they can't read Firestore).
  await rtdb().ref(`members/${result.coupleId}`).set({ [result.inviter]: true, [uid]: true });
  await pushToUser(result.inviter, { kind: 'couple', title: 'You’re paired 💞', body: `${result.name} joined your space. Compare your safety emojis.`, tag: 'pairing' });
  return { coupleId: result.coupleId };
});
