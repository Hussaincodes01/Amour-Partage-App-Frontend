import { onDocumentCreated } from 'firebase-functions/firestore';
import { onCall } from 'firebase-functions/https';

import { db } from './admin.js';
import { nameOf, rateLimit, requireCouple, requireUid } from './lib.js';
import { pushToUser } from './push.js';

const KIND_TEXT: Record<string, string> = {
  text: 'sent you a message',
  photo: 'sent you a photo',
  voice: 'sent you a voice note',
  lockedMoment: 'sent you a locked moment',
};

/** Push for a new message. The text itself is encrypted; we only say who. */
export const onMessageCreated = onDocumentCreated('couples/{coupleId}/messages/{messageId}', async (event) => {
  const message = event.data?.data();
  if (!message) return;
  const couple = (await db.collection('couples').doc(event.params.coupleId).get()).data();
  if (!couple || couple.status !== 'active') return;
  const sender = message.sender as string;
  const partner = (couple.members as string[]).find((m) => m !== sender);
  if (!partner) return;
  const name = nameOf(couple, sender);
  await pushToUser(partner, {
    kind: 'message',
    title: name,
    body: `${name} ${KIND_TEXT[message.kind as string] ?? KIND_TEXT.text}`,
    data: { coupleId: event.params.coupleId },
    tag: `chat_${event.params.coupleId}`,
  });
});

/** "Thinking of you" nudge from the Home screen. */
export const sendNudge = onCall(async (request) => {
  const uid = requireUid(request);
  const couple = await requireCouple(uid);
  await rateLimit(db.collection('users').doc(uid), 'nudges', 20, 60 * 60 * 1000);
  const name = nameOf(couple.data, uid);
  await pushToUser(couple.partner, { kind: 'nudge', title: '💗', body: `${name} is thinking of you`, tag: 'nudge' });
  return { ok: true };
});
