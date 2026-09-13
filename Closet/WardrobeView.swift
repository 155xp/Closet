import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \ClothingItem.addedAt, order: .reverse) private var items: [ClothingItem]
    @Query(sort: \DailyOutfit.day, order: .reverse) private var outfits: [DailyOutfit]
    @State private var topID: UUID?
    @State private var bottomID: UUID?
    @State private var shoesID: UUID?
    @State private var saveFailed = false
    @State private var addingCategory: ClothingCategory?

    private var selectedItems: [ClothingItem] {
        [topID, bottomID, shoesID].compactMap { id in items.first { $0.id == id } }
    }

    private func wearLabel(for id: UUID?, now: Date) -> String {
        guard let id else { return "" }
        return DailyOutfit.wearLabel(for: id, in: outfits, now: now)
    }

    private func restoredSelection(_ current: UUID?, category: ClothingCategory) -> UUID? {
        let choices = items.filter { $0.category == category }
        if let current, choices.contains(where: { $0.id == current }) { return current }
        if let saved = DailyOutfit.on(.now, in: outfits)?.pieces.first(where: { $0.categoryValue == category.rawValue }),
           choices.contains(where: { $0.id == saved.itemID }) { return saved.itemID }
        return choices.isEmpty ? nil : choices[min(1, choices.count - 1)].id
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                GeometryReader { geometry in
                    let outfitHeight = max(180, min(geometry.size.height - 80, geometry.size.width * 1.62))
                    VStack(spacing: 4) {
                        Text(wearLabel(for: topID, now: timeline.date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("wearHistory_tops")
                            .padding(.bottom, 6)
                        WardrobeCarousel(category: .tops, items: items.filter { $0.category == .tops }, selection: $topID) {
                            addingCategory = .tops
                        }
                        .frame(height: outfitHeight * 0.34)

                        WardrobeCarousel(category: .bottoms, items: items.filter { $0.category == .bottoms }, selection: $bottomID) {
                            addingCategory = .bottoms
                        }
                        .frame(height: outfitHeight * 0.46)

                        Text(wearLabel(for: bottomID, now: timeline.date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("wearHistory_bottoms")

                        WardrobeCarousel(category: .shoes, items: items.filter { $0.category == .shoes }, selection: $shoesID) {
                            addingCategory = .shoes
                        }
                        .frame(height: outfitHeight * 0.20)
                    }
                    .frame(maxHeight: .infinity)
                }
                .safeAreaInset(edge: .bottom) {
                    Button(DailyOutfit.on(timeline.date, in: outfits) == nil ? "Wear this today" : "Update today") {
                        do { try DailyOutfit.save(items: selectedItems, in: context) }
                        catch { saveFailed = true }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .buttonStyle(.glass)
                    .foregroundStyle(.primary)
                    .disabled(selectedItems.isEmpty)
                    .accessibilityIdentifier("wearTodayButton")
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
            }
            .onChange(of: items.map(\.id), initial: true) { _, _ in
                topID = restoredSelection(topID, category: .tops)
                bottomID = restoredSelection(bottomID, category: .bottoms)
                shoesID = restoredSelection(shoesID, category: .shoes)
            }
            .background(ClosetStyle.background)
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("doneWardrobeButton")
                }
            }
            .alert("Couldn't save today's outfit", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your previous outfit is still saved. Please try again.")
            }
            .sheet(item: $addingCategory) { category in
                AddPieceView(initialCategory: category)
            }
        }
    }
}

private struct WardrobeCarousel: View {
    let category: ClothingCategory
    let items: [ClothingItem]
    @Binding var selection: UUID?
    var add: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectedIndex: Int? { items.firstIndex { $0.id == selection } }
    private var positionLabel: String {
        guard let selectedIndex else { return "" }
        return "\(selectedIndex + 1) of \(items.count)"
    }

    var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let coordinateSpaceName = "outfit_\(category.rawValue)"
            let width = viewportWidth * (category == .tops ? 0.60 : 0.51)
            let spacing = -width * 0.14
            let anchor: UnitPoint = category == .tops ? .bottom : .top

            if items.isEmpty {
                Button(action: add) {
                    Label("Add \(category.rawValue)", systemImage: "plus")
                }
                .buttonStyle(.glass)
                .tint(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("wardrobeAdd_\(category.rawValue)")
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: spacing) {
                        ForEach(items) { item in
                            WardrobePhoto(item: item, width: width, height: geometry.size.height)
                            .visualEffect { content, proxy in
                                let center = proxy.frame(in: .named(coordinateSpaceName)).midX
                                let distance = abs(center - viewportWidth / 2)
                                let progress = min(distance / (width + spacing), 1)
                                return content.scaleEffect(1 - progress * 0.50, anchor: anchor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(reduceMotion ? nil : .snappy) { selection = item.id }
                            }
                            .accessibilityLabel(item.name)
                            .accessibilityAddTraits(.isButton)
                            .accessibilityIdentifier("wardrobePiece_\(item.name)")
                            .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, (geometry.size.width - width) / 2, for: .scrollContent)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
                .scrollPosition(id: $selection, anchor: .center)
                .accessibilityIdentifier("wardrobe_\(category.rawValue)")
                .accessibilityValue(positionLabel)

            }
        }
        .coordinateSpace(name: "outfit_\(category.rawValue)")
    }
}

private struct WardrobePhoto: View {
    let item: ClothingItem
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Group {
            if let image = UIImage(data: item.photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: width, height: height, alignment: item.category == .tops ? .bottom : .top)
    }
}
