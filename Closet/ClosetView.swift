import SwiftUI
import SwiftData

struct ClosetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ClothingItem.addedAt, order: .reverse) private var items: [ClothingItem]
    @State private var showingSettings = false
    @State private var showingLaundry = false
    @State private var addingCategory: ClothingCategory?
    @State private var importFailed = false

    private var countLabel: String {
        let count = items.count
        guard count > 0 else { return "0 pieces · A little room for you" }
        let recent = items.filter { $0.addedAt > Calendar.current.date(byAdding: .day, value: -30, to: .now)! }.count
        return "\(count) \(count == 1 ? "piece" : "pieces") · \(recent) added this month"
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(countLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 15)
                        .padding(.bottom, 26)
                        .accessibilityIdentifier("closetCount")

                    ForEach(ClothingCategory.allCases) { category in
                        RackSection(category: category, items: items.filter { $0.category == category }) {
                            addingCategory = category
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(ClosetStyle.background)
            .navigationTitle("Closet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { showingSettings = true }
                        .tint(.primary)
                        .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add a piece", systemImage: "plus") { addingCategory = .tops }
                        .tint(.blue)
                        .accessibilityIdentifier("addPieceButton")
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingLaundry = true
                    } label: {
                        let count = items.filter(\.needsWashing).count
                        Label(count == 0 ? "Laundry" : "Laundry · \(count)", systemImage: "basket")
                            .labelStyle(.titleAndIcon)
                    }
                    .tint(.primary)
                    .accessibilityIdentifier("laundryButton")
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingLaundry) { LaundryView() }
            .sheet(item: $addingCategory) { category in AddPieceView(initialCategory: category) }
            .navigationDestination(for: ClothingCategory.self) { category in
                CategoryView(category: category)
            }
            .navigationDestination(for: ClothingItem.self) { item in
                PieceDetailView(item: item)
            }
        }
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

struct RackSection: View {
    let category: ClothingCategory
    let items: [ClothingItem]
    var showsHeading = true
    var add: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swayAngle = 0.0
    @State private var scrollPhase = ScrollPhase.idle
    @State private var lastMotionSample = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsHeading {
                NavigationLink(value: category) {
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
                let slotWidth = min(190.0, max(140.0, geometry.size.width * 0.405))
                ZStack(alignment: .topLeading) {
                    ClothesRail().padding(.top, 7)

                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .top, spacing: -8) {
                            if items.isEmpty {
                                ForEach(0..<4) { index in
                                    HangerView(category: category)
                                        .frame(width: slotWidth)
                                        .opacity(index == 0 ? 1 : 0.72)
                                        .modifier(HangerSway(angle: swayAngle, index: index))
                                }
                            } else {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                    NavigationLink(value: item) {
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
                        .padding(.horizontal, 12)
                        .scrollTargetLayout()
                    }
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
                        swayAngle = max(-11, min(11, -velocity / 150))
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
    }
}

private struct HangerSway: ViewModifier {
    let angle: Double
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(reduceMotion ? 0 : angle * (0.9 + Double(index % 3) * 0.08)),
                            anchor: UnitPoint(x: 0.5, y: 0.025))
            .animation(reduceMotion ? nil : .spring(response: 0.52 + Double(index % 4) * 0.04,
                                                    dampingFraction: 0.3), value: angle)
    }
}

struct HangingPiece: View {
    let item: ClothingItem
    var width: CGFloat

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
                    .padding(.top, item.category == .tops ? 30 : 24)
                    .shadow(color: .black.opacity(0.07), radius: 3, x: 1, y: 4)
            }
        }
        .frame(width: width, height: width * (item.category == .tops ? 1.25 : 1.65) + 34, alignment: .top)
        .overlay(alignment: .bottom) {
            if item.needsWashing {
                Label("Needs washing", systemImage: "basket")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(.regularMaterial, in: Capsule())
                    .accessibilityHidden(true)
            }
        }
    }
}

struct CategoryView: View {
    let category: ClothingCategory
    @Query(sort: \ClothingItem.addedAt, order: .reverse) private var allItems: [ClothingItem]
    @State private var showingAdd = false

    private var items: [ClothingItem] { allItems.filter { $0.category == category } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(items.count) \(items.count == 1 ? "piece" : "pieces")")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .padding(.horizontal, 20).padding(.top, 16)
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("Your \(category.rawValue)", systemImage: category.symbol)
                    } description: {
                        Text("Add your first \(category.singular) to start this collection.")
                    } actions: {
                        Button("Add \(category.rawValue)", systemImage: "plus") { showingAdd = true }
                            .buttonStyle(.glass)
                            .accessibilityIdentifier("emptyAdd_\(category.rawValue)")
                    }
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                              alignment: .leading, spacing: 24) {
                        ForEach(items) { item in
                            NavigationLink(value: item) { ClothingGridCell(item: item) }
                                .buttonStyle(.plain)
                                .accessibilityLabel(item.name)
                                .accessibilityValue(item.needsWashing ? "Needs washing" : "Clean")
                        }
                    }
                    .padding(20)
                    .accessibilityIdentifier("categoryGrid")
                }
            }
        }
        .background(ClosetStyle.background)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add to \(category.title)", systemImage: "plus") { showingAdd = true }
            }
        }
        .sheet(isPresented: $showingAdd) { AddPieceView(initialCategory: category) }
    }
}

private struct ClothingGridCell: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .aspectRatio(0.85, contentMode: .fit)
                .overlay {
                    if let image = UIImage(data: item.photo) {
                        Image(uiImage: image)
                            .resizable().scaledToFit().padding(12)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            Text(item.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            if item.needsWashing {
                Label("Needs washing", systemImage: "basket")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview { ClosetView().modelContainer(for: ClothingItem.self, inMemory: true) }
