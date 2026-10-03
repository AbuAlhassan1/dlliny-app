# Dlliny

The Flutter app for Dlliny: discover venues, join hangouts, share posts and memories.

## Setup

The repo ships without its private configuration. Before running the app:

1. **Environment.** Copy `.env.example` to `.env` and fill in your API base URLs and Google web client ID.
2. **Firebase.** Run `flutterfire configure` against your own Firebase project. That regenerates
   `lib/firebase_options.dart`, `firebase.json`, `android/app/google-services.json` and
   `ios/Runner/GoogleService-Info.plist`.
3. **Google Sign-In on iOS.** In `ios/Runner/Info.plist`, replace `YOUR_IOS_CLIENT_ID` with the
   reversed iOS client ID from your `GoogleService-Info.plist`.
4. **Fastlane (optional).** `ios/fastlane/Appfile` reads `APP_IDENTIFIER`, `APPLE_ID`, `ITC_TEAM_ID`
   and `TEAM_ID` from the environment.
5. **Android release signing (optional).** Provide `android/key.properties`; without it release
   builds fall back to debug signing.

Then:

```sh
flutter pub get
flutter run
```
