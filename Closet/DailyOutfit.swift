import Foundation
import SwiftData

@Model
final class DailyOutfit {
    var day: Date
    @Relationship(deleteRule: .cascade) var pieces: [WornPiece]

    init(day: Date, items: [ClothingItem]) {
        self.day = day
        pieces = items.map { WornPiece(item: $0) }
    }

    static func on(_ date: Date, in outfits: [DailyOutfit], calendar: Calendar = .current) -> DailyOutfit? {
        outfits.first { calendar.isDate($0.day, inSameDayAs: date) }
    }

    static func wearLabel(for itemID: UUID, in outfits: [DailyOutfit],
                          now: Date = .now, calendar: Calendar = .current) -> String {
        let today = calendar.startOfDay(for: now)
        guard let lastDay = outfits.filter({
            calendar.startOfDay(for: $0.day) <= today && $0.pieces.contains { $0.itemID == itemID }
        }).map(\.day).max() else { return "Haven't worn yet" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDay), to: today).day ?? 0
        return days == 0 ? "Worn today" : "Worn \(days) \(days == 1 ? "day" : "days") ago"
    }

    static func save(items: [ClothingItem], on date: Date = .now, in context: ModelContext,
                     calendar: Calendar = .current) throws {
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        let existing = try context.fetch(FetchDescriptor<DailyOutfit>(
            predicate: #Predicate { $0.day >= day && $0.day < nextDay }
        ))
        // Replace the whole day's outfit, including snapshots that no longer belong to it.
        for outfit in existing { context.delete(outfit) }
        context.insert(DailyOutfit(day: day, items: items))
        for item in items where item.category.canBeWashed {
            item.needsWashing = true
        }
        do { try context.save() }
        catch {
            context.rollback()
            throw error
        }
    }
}

@Model
final class WornPiece {
    var itemID: UUID
    var name: String
    var categoryValue: String
    @Attribute(.externalStorage) var photo: Data

    init(item: ClothingItem) {
        itemID = item.id
        name = item.name
        categoryValue = item.categoryValue
        photo = item.photo
    }
}
