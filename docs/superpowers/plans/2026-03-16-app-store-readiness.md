# App Store Readiness (Free-Only) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all blockers preventing App Store submission for a free-only version of the Pyramid iOS app.

**Architecture:** Add a compile-time `PAID_FEATURES_ENABLED` flag (defaulting to `false` in Release). Client-side: hide wallet UI and paid-league entry points behind this flag. Server-side: the existing `fetchOpenLeagues()` already filters to `type == "free"` — no server changes needed in this plan. Also: fix hardcoded credentials, add PrivacyInfo.xcprivacy, add push notification entitlements, and remove internal references from user-facing text.

**Tech Stack:** Swift, SwiftUI, Xcode build configuration (.xcconfig), Apple Privacy Manifest

---

## Chunk 1: Credentials, Entitlements & Privacy Manifest

These are infrastructure fixes with no code dependencies between them.

### Task 1: Remove hardcoded Supabase credentials from source code

**Files:**
- Modify: `ios/Pyramid/Sources/Shared/SupabaseDependency.swift`

The `.xcconfig` files already inject `SUPABASE_URL` and `SUPABASE_ANON_KEY` into Info.plist. The source code should read from Info.plist instead of hardcoding values.

**Note:** `Test.xcconfig` is NOT wired to any build configuration in `project.pbxproj` — the test target uses the Debug configuration, which reads from `Debug.xcconfig`. So the test target will get the Debug credentials, which is correct.

- [ ] **Step 1: Rewrite SupabaseDependency to read from Info.plist**

Replace the `#if DEBUG` / `#else` block (lines 26-34) with Info.plist lookup:

```swift
// swiftlint:disable line_length
private static let supabaseURL: String = {
    guard let value = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
          !value.isEmpty else {
        fatalError("SUPABASE_URL not set in Info.plist — check your .xcconfig")
    }
    return "https://\(value)"
}()

private static let supabaseAnonKey: String = {
    guard let value = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
          !value.isEmpty else {
        fatalError("SUPABASE_ANON_KEY not set in Info.plist — check your .xcconfig")
    }
    return value
}()
// swiftlint:enable line_length
```

Remove the entire `#if DEBUG` ... `#else` ... `#endif` block and replace with the above.

- [ ] **Step 2: Verify the app builds**

Run: `cd /home/user/Pyramid/ios && xcodebuild -scheme Pyramid -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Shared/SupabaseDependency.swift
git commit -m "fix: read Supabase credentials from Info.plist instead of hardcoding"
```

---

### Task 2: Add push notification entitlements

**Files:**
- Modify: `ios/Pyramid/Resources/Pyramid.entitlements`

The app implements `NotificationService` with APNs token registration, but the entitlements file lacks the `aps-environment` key.

**Note on `production` vs `development`:** Using `production` is correct for App Store submission. Since iOS 13+, the `production` entitlement works with both development and distribution provisioning profiles. Debug builds on device will still deliver push notifications correctly as long as the provisioning profile includes APS capability.

- [ ] **Step 1: Add aps-environment to entitlements**

Add to the `<dict>` in `Pyramid.entitlements`, after the existing `com.apple.developer.applesignin` entry:

```xml
    <key>aps-environment</key>
    <string>production</string>
```

The full file should be:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
    <key>aps-environment</key>
    <string>production</string>
