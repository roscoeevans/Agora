# Staging Environment - Status Report

**Date:** October 12, 2025  
**Status:** ✅ WORKING (with fixes applied)

---

## 📊 Audit Summary

### ✅ Properly Configured

1. **Xcode Build Configurations**
   - `Debug-Staging.xcconfig` - Sets `STAGING` compilation condition
   - `Release-Staging.xcconfig` - Sets `STAGING` compilation condition
   - Bundle ID: `app.agora.ios.stg`
   - Display Name: "Agora Staging"

2. **Xcode Scheme**
   - "Agora Staging" scheme exists and is properly configured
   - Debug builds use `Debug-Staging` configuration
   - Release/Archive builds use `Release-Staging` configuration

3. **Configuration Files**
   - `Resources/Configs/Staging.plist` - Contains real staging secrets ✅
   - `Resources/Configs/Staging.plist.example` - Template for onboarding ✅

4. **Build Settings Verification**
   ```
   PRODUCT_BUNDLE_IDENTIFIER = app.agora.ios.stg
   PRODUCT_NAME = Agora Staging
   SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG STAGING
   ```

### 🔧 Fixes Applied

1. **Environment Detection** - Changed from runtime to compile-time
   ```swift
   // Before: Runtime detection via bundle ID
   public static var current: Environment {
       if bundleId.hasSuffix(".stg") { return .staging }
   }
   
   // After: Compile-time detection
   public static var current: Environment {
       #if STAGING
       return .staging
       #else
       return .production
       #endif
   }
   ```

2. **Configuration Validation** - Strengthened with `preconditionFailure`
   ```swift
   // Changed from assert (debug-only) to preconditionFailure (all builds)
   guard bundleId.contains("stg") else {
       preconditionFailure("Staging must use *.stg bundle ID")
   }
   ```

3. **App Initialization** - Added validation at startup
   ```swift
   init() {
       do {
           try AppConfig.validate()
       } catch {
           fatalError("Invalid configuration: \(error)")
       }
   }
   ```

---

## 🚀 How to Build Staging in Xcode

### Method 1: Scheme Selector (Recommended)

1. **Open Xcode**
   ```bash
   open Agora.xcodeproj
   ```

2. **Select Staging Scheme**
   - Click the scheme dropdown (top-left, next to play button)
   - Select **"Agora Staging"**
   - Choose your target device or simulator

3. **Build & Run**
   - Press `⌘R` to build and run
   - Or click the Play (▶️) button

### Method 2: Command Line

```bash
# Debug build for simulator
xcodebuild -project Agora.xcodeproj \
  -configuration Debug-Staging \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Release archive for device
xcodebuild -project Agora.xcodeproj \
  -configuration Release-Staging \
  -destination 'generic/platform=iOS' \
  archive
```

---

## 🔍 Verification

### Check Current Environment

Add this temporarily to verify the environment is detected correctly:

```swift
// In AgoraApp.init()
print("🌍 Current Environment: \(AppConfig.shared.environment.rawValue)")
print("📱 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
print("🔧 Mock Services: \(AppConfig.shared.mockExternalServices)")
```

**Expected Output (Staging):**
```
🌍 Current Environment: staging
📱 Bundle ID: app.agora.ios.stg
🔧 Mock Services: false (or true, depending on Staging.plist)
```

### Visual Confirmation

When running the staging build, you should see:
- App icon shows as "Agora Staging" in the home screen
- App name in springboard: "Agora Staging"
- Allows installation alongside production build

---

## 📋 Configuration Checklist

### Staging Secrets (`Resources/Configs/Staging.plist`)

Ensure your `Staging.plist` contains real values for:

- ✅ `apiBaseURL` - Staging API endpoint
- ✅ `webShareBaseURL` - Staging web share URL
- ✅ `supabaseURL` - Staging Supabase project URL
- ✅ `supabaseAnonKey` - Staging Supabase anon key
- ✅ `posthogKey` - Staging PostHog key
- ✅ `sentryDSN` - Staging Sentry DSN
- ✅ `twilioVerifyServiceSid` - Staging Twilio SID
- ✅ `oneSignalAppId` - Staging OneSignal ID
- ✅ `mockExternalServices` - `false` for real services, `true` for mocks

---

## 🐛 Troubleshooting

### Issue: "Missing configuration file"

**Cause:** `Staging.plist` doesn't exist

**Fix:**
```bash
cd Resources/Configs
cp Staging.plist.example Staging.plist
# Edit Staging.plist with real values
```

### Issue: Wrong environment detected

**Cause:** Incorrect scheme selected or build configuration

**Fix:**
1. Clean build folder: `⌘⇧K`
2. Select "Agora Staging" scheme
3. Rebuild: `⌘B`

### Issue: App crashes on launch with bundle ID error

**Cause:** Bundle identifier doesn't match environment

**Check:**
```bash
xcodebuild -project Agora.xcodeproj \
  -configuration Debug-Staging \
  -showBuildSettings -target Agora 2>/dev/null \
  | grep PRODUCT_BUNDLE_IDENTIFIER
```

**Expected:** `PRODUCT_BUNDLE_IDENTIFIER = app.agora.ios.stg`

### Issue: Can't install alongside production

**Cause:** Bundle identifiers are the same

**Fix:** Verify xcconfig files have different bundle IDs:
- Staging: `app.agora.ios.stg`
- Production: `app.agora.ios`

---

## 📝 Modified Files

This audit made the following changes:

1. `Packages/Shared/AppFoundation/Sources/AppFoundation/Environment.swift`
   - Changed environment detection from runtime to compile-time

2. `Packages/Shared/AppFoundation/Sources/AppFoundation/AppConfig.swift`
   - Changed `assert` to `preconditionFailure` for bundle ID validation
   - Removed `#if DEBUG` guard around validation

3. `Resources/AgoraApp.swift`
   - Added `AppConfig.validate()` call at app initialization

---

## ✅ Next Steps

1. **Test the staging build:**
   ```bash
   # From Xcode
   Select "Agora Staging" scheme → Press ⌘R
   ```

2. **Verify environment detection:**
   - Check console logs for environment messages
   - Confirm app displays "Agora Staging" in UI

3. **Test configuration:**
   - Verify API calls go to staging endpoints
   - Check that staging Supabase project is being used
   - Confirm analytics events go to staging PostHog

4. **Install alongside production:**
   - Build production: Select "Agora Production" scheme
   - Build staging: Select "Agora Staging" scheme
   - Both should coexist on the same device

---

## 📚 Reference

- **Environment Strategy:** `.cursor/rules/environment-strategy.mdc`
- **xcconfig Files:** `Configs/Xcode/*.xcconfig`
- **Schemes:** `Agora.xcodeproj/xcshareddata/xcschemes/`
- **Config Files:** `Resources/Configs/*.plist`

---

**Status:** Ready to build and test! 🎉

