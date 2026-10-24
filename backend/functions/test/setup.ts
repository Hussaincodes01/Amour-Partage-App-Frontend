// Test configuration: a demo project (never touches a real one) and fake
// LiveKit credentials. Emulator hosts come from `firebase emulators:exec`.
process.env.GCLOUD_PROJECT ??= 'demo-amour-partage';
process.env.FIREBASE_CONFIG ??= JSON.stringify({
  projectId: 'demo-amour-partage',
  databaseURL: `http://${process.env.FIREBASE_DATABASE_EMULATOR_HOST ?? '127.0.0.1:9000'}/?ns=demo-amour-partage-default-rtdb`,
  storageBucket: 'demo-amour-partage.appspot.com',
});
process.env.LIVEKIT_URL ??= 'wss://example.livekit.cloud';
process.env.LIVEKIT_API_KEY ??= 'APItestkey';
process.env.LIVEKIT_API_SECRET ??= 'test-secret-that-is-long-enough-for-hs256-signing';
