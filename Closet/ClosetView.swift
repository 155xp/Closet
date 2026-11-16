import SwiftUI
import SwiftData

/// The app's root. Compact width (an iPhone, or the iPhone Duo's outer display) gets the phone
/// layout; regular width (the Duo's inner display) gets the closet beside the piece, split at the fold.
struct ClosetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \ClothingItem.addedAt, order: .reverse) private var items: [ClothingItem]
    @State private var router = ClosetRouter()
    @State private var importFailed = false

    private var usesSplit: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if usesSplit {
                ClosetSplitView()
            } else {
                NavigationStack(path: $router.path) {
                    ClosetHome()
                }
            }
        }
        .environment(router)
        .environment(\.hingePulse, router.hingePulse)
        .modifier(HingePulseReader(pulse: $router.hingePulse))
        .onChange(of: usesSplit) { _, split in
            // Opening or closing the phone keeps your place.
            if split { router.moveToSplit() } else { router.moveToStack(items: items) }
        }
        // Presented from the root so they stay open when the layout changes.
        .sheet(isPresented: $router.showingSettings) { SettingsView() }
        .sheet(isPresented: $router.showingLaundry) { LaundryView() }
        .sheet(isPresented: $router.showingCalendar) { OutfitCalendarView() }
        .fullScreenCover(isPresented: $router.showingWardrobe) { WardrobeView() }
        .sheet(item: $router.addingCategory) { category in AddPieceView(initialCategory: category) }
        .task {
            guard !ProcessInfo.processInfo.arguments.contains("--empty-closet"),
                  ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
            do { try StarterWardrobe.importMissing(into: context) }
            catch { importFailed = true }
        }
        .alert("Couldn't load your wardrobe", isPresented: $importFailed) {
            Button("Try again") {
                do { try StarterWardrobe.importMissing(into: context) }
                catch { importFailed = true }
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Your saved pieces are still here. Try reopening the app to load the included photos.")
        }
    }
}

/// The rails screen. It's the root of the phone stack and of the split layout's browsing pane.
struct ClosetHome: View {
    @Environment(ClosetRouter.self) private var router
    @Query(sort: \ClothingItem.addedAt, order: .reverse) private var items: [ClothingItem]

