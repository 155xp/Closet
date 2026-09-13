import Foundation
import SwiftData

@Model
final class ImportedGarment {
    @Attribute(.unique) var key: String

    init(key: String) { self.key = key }
}

enum StarterWardrobe {
    struct Garment {
        let key: String
        let name: String
        var category: ClothingCategory = .tops
    }

    static let garments: [Garment] = [
        .init(key: "codex-cream-tee", name: "Codex tee"),
        .init(key: "green-striped-polo", name: "Green striped polo"),
        .init(key: "formula-one-brown-tee", name: "Formula 1 tee"),
        .init(key: "levi-wells-olive-tee", name: "Levi Wells Prentice tee"),
        .init(key: "washed-charcoal-tee", name: "Washed charcoal tee"),
        .init(key: "red-bull-cream-tee", name: "Red Bull Racing tee"),
        .init(key: "blue-moon-cream-tee", name: "Blue Moon tee"),
        .init(key: "vineyard-vines-boat-tee", name: "Vineyard Vines boat tee"),
        .init(key: "bucees-yellow-tee", name: "Buc-ee's tee"),
        .init(key: "cream-waffle-long-sleeve", name: "Cream waffle long sleeve"),
        .init(key: "dark-waffle-long-sleeve", name: "Dark waffle long sleeve"),
        .init(key: "blue-straight-jeans", name: "Blue jeans", category: .bottoms),
        .init(key: "stussy-hong-kong-sweatshirt", name: "Stüssy Hong Kong sweatshirt"),
        .init(key: "heather-gray-hoodie", name: "Heather gray hoodie"),
        .init(key: "virginia-tech-gray-sweatshirt", name: "Virginia Tech sweatshirt"),
        .init(key: "brown-hollister-sweatpants", name: "Brown Hollister sweatpants", category: .bottoms),
        .init(key: "slate-blue-sweatshirt", name: "Slate blue sweatshirt"),
        .init(key: "washed-charcoal-hoodie", name: "Washed charcoal hoodie"),
        .init(key: "washed-black-jeans", name: "Washed black jeans", category: .bottoms),
        .init(key: "charcoal-sweatpants", name: "Charcoal sweatpants", category: .bottoms),
        .init(key: "navy-hollister-sweatpants", name: "Navy Hollister sweatpants", category: .bottoms),
        .init(key: "deep-navy-sweatshirt", name: "Deep navy sweatshirt"),
        .init(key: "washed-blue-wide-jeans", name: "Washed blue jeans", category: .bottoms),
        .init(key: "taupe-shearling-clogs", name: "Taupe shearling clogs", category: .shoes),
        .init(key: "black-on-sneakers", name: "Black On sneakers", category: .shoes)
    ]

    /// Import receipts survive deleting a piece, so later launches respect removals.
    /// Add more entries and bundled PNGs to extend the wardrobe in a future update.
    @MainActor
    static func importMissing(into context: ModelContext, bundle: Bundle = .main) throws {
        let imported = Set(try context.fetch(FetchDescriptor<ImportedGarment>()).map(\.key))
        let now = Date.now
        do {
            for (index, garment) in garments.enumerated() where !imported.contains(garment.key) {
                guard let url = bundle.url(forResource: garment.key, withExtension: "png") else {
                    throw CocoaError(.fileNoSuchFile)
                }
                let photo = try Data(contentsOf: url)
                context.insert(ClothingItem(name: garment.name, category: garment.category, photo: photo,
                                           addedAt: now.addingTimeInterval(-Double(index))))
                context.insert(ImportedGarment(key: garment.key))
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
