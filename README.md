# MacAutoBackground

Auto-change macOS desktop wallpaper on a schedule and on wake. Supports multiple displays, fetches high‑quality online images, and avoids duplicates using content hashes. Built with Swift + SwiftUI, targeting macOS 12+.

## Features
- Automatic wallpaper rotation by interval (minutes)
- Change wallpaper after wake/lid open
- Multiple displays supported (sets each screen)
- Online HD image source (Picsum) with SHA256 de‑duplication
- Simple settings UI with persistence
- Dock icon while running; vector‑drawn app icon
- Standard AppIcon.appiconset and AppIcon.icns included
- Optional menu bar icon (toggleable)
- Launch at login (macOS 13+)

## Requirements
- macOS 12 or later
- Xcode 15 or later
- Network access to download images

## Project Structure
- App entry and UI: [MacAutoBackgroundApp.swift](Sources/MacAutoBackground/MacAutoBackgroundApp.swift), [ContentView.swift](Sources/MacAutoBackground/ContentView.swift)
- Engine and scheduling: [Scheduler.swift](Sources/MacAutoBackground/Scheduler.swift)
- Wallpaper operations: [WallpaperChanger.swift](Sources/MacAutoBackground/WallpaperChanger.swift)
- Settings and persistence: [Settings.swift](Sources/MacAutoBackground/Settings.swift), [HistoryStore.swift](Sources/MacAutoBackground/HistoryStore.swift)
- Image provider: [ImageProvider.swift](Sources/MacAutoBackground/ImageProvider.swift)
- Runtime vector icon: [IconGenerator.swift](Sources/MacAutoBackground/IconGenerator.swift)
- Xcode project: [MacAutoBackground.xcodeproj](MacAutoBackground.xcodeproj)
- App icons: AppIcon.appiconset (PNG) and AppIcon.icns

## Getting Started

### Run with Xcode (Recommended)
1. Open the project:
   - Double‑click `MacAutoBackground.xcodeproj`, or
   - File → Open… → select the repository root
2. Select the scheme “MacAutoBackground”, destination “My Mac”
3. Optional: Set your Team and a unique Bundle Identifier for signing
4. Run (Cmd+R)

### Swift Package (SPM)
- Open `Package.swift` with Xcode and run, or
- From terminal:
  - `swift run`

Note: On some restricted environments, `swift build` may require Xcode toolchain/SDK permissions. Running via Xcode is the smoothest path.

## App Icon
- Asset catalog: `Sources/MacAutoBackground/Resources/Assets.xcassets/AppIcon.appiconset`
- ICNS: `Sources/MacAutoBackground/Resources/AppIcon.icns`
- Info configuration: [Xcode/Info.plist](Xcode/Info.plist)
  - `CFBundleIconName = AppIcon`
  - `CFBundleIconFile = AppIcon.icns`

### Regenerate App Icons
Use the provided script to regenerate all PNGs and the `.icns` file from the same vector design:

```bash
cd <repo-root>
xcrun swift Scripts/generate_appicon.swift
```

This updates:
- `Assets.xcassets/AppIcon.appiconset` (all required sizes)
- `Resources/AppIcon.icns`

## Settings Overview
- Interval (minutes): change frequency
- Change after wake: rotate wallpaper when macOS wakes or lid opens
- Avoid duplicates: content‑hash based history
- Image source: Picsum random HD (no API key)
- “Change Now” button to force an immediate update
- Show menu bar icon: keep a status item in the menu bar
- Launch at login: auto‑start the app after user login (macOS 13+)

## Release Build & Packaging
- One‑click release script:

```bash
cd <repo-root>
./scripts/release.sh                # uses MARKETING_VERSION or defaults to 1.0.0
./scripts/release.sh 1.0.2          # explicitly set version
```

- Outputs:
  - `dist/MacAutoBackground_v<version>.zip`
  - `dist/MacAutoBackground_v<version>.dmg`
- Requirements:
  - Xcode 15+, macOS 12+
- Gatekeeper:
  - Unsigned builds are for internal testing. If blocked, right‑click the app → Open → Open.

## Recent Changes
- Menu bar residency:
  - [StatusItemManager.swift](Sources/MacAutoBackground/StatusItemManager.swift)
- Login item (launch at login):
  - [LaunchAtLogin.swift](Sources/MacAutoBackground/LaunchAtLogin.swift)
- Application Support storage helpers:
  - [ImagesDirectory.swift](Sources/MacAutoBackground/ImagesDirectory.swift)
  - [CacheManager.swift](Sources/MacAutoBackground/CacheManager.swift)
- One‑click release:
  - [scripts/release.sh](scripts/release.sh)

## Implementation Notes
- Concurrency: AppKit types (e.g., `NSScreen`) remain on the main actor; only primitive values cross `await` boundaries to satisfy Swift 6 concurrency checks.
- De‑duplication: SHA256 of downloaded image data; rolling history persisted under Application Support.
- Multi‑display: iterates `NSScreen.screens` and applies per screen.

## Troubleshooting
- Icon size warnings in Xcode: regenerate icons using the script above; images are exported at exact pixel sizes for each slot.
- No wallpaper change on wake: ensure the toggle is enabled in the app and the app is running; verify system sleep/wake events are delivered.
- Network failures: check connectivity; Picsum is used without an API key and may throttle; try again or switch networks.

## Roadmap
- Additional providers (e.g., Bing, Unsplash) with optional keys
- Per‑display provider/strategy and history browsing

## License
Choose a license before publishing (e.g., MIT). Add a `LICENSE` file at the repository root.
