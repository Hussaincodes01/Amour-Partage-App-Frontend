import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/scheduler';

import { Timestamp, db } from './admin.js';

/**
 * Deletes expired location shares. A Firestore TTL policy on
 * `locations.expiresAt` does the same within ~24 h; this runs every 15
 * minutes so an expired location never lingers.
 */
export const expireLocations = onSchedule('every 15 minutes', async () => {
  let removed = 0;
  for (;;) {
    const expired = await db.collectionGroup('locations').where('expiresAt', '<=', Timestamp.now()).limit(200).get();
    if (expired.empty) break;
    const batch = db.batch();
    expired.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    removed += expired.size;
    if (expired.size < 200) break;
  }
  if (removed > 0) logger.info('Expired locations removed', { removed });
});
