# Amour Partagé — Android APKs

Beta builds of the app in [`app/`](../app/), built by GitHub Actions (**Actions → Android app → Run workflow**). Each manual run replaces the APKs here.

| File | Use it for |
|---|---|
| `amour-partage-<version>.apk` | Any Android phone running Android 7.0 or later. Pick this one if you're unsure. |
| `amour-partage-<version>-arm64-v8a.apk` | A smaller download for 64-bit phones, which covers almost every phone from the last several years. |

## Install on a phone

1. Open the `.apk` file on GitHub and tap **Download** (or "View raw").
2. Open the downloaded file.
3. If Android asks, allow **Install unknown apps** for your browser or Files app.
4. Tap **Install**.

## Note on signing

These beta builds are signed with a temporary test key, and every build gets a new one. To install a newer build, uninstall the old one first. Uninstalling clears the app's local data.

Before a Play Store release, the app needs a permanent signing key.
