#if DEBUG
import SwiftUI
import SwiftData

// Previews for each iPhone Duo pose. Xcode 26 has no Duo simulator, so the fold is simulated with
// `simulatedDivisions`; on an iOS 27.1 SDK build the real reserved regions replace it.
//
// The sizes are placeholders: Apple's Duo pages don't list point sizes. Replace them with the
// values from the Xcode 27.1 iPhone Duo simulator.
enum DuoPreviewSize {
    static let outer = CGSize(width: 390, height: 844)
    static let inner = CGSize(width: 820, height: 980)
    static let foldWidth: CGFloat = 16

    /// Book pose: a vertical crease down the middle of the inner display.
    static var bookFold: [CGRect] {
        [CGRect(x: inner.width / 2 - foldWidth / 2, y: 0, width: foldWidth, height: inner.height)]
    }

    /// Open flat: the hinge is still there, just inactive and zero-width.
    static var flatHinge: [CGRect] {
        [CGRect(x: inner.width / 2, y: 0, width: 0, height: inner.height)]
    }

    /// Rotated and partly folded: the crease runs across the display.
    static var rotatedFold: [CGRect] {
        [CGRect(x: 0, y: inner.width / 2 - foldWidth / 2, width: inner.height, height: foldWidth)]
    }
}

@MainActor
enum PreviewCloset {
    static func container() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: ClothingItem.self, ImportedGarment.self, DailyOutfit.self, WornPiece.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            try StarterWardrobe.importMissing(into: container.mainContext)
            return container
        } catch {
            fatalError("Couldn't build the preview closet: \(error)")
        }
    }
}

#Preview("Duo closed · outer display", traits: .fixedLayout(width: 390, height: 844)) {
    ClosetView()
        .environment(\.horizontalSizeClass, .compact)
        .modelContainer(PreviewCloset.container())
}

#Preview("Duo open flat · inner display", traits: .fixedLayout(width: 820, height: 980)) {
    ClosetView()
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.simulatedDivisions, DuoPreviewSize.flatHinge)
        .modelContainer(PreviewCloset.container())
}

#Preview("Duo book pose · split at the fold", traits: .fixedLayout(width: 820, height: 980)) {
    ClosetView()
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.simulatedDivisions, DuoPreviewSize.bookFold)
        .modelContainer(PreviewCloset.container())
}

#Preview("Duo rotated and folded", traits: .fixedLayout(width: 980, height: 820)) {
    ClosetView()
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.simulatedDivisions, DuoPreviewSize.rotatedFold)
        .modelContainer(PreviewCloset.container())
}

#Preview("Wardrobe · Duo book pose", traits: .fixedLayout(width: 820, height: 980)) {
    WardrobeView()
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.simulatedDivisions, DuoPreviewSize.bookFold)
        .modelContainer(PreviewCloset.container())
}

#Preview("Wardrobe · Duo closed", traits: .fixedLayout(width: 390, height: 844)) {
    WardrobeView()
        .environment(\.horizontalSizeClass, .compact)
        .modelContainer(PreviewCloset.container())
}
#endif
