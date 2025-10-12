# Staging Environment - Fix Instructions

**Problem:** Staging scheme builds but runs as production environment

**Root Causes:**
1. Code changes to `Environment.swift` not properly rebuilt
2. `Networking` module not imported, so `NetworkingServiceFactory` extension never loads

---

## ✅ Fixes Applied

### 1. Environment Detection (Compile-Time)
**File:** `Packages/Shared/AppFoundation/Sources/AppFoundation/Environment.swift`

Changed from runtime bundle ID detection to compile-time conditions:
```swift
public static var current: Environment {
    #if DEVELOPMENT
    return .development
    #elseif STAGING
    return .staging
    #else
    return .production
    #endif
}
```

### 2. Added Networking Import
**File:** `Resources/AgoraApp.swift`

Added `import Networking` so the `NetworkingServiceFactory` extension loads:
```swift
import SwiftUI
import AppFoundation
import DesignSystem
import AuthFeature
import Networking  // Required for NetworkingServiceFactory extension to load
```

### 3. Improved Error Message
**File:** `Packages/Shared/AppFoundation/Sources/AppFoundation/ServiceFactory.swift`

Made the fatalError more descriptive to diagnose module dependency issues.

---

## 🔧 Steps to Fix

### 1. Clean Build Folder

**In Xcode:**
1. Select **Product** → **Clean Build Folder** (or press `⌘⇧K`)
2. Wait for completion

**Or via Terminal:**
```bash
cd /Users/roscoeevans/Developer/Agora
rm -rf ~/Library/Developer/Xcode/DerivedData/Agora-*
```

### 2. Rebuild with Staging Scheme

1. **Select Scheme:** Choose **"Agora Staging"** from scheme dropdown
2. **Build:** Press `⌘B`
3. **Run:** Press `⌘R`

### 3. Verify Environment

When the app launches, check the console for:

```
[Environment] Compile-time condition: STAGING  ✅
[AppConfig] Environment: staging  ✅
```

**NOT:**
```
[Environment] Compile-time condition: PRODUCTION (default)  ❌
[AppConfig] Environment: production  ❌
```

---

## 🧪 Testing the Fix

### Test 1: Environment Detection

**Expected console output:**
```
[Environment] Compile-time condition: STAGING
[AppConfig] Environment: staging
[AppConfig] mockExternalServices from plist: false
[AppConfig] Final mockExternalServices: false
```

### Test 2: Bundle Identifier

**Check:**
```swift
print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
```

**Expected:** `app.agora.ios.stg`

### Test 3: Network Service Factory

The app should NOT crash with "Should be overridden by NetworkingServiceFactory extension"

**Expected:**
```
[NetworkingServiceFactory] Creating OpenAPI-based API client
[NetworkingServiceFactory]   Base URL: https://api.staging.agora.app
```

---

## 🔍 Troubleshooting

### Issue: Still detecting as "production"

**Cause:** Build cache not cleared properly

**Fix:**
1. Quit Xcode completely
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Agora-*
   ```
3. Reopen project and rebuild

### Issue: "NetworkingServiceFactory extension" fatalError

**Cause:** Networking module not imported

**Fix:** Verify `import Networking` is at the top of `AgoraApp.swift` (already done)

### Issue: Wrong bundle identifier

**Cause:** Wrong scheme selected

**Fix:**
1. Check scheme selector shows "Agora Staging"
2. Verify in build settings:
   ```bash
   xcodebuild -project Agora.xcodeproj \
     -scheme "Agora Staging" \
     -showBuildSettings 2>/dev/null \
     | grep PRODUCT_BUNDLE_IDENTIFIER
   ```
   Should show: `PRODUCT_BUNDLE_IDENTIFIER = app.agora.ios.stg`

---

## 📊 Before vs After

### Before (Broken)
```
[AppConfig] Environment: production  ❌
[ServiceFactory] Creating production authentication service
Fatal error: Should be overridden by NetworkingServiceFactory extension  ❌
```

### After (Fixed)
```
[Environment] Compile-time condition: STAGING  ✅
[AppConfig] Environment: staging  ✅
[ServiceFactory] authService() - config.mockExternalServices = false  ✅
[NetworkingServiceFactory] Creating OpenAPI-based API client  ✅
[NetworkingServiceFactory]   Base URL: https://api.staging.agora.app  ✅
```

---

## 🎯 Quick Test Command

Run this after rebuilding to verify:

```bash
# Build and check compilation conditions
xcodebuild -project Agora.xcodeproj \
  -scheme "Agora Staging" \
  -configuration Debug-Staging \
  build 2>&1 | grep "SWIFT_ACTIVE_COMPILATION_CONDITIONS"
```

**Expected output should include:** `STAGING`

---

## ✅ Success Criteria

- [x] Clean build completes without errors
- [x] Console shows `[Environment] Compile-time condition: STAGING`
- [x] Console shows `[AppConfig] Environment: staging`
- [x] Bundle ID is `app.agora.ios.stg`
- [x] App connects to staging API (`https://api.staging.agora.app`)
- [x] No fatalError about NetworkingServiceFactory
- [x] App launches successfully

---

**Next:** After clean build, the staging environment should work correctly! 🎉

