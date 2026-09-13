import SwiftUI

struct ShoesSection: View {
    let items: [ClothingItem]
    var add: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(value: ClothingCategory.shoes) {
                HStack(spacing: 10) {
                    Text("Shoes").font(.title2.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .accessibilityIdentifier("category_shoes")

            if items.isEmpty {
                Button("Add shoes", systemImage: "plus", action: add)
                    .buttonStyle(.glass)
                    .tint(.primary)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .accessibilityIdentifier("emptyAdd_shoes")
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(items) { item in
                            NavigationLink(value: item) {
                                ShoePhoto(item: item)
                                    .frame(width: 160, height: 190)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.name)
                        }
                        Button("Add shoes", systemImage: "plus", action: add)
                            .labelStyle(.iconOnly)
                            .buttonStyle(.glass)
                            .tint(.primary)
                            .frame(width: 70, height: 190)
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .accessibilityIdentifier("shoesRow")
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

struct ShoePhoto: View {
    let item: ClothingItem

    var body: some View {
        if let image = UIImage(data: item.photo) {
            Image(uiImage: image).resizable().scaledToFit()
        }
    }
}
