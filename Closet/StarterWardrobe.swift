import Foundation
import SwiftData
import UIKit

@Model
final class ImportedGarment {
    @Attribute(.unique) var key: String
    var itemID: UUID?
    var photoRevision: Int = 1

    init(key: String, itemID: UUID? = nil, photoRevision: Int = 1) {
        self.key = key
        self.itemID = itemID
        self.photoRevision = photoRevision
    }
}

enum StarterWardrobe {
    struct Garment {
        let key: String
        let name: String
        var category: ClothingCategory = .tops
        var photoRevision = 1
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
        .init(key: "black-on-sneakers", name: "Black On sneakers", category: .shoes),
        .init(key: "brown-hammer-cap", name: "Hammer the Over cap", category: .hat),
        .init(key: "white-snoopy-tee", name: "Snoopy tee"),
        .init(key: "burgundy-u-tee", name: "Burgundy Uniqlo U tee", photoRevision: 2),
        .init(key: "charcoal-u-tee", name: "Charcoal Uniqlo U tee"),
        .init(key: "white-u-tee", name: "White Uniqlo U tee"),
        .init(key: "cream-manhattan-tee", name: "Manhattan Mini Mart tee"),
        .init(key: "cream-knit-sweater", name: "Cream knit sweater"),
        .init(key: "cream-guinness-sweatshirt", name: "Guinness sweatshirt"),
        .init(key: "washed-gray-jeans", name: "Washed gray jeans", category: .bottoms),
        .init(key: "brown-baggy-trousers", name: "Brown baggy trousers", category: .bottoms),
        .init(key: "stussy-cream-waffle-long-sleeve", name: "Stüssy cream waffle long sleeve", photoRevision: 2)
    ]

    /// Import receipts survive deleting a piece, so later launches respect removals.
    /// Add more entries and bundled PNGs to extend the wardrobe in a future update.
    @MainActor
    static func importMissing(into context: ModelContext, bundle: Bundle = .main) throws {
        let imported = Dictionary(uniqueKeysWithValues:
            try context.fetch(FetchDescriptor<ImportedGarment>()).map { ($0.key, $0) })
        let now = Date.now
        do {
            for (index, garment) in garments.enumerated() {
                let receipt = imported[garment.key]
                if let receipt, receipt.photoRevision >= garment.photoRevision { continue }
                guard let url = bundle.url(forResource: garment.key, withExtension: "png") else {
                    throw CocoaError(.fileNoSuchFile)
                }
                let photo = try Data(contentsOf: url)
                if let receipt {
                    let items = try context.fetch(FetchDescriptor<ClothingItem>())
                    // Older receipts lacked item IDs. Recognize only the original
                    // wide burgundy asset, so a user-added namesake is left alone.
                    let item = items.first {
                        if let id = receipt.itemID { return $0.id == id }
                        return garment.key == "burgundy-u-tee" && $0.name == garment.name
                            && $0.category == garment.category
                            && UIImage(data: $0.photo)?.size == CGSize(width: 1536, height: 1024)
                    }
                    if let item {
                        item.photo = photo
                        receipt.itemID = item.id
                        for snapshot in try context.fetch(FetchDescriptor<WornPiece>()) where snapshot.itemID == item.id {
                            snapshot.photo = photo
                        }
                    }
                    // A deleted item stays deleted, including after future launches.
                    receipt.photoRevision = garment.photoRevision
                } else {
                    let item = ClothingItem(name: garment.name, category: garment.category, photo: photo,
                                            addedAt: now.addingTimeInterval(-Double(index)))
                    context.insert(item)
                    context.insert(ImportedGarment(key: garment.key, itemID: item.id,
                                                  photoRevision: garment.photoRevision))
                }
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
