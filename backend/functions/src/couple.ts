import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/https';
import { onSchedule } from 'firebase-functions/scheduler';

import { FieldValue, Timestamp, db, rtdb, storage } from './admin.js';
import { UNLINK_GRACE_MS, nameOf, requireCouple, requireUid } from './lib.js';
import { pushToUser } from './push.js';

/**
 * Closes the couple for both partners. Data stays for a 24 h undo window
 * (pairing again restores it), then `purgeUnlinkedCouples` deletes it.
 */
export async function unlink(coupleId: string, by: string, graceMs = UNLINK_GRACE_MS): Promise<string[]> {
  const ref = db.collection('couples').doc(coupleId);
  const members = await db.runTransaction(async (tx) => {
    const couple = await tx.get(ref);
    const members = (couple.get('members') ?? []) as string[];
    tx.update(ref, {
      status: 'unlinked',
      unlinkedBy: by,
      unlinkedAt: FieldValue.serverTimestamp(),
      purgeAt: Timestamp.fromMillis(Date.now() + graceMs),
    });
    for (const uid of members) tx.set(db.collection('users').doc(uid), { coupleId: FieldValue.delete() }, { merge: true });
    return members;
  });
  await rtdb().ref(`members/${coupleId}`).remove();
  await rtdb().ref(`couples/${coupleId}`).remove();
  return members;
}

/** Deletes everything stored for a couple: documents, live state, media. */
export async function purgeCouple(coupleId: string): Promise<void> {
  await db.recursiveDelete(db.collection('couples').doc(coupleId));
  await rtdb().ref(`couples/${coupleId}`).remove();
  await rtdb().ref(`members/${coupleId}`).remove();
  try {
    await storage().bucket().deleteFiles({ prefix: `couples/${coupleId}/` });
  } catch (e) {
    logger.warn('Media not deleted (no bucket in this environment?)', { coupleId, error: String(e) });
  }
}

export const unlinkCouple = onCall(async (request) => {
  const uid = requireUid(request);
  const couple = await requireCouple(uid);
  await unlink(couple.id, uid);
  await pushToUser(couple.partner, {
    kind: 'couple',
    title: 'Your space was closed',
    body: `${nameOf(couple.data, uid)} unlinked. Everything is deleted in 24 hours unless you pair again.`,
    tag: 'pairing',
  });
  return { ok: true };
});

export const purgeUnlinkedCouples = onSchedule('every 60 minutes', async () => {
  const due = await db.collection('couples').where('status', '==', 'unlinked').where('purgeAt', '<=', Timestamp.now()).limit(50).get();
  for (const doc of due.docs) {
    await purgeCouple(doc.id);
    logger.info('Purged unlinked couple', { coupleId: doc.id });
  }
});
