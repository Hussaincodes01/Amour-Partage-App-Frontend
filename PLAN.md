# Amour Partage — Android Beta Plan

> A private space for two. Chat, call, watch and listen together, share where you are, and get to know each other better through playful, animated questions. A privacy layer runs on the device to protect what you share.

| | |
|---|---|
| **Platform** | Android first (iOS later from the same codebase) |
| **Release target** | Closed beta on Google Play |
| **Design reference** | [“AI Dating App” by Ronald Olsen (Dribbble)](https://dribbble.com/shots/26603794-AI-Dating-App): the visual language only; Amour Partage is a couples app, not a dating app |
| **Status** | Plan, ready for review. Decisions needed are listed in [§13](#13-open-decisions) |

---

## 1. Product summary

**Who it's for:** couples who are already together, whether they live together or apart, who want one private app for their shared time.

**Core promise:**
1. **Together, even apart.** Watch, listen, talk and see each other in real time.
2. **Private by design.** Only the two of you can read what you share. The AI that protects you runs on your phones, not on our servers.
3. **Delightful.** Every key moment is interactive and animated: onboarding, pairing, daily questions, reveals.

**Beta success metrics**

| Metric | Target |
|---|---|
| Invited partners who complete pairing | ≥ 70 % |
| Couples still active on day 7 (both partners) | ≥ 40 % |
| Daily-question answer rate (both partners) | ≥ 50 % of active couples |
| Watch/Listen-together sessions per couple per week | ≥ 2 |
| Call connection success | ≥ 95 % |
| Crash-free sessions | ≥ 99.5 % |

---

## 2. Beta scope

| # | Feature | In beta | Deferred (post-beta) |
|---|---|---|---|
| 1 | **Pairing** | Invite link/QR code, in-person key exchange, emoji safety check, unlink | Multi-device per user |
| 2 | **Live messaging** | End-to-end encrypted (E2E) text, photos, voice notes, reactions, replies, typing/read indicators, push notifications | Disappearing messages, encrypted backup |
| 3 | **Video & voice calls** | 1:1 HD video/voice, E2E media, incoming-call screen, picture-in-picture | Screen share |
| 4 | **Watch together** | Synced YouTube playback with a live chat/call overlay | Other providers |
| 5 | **Listen together** | Synced YouTube music videos/playlists, shared queue | Spotify-synced playback (see §2.1) |
| 6 | **Shared playlists** | "Our Songs", "Watch Later", "Movie Night" lists. Items can be YouTube videos, YouTube playlists or Spotify/Apple Music links | Import a full Spotify library |
| 7 | **Movies** | Shared watchlist, a "Movie Night" planner, a synced 3-2-1 start countdown for any service, YouTube-hosted films in Watch Together | Licensed in-app streaming |
| 8 | **Location sharing** | Opt-in and mutual, time-boxed live sharing (1 h / 8 h / "until I stop"), safe-arrival ping | Always-on background sharing |
| 9 | **Interactive questions** | Animated onboarding Q&A, daily question with a simultaneous reveal, "How well do you know me?" quiz, AI-generated question decks | Voice answers, streaks/rewards |
| 10 | **AI security layer** | See [§6](#6-ai-security-layer) | Server-side anomaly models |

### 2.1 Platform constraints that shaped this scope

- **Spotify:** since February 2026, new Spotify developer apps in Development Mode are limited to **5 users**, and the app owner must have Premium. Extended quota is effectively only for large companies. **Beta decision:** Spotify appears as shareable links/cards that open the Spotify app. Synced Spotify playback waits until we qualify for extended quota.
- **YouTube:** the IFrame player must stay visible and unmodified, keep ads, and pass identification/referrer. **Beta decision:** Watch/Listen Together play only in the foreground with the official player embedded. No background or audio-only playback.
- **Movies:** we don't host or stream copyrighted films. Movie Night syncs a countdown so each partner presses play on their own service at the same moment, while a call or chat bubble stays on top.
- **Location:** Google Play's stalkerware and location policies require clear, ongoing consent. Sharing is always mutual and visible, shows a persistent notification, and either partner can stop it with one tap.

---

## 3. Design direction (from the reference shot)

The reference shows two moods of the same onboarding screen. We turn them into our two themes:

| | **Midnight** (dark, default) | **Golden Hour** (light) |
|---|---|---|
| Base | Near-black `#0B0A0C` | Warm sand `#E9D6BC` → caramel `#C49A6C` |
| Hero art | Aurora bloom: magenta `#F27BEA`, pink `#FF3E9A`, red `#E8322E`, fading into black | Sun rays `#F6E25A` over haze and soft clouds |
| Accent | Coral → pink gradient `#FF6A4D → #FF3E9A` | Same accent; white text on the hero |
| Text | White / 70 % white | White on hero, ink `#141216` on surfaces |

**Typography** (all open-licensed Google Fonts):
- **Display:** *Instrument Serif*, a condensed editorial serif (the Golden Hour headline). Size 34–40 sp, line height ≈ 1.05, centred.
- **Script accent:** *Pinyon Script*, used for **one word per headline** in the accent gradient. The reference does this with the flourished "L" and the coral "*you*"; we use it for "*Amour*" and partner names.
- **UI:** *Instrument Sans* for body copy, buttons and labels.

**Components**
- **Primary button:** solid white pill, 52 dp tall, black 15 sp medium label ("Continue with Email").
- **Secondary button:** glass pill (white at 8–12 %, background blur, 1 dp hairline) with the label on the left and a 28 dp white circular icon on the right.
- **Divider:** hairlines either side of tracked 10 sp caps ("OR CONTINUE WITH").
- **Cards and sheets:** 28–32 dp radius, glass on Midnight and frosted cream on Golden Hour.
- **Grain:** a 4–7 % film-grain overlay on all hero art, which gives the premium analogue feel.

**Motion: the "interactive" part**
- The **aurora is alive**: a slow fragment-shader mesh gradient (20–30 s loop) that drifts, follows your touch and **changes colour with your answers** during questions. It is the AI's visual presence.
- Headline words fade and rise in a stagger, and the script word **writes itself on** (path reveal).
- Answers to questions are glass pills that spring in. Picking one makes the aurora shift, with a light haptic tick.
- Simultaneous reveals use a card flip with a confetti burst when partners match.
- Everything respects Android's *Remove animations* setting.

**Note:** the shot is a dating-app concept by another designer, for a different product. We take its look and feel but make our own hero art, copy and screens.

### 3.1 Key screens (beta)

1. Splash: the logo, with the aurora blooming in.
2. Welcome / sign-in, in the reference layout: Email and Google. Apple is added with iOS later.
3. Onboarding Q&A: 5–7 animated questions (name, how you met, love language, the vibe you want).
4. Pair with your partner: invite link or QR code, then the emoji safety check.
5. **Home ("Us"):** days together, partner presence, today's question, quick actions (call, watch, share location).
6. Chat, then the call screen.
7. **Together hub:** Watch / Listen / Movie Night, then the player room with an overlay.
8. Playlists, then the playlist detail.
9. Map: live location and safe-arrival.
10. Questions: daily question, decks, quiz, past answers.
11. **Privacy Center:** app lock, sessions and devices, AI Guard settings, data export/delete, unlink.
12. Settings / profile.

**Bottom navigation:** Home · Chat · Together · Map · Privacy.

---

## 4. Logo

A first concept is in [`brand/logo/`](brand/logo/) (SVG, with text converted to outlines):

- **Mark:** two hearts that overlap. **The space they share glows white**, a third heart that is literally *amour partagé* (shared love). The sparkle stands for the AI privacy layer.
- **Icon:** the mark on a Midnight aurora tile with grain. It also works on Golden Hour, as the preview shows.
- **Wordmark:** script "*Amour*" in the accent gradient plus serif "Partage", the same script-plus-serif pairing as the reference headline.

![Logo concept preview](brand/logo/preview.png)

**Next steps:** pick or iterate on the direction, then produce the Android adaptive icon (foreground mark inside the 66 dp safe zone, aurora background layer, monochrome layer for themed icons), the Play Store 512 px icon and a feature graphic.

---

## 5. Architecture

```
┌──────────────────────── Android app (Flutter) ────────────────────────┐
│  UI (design system, shaders, Rive/Lottie)                              │
│  Features: pairing · chat · calls · together · playlists · location ·  │
│            questions · privacy                                         │
│  Core: E2E crypto (X25519 + XChaCha20-Poly1305) · secure storage ·     │
│        on-device AI Guard (TFLite) · sync engine                       │
└───────┬───────────────┬──────────────────┬────────────────┬───────────┘
        │ ciphertext    │ presence/sync    │ media (E2E)    │ AI prompts
        ▼               ▼                  ▼                ▼ (no chat content)
  Cloud Firestore   Realtime Database   LiveKit Cloud   Cloud Functions ──► Claude API
  + Cloud Storage   (typing, playback   (WebRTC SFU,    (LiveKit tokens,
  (durable data)     state, presence)    data channel)   question decks,
                                                         push fan-out)
        └──── Firebase Auth · App Check (Play Integrity) · FCM ────┘
```

### 5.1 Stack (recommended)

| Layer | Choice | Why |
|---|---|---|
| App framework | **Flutter** (Dart) | Best-in-class custom animation and shaders (`FragmentProgram`) for the aurora look. One codebase for Android now and iOS later |
| State / routing | Riverpod · go_router | Testable and widely used |
| Animation | Custom fragment shaders, `rive`, `lottie`, `flutter_animate` | Aurora, the mascot/state machines, micro-interactions |
| Auth | Firebase Auth (email link + Google) | Matches the reference sign-in screen |
| Data | Cloud Firestore (durable), Realtime Database (high-frequency sync), Cloud Storage (encrypted media) | Managed, realtime, offline cache |
| Calls | **LiveKit** (`livekit_client`) with E2EE enabled | Open-source SFU, solid Flutter SDK, data channels |
| YouTube | `youtube_player_iframe` | Official IFrame API, so it complies with YouTube's player rules |
| Crypto | `cryptography` + `cryptography_flutter`, `flutter_secure_storage` (Android Keystore) | Audited primitives, hardware-backed key storage |
| On-device AI | TFLite (`tflite_flutter`) and ML Kit | Runs privately on the phone |
| Server AI | Cloud Function calling the Claude API (`claude-haiku-5-5`) | The API key never ships in the app. Only non-sensitive prompts are sent |
| Location / maps | `geolocator` with a location foreground service, `google_maps_flutter` (dark style) | No background-location permission needed for time-boxed sharing |
| Push / calls | FCM high-priority data messages, then a full-screen incoming-call notification | Reliable call ringing |
| Quality | Crashlytics, Firebase App Distribution, GitHub Actions | Fast beta loop |

**Repositories:** this repo is the **Flutter app**. A companion `amour-partage-app-backend` repo holds the Cloud Functions (TypeScript), security rules, Firestore indexes and the LiveKit token service.

### 5.2 App structure (this repo)

```
lib/
  main.dart
  app/                 # router, themes (Midnight, Golden Hour), DI, environment config
  core/
    design_system/     # tokens, typography, pill buttons, glass cards, grain, aurora shader
    crypto/            # key management, pairing handshake, encrypt/decrypt, safety emoji
    ai_guard/          # on-device classifiers, link scanner, policies
    sync/              # server-clock offset, playback sync engine
    data/              # Firestore/RTDB/Storage clients, repositories
  features/
    onboarding/  auth/  pairing/  home/  chat/  calls/  together/
    playlists/  movies/  location/  questions/  privacy/  settings/
      (each: data/ · domain/ · presentation/)
assets/  shaders/  rive/  lottie/  fonts/  images/
android/
test/  integration_test/
```

### 5.3 Data model (Firestore)

```
users/{uid}                       displayName, avatar, createdAt
users/{uid}/devices/{deviceId}    publicKey, fcmToken, model, lastSeen, approved
couples/{coupleId}                members[2], status (pending|active|unlinked), since, theme, settings
  messages/{id}                   senderId, type, ciphertext, nonce, createdAt, replyTo, reactions (enc)
  media/{id}                      storagePath (encrypted blob), mime, sizes
  playlists/{id}                  name (enc), kind (songs|videos|movies)
    items/{id}                    provider (youtube|spotify|apple|link), externalId, meta (enc), addedBy
  questions/{id}                  deckId, prompt, answers {uid: ciphertext}, revealedAt
  locations/{uid}                 ciphertext, expiresAt (TTL policy deletes expired docs)
  watchlist/{id}                  title, year, poster (enc), status
rtdb: /presence/{uid}  /typing/{coupleId}/{uid}  /sessions/{coupleId}
```

Security rules: a document under `couples/{coupleId}` can be read or written only when `request.auth.uid` is one of that couple's `members`. App Check is enforced on every service.

### 5.4 Watch/Listen-together sync

- **Shared state** in `rtdb:/sessions/{coupleId}`: `{provider, mediaId, playing, positionMs, at: serverTime, by, seq}`.
- Each client reads its server-clock offset from `.info/serverTimeOffset`. Expected position = `positionMs + (serverNow − at)` while playing.
- If drift exceeds 0.8 s, seek. Under that threshold, do nothing (no jitter).
- **Last writer wins**, using a `seq` transaction. Either partner can play, pause, seek or skip.
- **"Wait for me":** when one player is buffering it publishes `buffering`, which pauses both and resumes them together.
- During a call, the same events also go over the LiveKit data channel for lower latency.

---

## 6. AI security layer

The principle: **message content never leaves the couple's phones unencrypted, so all AI that looks at content runs on the device.**

| Guard | What it does | Where it runs |
|---|---|---|
| **Couple-only encryption** | Keys are exchanged in person by QR code at pairing. Messages, media, location, answers and call media are encrypted end to end | Device |
| **Safety emoji check** | Both phones show the same 4 emojis derived from the keys. A mismatch blocks pairing (stops interception). Built as a fun, animated step | Device |
| **Device approval** | Logging in on a new phone needs the partner's in-app approval and a re-key. Unknown devices get alerted and locked out | Device + Functions |
| **App lock & discreet mode** | Biometric/PIN lock, auto-lock timer, notification text hidden by default, optional neutral app icon and name | Device |
| **Screenshot shield** | `FLAG_SECURE` blocks screenshots and screen recording on chat, media, map and calls. On other screens, Android 14+ screenshot detection notifies the partner | Device |
| **Sensitive-media guard** | A TFLite classifier blurs intimate or sensitive images until tapped, and asks "Are you sure?" before sending | Device |
| **Link & scam guard** | Flags phishing links, payment scams and impersonation patterns in chat. URLs are checked by hash prefix (Google Web Risk), so full links never leave the phone | Device (+ hash lookups) |
| **Location safety** | Mutual, time-limited and always visible (persistent notification). Auto-expires and stops with one tap. AI notices unusual sharing (e.g. left on 24 h+) and asks whether to stop | Device |
| **Privacy check-up** | An animated quiz-style walkthrough: "Who can see this?", review sessions, permissions and lock settings. The AI explains each setting in plain language | Device + Claude (no personal content) |
| **Safe exit** | Either partner can unlink. Shared data is wiped from the server and keys are destroyed, with a 24 h undo window | Functions |

**Beta limitations (stated honestly):** one active device per user, and a single static couple key with no forward secrecy. Post-beta we upgrade to a ratcheting protocol (Signal protocol / MLS), add encrypted backups, and **get an independent security review before public launch.**

---

## 7. Interactive questions (and where the AI helps)

- **Onboarding Q&A:** one question per screen in the reference layout. A serif question with one script word, answers as glass pills, and the aurora shifting colour with each answer. The answers set your theme, your first question deck and your partner's invite message.
- **Daily question:** both partners answer privately. Answers stay **locked until both have answered**, then reveal with a card flip and confetti when they match.
- **"How well do you know me?"** Each partner answers about themselves and guesses the other's answer. The score is animated.
- **Decks:** a curated library (about 300 questions in fun / deep / future / memories) ships in the app for beta.
- **AI decks:** the Cloud Function asks Claude (`claude-haiku-5-5`) for fresh questions based **only** on the chosen deck, relationship stage, language and opt-in interest tags. **No chat content and no answers are ever sent.** Output is checked against a JSON schema and moderated. Each couple has a daily cap and results are cached to control cost.

---

## 8. Google Play compliance checklist

- [ ] Target **API 36 (Android 16)**, required for new apps and updates from 31 Aug 2026. minSdk 26.
- [ ] Permissions declared with clear in-app rationale screens: camera, microphone, notifications, fine location, Bluetooth connect.
- [ ] Foreground-service types declared and justified: `phoneCall`/`camera`/`microphone` for calls, `location` for sharing, `mediaPlayback` only if needed.
- [ ] `USE_FULL_SCREEN_INTENT` declared for incoming calls.
- [ ] **Photo picker** used instead of broad media permissions.
- [ ] **No background location** in beta, which avoids the background-location declaration.
- [ ] Location-sharing prominent disclosure and persistent notification (stalkerware policy).
- [ ] Data safety form: E2E encryption, data deletion, no data sold.
- [ ] Privacy policy and terms URLs, an in-app account deletion path, and web deletion request.
- [ ] Content rating questionnaire. Age gate 18+.
- [ ] Closed testing: new personal developer accounts must run a closed test with at least 12 testers for 14 days before production access. Plan this into the schedule.

---

## 9. Milestones

Assumed team: 2 Flutter devs, 1 backend/Firebase dev and a part-time designer. A solo developer should roughly double these figures.

| Phase | Weeks | Deliverables |
|---|---|---|
| **0. Foundations** | 1–2 | Logo finalised, design tokens and both themes, the aurora shader and grain, pill/glass components. Flutter scaffold, CI (analyze/test/build), Firebase dev/staging/prod, auth |
| **1. First impression** | 3–4 | Splash, welcome/sign-in, animated onboarding Q&A, **pairing with QR key exchange and safety emojis**, Home skeleton |
| **2. Talk** | 5–7 | E2E chat (text, photos, voice notes, reactions), push notifications, app lock, discreet notifications |
| **3. Together** | 7–9 | Video/voice calls (LiveKit, E2EE, incoming-call UI, PiP), Watch/Listen Together sync, shared playlists, Movie Night countdown and watchlist |
| **4. Close & safe** | 10–11 | Time-boxed location sharing and map, daily question, quiz, AI decks, AI Guard (screenshot shield, media guard, link guard, device approval), Privacy Center |
| **5. Beta** | 12–14 | Hardening, accessibility pass, battery/perf tuning, Play compliance, internal → closed testing (12+ testers × 14 days), feedback loop |

Each phase ends with a demo build on Firebase App Distribution.

---

## 10. Testing strategy

- **Unit:** crypto (known vectors, tamper detection), sync engine (drift and clock-offset cases), security-rule tests on the Firebase emulator.
- **Widget / golden:** design-system components in both themes, plus large-font and reduced-motion variants.
- **Integration:** a two-device flow on emulators (pair → chat → call → watch together → share location → unlink).
- **Device matrix:** Firebase Test Lab with low-end (3 GB RAM), mid-range and flagship phones, Android 10–16.
- **Manual beta scripts:** calls on poor networks, battery drain while sharing location, aurora shader frame rate (target 60 fps; fall back to a static gradient on low-end GPUs).

---

## 11. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Spotify API limits block co-listening | YouTube-first for beta. Spotify as links. Revisit extended quota later |
| YouTube policy breach (background play, player changes) | Official IFrame player only, foreground only, compliance review before beta |
| Location features misused for control or stalking | Mutual, visible, time-boxed and instantly stoppable. Safety copy. Nudges after long sessions |
| Homemade E2E crypto has bugs | Audited library primitives, a simple protocol, test vectors, external review before public launch |
| Shader animation slows low-end phones | Measure frame time and degrade to a static gradient with grain |
| Play review delays (foreground services, full-screen intent) | Declare early, record demo videos, run internal testing from week 6 |
| AI cost or unsafe output | Small model, caching, per-couple caps, schema validation, moderation, curated decks as the fallback |

---

## 12. Immediately after approval

1. Lock the open decisions below.
2. Scaffold the Flutter project here with the design-system package, both themes, the aurora shader and the welcome screen recreated in our style.
3. Create the `amour-partage-app-backend` repo with the Firebase project config and security rules.
4. Turn the phases into GitHub issues and milestones.

---

## 13. Open decisions

1. **Framework:** Flutter (recommended), React Native, or native Kotlin/Jetpack Compose?
2. **Backend:** Firebase and LiveKit Cloud (recommended), or Supabase / self-hosted?
3. **Sign-in:** Email and Google (as in the reference)? Phone number as well?
4. **Spotify:** OK to ship links only in beta (synced playback later)?
5. **Name:** "Amour Partage" (*sharing love*) or "Amour Partagé" (*shared love*, with the accent)?
6. **Logo:** go with the overlapping-hearts concept, or explore alternatives (script-"A" monogram, line art)?
7. **Team and date:** team size and target beta date, to firm up the schedule.
