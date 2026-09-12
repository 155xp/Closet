import XCTest

final class ClosetUITests: XCTestCase {
    @MainActor
    func testEmptyClosetNavigationAndAddSheet() {
        let app = XCUIApplication()
        app.launchArguments = ["--empty-closet"]
        app.launch()
        XCTAssertTrue(app.staticTexts["closetCount"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["closetCount"].label.hasPrefix("0 pieces"))
        app.buttons["addPieceButton"].tap()
        XCTAssertTrue(app.buttons["choosePhotoButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["savePieceButton"].isEnabled)
        app.textFields["pieceNameField"].tap()
        app.textFields["pieceNameField"].typeText("Everyday tee")
        app.buttons["cancelAddButton"].tap()
        XCTAssertTrue(app.staticTexts["closetCount"].label.hasPrefix("0 pieces"))

        app.buttons["category_tops"].tap()
        XCTAssertTrue(app.navigationBars["Tops"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["category_bottoms"].tap()
        XCTAssertTrue(app.navigationBars["Bottoms"].waitForExistence(timeout: 5))
        app.buttons["emptyAdd_bottoms"].tap()
        XCTAssertTrue(app.buttons["choosePhotoButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["pieceCategoryPicker"].label.contains("Bottoms"))
        app.buttons["cancelAddButton"].tap()
    }

    @MainActor
    func testAppearancePersistsAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--empty-closet"]
        app.launch()
        app.buttons["settingsButton"].tap()
        let picker = app.segmentedControls["appearancePicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.buttons["Dark"].tap()
        app.buttons["doneSettingsButton"].tap()
        app.terminate()
        app.launch()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(picker.buttons["Dark"].isSelected)
        picker.buttons["System"].tap()
        app.buttons["doneSettingsButton"].tap()
    }

    @MainActor
    func testPreparedWardrobeAppearsOnBothRails() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        let count = app.staticTexts["closetCount"]
        XCTAssertTrue(count.waitForExistence(timeout: 10))
        let populated = NSPredicate(format: "label BEGINSWITH '13 pieces'")
        expectation(for: populated, evaluatedWith: count)
        waitForExpectations(timeout: 10)
        app.buttons["Codex tee"].tap()
        XCTAssertTrue(app.staticTexts["Codex tee"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["category_bottoms"].tap()
        XCTAssertTrue(app.buttons["Blue jeans"].waitForExistence(timeout: 5))
        app.buttons["Blue jeans"].tap()
        XCTAssertTrue(app.staticTexts["Blue jeans"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFlickingRailStillOpensTheRevealedPiece() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        let rail = app.scrollViews["rail_tops"]
        rail.swipeLeft(velocity: .fast)
        rail.swipeLeft(velocity: .slow)
        // A flick can travel different distances across simulator frame rates.
        // Tap the shirt at the viewport center, not a fixed offscreen item.
        rail.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        XCTAssertTrue(app.navigationBars["Your piece"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testRapidRailReversalsKeepPiecesAttached() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        let rail = app.scrollViews["rail_tops"]
        XCTAssertTrue(rail.waitForExistence(timeout: 10))
        for _ in 0..<3 {
            rail.swipeLeft(velocity: .fast)
            rail.swipeRight(velocity: .fast)
        }
        let first = app.buttons["Codex tee"]
        XCTAssertTrue(first.isHittable)
        XCTAssertLessThan(abs(first.frame.minY - rail.frame.minY), 12)
        first.tap()
        XCTAssertTrue(app.navigationBars["Your piece"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaundryIndividualBatchWashAndUndo() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        for name in ["Codex tee", "Green striped polo"] {
            app.buttons[name].tap()
            let toggle = app.buttons["toggleWashButton"]
            XCTAssertTrue(toggle.waitForExistence(timeout: 5))
            XCTAssertTrue(toggle.label.contains("Put in laundry"))
            toggle.tap()
            XCTAssertTrue(toggle.label.contains("Mark washed"))
            app.navigationBars.buttons.firstMatch.tap()
        }
        XCTAssertTrue(app.buttons["laundryButton"].label.contains("2"))
        app.buttons["laundryButton"].tap()
        let codex = app.buttons["Mark Codex tee washed"]
        XCTAssertTrue(codex.waitForExistence(timeout: 5))
        let laundryScreenshot = XCTAttachment(screenshot: app.screenshot())
        laundryScreenshot.name = "Laundry"
        laundryScreenshot.lifetime = .keepAlways
        add(laundryScreenshot)
        codex.tap()
        XCTAssertFalse(codex.exists)
        app.buttons["undoWashButton"].tap()
        XCTAssertTrue(codex.waitForExistence(timeout: 5))
        app.buttons["washAllButton"].tap()
        XCTAssertTrue(app.staticTexts["All clean"].waitForExistence(timeout: 5))
        app.buttons["undoWashButton"].tap()
        XCTAssertTrue(codex.waitForExistence(timeout: 5))
        app.buttons["washAllButton"].tap()
        app.buttons["doneLaundryButton"].tap()
        XCTAssertFalse(app.buttons["laundryButton"].label.contains("2"))
        app.buttons["Codex tee"].tap()
        XCTAssertTrue(app.buttons["toggleWashButton"].label.contains("Put in laundry"))
    }

    @MainActor
    func testCategoryGridAndPhotoZoom() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        app.buttons["category_tops"].tap()
        let first = app.buttons["Codex tee"]
        let second = app.buttons["Green striped polo"]
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertEqual(first.frame.minY, second.frame.minY, accuracy: 3)
        XCTAssertLessThan(first.frame.midX, second.frame.midX)
        XCTAssertGreaterThan(app.buttons["Formula 1 tee"].frame.minY, first.frame.minY + 100)
        let grid = XCTAttachment(screenshot: app.screenshot())
        grid.name = "Tops grid"
        grid.lifetime = .keepAlways
        add(grid)
        first.tap()
        app.buttons["zoomPhotoButton"].tap()
        let photo = app.images["zoomablePhoto"]
        XCTAssertTrue(photo.waitForExistence(timeout: 5))
        XCTAssertEqual(photo.value as? String, "100 percent")
        photo.pinch(withScale: 2, velocity: 1)
        XCTAssertNotEqual(photo.value as? String, "100 percent")
        photo.doubleTap()
        XCTAssertEqual(photo.value as? String, "100 percent")
        app.buttons["photoZoomToggle"].tap()
        XCTAssertNotEqual(photo.value as? String, "100 percent")
        let zoom = XCTAttachment(screenshot: app.screenshot())
        zoom.name = "Zoomed photo"
        zoom.lifetime = .keepAlways
        add(zoom)
        app.buttons["closePhotoButton"].tap()
        XCTAssertTrue(app.buttons["toggleWashButton"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["category_bottoms"].tap()
        app.buttons["Blue jeans"].tap()
        app.buttons["zoomPhotoButton"].tap()
        XCTAssertTrue(photo.waitForExistence(timeout: 5))
        app.buttons["closePhotoButton"].tap()
    }

    @MainActor
    func testCameraPermissionRecoveryKeepsPhotoImportAvailable() {
        let app = XCUIApplication()
        app.launchArguments = ["--empty-closet"]
        app.resetAuthorizationStatus(for: .camera)
        app.launch()
        app.buttons["addPieceButton"].tap()
        app.buttons["takePhotoButton"].tap()
        let systemAlert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        if systemAlert.waitForExistence(timeout: 3) {
            systemAlert.buttons["Don’t Allow"].tap()
        }
        let denied = app.alerts["Allow camera access"]
        if denied.waitForExistence(timeout: 3) {
            XCTAssertTrue(denied.buttons["Open Settings"].exists)
            denied.buttons["Cancel"].tap()
        } else {
            XCTAssertTrue(app.alerts["Couldn't add this piece"].waitForExistence(timeout: 3))
            app.alerts.buttons["OK"].tap()
        }
        XCTAssertTrue(app.buttons["choosePhotoButton"].isEnabled)
        XCTAssertFalse(app.buttons["savePieceButton"].isEnabled)
        let addScreenshot = XCTAttachment(screenshot: app.screenshot())
        addScreenshot.name = "Add a piece"
        addScreenshot.lifetime = .keepAlways
        add(addScreenshot)
        app.buttons["cancelAddButton"].tap()
    }
}
