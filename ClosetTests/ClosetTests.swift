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
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 23)
        let all = try context.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertEqual(all.filter { $0.category == .bottoms }.count, 6)
        XCTAssertTrue(all.allSatisfy { UIImage(data: $0.photo) != nil })
        context.delete(try XCTUnwrap(all.first))
        try context.save()
        try StarterWardrobe.importMissing(into: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), 22)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ImportedGarment>()), 23)
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
        XCTAssertEqual(pieces.count, 11)
        XCTAssertEqual(pieces.filter { $0.category == .bottoms }.count, 5)
        XCTAssertTrue(existing.needsWashing)
        XCTAssertEqual(existing.photo, originalPhoto)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ImportedGarment>()), 23)
        for garment in StarterWardrobe.garments.suffix(10) {
            let piece = try XCTUnwrap(pieces.first { $0.name == garment.name })
            XCTAssertFalse(piece.needsWashing)
            XCTAssertNotNil(UIImage(data: piece.photo))
        }
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
