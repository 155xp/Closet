import Foundation
import SwiftData

enum ClothingCategory: String, CaseIterable, Identifiable, Codable {
    case tops, bottoms

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var singular: String { self == .tops ? "top" : "bottom" }
    var symbol: String { self == .tops ? "tshirt" : "hanger" }
}

@Model
final class ClothingItem {
    var id: UUID
    var name: String
    var categoryValue: String
    var addedAt: Date
    var needsWashing: Bool = false
    var lastWashedAt: Date?
    @Attribute(.externalStorage) var photo: Data

    var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryValue) ?? .tops }
        set { categoryValue = newValue.rawValue }
    }

    func markWashed(at date: Date = .now) {
        needsWashing = false
        lastWashedAt = date
    }

    init(name: String, category: ClothingCategory, photo: Data, addedAt: Date = .now) {
        id = UUID()
        self.name = name
        categoryValue = category.rawValue
        self.photo = photo
        self.addedAt = addedAt
    }
}
