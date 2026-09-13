import Foundation
import SwiftData

enum ClothingCategory: String, CaseIterable, Identifiable, Codable {
    case tops, bottoms, shoes, hat

    var id: String { rawValue }
    var title: String { rawValue }
    var singular: String {
        switch self {
        case .tops: "top"
        case .bottoms: "bottom"
        case .shoes: "pair of shoes"
        case .hat: "hat"
        }
    }
    var symbol: String {
        switch self {
        case .tops: "tshirt"
        case .bottoms: "hanger"
        case .shoes: "shoe.2"
        case .hat: "hat.cap"
        }
    }
    var canBeWashed: Bool { self != .shoes }
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
        guard category.canBeWashed else { return }
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
