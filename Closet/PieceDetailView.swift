import SwiftUI
import SwiftData

struct PieceDetailView: View {
    let item: ClothingItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    @State private var errorMessage: String?
    @State private var showingPhoto = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Button { showingPhoto = true } label: {
                    ZStack(alignment: .top) {
                        if item.category == .shoes || item.category == .hat {
                            ShoePhoto(item: item).frame(width: 260, height: 300)
                        } else {
                            ClothesRail().padding(.top, 7)
                            HangingPiece(item: item, width: 280)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                            .padding(13)
                            .glassEffect(in: Circle())
                            .padding(.trailing, 22)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View photo of \(item.name)")
                .accessibilityHint("Opens the photo. Pinch or double tap to zoom.")
                .accessibilityIdentifier("zoomPhotoButton")
                .padding(.top, 55)
                VStack(spacing: 8) {
                    Text(item.name).font(.title2.weight(.semibold))
                    Text(item.category.title).foregroundStyle(.secondary)
                    Text("Added \(item.addedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.footnote).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 24)
                if item.category.canBeWashed {
                    VStack(spacing: 14) {
                        Label(item.needsWashing ? "Needs washing" : "Clean",
                              systemImage: item.needsWashing ? "basket" : "checkmark.circle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(item.needsWashing ? Color.orange : Color.secondary)
                            .accessibilityIdentifier("washStatus")
                        Button {
                            if item.needsWashing { item.markWashed() }
                            else { item.needsWashing = true }
                            do { try context.save() }
                            catch { context.rollback(); errorMessage = "Couldn't update the wash status. Please try again." }
                        } label: {
                            Label(item.needsWashing ? "Mark washed" : "Put in laundry",
                                  systemImage: item.needsWashing ? "checkmark" : "basket")
                                .padding(.horizontal, 14).padding(.vertical, 6)
                        }
                        .buttonStyle(.glass)
                        .tint(.primary)
                        .accessibilityIdentifier("toggleWashButton")
                        if let date = item.lastWashedAt {
                            Text("Last washed \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .background(ClosetStyle.background)
        .navigationTitle("Your piece")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingPhoto) {
            PhotoViewer(photo: item.photo, name: item.name)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Delete piece", systemImage: "trash") { confirmingDelete = true }
                    .tint(.primary)
            }
        }
        .confirmationDialog("Remove this piece from your closet?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete piece", role: .destructive) {
                context.delete(item)
                do { try context.save(); dismiss() }
                catch { context.rollback(); errorMessage = "Couldn't delete this piece. Please try again." }
            }
        }
        .alert("Couldn't save the change", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage ?? "Please try again.") }
    }
}
