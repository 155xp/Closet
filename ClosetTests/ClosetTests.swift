import XCTest
import SwiftData
import UIKit
import SwiftUI
@testable import Closet

final class ClosetTests: XCTestCase {
    @MainActor
    func testBurgundyPhotoUpdateKeepsIdentityLaundryAndOutfitHistory() throws {
        let container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self, DailyOutfit.self, WornPiece.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let oldPhoto = UIGraphicsImageRenderer(size: CGSize(width: 1536, height: 1024), format: format).pngData { renderer in
            UIColor.red.setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: 1536, height: 1024))
        }
        let red = ClothingItem(name: "Burgundy Uniqlo U tee", category: .tops, photo: oldPhoto,
                               addedAt: Date(timeIntervalSince1970: 1000))
        context.insert(red)
        let id = red.id
        let washDate = Date(timeIntervalSince1970: 1500)
        red.lastWashedAt = washDate
        try DailyOutfit.save(items: [red], in: context)
        // Represents receipts from the installed app before photo revisions existed.
        for garment in StarterWardrobe.garments.dropLast() { context.insert(ImportedGarment(key: garment.key)) }
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        try StarterWardrobe.importMissing(into: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 2)
        XCTAssertEqual(red.id, id)
        XCTAssertEqual(red.addedAt, Date(timeIntervalSince1970: 1000))
        XCTAssertEqual(red.lastWashedAt, washDate)
        XCTAssertTrue(red.needsWashing)
        XCTAssertNotEqual(red.photo, oldPhoto)
        let image = try XCTUnwrap(UIImage(data: red.photo))
        XCTAssertGreaterThan(image.size.height / image.size.width, 1)
        let history = try XCTUnwrap(context.fetch(FetchDescriptor<DailyOutfit>()).first)
        XCTAssertEqual(history.pieces.count, 1)
        XCTAssertEqual(history.pieces.first?.itemID, id)
        XCTAssertEqual(history.pieces.first?.photo, red.photo)
        let receipt = try XCTUnwrap(context.fetch(FetchDescriptor<ImportedGarment>()).first { $0.key == "burgundy-u-tee" })
        XCTAssertEqual(receipt.photoRevision, 2)
        XCTAssertEqual(receipt.itemID, id)
        XCTAssertNotNil(UIImage(systemName: "washer"))
        context.delete(red)
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 1)
    }

    @MainActor
    func testPhotoRevisionDoesNotReplaceUserPhotoWithSameName() throws {
        let container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let photo = try makePhoto()
        let userPhoto = ClothingItem(name: "Burgundy Uniqlo U tee", category: .tops, photo: photo)
        context.insert(userPhoto)
        for garment in StarterWardrobe.garments { context.insert(ImportedGarment(key: garment.key)) }
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        XCTAssertEqual(userPhoto.photo, photo)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 1)
    }

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
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 36)
        let all = try context.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertEqual(all.filter { $0.category == .bottoms }.count, 8)
        XCTAssertTrue(all.allSatisfy { UIImage(data: $0.photo) != nil })
        context.delete(try XCTUnwrap(all.first))
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 35)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ImportedGarment>()), 36)
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
        XCTAssertEqual(pieces.count, 24)
        XCTAssertEqual(pieces.filter { $0.category == .bottoms }.count, 7)
        XCTAssertTrue(existing.needsWashing)
        XCTAssertEqual(existing.photo, originalPhoto)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ImportedGarment>()), 36)
        for garment in StarterWardrobe.garments.dropFirst(13) {
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
    func testNewImportsPreserveExistingOutfits() throws {
        let container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self, DailyOutfit.self, WornPiece.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let shirt = ClothingItem(name: "Saved shirt", category: .tops, photo: try makePhoto())
        context.insert(shirt)
        try DailyOutfit.save(items: [shirt], in: context)
        for garment in StarterWardrobe.garments.prefix(25) {
            context.insert(ImportedGarment(key: garment.key))
        }
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        try StarterWardrobe.importMissing(into: context)
        let pieces = try context.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertEqual(pieces.count, 12)
        XCTAssertTrue(shirt.needsWashing)
        let hat = try XCTUnwrap(pieces.first { $0.category == .hat })
        XCTAssertEqual(hat.categoryValue, "hat")
        XCTAssertFalse(hat.needsWashing)
        XCTAssertNotNil(UIImage(systemName: ClothingCategory.hat.symbol))
        let before = try XCTUnwrap(context.fetch(FetchDescriptor<DailyOutfit>()).first)
        XCTAssertEqual(before.pieces.map(\.itemID), [shirt.id])
        try DailyOutfit.save(items: [shirt, hat], in: context)
        let withHat = try XCTUnwrap(context.fetch(FetchDescriptor<DailyOutfit>()).first)
        XCTAssertEqual(withHat.pieces.count, 2)
        XCTAssertEqual(withHat.pieces.first { $0.categoryValue == "hat" }?.photo, hat.photo)
        XCTAssertTrue(hat.needsWashing)
        try DailyOutfit.save(items: [shirt], in: context)
        let withoutHat = try XCTUnwrap(context.fetch(FetchDescriptor<DailyOutfit>()).first)
        XCTAssertFalse(withoutHat.pieces.contains { $0.categoryValue == "hat" })
        // Updating today's outfit does not silently mark a worn piece clean.
        XCTAssertTrue(hat.needsWashing)
        hat.markWashed()
        XCTAssertFalse(hat.needsWashing)
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

/// Layout math for iPhone Duo poses. These run on any simulator, so they cover the fold logic
/// even on Xcode versions without an iPhone Duo simulator.
final class AdaptiveLayoutTests: XCTestCase {
    func testGridKeepsTwoColumnsOnAPhoneAndAddsColumnsAsItWidens() {
        XCTAssertEqual(ClosetMetrics.gridColumnCount(width: 0), 2)
        XCTAssertEqual(ClosetMetrics.gridColumnCount(width: 402), 2)
        XCTAssertEqual(ClosetMetrics.gridColumnCount(width: 440), 2)
        XCTAssertEqual(ClosetMetrics.gridColumnCount(width: 600), 3)
        XCTAssertEqual(ClosetMetrics.gridColumnCount(width: 900), 5)
        XCTAssertEqual(ClosetMetrics.gridColumnCount(width: 2000), ClosetMetrics.maximumGridColumns)
    }

    func testRailAndDetailSizesMatchThePhoneAndShrinkInNarrowPanes() {
        XCTAssertEqual(ClosetMetrics.railSlotWidth(width: 402), 402 * 0.405, accuracy: 0.001)
        XCTAssertEqual(ClosetMetrics.railSlotWidth(width: 300), 140)
        XCTAssertEqual(ClosetMetrics.railSlotWidth(width: 600), 190)
        XCTAssertEqual(ClosetMetrics.detailPhotoWidth(available: 0), 280)
        XCTAssertEqual(ClosetMetrics.detailPhotoWidth(available: 402), 280)
        XCTAssertEqual(ClosetMetrics.detailPhotoWidth(available: 250), 202)
        XCTAssertEqual(ClosetMetrics.detailPhotoWidth(available: 100), 160)
    }

    func testFlatSplitWithoutAHingeDividesDownTheMiddle() {
        let split = SplitGeometry.resolve(size: CGSize(width: 820, height: 980), divisions: [])
        XCTAssertEqual(split.axis, .sideBySide)
        XCTAssertFalse(split.isFolded)
        XCTAssertEqual(split.primary.width, 410)
        XCTAssertEqual(split.gap.width, 1)
        XCTAssertEqual(split.secondary.minX, 411)
        XCTAssertEqual(split.primary.width + split.gap.width + split.secondary.width, 820)
    }

    func testFlatSplitSitsOnTheInactiveHingeSoFoldingDoesNotMoveIt() {
        let hinge = CGRect(x: 400, y: 0, width: 0, height: 980)
        let flat = SplitGeometry.resolve(size: CGSize(width: 820, height: 980), divisions: [hinge])
        XCTAssertFalse(flat.isFolded)
        XCTAssertEqual(flat.primary.width, 400)

        let fold = CGRect(x: 392, y: 0, width: 16, height: 980)
        let folded = SplitGeometry.resolve(size: CGSize(width: 820, height: 980), divisions: [fold])
        XCTAssertTrue(folded.isFolded)
        XCTAssertEqual(folded.axis, .sideBySide)
        XCTAssertEqual(folded.primary, CGRect(x: 0, y: 0, width: 392, height: 980))
        XCTAssertEqual(folded.gap, fold)
        XCTAssertEqual(folded.secondary, CGRect(x: 408, y: 0, width: 412, height: 980))
    }

    func testCrossFoldStacksThePanes() {
        let fold = CGRect(x: 0, y: 402, width: 980, height: 16)
        let split = SplitGeometry.resolve(size: CGSize(width: 980, height: 820), divisions: [fold])
        XCTAssertTrue(split.isFolded)
        XCTAssertEqual(split.axis, .stacked)
        XCTAssertEqual(split.primary.height, 402)
        XCTAssertEqual(split.secondary.minY, 418)
        XCTAssertEqual(split.secondary.height, 402)
    }

    func testFoldsThatWouldLeaveAnUnusablePaneOrSitOutsideAreIgnored() {
        let size = CGSize(width: 820, height: 980)
        let nearEdge = SplitGeometry.resolve(size: size, divisions: [CGRect(x: 100, y: 0, width: 16, height: 980)])
        XCTAssertFalse(nearEdge.isFolded)
        XCTAssertEqual(nearEdge.primary.width, SplitGeometry.minimumPane)

        let outside = SplitGeometry.resolve(size: size, divisions: [CGRect(x: 2000, y: 0, width: 16, height: 980)])
        XCTAssertEqual(outside.primary.width, 410)
    }

    func testPanesStayClearOfAnActiveCameraOcclusion() {
        let pane = CGRect(x: 0, y: 0, width: 400, height: 900)
        let camera = CGRect(x: 150, y: 0, width: 100, height: 40)
        XCTAssertEqual(SplitGeometry.insets(for: pane, avoiding: [camera]).top, 40)
        XCTAssertEqual(SplitGeometry.insets(for: pane, avoiding: [CGRect(x: 500, y: 0, width: 100, height: 40)]),
                       EdgeInsets())
    }

    @MainActor
    func testOpeningAndClosingThePhoneKeepsTheOpenPiece() {
        let tee = ClothingItem(name: "Tee", category: .tops, photo: Data())
        let router = ClosetRouter()
        router.path = [.category(.tops), .piece(tee)]

        router.moveToSplit()
        XCTAssertEqual(router.browsePath, [.category(.tops)])
        XCTAssertEqual(router.selectedID, tee.id)
        XCTAssertTrue(router.path.isEmpty)

        router.moveToStack(items: [tee])
        XCTAssertEqual(router.path, [.category(.tops), .piece(tee)])
        XCTAssertNil(router.selectedID)
        XCTAssertTrue(router.browsePath.isEmpty)

        router.moveToSplit()
        router.moveToStack(items: [])
        XCTAssertEqual(router.path, [.category(.tops)], "A piece removed while open isn't pushed back")
    }
}
