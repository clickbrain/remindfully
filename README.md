# Remindfully

**Remindfully** is a focus and mindfulness mobile app built with Flutter.  
Its core mechanic: scientifically engineered concentration music (binaural beats / isochronic tones) plays continuously, with random silent gaps injected. The user must tap the screen before the music resumes. The faster they tap, the more points they earn.

---

## Tech Stack

- **Flutter** (Dart) — cross-platform, iOS priority
- **PocketBase** — self-hosted backend (auth, database, real-time API)
- **Riverpod** — state management
- **just_audio** — audio playback and silence injection
- **shared_preferences** — local storage for guest mode and auth persistence

---

## Features

- 🎵 **Audio Engine** — looping focus music with random silence gaps
- 👆 **Tap Mechanic** — react within the silence window to earn points
- ⏱️ **Session Timer** — choose 5–60 minute focus sessions
- 🏆 **Leaderboard** — global, weekly, and daily rankings
- 👤 **Auth** — Email, Google OAuth2, Apple OAuth2, and Guest mode
- 👫 **Friends** — find friends, accept requests, share invite links
- 📳 **Haptic Feedback** — tactile cues for taps, misses, and session events

---

## Setting Up PocketBase

PocketBase is the self-hosted backend for Remindfully. Follow these steps to set it up on your server.

**Server:** `http://178.156.225.241:8090`  
**Admin UI:** `http://178.156.225.241:8090/_/`

### Step 1: Clone the repo and navigate to the pocketbase folder

```bash
git clone https://github.com/clickbrain/remindfully.git
cd remindfully/pocketbase
```

### Step 2: Update your Portainer stack

1. Go to **Portainer → Stacks → pocketbase → Editor**
2. Replace the entire compose content with the contents of `pocketbase/docker-compose.yml` from this repo
3. **IMPORTANT:** Change the volume mount path `./pb_migrations` to the **absolute path** where you cloned the repo on your server, for example:
   ```yaml
   - /opt/remindfully/pocketbase/pb_migrations:/pb/pb_migrations
   ```
4. Click **"Update the stack"**

### Step 3: Restart the PocketBase container

- In **Portainer → Containers → pocketbase → Restart**
- Or in **Portainer → Stacks → pocketbase** → click **"Stop"** then **"Start"**

### Step 4: Verify migrations ran

1. Visit `http://178.156.225.241:8090/_/`
2. Log in with your admin credentials
3. Go to **Collections** — you should see all of the following created automatically:
   - `sessions` ✅
   - `leaderboard_entries` ✅
   - `friendships` ✅
   - `invite_links` ✅
   - `users` (extended with extra fields) ✅

### Step 5: Configure OAuth2 (for Google and Apple Sign-In)

1. In **PocketBase Admin → Collections → users → Edit → Auth Providers**
2. **Enable Google OAuth2:**
   - Add your **Google Client ID** and **Client Secret**
   - (Obtained from [Google Cloud Console](https://console.cloud.google.com))
3. **Enable Apple OAuth2:**
   - Add your **Apple Client ID** and **Client Secret**
   - (Obtained from [Apple Developer Portal](https://developer.apple.com))

### Step 6: Run the Flutter app

```bash
flutter pub get
flutter run
```

---

## Project Structure

```
remindfully/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # Root widget + navigation shell
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart         # App-wide constants (pocketbaseUrl, etc.)
│   │   ├── services/
│   │   │   └── pocketbase_service.dart    # PocketBase client + auth persistence
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Dark-mode-first theme
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── providers/auth_provider.dart
│   │   │   └── screens/
│   │   ├── session/
│   │   │   ├── audio_engine/audio_engine.dart
│   │   │   ├── providers/session_provider.dart
│   │   │   └── screens/
│   │   ├── leaderboard/
│   │   │   ├── providers/leaderboard_provider.dart
│   │   │   └── screens/
│   │   ├── friends/
│   │   │   ├── providers/friends_provider.dart
│   │   │   └── screens/
│   │   └── profile/
│   │       ├── providers/profile_provider.dart
│   │       └── screens/
│   └── shared/
│       ├── models/
│       └── widgets/
├── assets/
│   ├── audio/   # Place focus music tracks here (binaural beats / isochronic tones)
│   └── images/
├── pocketbase/
│   ├── docker-compose.yml                 # Docker Compose stack for PocketBase
│   └── pb_migrations/                     # Auto-run migrations on PocketBase start
│       ├── 1700000001_extend_users.js
│       ├── 1700000002_create_sessions.js
│       ├── 1700000003_create_leaderboard_entries.js
│       ├── 1700000004_create_friendships.js
│       └── 1700000005_create_invite_links.js
├── pubspec.yaml
└── README.md
```

---

## Development Notes

- The PocketBase URL is stored in `lib/core/constants/app_constants.dart` as `pocketbaseUrl`.  
  Update this if you self-host on a different server.
- Audio files are not included — add your own `.mp3` or `.m4a` tracks to `assets/audio/`.
- The app works fully in **guest mode** without any network connection — guest data is stored locally via `shared_preferences`.
- If PocketBase is unreachable, the app degrades gracefully: sessions still complete and scores are tracked locally for guests.
