# Closet

A native SwiftUI iPhone app based on the supplied clothes-rail reference. Requires iOS 26 and Xcode 26 or later. No packages or backend.

Open `Closet.xcodeproj`, select the Closet scheme and an iPhone simulator, then press Run. To run on your own iPhone, select your Apple development team under Signing & Capabilities and select the connected phone.

The app includes your 12 tops and one pair of jeans as retouched transparent PNGs. The home screen has horizontal rails and wooden hangers. Tap Tops or Bottoms to browse a two-column grid. Tap a piece, then its photo, to open a full-screen viewer with pinch zoom up to 6×, panning, double-tap zoom, and a toolbar zoom control. Toolbar controls use the system's Liquid Glass appearance; the empty-rail buttons use SwiftUI's `.glass` button style. Settings supports system, light, and dark appearance. The app icon is a wooden hanger on white.

The plus button opens a photo form with the native iPhone camera, Photos picker, name, category, and initial wash status. Camera access is requested when you tap Take photo. Imports are stored locally with SwiftData and remain after relaunch. Tap a piece to see it or remove it. The included garments import once; deleting one does not restore it on the next launch. To add another prepared batch, copy the PNGs into `Closet/Resources/Garments`, add entries in `StarterWardrobe.swift`, and regenerate the project with XcodeGen. New photo imports preserve transparency but do not automatically retouch photos.

Each piece starts clean. Tap Put in laundry after wearing it, then open Laundry to mark individual pieces or the whole batch washed. Undo restores the last washed batch while the sheet is open. The last-washed date and status persist on this iPhone. Existing wardrobes migrate with their photos intact.

ChatGPT sign-in and automatic cleanup are deferred. There is no Mac companion, backend, or OpenAI API connection.

Imagegen smoothed creases and removed the original hangers. A local chroma-key pass supplied genuine alpha transparency after imagegen exported opaque backgrounds. Original photos remain untouched. Missing sleeve cuffs and jean hems in cropped source photos were conservatively completed.

## Build and test

```sh
xcodebuild -project Closet.xcodeproj -scheme Closet \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build test CODE_SIGNING_ALLOWED=NO
```

Flicking a rail makes the clothes swing from their hanger hooks. The spring response follows scroll velocity, varies slightly between hangers, and settles after scrolling. Reduce Motion disables the sway.

Tests cover saved photos and wash-state persistence, image resizing and transparency, empty-state navigation, add-sheet cancellation, appearance persistence, one-time wardrobe import, adding the new sweatshirt without changing existing laundry, opening included tops and jeans, grid layout and photo zoom gestures, opening a piece after flicking its rail, individual and batch washing with Undo, and camera-permission recovery. Physical camera capture requires an iPhone.

`project.yml` is the XcodeGen source. The generated Xcode project is included, so XcodeGen is only needed if you change the project structure.
