import XCTest
import SwiftData
import UIKit
import SwiftUI
@testable import Closet

final class ClosetTests: XCTestCase {
    @MainActor
    func testRepeatedFlicksDoNotAmplifyHangerSwing() {
        for index in 0..<12 {
            for frameRate in [30.0, 60.0, 120.0] {
                let spring = HangerSway.spring(index: index)
                var angle = 0.0
                var angularVelocity = 0.0
                var peak = 0.0
                for frame in 0..<Int(frameRate * 6) {
                    let time = Double(frame) / frameRate
                    let velocity = time < 4 ? (Int(time / 0.267) % 2 == 0 ? 20_000.0 : -20_000.0) : 0
                    spring.update(value: &angle, velocity: &angularVelocity,
                                  target: HangerSway.targetAngle(velocity: velocity), deltaTime: 1 / frameRate)
                    peak = max(peak, abs(angle))
                }
                XCTAssertLessThanOrEqual(peak, HangerSway.maximumAngle + 0.001,
                                         "Rapid reversals must not amplify the swing at \(frameRate) fps")
                XCTAssertEqual(angle, 0, accuracy: 0.01, "Clothes should settle after scrolling stops")
            }
        }
    }

    @MainActor
    func testPhotoSurvivesReopeningStoreAndDeletion() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appending(path: "closet.store"))
        let photo = try makePhoto()
        let id: UUID
        do {
            let container = try ModelContainer(for: ClothingItem.self, configurations: configuration)
            let context = ModelContext(container)
            let item = ClothingItem(name: "Favorite tee", category: .tops, photo: photo)
            XCTAssertFalse(item.needsWashing)
            XCTAssertNil(item.lastWashedAt)
            item.needsWashing = true
            id = item.id
            context.insert(item)
            try context.save()
        }
        let reopened = try ModelContainer(for: ClothingItem.self, configurations: configuration)
        let context = ModelContext(reopened)
        let saved = try XCTUnwrap(context.fetch(FetchDescriptor<ClothingItem>()).first)
        XCTAssertEqual(saved.id, id)
        XCTAssertEqual(saved.photo, photo)
        XCTAssertEqual(saved.category, .tops)
        XCTAssertTrue(saved.needsWashing)
        let washedAt = Date(timeIntervalSince1970: 1_800_000_000)
        saved.markWashed(at: washedAt)
        try context.save()
        let washedContainer = try ModelContainer(for: ClothingItem.self, configurations: configuration)
        let washedContext = ModelContext(washedContainer)
        let washed = try XCTUnwrap(washedContext.fetch(FetchDescriptor<ClothingItem>()).first)
        XCTAssertFalse(washed.needsWashing)
        XCTAssertEqual(washed.lastWashedAt, washedAt)
        context.delete(saved)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 0)
    }

    @MainActor
    func testPhotoPreparationPreservesTransparencyAndLimitsSize() throws {
        let prepared = try PhotoPreparation.prepare(makePhoto())
        let image = try XCTUnwrap(UIImage(data: prepared)?.cgImage)
        XCTAssertLessThanOrEqual(max(image.width, image.height), 1600)
        XCTAssertTrue([CGImageAlphaInfo.premultipliedLast, .premultipliedFirst, .first, .last].contains(image.alphaInfo))
    }

    func testUnreadablePhotoIsRejected() {
        XCTAssertThrowsError(try PhotoPreparation.prepare(Data("invalid".utf8)))
    }

    @MainActor
    func testBundledWardrobeImportsOnceAndRespectsDeletion() throws {
        let container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        try StarterWardrobe.importMissing(into: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 25)
        let all = try context.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertEqual(all.filter { $0.category == .bottoms }.count, 6)
        XCTAssertTrue(all.allSatisfy { UIImage(data: $0.photo) != nil })
        context.delete(try XCTUnwrap(all.first))
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 24)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ImportedGarment>()), 25)
    }

    @MainActor
    func testNewSweatshirtImportsWithoutChangingExistingLaundry() throws {
        let container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let existing = ClothingItem(name: "My saved shirt", category: .tops, photo: try makePhoto())
        existing.needsWashing = true
        context.insert(existing)
        for garment in StarterWardrobe.garments where garment.key != "stussy-hong-kong-sweatshirt" {
            context.insert(ImportedGarment(key: garment.key))
        }
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        try StarterWardrobe.importMissing(into: context)
        let pieces = try context.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertEqual(pieces.count, 2)
        XCTAssertTrue(existing.needsWashing)
        XCTAssertEqual(pieces.filter { $0.name == "Stüssy Hong Kong sweatshirt" }.count, 1)
    }

    @MainActor
    func testNewBatchImportsOnceAndPreservesExistingCloset() throws {
        let container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let originalPhoto = try makePhoto()
        let existing = ClothingItem(name: "My saved shirt", category: .tops, photo: originalPhoto)
        existing.needsWashing = true
        context.insert(existing)
        // Earlier import receipts include pieces the user may have deleted.
        for garment in StarterWardrobe.garments.prefix(13) {
            context.insert(ImportedGarment(key: garment.key))
        }
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        try StarterWardrobe.importMissing(into: context)
        let pieces = try context.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertEqual(pieces.count, 13)
        XCTAssertEqual(pieces.filter { $0.category == .bottoms }.count, 5)
        XCTAssertTrue(existing.needsWashing)
        XCTAssertEqual(existing.photo, originalPhoto)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ImportedGarment>()), 25)
        for garment in StarterWardrobe.garments.suffix(12) {
            let piece = try XCTUnwrap(pieces.first { $0.name == garment.name })
            XCTAssertFalse(piece.needsWashing)
            XCTAssertNotNil(UIImage(data: piece.photo))
        }
    }

    @MainActor
    func testShoesImportOnceWithoutChangingClothesOrAddingWashHistory() throws {
        let container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let shirt = ClothingItem(name: "Saved shirt", category: .tops, photo: try makePhoto())
        shirt.needsWashing = true
        context.insert(shirt)
        for garment in StarterWardrobe.garments where garment.category != .shoes {
            context.insert(ImportedGarment(key: garment.key))
        }
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        try StarterWardrobe.importMissing(into: context)
        let shoes = try context.fetch(FetchDescriptor<ClothingItem>()).filter { $0.category == .shoes }
        XCTAssertEqual(shoes.count, 2)
        XCTAssertTrue(shirt.needsWashing)
        for pair in shoes {
            XCTAssertFalse(pair.category.canBeWashed)
            XCTAssertFalse(pair.needsWashing)
            pair.markWashed()
            XCTAssertNil(pair.lastWashedAt)
            let image = try XCTUnwrap(UIImage(data: pair.photo)?.cgImage)
            XCTAssertTrue([CGImageAlphaInfo.premultipliedLast, .premultipliedFirst, .first, .last].contains(image.alphaInfo))
        }
    }

    @MainActor
    func testWearHistoryUsesCalendarDaysAcrossDaylightSaving() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let item = ClothingItem(name: "Tee", category: .tops, photo: Data())
        let worn = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 23, minute: 55))!
        let nextMorning = calendar.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 0, minute: 5))!
        let outfit = DailyOutfit(day: worn, items: [item])
        XCTAssertEqual(DailyOutfit.wearLabel(for: item.id, in: [], now: worn, calendar: calendar), "Haven't worn yet")
        XCTAssertEqual(DailyOutfit.wearLabel(for: item.id, in: [outfit], now: worn, calendar: calendar), "Worn today")
        XCTAssertEqual(DailyOutfit.wearLabel(for: item.id, in: [outfit], now: nextMorning, calendar: calendar), "Worn 1 day ago")
        let later = calendar.date(byAdding: .day, value: 4, to: nextMorning)!
        XCTAssertEqual(DailyOutfit.wearLabel(for: item.id, in: [outfit], now: later, calendar: calendar), "Worn 5 days ago")
    }

    @MainActor
    func testDailyOutfitReplacementPersistsAndKeepsDeletedPiecePhotos() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appending(path: "outfits.store"))
        let photo = try makePhoto()
        let today = Calendar.current.startOfDay(for: .now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let originalID: UUID
        let replacementID: UUID
        do {
            // Begin with the previous app schema and an existing saved garment.
            let oldContainer = try ModelContainer(for: ClothingItem.self, ImportedGarment.self, configurations: configuration)
            let oldContext = ModelContext(oldContainer)
            let original = ClothingItem(name: "Original tee", category: .tops, photo: photo)
            original.needsWashing = true
            originalID = original.id
            oldContext.insert(original)
            try oldContext.save()
        }
        do {
            let container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self, DailyOutfit.self, WornPiece.self,
                                               configurations: configuration)
            let context = ModelContext(container)
            let original = try XCTUnwrap(context.fetch(FetchDescriptor<ClothingItem>()).first)
            XCTAssertTrue(original.needsWashing)
            XCTAssertEqual(original.photo, photo)
            let replacement = ClothingItem(name: "Replacement tee", category: .tops, photo: photo)
            let shoes = ClothingItem(name: "Shoes", category: .shoes, photo: photo)
            replacementID = replacement.id
            context.insert(replacement)
            context.insert(shoes)
            try DailyOutfit.save(items: [original], on: yesterday, in: context)
            try DailyOutfit.save(items: [original, shoes], on: today, in: context)
            try DailyOutfit.save(items: [replacement, shoes], on: today.addingTimeInterval(3600), in: context)
            XCTAssertTrue(original.needsWashing, "Updating an outfit must not clean previously worn clothes")
            XCTAssertTrue(replacement.needsWashing)
            XCTAssertFalse(shoes.needsWashing)
            XCTAssertNil(shoes.lastWashedAt)
            let outfits = try context.fetch(FetchDescriptor<DailyOutfit>())
            XCTAssertEqual(outfits.count, 2)
            XCTAssertEqual(DailyOutfit.on(today, in: outfits)?.pieces.count, 2)
            XCTAssertEqual(DailyOutfit.wearLabel(for: originalID, in: outfits), "Worn 1 day ago")
            XCTAssertEqual(DailyOutfit.wearLabel(for: replacementID, in: outfits), "Worn today")
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<WornPiece>()), 3)
            context.delete(original)
            try context.save()
        }
        let reopened = try ModelContainer(for: ClothingItem.self, ImportedGarment.self, DailyOutfit.self, WornPiece.self,
                                          configurations: configuration)
        let reopenedContext = ModelContext(reopened)
        let outfits = try reopenedContext.fetch(FetchDescriptor<DailyOutfit>())
        let savedItems = try reopenedContext.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertTrue(try XCTUnwrap(savedItems.first { $0.id == replacementID }).needsWashing)
        XCTAssertFalse(try XCTUnwrap(savedItems.first { $0.category == .shoes }).needsWashing)
        XCTAssertEqual(outfits.count, 2)
        let oldSnapshot = try XCTUnwrap(DailyOutfit.on(yesterday, in: outfits)?.pieces.first)
        XCTAssertEqual(oldSnapshot.itemID, originalID)
        XCTAssertEqual(oldSnapshot.photo, photo)
        XCTAssertEqual(oldSnapshot.name, "Original tee")
        XCTAssertTrue(try XCTUnwrap(DailyOutfit.on(today, in: outfits)).pieces.contains { $0.itemID == replacementID })
    }

    @MainActor
    private func makePhoto() throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: 1800, height: 1200), format: format).pngData { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 200, y: 200, width: 600, height: 600))
        }
    }
}
