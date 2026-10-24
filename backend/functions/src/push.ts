import { logger } from 'firebase-functions';

import { db, messaging } from './admin.js';

export type PushKind = 'message' | 'call' | 'nudge' | 'spark' | 'couple';

export interface Push {
  kind: PushKind;
  title: string;
  body: string;
  data?: Record<string, string>;
  /** Replaces an earlier notification with the same tag on the phone. */
  tag?: string;
}

const INVALID_TOKEN_CODES = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token', 'messaging/invalid-argument']);

/**
 * Sends a notification to every registered phone of [uid]. Message content is
 * end-to-end encrypted, so pushes only ever say *that* something arrived.
 * Returns the number of phones reached.
 */
export async function pushToUser(uid: string, push: Push): Promise<number> {
  const devices = await db.collection('users').doc(uid).collection('devices').get();
  const tokens = devices.docs.map((d) => d.get('fcmToken')).filter((t): t is string => typeof t === 'string' && t.length > 0);
  if (tokens.length === 0) return 0;
  const isCall = push.kind === 'call';
  const response = await messaging().sendEachForMulticast({
    tokens,
    notification: { title: push.title, body: push.body },
    data: { kind: push.kind, ...push.data },
    android: {
      priority: 'high',
      ttl: isCall ? 45_000 : 24 * 60 * 60 * 1000,
      collapseKey: push.tag,
      notification: {
        channelId: isCall ? 'amour_calls' : 'amour_messages',
        tag: push.tag,
        icon: 'ic_notification',
        color: '#FF4799',
        // Lock screens show "Amour Partagé" instead of the text by default.
        visibility: 'private',
      },
    },
  });
  // Forget tokens of uninstalled apps.
  const stale = response.responses
    .map((r, i) => (r.error && INVALID_TOKEN_CODES.has(r.error.code) ? devices.docs.find((d) => d.get('fcmToken') === tokens[i]) : undefined))
    .filter((d) => d !== undefined);
  await Promise.all(stale.map((d) => d.ref.delete()));
  if (response.failureCount > stale.length) logger.warn('Some pushes failed', { uid, failures: response.failureCount });
  return response.successCount;
}
