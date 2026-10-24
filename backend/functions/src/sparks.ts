import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/firestore';
import { onCall } from 'firebase-functions/https';
import { onSchedule } from 'firebase-functions/scheduler';

import { FieldValue, db } from './admin.js';
import { DAILY_PROMPTS } from './decks.js';
import { dayKey, nameOf, requireCouple, requireUid, stableIndex } from './lib.js';
import { pushToUser } from './push.js';

/**
 * Creates today's question for a couple if it doesn't exist yet. AI-written
 * prompts queued by `generateQuestions` are used first, then the curated deck.
 * Answers live in `sparks/{day}/answers/{uid}`, sealed with the couple key;
 * the security rules hide a partner's answer until you've answered.
 */
export async function ensureSpark(coupleId: string, day = dayKey()): Promise<{ id: string; prompt: string; created: boolean }> {
  const coupleRef = db.collection('couples').doc(coupleId);
  const sparkRef = coupleRef.collection('sparks').doc(day);
  return db.runTransaction(async (tx) => {
    const [spark, couple] = await Promise.all([tx.get(sparkRef), tx.get(coupleRef)]);
    if (spark.exists) return { id: day, prompt: spark.get('prompt') as string, created: false };
    const queued = (couple.get('promptQueue') ?? []) as string[];
    const used = new Set((couple.get('recentPrompts') ?? []) as string[]);
    let prompt = queued[0];
    if (!prompt) {
      // Skip prompts used recently; fall back to the stable pick if all were.
      const fresh = DAILY_PROMPTS.filter((p) => !used.has(p));
      const pool = fresh.length > 0 ? fresh : DAILY_PROMPTS;
      prompt = pool[stableIndex(`${coupleId}:${day}`, pool.length)];
    }
    const number = ((couple.get('sparkCount') as number | undefined) ?? 0) + 1;
    tx.set(sparkRef, { prompt, number, answered: {}, createdAt: FieldValue.serverTimestamp() });
    tx.update(coupleRef, {
      sparkCount: number,
      promptQueue: queued.slice(queued[0] === prompt ? 1 : 0),
      recentPrompts: [...used, prompt].slice(-30),
    });
    return { id: day, prompt, created: true };
  });
}

export const ensureTodaySpark = onCall(async (request) => {
  const uid = requireUid(request);
  const couple = await requireCouple(uid);
  const { id, prompt } = await ensureSpark(couple.id);
  return { id, prompt };
});

/** Marks who answered; when both have, reveals and tells both phones. */
export const onSparkAnswered = onDocumentCreated('couples/{coupleId}/sparks/{day}/answers/{uid}', async (event) => {
  const { coupleId, day, uid } = event.params;
  const coupleRef = db.collection('couples').doc(coupleId);
  const sparkRef = coupleRef.collection('sparks').doc(day);
  const { both, partner, couple } = await db.runTransaction(async (tx) => {
    const [spark, couple] = await Promise.all([tx.get(sparkRef), tx.get(coupleRef)]);
    const members = (couple.get('members') ?? []) as string[];
    const answered = { ...((spark.get('answered') ?? {}) as Record<string, boolean>), [uid]: true };
    const both = members.length === 2 && members.every((m) => answered[m]);
    tx.set(sparkRef, { answered, ...(both ? { revealedAt: FieldValue.serverTimestamp() } : {}) }, { merge: true });
    return { both, partner: members.find((m) => m !== uid), couple: couple.data() ?? {} };
  });
  if (!partner) return;
  const name = nameOf(couple, uid);
  if (both) {
    await Promise.all([
      pushToUser(partner, { kind: 'spark', title: 'Both answers are in ✨', body: `See what ${name} said`, tag: `spark_${day}` }),
      pushToUser(uid, { kind: 'spark', title: 'Both answers are in ✨', body: `See what ${nameOf(couple, partner)} said`, tag: `spark_${day}` }),
    ]);
  } else {
    await pushToUser(partner, { kind: 'spark', title: 'Today’s question', body: `${name} answered. Answer to unlock both.`, tag: `spark_${day}` });
  }
});

/** Every morning (UTC): today's question for every active couple. */
export const dailySparks = onSchedule('every day 07:00', async () => {
  const couples = await db.collection('couples').where('status', '==', 'active').select('members').get();
  let created = 0;
  for (const doc of couples.docs) {
    try {
      const spark = await ensureSpark(doc.id);
      if (!spark.created) continue;
      created++;
      await Promise.all(
        ((doc.get('members') ?? []) as string[]).map((m) => pushToUser(m, { kind: 'spark', title: 'Today’s question 💭', body: spark.prompt, tag: 'spark' })),
      );
    } catch (e) {
      logger.warn('Daily question failed', { coupleId: doc.id, error: String(e) });
    }
  }
  logger.info('Daily questions created', { created });
});
