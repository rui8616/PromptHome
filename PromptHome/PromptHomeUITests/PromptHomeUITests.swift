//
//  PromptHomeUITests.swift
//  PromptHomeUITests
//
//  Created by Rui on 2025/6/15.
//

import XCTest

final class PromptHomeUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic UI Tests
    
    func testAppLaunch() throws {
        // Test that the app launches successfully
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testMainInterfaceElements() throws {
        // Test that main interface elements are present
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists)
        
        // Wait for the interface to load
        sleep(2)
        
        // Take a screenshot for verification
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Main Interface"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testBasicInteraction() throws {
        // Wait for app to fully load
        sleep(3)
        
        // Try to interact with any available buttons or elements
        let buttons = app.buttons
        if buttons.count > 0 {
            let firstButton = buttons.firstMatch
            if firstButton.exists {
                firstButton.tap()
            }
        }
        
        // Take another screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "After Interaction"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
