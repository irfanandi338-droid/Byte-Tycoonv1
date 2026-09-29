# BYTE TYCOON

## Audit fix log

This codebase went through a full audit and bug-fix pass. Summary of what
changed (see git history / diff for exact lines):

- **Fixed a compile error** in `game_state.dart` (`GameState.load()` called a
  non-existent `lastTick` setter).
- **Fixed an infinite-free-computer exploit**: BASIC COMPUTER had `cost: 0`
  for every purchase (not just the first), letting the economy be broken by
  spam-buying free units. Now only the very first unit is free.
- **Fixed offline income**, which did not work for a real close-and-reopen:
  the "time away" calculation used a field that always reset on app start,
  and the field that *should* have driven it (`lastOnlineTime`) was being
  overwritten on every autosave. Both are fixed; the tick loop is now also
  stopped while the app is truly backgrounded so income can't be counted
  twice.
- **Fixed a daily-reward clock-rollback exploit**: winding the device date
  back a day no longer unlocks another claim.
- **Fixed two hardcoded-economy-in-UI spots** (network bracket table,
  quantum-point % text) that had drifted from `GameConfig`/`EconomyService`.
- **Fixed a broken unit test** (`formatHash` assertion), added a scientific-
  notation fallback so big numbers stay readable up to the `1e100` cap, and
  added `GameState`/`SaveService`-level tests (merge, prestige, daily-claim
  exploit regression, corrupt-save recovery, offline-income cold start).
- Reduced unnecessary full-tree rebuilds on every game tick, and added
  `analysis_options.yaml` so `flutter_lints` actually applies.

None of this required a network connection, a backend, or any new
dependency - the game is still, and was always meant to be, 100% offline.

Offline idle tycoon game: from 1 red BASIC COMPUTER to a GLOBAL COMPUTING EMPIRE.
**100% offline. No VPS, no server, no Firebase, no login, no HTTP requests.**
Everything runs on the phone and saves locally (SharedPreferences JSON, primary + backup).

## 1. Install Flutter

- Install Flutter SDK (stable): https://docs.flutter.dev/get-started/install
- `flutter doctor` must show Android toolchain OK.

## 2. Install Android SDK

- Install Android Studio -> SDK Manager -> Android SDK, build-tools, platform-tools.
- Accept licenses: `flutter doctor --android-licenses`

## 3. Copy project

Copy the `byte_tycoon/` folder anywhere, then enter it:

```
cd byte_tycoon
```

The repo ships `lib/`, `assets/`, `test/`, `pubspec.yaml`. Generate the Android
platform folder (standard Flutter workflow):

```
flutter create . --org com.example --project-name byte_tycoon
```

## 4. Install dependencies

```
flutter pub get
```

## 5. Run

```
flutter run
```

## 6. Build APK

```
flutter build apk --release
```

## 7. APK location

```
build/app/outputs/flutter-apk/app-release.apk
```

## 8. Change game name

- `pubspec.yaml` -> `name:` (dart package name, lowercase)
- `android/app/src/main/AndroidManifest.xml` -> `android:label="BYTE TYCOON"` (after `flutter create .`)
- Title strings in `lib/main.dart` (`MaterialApp title`, AppBar texts).

## 9. Change icon

- Easiest: `flutter pub add flutter_launcher_icons`, add a 1024x1024 PNG at
  `assets/icons/icon.png`, configure `flutter_launcher_icons` in `pubspec.yaml`, run
  `dart run flutter_launcher_icons`.
- Or replace `android/app/src/main/res/mipmap-*/ic_launcher.png` after `flutter create .`.

## 10. Change balance

Everything lives in `lib/config/game_config.dart`:
- computer tiers (cost/income/power/storage/energy/color)
- `upgradeGrowth` (1.15), `upgradeMaxLevel`
- `networkBrackets` multiplier table
- `prestigeRequirement`, `prestigePerQP`
- `offlineMaxHours` (8)
- `dailyRewards`, `research`, `achievements`

**Never hardcode numbers in widgets.** `EconomyService` is the only place with formulas.

## 11. Add a computer tier

Add one entry to `GameConfig.tiers` (name, cost, income, power, storageGB, energy, colorHex).
The buy list, network view, merge chain and painter pick it up automatically.

## 12. Add research

Add a `ResearchDef` to `GameConfig.research` with a unique `id`, `cost`, `requires`
(previous node id or null) and `incomeMult`/`powerMult`. Unlocking AI CORE upgrades
only needs the research id `ai_proc` to exist.

## 13. Add achievement

1. Add an `AchievementDef` to `GameConfig.achievements` (id, name, desc, rewards).
2. Add the condition in `GameState._achievementCondition` (a `case 'your_id':`).

## Architecture

- `lib/game_state.dart` - single source of truth (GameState). Tick loop 250ms,
  autosave every 10s + after every important action + on app pause.
- `lib/services/economy_service.dart` - EconomyManager: all formulas + big number
  formatting (K/M/B/T... and KH/s..EH/s), NaN/Infinity/negative guards, 1e100 cap.
- `lib/services/save_service.dart` - SaveManager: primary + backup save, versioned
  (`saveVersion: 1`) with migration hook; corrupt primary -> backup; both corrupt ->
  fresh start with "SAVE DATA ERROR" notice (no crash).
- `lib/services/offline_income_service.dart` - offline income, capped at 8h, popup
  after 60s away, safe against clock changes.
- Computer visuals: `CustomPainter` (`lib/widgets/computer_painter.dart`) - original
  vector art with LEDs, ports, heatsink, glow. Zero bitmap assets.

## Tests

```
flutter test
```

Covers: income calculation, upgrade cost, purchase cost, merge rule, research,
prestige, offline income (incl. 8h cap + clock rollback), daily reward, save/json
roundtrip, number safety.
