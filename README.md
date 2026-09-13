# closet

A native SwiftUI iPhone app based on the supplied clothes-rail reference. Requires iOS 26 and Xcode 26 or later. No packages or backend.

Friends can use the same wardrobe on the web at [closet.enci.dev](https://closet.enci.dev). The site lives in `web/`: swipe the tops, bottoms, and shoes carousels, browse the rails, and send a look with a shareable link.

```sh
cd web
npm install
npm run optimize-garments
npm run dev
```

Open `Closet.xcodeproj`, select the Closet scheme and an iPhone simulator, then press Run. To run on your own iPhone, select your Apple development team under Signing & Capabilities and select the connected phone.

The app includes your 17 tops, six bottoms, and two pairs of shoes as retouched transparent PNGs. The home screen has horizontal rails and wooden hangers. Tap Tops or Bottoms to browse a two-column grid. Tap a piece, then its photo, to open a full-screen viewer with pinch zoom up to 6×, panning, double-tap zoom, and a toolbar zoom control. Toolbar controls use the system's Liquid Glass appearance; the empty-rail buttons use SwiftUI's `.glass` button style. Settings supports system, light, and dark appearance. Settings also offers Automatic, Light, and Dark app icons. Light uses the wooden hanger on white; Dark uses a white hanger on a charcoal-to-black gradient. Automatic follows the iPhone icon appearance. The selection is saved by iOS and survives relaunch.

The plus button opens a photo form with the native iPhone camera, Photos picker, name, category, and initial wash status. Camera access is requested when you tap Take photo. Imports are stored locally with SwiftData and remain after relaunch. Tap a piece to see it or remove it. The included garments import once; deleting one does not restore it on the next launch. To add another prepared batch, copy the PNGs into `Closet/Resources/Garments`, add entries in `StarterWardrobe.swift`, and regenerate the project with XcodeGen. New photo imports preserve transparency but do not automatically retouch photos.

Clothing starts clean. Shoes have no wash status or laundry controls and are excluded from Laundry. Tap Put in laundry after wearing it, then open Laundry to mark individual pieces or the whole batch washed. Undo restores the last washed batch while the sheet is open. The last-washed date and status persist on this iPhone. Existing wardrobes migrate with their photos intact.

Wardrobe, beside Laundry in the bottom toolbar, opens an outfit preview. Swipe tops, bottoms, and shoes independently, or tap a neighboring piece to center it. The center garment grows while its neighbors shrink, with the shirt hem and pants waist close together. This view displays only the item photos, without rails, hangers, or visible names. Shoes sit beneath the pants. The main closet has a separate Shoes row with photo details and a category grid.

The centered shirt and pants show when you last wore them, or "Haven't worn yet." Tap "Wear this today" to save the centered shirt, pants, and shoes. The button becomes "Update today" and replaces that day's outfit when tapped again. Reopening Wardrobe restores today's selections. Calendar in the bottom toolbar shows a week of daily outfit photos; swipe left or right to change weeks, or tap Today to return. Outfit history persists locally and keeps photo snapshots even after a piece is removed. Saving or updating an outfit puts its shirt and pants in Laundry. Shoes stay out of Laundry. The basket icon shows a red count badge while pieces need washing; washing pieces updates the badge, and it disappears when the basket is empty.

ChatGPT sign-in and automatic cleanup are deferred. There is no Mac companion, backend, or OpenAI API connection.

Imagegen smoothed creases and removed the original hangers. A local chroma-key pass supplied genuine alpha transparency after imagegen exported opaque backgrounds. Original photos remain untouched. Missing sleeve cuffs and jean hems in cropped source photos were conservatively completed.

## Build and test

```sh
xcodebuild -project Closet.xcodeproj -scheme Closet \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build test CODE_SIGNING_ALLOWED=NO
```

Flicking a rail makes the clothes sway up to 8° from their hanger hooks. The spring follows scroll velocity and settles without overshooting, including after repeated direction changes. Only rotation is animated, so clothing photos retain their layout as they enter the rail. Reduce Motion disables the sway.

Tests cover saved photos and wash-state persistence, image resizing and transparency, empty-state navigation, add-sheet cancellation, appearance persistence, one-time wardrobe import, adding the new sweatshirt without changing existing laundry, opening included tops and jeans, grid layout and photo zoom gestures, opening a piece after flicking its rail, individual and batch washing with Undo, and camera-permission recovery. Physical camera capture requires an iPhone.

`project.yml` is the XcodeGen source. The generated Xcode project is included, so XcodeGen is only needed if you change the project structure.
