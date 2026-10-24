import { onCall } from 'firebase-functions/https';

import { auth, db } from './admin.js';
import { nameOf, requireUid } from './lib.js';
import { purgeCouple, unlink } from './couple.js';
import { pushToUser } from './push.js';

/**
 * Deletes the caller's account (Google Play's in-app deletion requirement):
 * unlinks and immediately deletes the shared space, then the user's own data
 * and their sign-in.
 */
export const deleteAccount = onCall(async (request) => {
  const uid = requireUid(request);
  const userRef = db.collection('users').doc(uid);
  const coupleId = (await userRef.get()).get('coupleId') as string | undefined;
  if (coupleId) {
    const couple = (await db.collection('couples').doc(coupleId).get()).data();
    const members = await unlink(coupleId, uid, 0);
    await purgeCouple(coupleId);
    const partner = members.find((m) => m !== uid);
    if (partner && couple) {
      await pushToUser(partner, { kind: 'couple', title: 'Your space was closed', body: `${nameOf(couple, uid)} deleted their account.`, tag: 'pairing' });
    }
  }
  const invites = await db.collection('invites').where('inviter', '==', uid).get();
  await Promise.all(invites.docs.map((d) => d.ref.delete()));
  await db.recursiveDelete(userRef);
  try {
    await auth().deleteUser(uid);
  } catch (e) {
    if ((e as { code?: string }).code !== 'auth/user-not-found') throw e;
  }
  return { ok: true };
});
