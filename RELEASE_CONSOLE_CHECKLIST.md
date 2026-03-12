# Release Checklist (Android + iOS)

## 1) Project identity
- Android application id: `com.lingufranca.app`
- iOS bundle id: `com.lingufranca.app`
- App display name: `LinguFranca`

## 0) Build environment rule (important)
- Build path must be ASCII-only (no Turkish characters like `ü`, `ş`, `ı`).
- Example good path:
  - `C:\projects\lingufranca_mobile`
- If project stays under a path like `Masaüstü`, Android release build can fail with `Unable to read ... app.dill`.

## 2) Android release signing
1. Create keystore (once):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Put keystore file under:
   - `mobile/lingufranca_mobile/android/keystore/upload-keystore.jks`
3. Create `mobile/lingufranca_mobile/android/key.properties` from `key.properties.example`.
4. Fill real passwords/alias in `key.properties`.

## 3) iOS signing
1. Open:
   - `mobile/lingufranca_mobile/ios/Runner.xcworkspace`
2. Runner > Signing & Capabilities:
   - Team: your Apple Developer Team
   - Bundle Identifier: `com.lingufranca.app`
   - Signing: Automatic

## 4) Build commands
From `mobile/lingufranca_mobile`:

- Android App Bundle:
  ```bash
  flutter clean
  flutter pub get
  flutter build appbundle --release
  ```
  Output:
  - `build/app/outputs/bundle/release/app-release.aab`

- iOS release build:
  ```bash
  flutter clean
  flutter pub get
  flutter build ios --release
  ```
  Then archive with Xcode and upload to App Store Connect.

## 5) Console upload
- Google Play Console:
  - Create app
  - Upload `.aab`
  - Fill Data safety, Privacy policy, content rating, store listing
  - Create production release

- App Store Connect:
  - Create app with bundle id `com.lingufranca.app`
  - Upload archive from Xcode
  - Fill privacy questionnaire, screenshots, metadata
  - Submit for review

## 6) Final preflight
- Verify API URL is production:
  - `lib/src/core/config/app_config.dart`
- Run in release mode on physical Android/iOS and test:
  - login/register
  - payment redirect deep-link (`lingufranca://payment`)
  - auth deep-link (`lingufranca://auth`)
  - camera/microphone flow (Zoom / live lesson)
