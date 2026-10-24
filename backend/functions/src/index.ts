/**
 * Amour Partagé Cloud Functions.
 *
 * Callable (from the app): createInvite, acceptInvite, unlinkCouple,
 * deleteAccount, startCall, joinCall, endCall, sendNudge, ensureTodaySpark,
 * generateQuestions.
 * Triggers: onMessageCreated (push), onSparkAnswered (reveal + push).
 * Scheduled: dailySparks, expireLocations, purgeUnlinkedCouples.
 */
import { setGlobalOptions } from 'firebase-functions';

setGlobalOptions({ region: process.env.FUNCTIONS_REGION ?? 'us-central1', maxInstances: 20 });

export { deleteAccount } from './account.js';
export { generateQuestions } from './ai.js';
export { endCall, joinCall, startCall } from './calls.js';
export { purgeUnlinkedCouples, unlinkCouple } from './couple.js';
export { expireLocations } from './location.js';
export { onMessageCreated, sendNudge } from './notify.js';
export { acceptInvite, createInvite } from './pairing.js';
export { dailySparks, ensureTodaySpark, onSparkAnswered } from './sparks.js';
