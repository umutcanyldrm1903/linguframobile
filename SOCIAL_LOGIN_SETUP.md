# Social Login Setup

## Backend `.env`

Set allowed OAuth client IDs on the Laravel server:

```env
MOBILE_GOOGLE_CLIENT_IDS=284981345033-ssp855uprkfrpetnn25ni3074m0ud7f3.apps.googleusercontent.com,284981345033-uhh8ltpjg2cldtg6iu7n1segitdho9j2.apps.googleusercontent.com,YOUR_GOOGLE_ANDROID_CLIENT_ID
MOBILE_APPLE_CLIENT_IDS=com.lingufranca.app
```

Google ID token audience must match one of `MOBILE_GOOGLE_CLIENT_IDS`.
Apple identity token audience must match one of `MOBILE_APPLE_CLIENT_IDS`.

## Codemagic

Add these environment variables to the Codemagic group used by the workflow:

```env
GOOGLE_WEB_CLIENT_ID=284981345033-ssp855uprkfrpetnn25ni3074m0ud7f3.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=284981345033-uhh8ltpjg2cldtg6iu7n1segitdho9j2.apps.googleusercontent.com
```

The workflow already passes them to Flutter with `--dart-define`.

## Apple Developer

For bundle id `com.lingufranca.app`, enable:

- Sign in with Apple

The iOS entitlement file is already added at `ios/Runner/Runner.entitlements`.

## Google Cloud

Create OAuth clients for:

- Web client: used as `GOOGLE_WEB_CLIENT_ID` and backend audience.
- iOS client: bundle id `com.lingufranca.app`, used as `GOOGLE_IOS_CLIENT_ID`.
- Android client if Android release is needed: package `com.lingufranca.app` and release SHA-1.

For local Chrome testing:

```bash
flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
```
