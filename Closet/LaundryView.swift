import SwiftUI
import SwiftData

struct LaundryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<ClothingItem> { $0.needsWashing && $0.categoryValue != "shoes" }, sort: \ClothingItem.name)
    private var items: [ClothingItem]
    @State private var lastBatch: [(item: ClothingItem, date: Date?)] = []
    @State private var saveError = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("All clean", systemImage: "basket")
                    } description: {
                        Text("Put a piece in the laundry after wearing it.\nIt will show up here.")
                    }
                } else {
                    List {
                        Section {
                            ForEach(items) { item in
                                HStack(spacing: 16) {
                                    if let image = UIImage(data: item.photo) {
                                        Image(uiImage: image).resizable().scaledToFit()
                                            .frame(width: 64, height: 76)
                                            .accessibilityHidden(true)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name).font(.body.weight(.medium))
                                        Text(item.category.title).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    Button { wash([item]) } label: {
                                        Image(systemName: "checkmark").frame(width: 30, height: 30)
                                    }
                                    .buttonStyle(.glass)
                                    .tint(.primary)
                                    .accessibilityLabel("Mark \(item.name) washed")
                                }
                                .padding(.vertical, 5)
                            }
                        } header: {
                            Text("\(items.count) \(items.count == 1 ? "piece" : "pieces") to wash")
                        } footer: {
                            Text("Tap a checkmark when a piece is washed and ready to wear.")
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(ClosetStyle.background)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if !lastBatch.isEmpty {
                        HStack {
                            Text("Marked \(lastBatch.count) \(lastBatch.count == 1 ? "piece" : "pieces") clean")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                            Button("Undo", action: undo).accessibilityIdentifier("undoWashButton")
                        }
                        .padding(.horizontal, 24)
                    }
                    if !items.isEmpty {
                        Button { wash(items) } label: {
                            Label("Mark all washed", systemImage: "checkmark")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.primary)
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier("washAllButton")
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Laundry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("doneLaundryButton")
                }
            }
            .alert("Couldn't update your laundry", isPresented: $saveError) {
                Button("OK", role: .cancel) {}
            } message: { Text("Please try again. Your previous wash status has been kept.") }
        }
    }

    private func wash(_ batch: [ClothingItem]) {
        let previous = batch.map { (item: $0, date: $0.lastWashedAt) }
        let now = Date.now
        for item in batch { item.markWashed(at: now) }
        do {
            try context.save()
            withAnimation { lastBatch = previous }
        } catch { context.rollback(); saveError = true }
    }

    private func undo() {
        for entry in lastBatch where !entry.item.isDeleted {
            entry.item.needsWashing = true
            entry.item.lastWashedAt = entry.date
        }
        do {
            try context.save()
            withAnimation { lastBatch = [] }
        } catch { context.rollback(); saveError = true }
    }
}