</dict>
</plist>
```

- [ ] **Step 2: Commit**

```bash
git add ios/Pyramid/Resources/Pyramid.entitlements
git commit -m "fix: add push notification entitlement (aps-environment)"
```

---

### Task 3: Create PrivacyInfo.xcprivacy manifest

**Files:**
- Create: `ios/Pyramid/Resources/PrivacyInfo.xcprivacy`

Apple requires this manifest for iOS 17+ submissions. The app uses: UserDefaults (for auth storage), networking (Supabase API), and push notifications.

- [ ] **Step 1: Create the privacy manifest file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

Reason code `CA92.1` = "Access info from same app, per documentation."

**Note on third-party SDK manifests:** The Supabase Swift SDK (v2.x) bundles its own `PrivacyInfo.xcprivacy`. Verify during build that no App Store Connect warnings appear about missing SDK manifests. If they do, update the Supabase package to the latest version.

- [ ] **Step 2: Add the file to the Xcode project**

The file **must** be added to the Pyramid target's "Copy Bundle Resources" build phase in `project.pbxproj`. Without this, the file sits on disk but is NOT included in the `.ipa`, and App Store will still flag the missing manifest.

Search for the existing resource file references in `Pyramid.xcodeproj/project.pbxproj` (e.g., `Info.plist`, `Assets.xcassets`), then add `PrivacyInfo.xcprivacy` using the same pattern: add a PBXFileReference, add it to the Resources PBXGroup, and add a PBXBuildFile entry in the "Copy Bundle Resources" build phase.

- [ ] **Step 3: Verify build succeeds**

Run: `cd /home/user/Pyramid/ios && xcodebuild -scheme Pyramid -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Resources/PrivacyInfo.xcprivacy ios/Pyramid.xcodeproj/project.pbxproj
git commit -m "feat: add PrivacyInfo.xcprivacy for App Store submission"
```

---

## Chunk 2: Feature Flag & Paid Feature Gating

### Task 4: Add PAID_FEATURES_ENABLED build flag

**Files:**
- Modify: `ios/Config/Debug.xcconfig`
- Modify: `ios/Config/Release.xcconfig`
- Modify: `ios/Config/Test.xcconfig`
- Create: `ios/Pyramid/Sources/Shared/FeatureFlags.swift`

We use a compile-time Swift flag via xcconfig `OTHER_SWIFT_FLAGS`. In Debug, paid features are enabled for development. In Release, they're disabled for App Store. When paid features are ready post-GATE, flip the Release flag.

**Note:** `Test.xcconfig` is not wired to any build configuration in `project.pbxproj`. The test target uses the Debug configuration. We still add the flag to `Test.xcconfig` for documentation purposes, but it has no effect — tests use Debug's flags.

- [ ] **Step 1: Add flag to xcconfig files**

Append to `ios/Config/Debug.xcconfig`:
```
PAID_FEATURES_ENABLED = YES
OTHER_SWIFT_FLAGS = $(inherited) -DPAID_FEATURES_ENABLED
```

Append to `ios/Config/Release.xcconfig`:
```
PAID_FEATURES_ENABLED = NO
// Paid features disabled for free-only App Store launch.
// To enable: add -DPAID_FEATURES_ENABLED to OTHER_SWIFT_FLAGS
OTHER_SWIFT_FLAGS = $(inherited)
```

Append to `ios/Config/Test.xcconfig`:
```
PAID_FEATURES_ENABLED = NO
OTHER_SWIFT_FLAGS = $(inherited)
```

- [ ] **Step 2: Create FeatureFlags.swift convenience enum**

```swift
import Foundation

/// Compile-time feature flags.
/// Controlled via OTHER_SWIFT_FLAGS in .xcconfig files.
enum FeatureFlags {
    /// Whether paid leagues, wallet, and financial features are enabled.
    /// Controlled by -DPAID_FEATURES_ENABLED in OTHER_SWIFT_FLAGS.
    static var paidFeaturesEnabled: Bool {
        #if PAID_FEATURES_ENABLED
        return true
        #else
        return false
        #endif
    }
}
```

- [ ] **Step 3: Verify build succeeds in both Debug and Release**

Run: `cd /home/user/Pyramid/ios && xcodebuild -scheme Pyramid -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ios/Config/Debug.xcconfig ios/Config/Release.xcconfig ios/Config/Test.xcconfig ios/Pyramid/Sources/Shared/FeatureFlags.swift
git commit -m "feat: add PAID_FEATURES_ENABLED compile-time feature flag"
```

---

### Task 5: Gate wallet deep link routing

**Files:**
- Modify: `ios/Pyramid/Sources/App/MainTabView.swift`

The deep link handler routes `.wallet` notifications to the profile tab. When paid features are disabled, wallet deep links should be silently ignored (no-op — intentionally does not navigate anywhere).

**Why only the deep link needs gating:** `WalletView` and `JoinPaidLeagueView` are currently UI-orphaned — no navigation path in the app leads to them. There is no Wallet tab in `MainTabView`, `ProfileView` does not link to WalletView, and `LeaguesView`/`BrowseLeaguesView` only show free leagues. The only way to reach wallet functionality is via a `.wallet` push notification deep link.

**IMPORTANT for future work:** If any navigation link to `WalletView`, `JoinPaidLeagueView`, or paid league browsing is added in the future, it MUST be wrapped in `#if PAID_FEATURES_ENABLED` or check `FeatureFlags.paidFeaturesEnabled` at the call site.

