# Amour Partagé: Android APKs

Beta builds of the app in [`app/`](../app/), built by GitHub Actions (**Actions → Android app → Run workflow**). Each manual run replaces the APKs here.

| File | Use it for |
|---|---|
| `amour-partage-<version>-arm64-v8a.apk` | Almost every phone from the last several years (64-bit). Pick this one if you're unsure. |
| `amour-partage-<version>-armeabi-v7a.apk` | Older 32-bit phones. |
| `amour-partage-<version>.apk` | Any phone (all CPU types in one, bigger download). Only included when it fits GitHub's file size limit. |

All of them need Android 7.0 or later.

## Demo or connected

Builds made without Firebase settings run the **demo**: everything stays on the phone, with a simulated partner. Once the repository has the `AMOUR_FIREBASE_CONFIG` secret (see [`backend/README.md`](../backend/README.md)), new builds connect to your Firebase project with real accounts, pairing and calls.

## Install on a phone

1. Open the `.apk` file on GitHub and tap **Download** (or "View raw").
2. Open the downloaded file.
3. If Android asks, allow **Install unknown apps** for your browser or Files app.
4. Tap **Install**.

## Note on signing

These beta builds are signed with a temporary test key, and every build gets a new one. To install a newer build, uninstall the old one first. Uninstalling clears the app's local data.

Before a Play Store release, the app needs a permanent signing key. Google sign-in also needs it, because the key's fingerprint has to be registered in Firebase.
