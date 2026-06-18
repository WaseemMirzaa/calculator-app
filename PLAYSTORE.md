# Play Store beta delivery

This repo ships a complete CI/CD pipeline that builds a **signed Android App
Bundle** and uploads it — together with the **store listing and screenshots** —
to a Google Play track using [Fastlane](https://docs.fastlane.tools/).

- Workflow: [`.github/workflows/playstore-beta.yml`](.github/workflows/playstore-beta.yml)
- Fastlane: [`android/fastlane/`](android/fastlane/) (`Fastfile`, `Appfile`)
- Listing + assets: [`android/fastlane/metadata/android/en-US/`](android/fastlane/metadata/android/en-US/)
  - `title.txt`, `short_description.txt`, `full_description.txt`
  - `changelogs/default.txt`
  - `images/icon.png` (512²), `images/featureGraphic.png` (1024×500)
  - `images/phoneScreenshots/` (1080×2160 ×4)

## One‑time setup

### 1. Create the app + first manual upload
Google Play's API **cannot create** an app or accept the very first binary.
In the Play Console, create the app `com.goldengrain.golden_grain_calculator`
and upload one AAB manually (any track). After that, CI can take over.

### 2. Create an upload keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
# then base64-encode it for the GitHub secret:
base64 -w0 upload-keystore.jks > upload-keystore.jks.base64
```
Keep `upload-keystore.jks` safe and out of git (it already is — `*.jks` is
gitignored). For local release builds, create `android/key.properties`:
```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=••••
keyAlias=upload
keyPassword=••••
```
(When `android/key.properties` is absent, the app falls back to debug signing so
`flutter run --release` still works.)

### 3. Create a Google Play service account
1. In Google Play Console → **Users & permissions → API access**, link a Google
   Cloud project and create a **service account**.
2. In Google Cloud Console, create a **JSON key** for that service account.
3. Back in the Play Console, grant the service account **Release** permissions
   (Releases → manage testing tracks, edit store listing).

### 4. Add GitHub repository secrets
`Settings → Secrets and variables → Actions`:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | contents of `upload-keystore.jks.base64` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore store password |
| `ANDROID_KEY_ALIAS` | `upload` (or your alias) |
| `ANDROID_KEY_PASSWORD` | key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | the full service‑account JSON |

## Running it

- **Manually:** Actions → **Play Store (beta)** → *Run workflow* → pick a track
  (`internal` / `alpha` / `beta` / `production`) and status (`completed` / `draft`).
- **By tag:** `git tag beta-v1.0.0 && git push origin beta-v1.0.0`.

The workflow bumps the `versionCode` automatically using the run number
(`--build-number`), so each upload is unique and increasing.

> First automated run failing on the `beta` track? Use the `internal` track (or
> `status: draft`) until the app has cleared its first review.

## Local Fastlane (optional)
```bash
cd android
bundle install
export PLAY_SERVICE_ACCOUNT_JSON_PATH=/abs/path/play-service-account.json
flutter build appbundle --release        # from repo root
bundle exec fastlane beta track:internal # upload AAB + listing
bundle exec fastlane validate            # dry-run, uploads nothing
bundle exec fastlane metadata            # listing/screenshots only
```

## Regenerating screenshots & the feature graphic
The Play assets are produced from the app itself (so they always match the UI):
```bash
flutter test --run-skipped --tags screenshots --update-goldens test/screenshots_test.dart
```
This renders the free/premium calculators, the drawer and the upgrade screen at
1080×2160 plus the 1024×500 feature graphic into the fastlane `images/` folder.
The generator loads real fonts from the Flutter SDK; on a packaged SDK (no
engine sources) point the font paths in `test/screenshots_test.dart` at a
Roboto `.ttf` you provide.
