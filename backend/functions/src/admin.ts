import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getDatabase } from 'firebase-admin/database';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';

if (getApps().length === 0) initializeApp();

export const db = getFirestore();
export const auth = () => getAuth();
export const rtdb = () => getDatabase();
export const messaging = () => getMessaging();
export const storage = () => getStorage();
export { FieldValue, Timestamp };