    private var laundryCount: Int {
        items.filter { $0.category.canBeWashed && $0.needsWashing }.count
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(ClothingCategory.allCases) { category in
                    if category == .shoes || category == .hat {
                        ShoesSection(category: category, items: items.filter { $0.category == category }) {
                            router.addingCategory = category
                        }
                    } else {
                        RackSection(category: category, items: items.filter { $0.category == category }) {
                            router.addingCategory = category
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(ClosetStyle.background)
        .navigationTitle("closet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Settings", systemImage: "gearshape") { router.showingSettings = true }
                    .tint(.primary)
                    .accessibilityIdentifier("settingsButton")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add a piece", systemImage: "plus") { router.addingCategory = .tops }
                    .tint(.blue)
                    .accessibilityIdentifier("addPieceButton")
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Wardrobe", systemImage: "tshirt") {
                    router.showingWardrobe = true
                }
                .labelStyle(.titleAndIcon)
                .tint(.primary)
                .accessibilityIdentifier("wardrobeButton")
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Calendar", systemImage: "calendar") { router.showingCalendar = true }
                    .labelStyle(.titleAndIcon)
                    .tint(.primary)
                    .accessibilityIdentifier("calendarButton")
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    router.showingLaundry = true
                } label: {
                    Image(systemName: "basket")
                        .overlay(alignment: .topTrailing) {
                            if laundryCount > 0 {
                                Text("\(laundryCount)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .frame(width: 20, height: 20)
                                    .background(.red, in: Circle())
                                    .offset(x: 10, y: -8)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.trailing, 5)
                        .padding(.top, 3)
                }
                .tint(.primary)
                .accessibilityLabel(laundryCount == 0 ? "Laundry" : "Laundry · \(laundryCount)")
                .accessibilityValue("\(laundryCount) \(laundryCount == 1 ? "item" : "items") to wash")
                .accessibilityIdentifier("laundryButton")
            }
        }
        .navigationDestination(for: ClosetRoute.self) { route in
            switch route {
            case .category(let category): CategoryView(category: category)
            case .piece(let item): PieceDetailView(item: item)
            }
        }
    }
}

struct RackSection: View {
    let category: ClothingCategory
    let items: [ClothingItem]
    var showsHeading = true
    var add: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swayAngle = 0.0
    @State private var scrollPhase = ScrollPhase.idle
    @State private var lastMotionSample = 0.0
    @Environment(\.hingePulse) private var hingePulse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsHeading {
                NavigationLink(value: ClosetRoute.category(category)) {
                    HStack(spacing: 10) {
                        Text(category.title)
                            .font(.title2.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .accessibilityIdentifier("category_\(category.rawValue)")
            }

            GeometryReader { geometry in
                let slotWidth = ClosetMetrics.railSlotWidth(width: geometry.size.width)
                let slotSpacing = -8.0
                let leadingMargin = 12.0
                // Leave the last garment in the first column, with the add hanger beside it.
                let trailingMargin = max(leadingMargin,
                                         geometry.size.width - leadingMargin - 2 * slotWidth - slotSpacing)
                ZStack(alignment: .topLeading) {
                    ClothesRail().padding(.top, 7)

                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .top, spacing: slotSpacing) {
                            if items.isEmpty {
                                ForEach(0..<4) { index in
                                    HangerView(category: category)
                                        .frame(width: slotWidth)
                                        .opacity(index == 0 ? 1 : 0.72)
                                        .modifier(HangerSway(angle: swayAngle, index: index))
                                }
                            } else {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                    PieceLink(item: item) {
                                        HangingPiece(item: item, width: slotWidth)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(item.name)
                                    .accessibilityValue(item.needsWashing ? "Needs washing" : "Clean")
                                    .modifier(HangerSway(angle: swayAngle, index: index))
                                }
                                Button(action: add) {
                                    VStack(spacing: 35) {
                                        HangerView(category: category)
                                            .frame(width: slotWidth * 0.6)
                                            .padding(.top, 3)
                                        Image(systemName: "plus").font(.title3).foregroundStyle(.secondary)
                                    }
                                    .frame(width: slotWidth)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Add to \(category.title)")
                                .modifier(HangerSway(angle: swayAngle, index: items.count))
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .contentMargins(.leading, leadingMargin, for: .scrollContent)
                    .contentMargins(.trailing, trailingMargin, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned)
                    .onScrollPhaseChange { _, phase in
                        scrollPhase = phase
                        lastMotionSample = ProcessInfo.processInfo.systemUptime
                        if phase == .idle { swayAngle = 0 }
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.x
                    } action: { previous, current in
                        guard !reduceMotion, scrollPhase != .idle else { return }
                        let now = ProcessInfo.processInfo.systemUptime
                        let interval = max(1.0 / 120, min(now - lastMotionSample, 1.0 / 15))
                        let velocity = Double(current - previous) / interval
                        lastMotionSample = now
                        // Inertia pulls the hem opposite the rail's movement.
                        swayAngle = HangerSway.targetAngle(velocity: velocity)
                    }
                    .accessibilityIdentifier("rail_\(category.rawValue)")

                    if items.isEmpty {
                        VStack(spacing: 12) {
                            Text(category == .tops ? "Your favorites will hang here." : "Room for the rest.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button(action: add) {
                                Label("Add \(category.rawValue)", systemImage: "plus")
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                            }
                            .buttonStyle(.glass)
                            .tint(.primary)
                            .accessibilityIdentifier("emptyAdd_\(category.rawValue)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, category == .tops ? 139 : 114)
                    }
                }
            }
            .frame(height: items.isEmpty ? 265 : (category == .tops ? 245 : 305))
            .padding(.top, 48)
        }
        .onChange(of: hingePulse) { _, pulse in
            // Folding or unfolding the phone gives the clothes a small swing, like moving a real rail.
            guard !reduceMotion, scrollPhase == .idle else { return }
            swayAngle = HangerSway.maximumAngle * 0.5 * (pulse.isMultiple(of: 2) ? 1 : -1)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(160))
                if scrollPhase == .idle { swayAngle = 0 }
            }
        }
    }
}

struct HangerSway: ViewModifier {
    static let maximumAngle = 8.0

    static func targetAngle(velocity: Double) -> Double {
        guard velocity.isFinite else { return 0 }
        return max(-maximumAngle, min(maximumAngle, -velocity / 180))
    }

    static func spring(index: Int) -> Spring {
        // Critical damping keeps repeated flicks from building up a large swing.
        Spring(response: 0.48 + Double(index % 4) * 0.02, dampingRatio: 1)
    }

    let angle: Double
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        // Animate just the rotation, not photo layout when a lazy row appears.
        content.animation(reduceMotion ? nil : .spring(Self.spring(index: index))) { view in
            view.rotationEffect(.degrees(reduceMotion ? 0 : angle * (0.9 + Double(index % 3) * 0.05)),
                                anchor: UnitPoint(x: 0.5, y: 0.025))
        }
    }
}

struct HangingPiece: View {
    let item: ClothingItem
    var width: CGFloat

    private var photoTopPadding: CGFloat {
        guard item.category == .tops else { return 24 }
        let hasHood = item.name.localizedCaseInsensitiveContains("hoodie")
            || item.name.localizedCaseInsensitiveContains("hooded")
        // A raised hood covers the hanger's shoulders; only its hook emerges.
        return hasHood ? 8 : 30
    }

    var body: some View {
        ZStack(alignment: .top) {
            HangerView(category: item.category)
                .frame(width: width * 0.6)
                .padding(.top, 3)
            if let image = UIImage(data: item.photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: width * (item.category == .tops ? 1.25 : 1.65), alignment: .top)
                    .padding(.top, photoTopPadding)
                    .shadow(color: .black.opacity(0.07), radius: 3, x: 1, y: 4)
            }
        }
        .frame(width: width, height: width * (item.category == .tops ? 1.25 : 1.65) + 34, alignment: .top)
        .overlay(alignment: .bottom) {
            if item.needsWashing {
                Image(systemName: "washer")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(.regularMaterial, in: Circle())
                    .accessibilityIdentifier("washIndicator_\(item.id)")
                    .accessibilityHidden(true)
            }
        }
    }
}

struct CategoryView: View {
    let category: ClothingCategory
    @Query(sort: \ClothingItem.addedAt, order: .reverse) private var allItems: [ClothingItem]
    @Environment(ClosetRouter.self) private var router
    @State private var width: CGFloat = 0

