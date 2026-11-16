import SwiftUI

// Layout for any window shape: the phone, both iPhone Duo displays, and every Duo pose.
// Decisions come from size classes and the view's own geometry, never the device idiom,
// interface orientation, or UIScreen.

/// Pure layout math, kept separate so unit tests can cover it without a simulator.
enum ClosetMetrics {
    static let gutter: CGFloat = 20
    static let gridSpacing: CGFloat = 16
    static let minimumGridCell: CGFloat = 150
    static let maximumGridColumns = 6

    /// Two columns on a phone; more as the grid's own width grows (a Duo pane or inner display).
    static func gridColumnCount(width: CGFloat) -> Int {
        let content = width - 2 * gutter
        guard content.isFinite, content > 0 else { return 2 }
        let fit = Int(((content + gridSpacing) / (minimumGridCell + gridSpacing)).rounded(.down))
        return min(maximumGridColumns, max(2, fit))
    }

    /// Hanger slot width for a rail of the given width, the same on every display.
    static func railSlotWidth(width: CGFloat) -> CGFloat {
        min(190, max(140, width * 0.405))
    }

    /// Photo width on a piece's detail page, which can sit in a narrow pane.
    static func detailPhotoWidth(available: CGFloat) -> CGFloat {
        guard available > 0 else { return 280 }
        return max(160, min(280, available - 2 * gutter - 8))
    }
}

/// Where the two panes of a split go: at the fold when the iPhone Duo has one, otherwise down the middle.
struct SplitGeometry: Equatable {
    enum Axis: Equatable { case sideBySide, stacked }

    var axis: Axis
    /// True when an active fold separates the panes, so no divider is drawn.
    var isFolded = false
    var primary: CGRect
    var gap: CGRect
    var secondary: CGRect

    /// Panes narrower than this aren't usable, so a fold that would make one is ignored.
    static let minimumPane: CGFloat = 240

    /// - Parameters:
    ///   - size: The split's own size.
    ///   - divisions: Fold regions in the split's coordinate space. An active fold has its real
    ///     width; an inactive one (the phone open flat) has zero width but still marks the hinge.
    ///   - hairline: Space left between the panes when there's no fold to fill it.
    static func resolve(size: CGSize, divisions: [CGRect], hairline: CGFloat = 1) -> SplitGeometry {
        let bounds = CGRect(origin: .zero, size: size)
        let folds = divisions.filter { fold in
            fold.midX >= bounds.minX && fold.midX <= bounds.maxX
                && fold.midY >= bounds.minY && fold.midY <= bounds.maxY
                && (fold.width > 0 || fold.height > 0)
        }
        let activeFold = folds.first { $0.width >= 1 && $0.height >= 1 }

        if let fold = activeFold {
            // Folded (book or tabletop pose): one pane on each side, nothing in the crease.
            if fold.height >= fold.width {
                let primary = CGRect(x: 0, y: 0, width: max(0, fold.minX), height: size.height)
                let secondary = CGRect(x: fold.maxX, y: 0, width: max(0, size.width - fold.maxX), height: size.height)
                if primary.width >= minimumPane, secondary.width >= minimumPane {
                    return SplitGeometry(axis: .sideBySide, isFolded: true, primary: primary,
                                         gap: CGRect(x: fold.minX, y: 0, width: fold.width, height: size.height),
                                         secondary: secondary)
                }
            } else {
                let primary = CGRect(x: 0, y: 0, width: size.width, height: max(0, fold.minY))
                let secondary = CGRect(x: 0, y: fold.maxY, width: size.width, height: max(0, size.height - fold.maxY))
                if primary.height >= minimumPane, secondary.height >= minimumPane {
                    return SplitGeometry(axis: .stacked, isFolded: true, primary: primary,
                                         gap: CGRect(x: 0, y: fold.minY, width: size.width, height: fold.height),
                                         secondary: secondary)
                }
            }
        }

        // Open flat: side by side. Split at the inactive hinge so folding later doesn't move anything.
        let hingeX = folds.first { $0.height > $0.width }?.midX
        var splitX = (hingeX ?? size.width / 2).rounded()
        if size.width >= 2 * minimumPane + hairline {
            splitX = min(max(splitX, minimumPane), size.width - minimumPane - hairline)
        } else {
            splitX = ((size.width - hairline) / 2).rounded(.down)
        }
        let primary = CGRect(x: 0, y: 0, width: max(0, splitX), height: size.height)
        let gap = CGRect(x: primary.maxX, y: 0, width: hairline, height: size.height)
        let secondary = CGRect(x: gap.maxX, y: 0, width: max(0, size.width - gap.maxX), height: size.height)
        return SplitGeometry(axis: .sideBySide, primary: primary, gap: gap, secondary: secondary)
    }

