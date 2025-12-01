# Secrets Configuration Setup

This document explains how to set up sensitive API keys and identifiers for local development. These files are **NOT** committed to version control for security reasons.

## Firebase Configuration (Required)

Firebase configuration files contain API keys and project identifiers. You must set these up before the app can connect to Firebase services.

### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run the configuration command:
   ```bash
   flutterfire configure
   ```

3. Select your Firebase project and platforms. This will automatically generate:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `lib/firebase_options.dart`

### Option B: Manual Download from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon → **Project settings**

**For Android:**
1. Under "Your apps", select your Android app
2. Click **Download google-services.json**
3. Place it in `android/app/google-services.json`

**For iOS:**
1. Under "Your apps", select your iOS app
2. Click **Download GoogleService-Info.plist**
3. Place it in `ios/Runner/GoogleService-Info.plist`

**For Dart:**
1. Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart`
2. Fill in the values from your Firebase Console

---

## Flutter/Dart Setup (App-level)

### 1. Create `secrets.json`

Copy the example file and fill in your actual values:

```bash
cp secrets.json.example secrets.json
```

### 2. Edit `secrets.json`

Open `secrets.json` and replace the placeholders with your actual AdMob Ad Unit IDs:

```json
{
  "admob": {
    "android": {
      "bannerAdUnitId": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    },
    "ios": {
      "bannerAdUnitId": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    }
  }
}
```

**Note:** The app will automatically fall back to test ad unit IDs if `secrets.json` is not found or fails to load, so the app will still run for development/testing.

## Android Setup

### 1. Configure `local.properties`

The file `android/local.properties` should already exist. Add the following line if not present:

```properties
admob.appId=your-admob-app-id-here
```

**Example:**
```properties
sdk.dir=/Users/yourname/Library/Android/sdk
flutter.sdk=/path/to/flutter
admob.appId=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
```

## iOS Setup

### 1. Create `Secrets.xcconfig`

Copy the example file and fill in your actual values:

```bash
cd ios/Flutter
cp Secrets.xcconfig.example Secrets.xcconfig
```

### 2. Edit `Secrets.xcconfig`

Open `ios/Flutter/Secrets.xcconfig` and replace the placeholder with your actual AdMob Application ID:

```
GAD_APPLICATION_IDENTIFIER = ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
```

## Getting Your AdMob IDs

### Application ID (for Android/iOS native config)

1. Go to [AdMob Console](https://apps.admob.com/)
2. Select your app
3. Go to **App settings**
4. Copy the **App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

### Ad Unit IDs (for Flutter app code)

1. Go to [AdMob Console](https://apps.admob.com/)
2. Select your app
3. Go to **Ad units**
4. Select your banner ad unit
5. Copy the **Ad unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`)
6. Repeat for each platform (Android/iOS) if you have separate ad units

## Security Notes

- **NEVER** commit the following files to git:
  - `secrets.json` (Flutter/Dart app-level secrets)
  - `android/local.properties` (admob.appId line)
  - `ios/Flutter/Secrets.xcconfig`
  - `firebase.json` (Firebase project configuration)
  - `android/app/google-services.json` (Firebase Android config)
  - `ios/Runner/GoogleService-Info.plist` (Firebase iOS config)
  - `lib/firebase_options.dart` (Firebase Dart options)
  
- These files are already listed in `.gitignore`
- The example files (`*.example`) are safe to commit as they contain no real credentials
- Test ad unit IDs are safe to use in development and can be in the code as fallback values

## Verification

After setup, verify that your configuration is working:

**Flutter App:**
- Run the app: `flutter run`
- Check the debug console for "AppSecrets loaded successfully"
- If secrets.json is missing, you'll see "Using test ad unit IDs as fallback"
- The app will still work with test ads even without secrets.json

**Android:**
- Build the app: `flutter build apk` or `flutter run`
- Check that no errors about missing AdMob App ID appear

**iOS:**
- Build the app: `flutter build ios` or `flutter run`
- Check that Xcode doesn't show errors about undefined variables

## Troubleshooting

### Flutter: "AppSecrets not initialized" error
- Ensure `secrets.json` exists in the project root
- Check that the JSON format is valid
- The app should fall back to test ad unit IDs if the file is missing

### Flutter: Ads not showing
- Check debug console for ad loading errors
- Verify ad unit IDs in `secrets.json` are correct
- Test ads should appear immediately; production ads may take time to serve

### Android: "AdMob App ID is missing"
- Check that `admob.appId` is defined in `android/local.properties`
- Rebuild: `flutter clean && flutter pub get && flutter run`

### iOS: "GAD_APPLICATION_IDENTIFIER is not defined"
- Verify `ios/Flutter/Secrets.xcconfig` exists and contains the correct value
- Clean the build: `flutter clean` and rebuild
- In Xcode, go to Product → Clean Build Folder

## For CI/CD

For continuous integration environments, inject these secrets as environment variables and create the files during the build process.

**Example GitHub Actions:**
```yaml
- name: Create secrets files
  run: |
    # Flutter/Dart secrets
    echo '{"admob":{"android":{"bannerAdUnitId":"${{ secrets.ADMOB_ANDROID_BANNER_ID }}","nativeAdUnitId":"${{ secrets.ADMOB_ANDROID_NATIVE_ID }}"},"ios":{"bannerAdUnitId":"${{ secrets.ADMOB_IOS_BANNER_ID }}","nativeAdUnitId":"${{ secrets.ADMOB_IOS_NATIVE_ID }}"}}}' > secrets.json
    
    # Android secrets
    echo "admob.appId=${{ secrets.ADMOB_APP_ID }}" >> android/local.properties
    
    # iOS secrets
    echo "GAD_APPLICATION_IDENTIFIER = ${{ secrets.ADMOB_APP_ID }}" > ios/Flutter/Secrets.xcconfig
    
    # Firebase configuration (base64 encoded)
    echo "${{ secrets.GOOGLE_SERVICES_JSON }}" | base64 --decode > android/app/google-services.json
    echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" | base64 --decode > ios/Runner/GoogleService-Info.plist
    echo "${{ secrets.FIREBASE_OPTIONS_DART }}" | base64 --decode > lib/firebase_options.dart
```

**Required GitHub Secrets:**
- `ADMOB_APP_ID`: Your AdMob Application ID (e.g., ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX)
- `ADMOB_ANDROID_BANNER_ID`: Android banner ad unit ID
- `ADMOB_IOS_BANNER_ID`: iOS banner ad unit ID
- `ADMOB_ANDROID_NATIVE_ID`: Android native ad unit ID
- `ADMOB_IOS_NATIVE_ID`: iOS native ad unit ID
- `GOOGLE_SERVICES_JSON`: Base64 encoded content of google-services.json
- `GOOGLE_SERVICE_INFO_PLIST`: Base64 encoded content of GoogleService-Info.plist
- `FIREBASE_OPTIONS_DART`: Base64 encoded content of firebase_options.dart

**To create base64 encoded secrets:**
```bash
# On macOS/Linux
base64 -i android/app/google-services.json | pbcopy
base64 -i ios/Runner/GoogleService-Info.plist | pbcopy
base64 -i lib/firebase_options.dart | pbcopy
```