- [ ] **Step 1: Guard the wallet deep link**

In `MainTabView.swift`, change the `.onReceive` handler (lines 32-39):

```swift
.onReceive(NotificationCenter.default.publisher(for: .navigateToScreen)) { notification in
    guard let screen = notification.object as? String else { return }
    switch DeepLinkScreen(rawValue: screen) {
    case .picks, .standings:
        selectedTab = .leagues
    case .wallet:
        if FeatureFlags.paidFeaturesEnabled {
            selectedTab = .profile
        }
    case .none:
        selectedTab = .profile
    }
}
```

- [ ] **Step 2: Verify build**

Run: `cd /home/user/Pyramid/ios && xcodebuild -scheme Pyramid -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/App/MainTabView.swift
git commit -m "fix: gate wallet deep link behind paid features flag"
```

---

### Task 6: Remove internal references from user-facing text

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Wallet/WalletView+Sheets.swift`

The TopUpSheet contains a user-visible banner that references "PYR-25" (an internal GATE decision identifier). This must not ship to App Store.

- [ ] **Step 1: Replace the GATE banner with a generic message**

In `WalletView+Sheets.swift`, replace lines 43-54 (the `HStack` containing the PYR-25 reference):

```swift
                    // Stripe GATE banner
                    HStack(spacing: 8) {
                        Image(systemName: Theme.Icon.Status.info)
                            .foregroundStyle(warningYellow)
                        Text("Payment processing coming soon")
                            .font(.caption)
                            .foregroundStyle(warningYellow)
                    }
                    .padding(12)
                    .background(warningYellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
```

The only change is removing `" — Stripe integration pending (PYR-25)"` from the Text string.

- [ ] **Step 2: Remove TODO comment on line 118**

Change:
```swift
                        // TODO: PYR-25 GATE — wire up Stripe PaymentSheet here
```
To:
```swift
                        // Stripe payment integration pending GATE decision
```

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Wallet/WalletView+Sheets.swift
git commit -m "fix: remove internal GATE reference from user-facing text"
```

---

### Task 7: Clean up TODO in WalletService

**Files:**
- Modify: `ios/Pyramid/Sources/Services/WalletService.swift`

- [ ] **Step 1: Read the file to find the TODO**

Read `ios/Pyramid/Sources/Services/WalletService.swift` around line 93.

- [ ] **Step 2: Replace the TODO comment**

Change:
```swift
// TODO: PYR-25 GATE — Stripe PaymentSheet integration is pending.
```
To:
```swift
// Stripe PaymentSheet integration pending GATE decision
```

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Services/WalletService.swift
git commit -m "fix: remove internal ticket reference from TODO comment"
```

---

## Chunk 3: Final Verification & Push

### Task 8: Full build verification

- [ ] **Step 1: Run full build**

```bash
cd /home/user/Pyramid/ios && xcodebuild -scheme Pyramid -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Run tests**

```bash
cd /home/user/Pyramid/ios && xcodebuild -scheme Pyramid -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -30
```
Expected: All tests pass.

- [ ] **Step 3: Push branch**

```bash
git push -u origin claude/next-best-action-ErNi3
```

---

## Out of Scope (Noted for Future)

These items were identified in the audit but are NOT addressed in this plan:

1. **App icon images** — Requires design assets (1024x1024 PNG). Cannot be generated in code. Design team deliverable.
2. **Server-side paid league filtering** — `LeagueService.fetchOpenLeagues()` already filters `type == "free"`. The user's own joined paid leagues may still appear in their leagues list via `fetchMyLeagues()` — this is acceptable since they joined them. For full server-side gating, a backend task should filter paid leagues from the `fetchMyLeagues` response too.
3. **Stripe integration** — Blocked by GATE PYR-25.
4. **AuthViewModel #if DEBUG block** — Reviewed; contains acceptable test-only code behind conditional compilation.