    private var items: [ClothingItem] { allItems.filter { $0.category == category } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("Your \(category.rawValue)", systemImage: category.symbol)
                    } description: {
                        Text("Add your first \(category.singular) to start this collection.")
                    } actions: {
                        Button("Add \(category.rawValue)", systemImage: "plus") { router.addingCategory = category }
                            .buttonStyle(.glass)
                            .accessibilityIdentifier("emptyAdd_\(category.rawValue)")
                    }
                    .padding(.top, 50)
                } else {
                    // Two columns on a phone; more on a wide pane or the iPhone Duo's inner display.
                    let columns = Array(repeating: GridItem(.flexible(), spacing: ClosetMetrics.gridSpacing),
                                        count: ClosetMetrics.gridColumnCount(width: width))
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                        ForEach(items) { item in
                            PieceLink(item: item) { ClothingGridCell(item: item) }
                                .buttonStyle(.plain)
                                .accessibilityLabel(item.name)
                                .accessibilityValue(item.category.canBeWashed ? (item.needsWashing ? "Needs washing" : "Clean") : "")
                        }
                    }
                    .padding(ClosetMetrics.gutter)
                    .accessibilityIdentifier("categoryGrid")
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .background(ClosetStyle.background)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add to \(category.title)", systemImage: "plus") { router.addingCategory = category }
            }
        }
    }
}

private struct ClothingGridCell: View {
    let item: ClothingItem

    var body: some View {
        Color.clear
            .aspectRatio(item.category == .bottoms ? 0.7 : 1, contentMode: .fit)
            .overlay {
                if let image = UIImage(data: item.photo) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                }
            }
            .contentShape(Rectangle())
    }
}

