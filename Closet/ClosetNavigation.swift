import SwiftUI
import SwiftData

enum ClosetRoute: Hashable {
    case category(ClothingCategory)
    case piece(ClothingItem)
}

enum PieceRoute: Hashable {
    case photo
}

/// Navigation and presentation state shared by the phone layout and the split layout, so
/// opening or closing an iPhone Duo keeps the piece you were looking at and any open screen.
@MainActor @Observable
final class ClosetRouter {
    /// Phone layout: the whole stack, including an open piece.
    var path: [ClosetRoute] = []
    /// Split layout: the browsing pane's stack (categories only)…
    var browsePath: [ClosetRoute] = []
    /// …and the piece shown in the detail pane.
    var selectedID: UUID?
    var detailPath: [PieceRoute] = []

    var showingSettings = false
    var showingLaundry = false
    var showingWardrobe = false
    var showingCalendar = false
    var addingCategory: ClothingCategory?
    var hingePulse = 0

    func select(_ item: ClothingItem) {
        if selectedID != item.id { detailPath = [] }
        selectedID = item.id
    }

    func clearSelection() {
        selectedID = nil
        detailPath = []
    }

    /// Phone stack → split: categories stay in the browsing pane; the open piece moves to the detail pane.
    func moveToSplit() {
        var categories: [ClosetRoute] = []
        var piece: ClothingItem?
        for route in path {
            switch route {
            case .category: categories.append(route)
            case .piece(let item): piece = item
            }
        }
        browsePath = categories
        selectedID = piece.flatMap { $0.isDeleted ? nil : $0.id }
        detailPath = []
        path = []
    }

    /// Split → phone stack: the selected piece is pushed on top of the browsing stack.
    func moveToStack(items: [ClothingItem]) {
        var stack = browsePath
        if let selectedID, let item = items.first(where: { $0.id == selectedID && !$0.isDeleted }) {
            stack.append(.piece(item))
        }
        path = stack
        browsePath = []
        clearSelection()
    }
}

extension EnvironmentValues {
    /// Set in the split layout, where tapping a piece shows it beside the list instead of pushing it.
    @Entry var selectPiece: ((ClothingItem) -> Void)? = nil
    @Entry var selectedPieceID: UUID? = nil
}

/// A tap target for a piece: pushes its page on the phone, fills the detail pane in the split layout.
struct PieceLink<Label: View>: View {
    let item: ClothingItem
    @ViewBuilder var label: Label
    @Environment(\.selectPiece) private var selectPiece
    @Environment(\.selectedPieceID) private var selectedPieceID

    var body: some View {
        if let selectPiece {
            Button { selectPiece(item) } label: { label }
                .accessibilityAddTraits(selectedPieceID == item.id ? .isSelected : [])
        } else {
            NavigationLink(value: ClosetRoute.piece(item)) { label }
        }
    }
}

/// Regular width (the iPhone Duo inner display): the closet on one side of the fold, the piece on the other.
struct ClosetSplitView: View {
    @Environment(ClosetRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        FoldAwareSplit {
            NavigationStack(path: $router.browsePath) {
                ClosetHome()
            }
            .environment(\.selectPiece, { item in router.select(item) })
            .environment(\.selectedPieceID, router.selectedID)
        } secondary: {
            PieceDetailPane()
        }
        .background(ClosetStyle.background)
    }
}

private struct PieceDetailPane: View {
    @Environment(ClosetRouter.self) private var router
    @Query private var items: [ClothingItem]

    private var selected: ClothingItem? {
        guard let id = router.selectedID else { return nil }
        return items.first { $0.id == id && !$0.isDeleted }
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.detailPath) {
            Group {
                if let item = selected {
                    PieceDetailView(item: item,
                                    openPhoto: { router.detailPath.append(.photo) },
                                    onDeleted: { router.clearSelection() })
                        .id(item.id)
                } else {
                    PieceDetailPlaceholder()
                }
            }
            .navigationDestination(for: PieceRoute.self) { _ in
                if let item = selected {
                    PhotoZoomView(photo: item.photo, name: item.name, zoomPlacement: .topBarTrailing)
                }
            }
        }
    }
}

/// The detail pane before anything is picked: what's missing and what to do, nothing more.
private struct PieceDetailPlaceholder: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hanger")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
            Text("No piece selected")
                .font(.subheadline.weight(.medium))
            Text("Tap a piece to see its photo and wash status here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, ClosetMetrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClosetStyle.background)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("detailPlaceholder")
    }
}
