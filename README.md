# closet

A wardrobe app for iPhone, written in SwiftUI. Your clothes hang on wooden hangers along horizontal rails. You can browse each category in a photo grid, zoom into any piece, track what needs washing, and plan the day's outfit. Everything stays on the phone: there's no account, no backend, and no third-party packages.

## Features

- **Rails and grids.** Tops and bottoms hang on rails that sway when you flick them. Shoes and hats sit in their own rows. Tap a heading to see that category as a grid.
- **Photo zoom.** Pinch up to 6×, pan, double-tap, or use the toolbar zoom control (which also works with VoiceOver).
- **Laundry.** Put a piece in the laundry after wearing it, then mark pieces washed one at a time or all at once, with Undo. The basket shows how many pieces need washing.
- **Wardrobe.** Swipe the hat, top, bottom, and shoe rows independently to build an outfit, then tap **Wear this today**. The pieces you wear go into the laundry.
- **Calendar.** A week of saved outfits. Swipe between weeks.
- **Add a piece.** Take a photo or pick one from Photos. Transparent PNGs keep their transparency.
- **Settings.** System, light, or dark appearance, plus Automatic, Light, and Dark app icons.
- **iPhone Duo.** The layout adapts to every pose. See [iPhone Duo](#iphone-duo).

The app comes with a starter wardrobe of sample garment photos in `Closet/Resources/Garments`. They're imported once on first launch. Delete any of them and they stay deleted.

## Requirements

- iOS 26 or later
- Xcode 26 or later
- Xcode 27.1 or later (iOS 27.1 SDK) to build the iPhone Duo features: fold-aware splits and hinge effects. Older Xcode versions build the same app without them.

## Build and run

1. Open `Closet.xcodeproj` and select the **Closet** scheme.
2. Pick an iPhone simulator and press Run.

To run on your own iPhone, create `Config/Local.xcconfig` with your signing details. The file is git-ignored.

```
DEVELOPMENT_TEAM = ABCDE12345
CLOSET_BUNDLE_PREFIX = com.yourname
```

If you already have the app installed, keep the bundle prefix you used before. iOS stores the app's data under its bundle identifier, so a new identifier installs as a separate, empty app.

## Tests

```sh
xcodebuild -project Closet.xcodeproj -scheme Closet \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build test CODE_SIGNING_ALLOWED=NO
```

Unit tests cover:
- Photo storage and transparency
- Wash state and outfit history
- One-time starter imports
- The iPhone Duo layout math: grid columns, split position at the fold, camera insets, and keeping your place when the phone opens or closes

UI tests cover the main flows: rails, grids, photo zoom, laundry, the wardrobe, the calendar, and app icons. Physical camera capture needs a real iPhone.

## iPhone Duo

The app follows Apple's [iPhone Duo guidance](https://developer.apple.com/iphone-duo/). Layout decisions use size classes and each view's own geometry, never the device model, idiom, interface orientation, or `UIScreen`.

| Pose | Layout |
| --- | --- |
| Closed (outer display) | The phone layout, unchanged |
| Open flat (inner display) | The closet beside the selected piece, divided at the hinge, so folding doesn't move anything. Category grids add columns as they get wider. |
| Book pose (partly folded) | The closet on one side of the fold and the piece, or its zoomable photo, on the other. The Wardrobe puts the outfit on one side and today's choice on the other, so nothing sits on the crease. |
| Rotated and folded | The same panes, stacked above and below the fold |

How it works:
- **Fold position.** `FoldAwareSplit` (in `Closet/AdaptiveLayout.swift`) reads the fold with `GeometryProxy.reservedRegions(kind: .division)`. It also reads the inner camera area (`.occlusion`) so pane content stays clear of it.
- **Hinge effect.** Folding or unfolding gives the hangers a small sway through `onHingeChange`. Reduce Motion turns it off. Layout never depends on hinge data, as Apple recommends.
- **SDK guard.** The iOS 27 APIs sit behind a `CLOSET_DUO_SDK` compile flag, which `Config/Closet.xcconfig` sets only for iOS 27 SDKs, and behind `#available(iOS 27.1, *)` at runtime.
- **Opening and closing.** The piece you were looking at carries over between layouts, and so do the Wardrobe, Laundry, Calendar, Settings, and Add screens if one is open.

`Closet/DuoPreviews.swift` has SwiftUI previews for each pose. They simulate the fold, so you can check the layouts in Xcode 26, which has no Duo simulator.

## Adding garments to the starter wardrobe

1. Copy transparent PNGs into `Closet/Resources/Garments`.
2. Add an entry for each in `StarterWardrobe.swift`.
3. Regenerate the project with [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`xcodegen`).

`project.yml` is the XcodeGen source. The generated project is checked in, so you only need XcodeGen if you change the project structure.

## Web companion

`web/` is an optional Next.js site that shows the same wardrobe in a browser. Visitors can swipe the outfit carousels, browse the rails, and share a look as a link.

```sh
cd web
npm install
npm run optimize-garments
npm run dev
```

Set `NEXT_PUBLIC_SITE_URL` to your domain when you deploy, so share images get absolute links. On Vercel, the production domain is detected automatically.

## Project layout

| Path | Contents |
| --- | --- |
| `Closet/` | App source, assets, and starter garments |
| `ClosetTests/`, `ClosetUITests/` | Unit and UI tests |
| `Config/` | Shared build settings |
| `docs/` | Design notes and records of how the garment photos were prepared |
| `web/` | Optional web companion |
