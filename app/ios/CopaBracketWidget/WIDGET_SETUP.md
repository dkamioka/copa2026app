# Home Screen widget — Xcode setup

This folder holds the source for the "Mundial 2026" Home Screen
widget (Small/Medium/Large — shows the live match or the current
round's fixtures, tapping opens the app to the bracket).

**Why this can't be wired up automatically:** creating a new Xcode
target and an App Groups entitlement both require Xcode's GUI and your
Apple Developer Team ID — neither is scriptable from outside Xcode, and
this app was built in a Linux sandbox with no Xcode available to test
against. The code below is written and internally consistent, but you
need to do the following once, on a Mac, before it'll build.

## 1. Add the widget extension target

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension.**
3. Product Name: `CopaBracketWidget`. Uncheck "Include Configuration
   Intent" (we use a static, non-configurable widget). Team/deployment
   target: match your Runner target (this widget uses
   `containerBackground(for:.widget)`, which needs **iOS 17+** as the
   extension's minimum deployment target).
4. Xcode will scaffold a `CopaBracketWidget/` group with placeholder
   files (`CopaBracketWidgetBundle.swift`, etc.) — **delete those
   placeholders** and drag the real files from this folder
   (`Models.swift`, `Provider.swift`, `CopaBracketWidget.swift`,
   `CopaBracketWidgetBundle.swift`) into the new target instead. Make
   sure each file's Target Membership is the `CopaBracketWidget`
   extension (not `Runner`).

## 2. Add the App Group (shared storage between app and widget)

The app and widget can't share Dart/Swift state directly — the Flutter
app writes a JSON snapshot to a shared `UserDefaults` suite, and the
widget reads it from there.

1. Select the **Runner** target → **Signing & Capabilities** → **+
   Capability → App Groups**. Add a group with the exact identifier
   `group.com.veogroup.worldcup2026`.
2. Select the **CopaBracketWidget** target → **Signing & Capabilities**
   → **+ Capability → App Groups**. Add the **same** group ID.
3. If you use a different bundle ID / team, you can rename the group —
   just update it consistently in all three places it's hardcoded:
   - `ios/Runner/AppDelegate.swift` → `kCopaWidgetAppGroupId`
   - `ios/CopaBracketWidget/Provider.swift` → `CopaWidgetProvider.appGroupId`
   - (the Dart side doesn't need the group ID — it only talks to
     `AppDelegate` over the method channel)

## 3. Build & test

1. Build the `Runner` scheme once (this registers the widget extension
   with the system) and run it on a device or simulator running iOS 17+.
2. Long-press the Home Screen → **+** → search "Mundial 2026" →
   add the widget in any size.
3. Open the app once so it pushes a snapshot (`HomeWidgetBridge.pushSnapshot`
   runs on every launch in `lib/main.dart`) — the widget should populate
   within a few seconds (`WidgetCenter.shared.reloadAllTimelines()` is
   called immediately after the snapshot is written).
4. Tapping the widget opens the app via the `copa2026://` URL scheme
   (already registered in `Info.plist`); since the bracket is the app's
   default first tab, no further deep-link routing was needed.

## What this widget deliberately does NOT do

Real WidgetKit widgets cannot scroll or open in-app sheets — that was
flagged to the user up front as a hard iOS platform limitation, not an
oversight. This widget shows a compact, glanceable snapshot (the live
match, or the current round's fixtures) and defers everything else —
full bracket, group tables, scorers, match detail — to a tap that opens
the full app.

## Refresh cadence

`Provider.swift` asks for a new timeline every 15 minutes
(`Timeline(..., policy: .after(...))`), which is what WidgetKit's
refresh budget realistically supports — a live match's minute will lag
behind the in-app ticker between refreshes. The snapshot is also pushed
proactively every time the app is foregrounded, so opening the app
keeps the widget close to current.
