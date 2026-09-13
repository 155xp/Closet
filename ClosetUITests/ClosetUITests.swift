import XCTest

final class ClosetUITests: XCTestCase {
    @MainActor
    func testHatCategoryAndOptionalOutfitCalendar() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        let heading = app.buttons["category_hat"]
        for _ in 0..<5 {
            if heading.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(heading.isHittable)
        heading.tap()
        XCTAssertTrue(app.navigationBars["hat"].waitForExistence(timeout: 5))
        app.buttons["Hammer the Over cap"].tap()
        XCTAssertTrue(app.buttons["zoomPhotoButton"].waitForExistence(timeout: 5))
        let detail = XCTAttachment(screenshot: app.screenshot())
        detail.name = "Hat detail"
        detail.lifetime = .keepAlways
        add(detail)
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["addPieceButton"].tap()
        app.buttons["pieceCategoryPicker"].tap()
        app.buttons.matching(NSPredicate(format: "label == 'hat' AND identifier != 'category_hat'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["pieceCategoryPicker"].label.contains("hat"))
        app.buttons["cancelAddButton"].tap()
        app.buttons["wardrobeButton"].tap()
        let hats = app.scrollViews["wardrobe_hat"]
        XCTAssertTrue(hats.waitForExistence(timeout: 5))
        XCTAssertEqual(hats.value as? String, "No hat")
        hats.swipeLeft(velocity: .slow)
        XCTAssertEqual(hats.value as? String, "1 of 1")
        let outfit = XCTAttachment(screenshot: app.screenshot())
        outfit.name = "Outfit with optional hat"
        outfit.lifetime = .keepAlways
        add(outfit)
        app.buttons["wearTodayButton"].tap()
        app.buttons["doneWardrobeButton"].tap()
        XCTAssertEqual(app.buttons["laundryButton"].value as? String, "3 items to wash")
        app.buttons["calendarButton"].tap()
        XCTAssertTrue(app.images["calendarPhoto_hat"].waitForExistence(timeout: 5))
        let calendar = XCTAttachment(screenshot: app.screenshot())
        calendar.name = "Calendar with hat"
        calendar.lifetime = .keepAlways
        add(calendar)
        app.buttons["doneCalendarButton"].tap()
        app.buttons["wardrobeButton"].tap()
        XCTAssertEqual(hats.value as? String, "1 of 1")
        hats.swipeRight(velocity: .slow)
        XCTAssertEqual(hats.value as? String, "No hat")
        app.buttons["wearTodayButton"].tap()
        app.buttons["doneWardrobeButton"].tap()
        app.buttons["calendarButton"].tap()
        XCTAssertTrue(app.images["calendarPhoto_tops"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["calendarPhoto_hat"].exists)
    }

    @MainActor
    func testAppIconChoicesPersistAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--empty-closet"]
        app.launch()
        app.buttons["settingsButton"].tap()

        func dismissIconNotice() {
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            if springboard.alerts.firstMatch.waitForExistence(timeout: 2) {
                springboard.alerts.buttons["OK"].tap()
            } else if app.alerts.firstMatch.exists {
                XCTAssertFalse(app.alerts["Couldn't change the app icon"].exists)
                app.alerts.buttons["OK"].tap()
            }
        }

        for choice in ["light", "dark"] {
            let button = app.buttons["appIcon_\(choice)"]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            button.tap()
            dismissIconNotice()
            let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == 'Selected'"), object: button)
            XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 10), .completed)
            if choice == "dark" {
                let settings = XCTAttachment(screenshot: app.screenshot())
                settings.name = "Settings icon choices"
                settings.lifetime = .keepAlways
                add(settings)
                XCUIDevice.shared.press(.home)
                let home = XCTAttachment(screenshot: XCUIApplication(bundleIdentifier: "com.apple.springboard").screenshot())
                home.name = "Dark app icon on the Home Screen"
                home.lifetime = .keepAlways
                add(home)
            }
            app.terminate()
            app.launch()
            app.buttons["settingsButton"].tap()
            XCTAssertEqual(app.buttons["appIcon_\(choice)"].value as? String, "Selected")
        }
        app.buttons["appIcon_automatic"].tap()
        dismissIconNotice()
        let automatic = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == 'Selected'"),
                                                  object: app.buttons["appIcon_automatic"])
        XCTAssertEqual(XCTWaiter.wait(for: [automatic], timeout: 10), .completed)
    }

    @MainActor
    func testWearingOutfitAddsLaundryAndBadgeTracksWashing() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        let laundry = app.buttons["laundryButton"]
        XCTAssertEqual(laundry.value as? String, "0 items to wash")
        app.buttons["wardrobeButton"].tap()
        let wear = app.buttons["wearTodayButton"]
        XCTAssertTrue(wear.waitForExistence(timeout: 5))
        wear.tap()
        app.buttons["doneWardrobeButton"].tap()
        XCTAssertEqual(laundry.value as? String, "2 items to wash")
        let badge = XCTAttachment(screenshot: app.screenshot())
        badge.name = "Laundry badge after wearing an outfit"
        badge.lifetime = .keepAlways
        add(badge)

        app.buttons["wardrobeButton"].tap()
        wear.tap()
        app.buttons["doneWardrobeButton"].tap()
        XCTAssertEqual(laundry.value as? String, "2 items to wash", "Wearing the same pieces must not double-count them")
        laundry.tap()
        XCTAssertTrue(app.buttons["Mark Green striped polo washed"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Mark Brown Hollister sweatpants washed"].exists)
        XCTAssertFalse(app.buttons["Mark Black On sneakers washed"].exists)
        app.buttons["Mark Green striped polo washed"].tap()
        app.buttons["doneLaundryButton"].tap()
        XCTAssertEqual(laundry.value as? String, "1 item to wash")
        laundry.tap()
        app.buttons["washAllButton"].tap()
        XCTAssertTrue(app.staticTexts["All clean"].waitForExistence(timeout: 5))
        app.buttons["undoWashButton"].tap()
        app.buttons["doneLaundryButton"].tap()
        XCTAssertEqual(laundry.value as? String, "1 item to wash")
        laundry.tap()
        app.buttons["washAllButton"].tap()
        app.buttons["doneLaundryButton"].tap()
        XCTAssertEqual(laundry.value as? String, "0 items to wash")
        let clean = XCTAttachment(screenshot: app.screenshot())
        clean.name = "Laundry badge clears when everything is washed"
        clean.lifetime = .keepAlways
        add(clean)
    }

    @MainActor
    func testWearTodayUpdateHistoryAndWeeklyCalendar() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        app.buttons["wardrobeButton"].tap()
        let topHistory = app.staticTexts["wearHistory_tops"]
        let bottomHistory = app.staticTexts["wearHistory_bottoms"]
        XCTAssertTrue(topHistory.waitForExistence(timeout: 5))
        XCTAssertEqual(topHistory.label, "Haven't worn yet")
        XCTAssertEqual(bottomHistory.label, "Haven't worn yet")
        let save = app.buttons["wearTodayButton"]
        XCTAssertEqual(save.label, "Wear this today")
        save.tap()
        XCTAssertEqual(save.label, "Update today")
        XCTAssertEqual(topHistory.label, "Worn today")
        XCTAssertEqual(bottomHistory.label, "Worn today")
        app.scrollViews["wardrobe_tops"].swipeRight(velocity: .slow)
        XCTAssertEqual(topHistory.label, "Haven't worn yet")
        save.tap()
        XCTAssertEqual(topHistory.label, "Worn today")
        let wardrobe = XCTAttachment(screenshot: app.screenshot())
        wardrobe.name = "Wear history and update today"
        wardrobe.lifetime = .keepAlways
        add(wardrobe)
        app.buttons["doneWardrobeButton"].tap()
        app.buttons["calendarButton"].tap()
        let shirt = app.images["calendarPhoto_tops"].firstMatch
        XCTAssertTrue(shirt.waitForExistence(timeout: 5))
        XCTAssertEqual(shirt.label, "Codex tee")
        XCTAssertTrue(app.images["calendarPhoto_bottoms"].firstMatch.exists)
        XCTAssertTrue(app.images["calendarPhoto_shoes"].firstMatch.exists)
        let calendar = XCTAttachment(screenshot: app.screenshot())
        calendar.name = "Weekly outfit calendar"
        calendar.lifetime = .keepAlways
        add(calendar)
        let title = app.staticTexts["calendarWeekTitle"]
        let initialWeek = title.label
        app.swipeRight(velocity: .slow)
        XCTAssertNotEqual(title.label, initialWeek)
        XCTAssertFalse(app.images["calendarPhoto_tops"].firstMatch.isHittable)
        app.swipeLeft(velocity: .slow)
        XCTAssertEqual(title.label, initialWeek)
        XCTAssertTrue(shirt.isHittable)
        app.swipeLeft(velocity: .slow)
        XCTAssertNotEqual(title.label, initialWeek)
        app.buttons["calendarTodayButton"].tap()
        XCTAssertEqual(title.label, initialWeek)
        XCTAssertTrue(shirt.isHittable)
        app.buttons["doneCalendarButton"].tap()
        app.buttons["wardrobeButton"].tap()
        XCTAssertEqual(app.scrollViews["wardrobe_tops"].value as? String, "1 of 24")
        XCTAssertEqual(app.buttons["wearTodayButton"].label, "Update today")
    }

    @MainActor
    func testEmptyOutfitCannotBeSaved() {
        let app = XCUIApplication()
        app.launchArguments = ["--empty-closet"]
        app.launch()
        app.buttons["wardrobeButton"].tap()
        XCTAssertTrue(app.buttons["wearTodayButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["wearTodayButton"].isEnabled)
    }

    @MainActor
    func testShoesAppearInClosetAndOutfitWithoutLaundryControls() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        let shoesHeading = app.buttons["category_shoes"]
        for _ in 0..<5 {
            if shoesHeading.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(shoesHeading.isHittable)
        let home = XCTAttachment(screenshot: app.screenshot())
        home.name = "Shoes on the main closet"
        home.lifetime = .keepAlways
        add(home)
        shoesHeading.tap()
        app.buttons["Taupe shearling clogs"].tap()
        XCTAssertTrue(app.buttons["zoomPhotoButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["toggleWashButton"].exists)
        XCTAssertFalse(app.staticTexts["washStatus"].exists)
        app.buttons["zoomPhotoButton"].tap()
        XCTAssertTrue(app.images["zoomablePhoto"].waitForExistence(timeout: 5))
        app.buttons["closePhotoButton"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["wardrobeButton"].tap()
        let shoes = app.scrollViews["wardrobe_shoes"]
        let tops = app.scrollViews["wardrobe_tops"]
        let bottoms = app.scrollViews["wardrobe_bottoms"]
        XCTAssertTrue(shoes.waitForExistence(timeout: 5))
        XCTAssertEqual(shoes.value as? String, "2 of 2")
        let topSelection = tops.value as? String
        let bottomSelection = bottoms.value as? String
        shoes.swipeRight(velocity: .slow)
        XCTAssertEqual(shoes.value as? String, "1 of 2")
        XCTAssertEqual(tops.value as? String, topSelection)
        XCTAssertEqual(bottoms.value as? String, bottomSelection)
        let outfit = XCTAttachment(screenshot: app.screenshot())
        outfit.name = "Outfit with shoes"
        outfit.lifetime = .keepAlways
        add(outfit)
        app.buttons["doneWardrobeButton"].tap()
        app.buttons["laundryButton"].tap()
        XCTAssertTrue(app.staticTexts["All clean"].waitForExistence(timeout: 5))
        app.buttons["doneLaundryButton"].tap()
        app.buttons["addPieceButton"].tap()
        let picker = app.buttons["pieceCategoryPicker"]
        picker.tap()
        app.buttons.matching(NSPredicate(format: "label == 'shoes' AND identifier != 'category_shoes'")).firstMatch.tap()
        XCTAssertFalse(app.switches["newPieceNeedsWashing"].exists)
    }

    @MainActor
    func testWardrobeSwipesRowsIndependently() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        app.buttons["wardrobeButton"].tap()
        let tops = app.scrollViews["wardrobe_tops"]
        let bottoms = app.scrollViews["wardrobe_bottoms"]
        XCTAssertTrue(tops.waitForExistence(timeout: 5))
        XCTAssertTrue(bottoms.exists)
        XCTAssertEqual(tops.value as? String, "2 of 24")
        XCTAssertEqual(bottoms.value as? String, "2 of 8")
        XCTAssertFalse(app.staticTexts["Green striped polo"].exists)
        XCTAssertFalse(app.scrollViews["rail_tops"].isHittable)

        let initial = XCTAttachment(screenshot: app.screenshot())
        initial.name = "Wardrobe outfit"
        initial.lifetime = .keepAlways
        add(initial)

        tops.swipeLeft(velocity: .slow)
        XCTAssertNotEqual(tops.value as? String, "2 of 24")
        XCTAssertEqual(bottoms.value as? String, "2 of 8")
        let topSelection = tops.value as? String
        bottoms.swipeLeft(velocity: .slow)
        XCTAssertNotEqual(bottoms.value as? String, "2 of 8")
        XCTAssertEqual(tops.value as? String, topSelection)

        let changed = XCTAttachment(screenshot: app.screenshot())
        changed.name = "Wardrobe after swiping both rows"
        changed.lifetime = .keepAlways
        add(changed)
        app.buttons["doneWardrobeButton"].tap()
        XCTAssertTrue(app.buttons["laundryButton"].waitForExistence(timeout: 5))
        app.buttons["laundryButton"].tap()
        XCTAssertTrue(app.staticTexts["All clean"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEmptyWardrobeCanAddEitherCategory() {
        let app = XCUIApplication()
        app.launchArguments = ["--empty-closet"]
        app.launch()
        app.buttons["wardrobeButton"].tap()
        for category in ["tops", "bottoms", "shoes", "hat"] {
            let add = app.buttons["wardrobeAdd_\(category)"]
            XCTAssertTrue(add.waitForExistence(timeout: 5))
            add.tap()
            XCTAssertTrue(app.buttons["choosePhotoButton"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["pieceCategoryPicker"].label.contains(category))
            app.buttons["cancelAddButton"].tap()
        }
        app.buttons["doneWardrobeButton"].tap()
        XCTAssertTrue(app.buttons["wardrobeButton"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEmptyClosetNavigationAndAddSheet() {
        let app = XCUIApplication()
        app.launchArguments = ["--empty-closet"]
        app.launch()
        XCTAssertTrue(app.buttons["emptyAdd_tops"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["closetCount"].exists)
        app.buttons["addPieceButton"].tap()
        XCTAssertTrue(app.buttons["choosePhotoButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["savePieceButton"].isEnabled)
        app.textFields["pieceNameField"].tap()
        app.textFields["pieceNameField"].typeText("Everyday tee")
        app.buttons["cancelAddButton"].tap()
        XCTAssertTrue(app.buttons["emptyAdd_tops"].waitForExistence(timeout: 5))

        app.buttons["category_tops"].tap()
        XCTAssertTrue(app.navigationBars["tops"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["category_bottoms"].tap()
        XCTAssertTrue(app.navigationBars["bottoms"].waitForExistence(timeout: 5))
        app.buttons["emptyAdd_bottoms"].tap()
        XCTAssertTrue(app.buttons["choosePhotoButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["pieceCategoryPicker"].label.contains("bottoms"))
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
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["closetCount"].exists)
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
    func testLastPiecesSnapToTheSameColumn() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        let columnX = app.buttons["Codex tee"].frame.minX

        for (category, lastName) in [("tops", "Guinness sweatshirt"), ("bottoms", "Brown baggy trousers")] {
            let rail = app.scrollViews["rail_\(category)"]
            let addButton = rail.buttons["Add to \(category)"]
            for _ in 0..<14 {
                if addButton.exists && addButton.frame.maxX <= rail.frame.maxX { break }
                rail.swipeLeft(velocity: .fast)
            }
            // Scroll all the way to the boundary, including another drag against it.
            rail.swipeLeft(velocity: .slow)
            rail.swipeLeft(velocity: .slow)
            let last = rail.buttons[lastName]
            XCTAssertTrue(last.isHittable)
            XCTAssertEqual(last.frame.minX, columnX, accuracy: 2,
                           "The last \(category) piece must align with the initial outfit column")
            XCTAssertLessThanOrEqual(last.frame.maxX, rail.frame.maxX)
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Last top and bottom aligned"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Guinness sweatshirt"].tap()
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
        XCTAssertTrue(app.buttons["Codex tee"].waitForExistence(timeout: 10))
        app.buttons["Codex tee"].tap()
        app.buttons["toggleWashButton"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["category_tops"].tap()
        let first = app.buttons["Codex tee"]
        let second = app.buttons["Green striped polo"]
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertEqual(first.frame.minY, second.frame.minY, accuracy: 3)
        XCTAssertEqual(first.frame.height, second.frame.height, accuracy: 1)
        XCTAssertEqual(first.frame.width, second.frame.width, accuracy: 1)
        XCTAssertEqual(first.value as? String, "Needs washing")
        XCTAssertFalse(app.staticTexts["Codex tee"].exists)
        XCTAssertFalse(app.staticTexts["Needs washing"].exists)
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
        let jeans = app.buttons["Blue jeans"]
        let sweatpants = app.buttons["Brown Hollister sweatpants"]
        XCTAssertEqual(jeans.frame.minY, sweatpants.frame.minY, accuracy: 1)
        XCTAssertEqual(jeans.frame.height, sweatpants.frame.height, accuracy: 1)
        XCTAssertFalse(app.staticTexts["Blue jeans"].exists)
        let bottomsGrid = XCTAttachment(screenshot: app.screenshot())
        bottomsGrid.name = "Bottoms grid"
        bottomsGrid.lifetime = .keepAlways
        add(bottomsGrid)
        app.buttons["Blue jeans"].tap()
        app.buttons["zoomPhotoButton"].tap()
        XCTAssertTrue(photo.waitForExistence(timeout: 5))
        app.buttons["closePhotoButton"].tap()
    }

    @MainActor
    func testNewBatchAppearsInBothCategories() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        app.buttons["category_tops"].tap()
        let sweatshirt = app.buttons["Virginia Tech sweatshirt"]
        for _ in 0..<5 {
            if sweatshirt.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(sweatshirt.isHittable)
        let tops = XCTAttachment(screenshot: app.screenshot())
        tops.name = "New tops"
        tops.lifetime = .keepAlways
        add(tops)
        sweatshirt.tap()
        XCTAssertTrue(app.buttons["zoomPhotoButton"].waitForExistence(timeout: 5))
        app.buttons["zoomPhotoButton"].tap()
        XCTAssertTrue(app.images["zoomablePhoto"].waitForExistence(timeout: 5))
        app.buttons["closePhotoButton"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["category_bottoms"].tap()
        XCTAssertTrue(app.buttons["Brown Hollister sweatpants"].waitForExistence(timeout: 5))
        let jeans = app.buttons["Washed black jeans"]
        XCTAssertTrue(jeans.isHittable)
        let bottoms = XCTAttachment(screenshot: app.screenshot())
        bottoms.name = "New bottoms"
        bottoms.lifetime = .keepAlways
        add(bottoms)
        jeans.tap()
        XCTAssertTrue(app.buttons["toggleWashButton"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHoodiesOnRail() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-wardrobe"]
        app.launch()
        let rail = app.scrollViews["rail_tops"]
        XCTAssertTrue(rail.waitForExistence(timeout: 10))
        for name in ["Heather gray hoodie", "Washed charcoal hoodie"] {
            let hoodie = app.buttons[name]
            for _ in 0..<14 {
                if hoodie.exists && hoodie.frame.minX >= rail.frame.minX
                    && hoodie.frame.maxX <= rail.frame.maxX { break }
                rail.swipeLeft(velocity: .slow)
            }
            XCTAssertTrue(hoodie.isHittable)
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
            hoodie.tap()
            XCTAssertTrue(app.navigationBars["Your piece"].waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
        }
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