    /// Insets that keep a pane's content clear of occluded areas, such as the inner camera while it's active.
    static func insets(for pane: CGRect, avoiding occlusions: [CGRect]) -> EdgeInsets {
        var insets = EdgeInsets()
        for occlusion in occlusions {
            let overlap = pane.intersection(occlusion)
            guard !overlap.isNull, overlap.width > 0, overlap.height > 0 else { continue }
            // Push content away from whichever pane edge the occlusion is closest to.
            let distances: [(Edge, CGFloat)] = [
                (.top, overlap.minY - pane.minY), (.bottom, pane.maxY - overlap.maxY),
                (.leading, overlap.minX - pane.minX), (.trailing, pane.maxX - overlap.maxX)
            ]
            guard let nearest = distances.min(by: { $0.1 < $1.1 })?.0 else { continue }
            switch nearest {
            case .top: insets.top = max(insets.top, overlap.maxY - pane.minY)
            case .bottom: insets.bottom = max(insets.bottom, pane.maxY - overlap.minY)
            case .leading: insets.leading = max(insets.leading, overlap.maxX - pane.minX)
            case .trailing: insets.trailing = max(insets.trailing, pane.maxX - overlap.minX)
            }
        }
        return insets
    }
}

/// Reads iPhone Duo reserved regions. Builds with older SDKs return no regions, so the same
/// layout code runs everywhere. `CLOSET_DUO_SDK` is set by Config/Closet.xcconfig for iOS 27 SDKs.
enum DuoRegions {
    static func divisions(in proxy: GeometryProxy) -> [CGRect] {
        #if CLOSET_DUO_SDK
        if #available(iOS 27.1, *) {
            // Inactive divisions mark the hinge while the phone is flat, so the split doesn't jump on folding.
            return proxy.reservedRegions(kind: .division, options: .includeInactive).map(\.frame)
        }
        #endif
        return []
    }

    static func occlusions(in proxy: GeometryProxy) -> [CGRect] {
        #if CLOSET_DUO_SDK
        if #available(iOS 27.1, *) {
            return proxy.reservedRegions(kind: .occlusion).map(\.frame)
        }
        #endif
        return []
    }
}

extension EnvironmentValues {
    /// Lets previews and tests stand in for a fold, since Xcode 26 has no iPhone Duo simulator.
    /// Rects are in the split's coordinate space. Real reserved regions take priority.
    @Entry var simulatedDivisions: [CGRect] = []
    /// Increases each time the hinge moves into or out of a partly folded pose.
    @Entry var hingePulse = 0
}

/// Two panes that meet at the fold. In book pose each pane gets its own half of the display
/// and nothing sits on the crease; open flat, the split stays where the hinge is.
struct FoldAwareSplit<Primary: View, Secondary: View>: View {
    @ViewBuilder var primary: Primary
    @ViewBuilder var secondary: Secondary
    @Environment(\.simulatedDivisions) private var simulatedDivisions
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { proxy in
            let real = DuoRegions.divisions(in: proxy)
            let split = SplitGeometry.resolve(size: proxy.size,
                                              divisions: real.isEmpty ? simulatedDivisions : real,
                                              hairline: 1 / max(displayScale, 1))
            let occlusions = DuoRegions.occlusions(in: proxy)
            let sideBySide = split.axis == .sideBySide
            // AnyLayout keeps each pane's state when a rotated fold switches the axis.
            let layout = sideBySide ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))

            layout {
                primary
                    .safeAreaPadding(SplitGeometry.insets(for: split.primary, avoiding: occlusions))
                    .frame(width: sideBySide ? split.primary.width : nil,
                           height: sideBySide ? nil : split.primary.height)
                Rectangle()
                    // A hairline when flat; when folded the crease itself separates the panes.
                    .fill(split.isFolded ? Color.clear : Color(uiColor: .separator))
                    .frame(width: sideBySide ? split.gap.width : nil,
                           height: sideBySide ? nil : split.gap.height)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                secondary
                    .safeAreaPadding(SplitGeometry.insets(for: split.secondary, avoiding: occlusions))
                    .frame(width: sideBySide ? split.secondary.width : nil,
                           height: sideBySide ? nil : split.secondary.height)
            }
        }
    }
}

/// Counts hinge pose changes so the rails can sway as the phone folds. Hinge data drives
/// effects only; layout uses reserved regions, as Apple recommends.
struct HingePulseReader: ViewModifier {
    @Binding var pulse: Int
    @State private var wasPartlyFolded: Bool?

    @ViewBuilder
    func body(content: Content) -> some View {
        #if CLOSET_DUO_SDK
        if #available(iOS 27.1, *) {
            content.onHingeChange { _, context in
                let partlyFolded = context.hinge?.status == .partiallyOpen
                if let wasPartlyFolded, wasPartlyFolded != partlyFolded { pulse &+= 1 }
                wasPartlyFolded = partlyFolded
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// A raised card whose corners stay concentric with the display or pane around it.
struct ClosetCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let dark = colorScheme == .dark
        content.background {
            ConcentricRectangle(corners: .concentric(minimum: 12), isUniform: true)
                .fill(dark ? Color(white: 0.13) : .white)
                .overlay {
                    // Light: a fine ring. Dark: one solid hairline a step lighter than the fill.
                    ConcentricRectangle(corners: .concentric(minimum: 12), isUniform: true)
                        .stroke(dark ? Color(white: 0.22) : Color.black.opacity(0.07), lineWidth: dark ? 0.5 : 1)
                }
                .shadow(color: .black.opacity(dark ? 0.5 : 0.12), radius: 1, x: 0, y: 1)
        }
    }
}
