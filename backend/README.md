# Amour Partagé: backend

The server side of the app: a Firebase project (Auth, Firestore, Realtime Database, Storage, Cloud Functions, Cloud Messaging) plus [LiveKit](https://livekit.io) for calls.

**The server never sees private content.** Messages, photos, voice notes, daily answers, locations, memories and queue titles are encrypted on the phones with a key only the couple's two phones can derive (see [Encryption](#encryption)). The server stores ciphertext, routes notifications that never contain message text, and enforces who can read and write what.

```
backend/
  firebase.json            emulator ports and deploy targets
  firestore.rules          who can read/write each document
  firestore.indexes.json   query indexes + TTL on shared locations
  database.rules.json      presence, typing, watch-together sync
  storage.rules            encrypted photos and voice notes
  functions/src/           Cloud Functions (TypeScript, Node 22)
  functions/test/          unit tests + end-to-end tests on the emulators
  tests/                   security rules tests on the emulators
```

## What runs where

| Feature | Data | Server logic |
|---|---|---|
| Sign-in | Firebase Auth (Google, email + password) | – |
| Pairing | `invites/{code}`, `couples/{id}` | `createInvite`, `acceptInvite` |
| Chat | `couples/{id}/messages` (sealed), media in Storage (sealed) | `onMessageCreated` → push |
| Online / typing | RTDB `couples/{id}/presence`, `typing` | – |
| Watch together | `couples/{id}/queue`, `playlists` (sealed titles), RTDB `playback`, `countdown` | – |
| Calls | `couples/{id}/calls` | `startCall`, `joinCall`, `endCall` (LiveKit tokens, ringing push) |
| Daily question | `couples/{id}/sparks/{day}`, `answers/{uid}` (sealed) | `ensureTodaySpark`, `dailySparks`, `onSparkAnswered`, `generateQuestions` (Claude) |
| Location | `couples/{id}/locations/{uid}` (sealed, expires) | `expireLocations` + Firestore TTL |
| Memories | `couples/{id}/memories` (sealed), media in Storage | – |
| Nudges | – | `sendNudge` |
| Unlink / delete | – | `unlinkCouple`, `purgeUnlinkedCouples`, `deleteAccount` |

Rules worth knowing:

- Only the couple's two members can touch `couples/{id}/**`, and only while the couple is active.
- Pairing, calls and daily questions are written by functions only; clients can't fake them.
- Your partner's answer to the daily question is readable only after yours exists.
- Shared locations must expire within 8 hours; "until I stop" renews a 2-hour expiry while the app is sharing.
- Unlinking closes the space for both. Everything is deleted after 24 hours; pairing again before then restores it.
- `deleteAccount` removes the user, their shared space and media, and their sign-in immediately.

## Encryption

Each phone creates an X25519 key pair on first sign-in and keeps the private key in the Android Keystore. At pairing, both public keys are stored on the couple document. Each phone then derives the same couple key:

```
couple key = HKDF-SHA256(X25519(my private key, partner public key), salt: "amour-couple:<coupleId>", info: "amour/couple-key/v1")
```

Private fields are sealed with XChaCha20-Poly1305 (random 24-byte nonce). The associated data binds each ciphertext to its couple and document, so it can't be replayed elsewhere. Photos and voice notes get their own random key, which travels inside the sealed message. Call audio and video use LiveKit's end-to-end encryption with a key derived from the couple key, so the media server only relays ciphertext.

Both phones show four **safety emojis** computed from both public keys. If they match, nobody swapped a key in between. If a partner reinstalls or changes phone, their key changes, the app asks you to compare emojis again, and older messages can't be opened on the new phone.

**Beta limitations:** one phone per person, a static couple key (no forward secrecy), and no encrypted backup. A ratcheting protocol (Signal/MLS) and an independent security review are planned before a public launch (see `PLAN.md` §6).

## Set it up

You need Node 22, Java 21 (for the emulators) and a Firebase project on the **Blaze** plan (Cloud Functions and scheduled jobs require it).

1. **Create the Firebase project.** In the console:
   - **Authentication** → enable *Google* and *Email/Password*.
   - **Firestore** (native mode), **Realtime Database** and **Storage**: create each one.
   - **Project settings → Add app → Android**, package name `com.amourpartage.app`. Add the SHA-1 of the key that signs your APKs, or Google sign-in won't work. The CI builds use a throwaway debug key, so set up a permanent signing key first. Email sign-in works without this step.

2. **Create a LiveKit project** (LiveKit Cloud or self-hosted) and note the URL, API key and API secret.

3. **Deploy:**

   ```bash
   cd backend
   npm ci && npm --prefix functions ci
   npx firebase login
   npx firebase use --add                 # pick your project
   echo "LIVEKIT_URL=wss://your-project.livekit.cloud" > functions/.env.<project-id>
   npx firebase functions:secrets:set LIVEKIT_API_KEY
   npx firebase functions:secrets:set LIVEKIT_API_SECRET
   npx firebase functions:secrets:set ANTHROPIC_API_KEY   # optional: AI daily questions
   npx firebase deploy
   ```

   `generateQuestions` uses `claude-opus-5-5` by default. Set `AI_MODEL` in `functions/.env.<project-id>` to use another Claude model. Only the theme and earlier prompts are sent to the Claude API, never messages or answers.

4. **Point the app at it.** Copy `app/config/firebase.example.json` to `app/config/firebase.json` and fill it in from *Project settings → Your apps*. `GOOGLE_SERVER_CLIENT_ID` is the *Web client* ID under *Authentication → Sign-in method → Google*. Then:

   ```bash
   cd app
   flutter build apk --release --dart-define-from-file=config/firebase.json
   ```

   To have CI build against Firebase instead, save the same JSON as a repository secret named `AMOUR_FIREBASE_CONFIG`. Then run **Actions → Android app → Run workflow**. Without the config, the app runs its built-in demo.

Before inviting testers, also:

- enable **App Check** (Play Integrity) and enforce it on the callable functions;
- check that the TTL policy on `locations.expiresAt` is active (`firebase deploy` creates it from `firestore.indexes.json`);
- set budget alerts on the project.

## Develop locally

```bash
npm run emulators   # builds functions, then starts auth, firestore, database, storage, functions
```

Run the app against them (Android emulator → host machine):

```bash
flutter run --dart-define-from-file=config/firebase.json --dart-define=USE_FIREBASE_EMULATORS=true
```

## Tests

```bash
npm run test:unit        # pure logic: invite codes, decks, AI output handling, call tokens
npm run test:rules       # security rules, on the emulators
npm run test:functions   # pairing, calls, daily questions, unlink, account deletion, on the emulators
```

The `Backend` GitHub workflow runs all three on every change under `backend/`.
