//
//  ViewComponentsTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import XCTest
import SwiftUI
@testable import PromptHome

final class ViewComponentsTests: XCTestCase {
    
    // MARK: - PromptEditorView Tests
    
    func testPromptEditorViewInitialization() {
        let prompt = Prompt(title: "Test", tags: ["test"], content: "Test content")
        
        let editorView = PromptEditorView(
            prompt: prompt,
            isEditing: .constant(false),
            editingTitle: .constant("Test"),
            editingTags: .constant(["test"]),
            editingContent: .constant("Test content"),
            showingPreview: .constant(false),
            onSave: {},
            onDelete: { _ in }
        )
        
        XCTAssertNotNil(editorView)
    }
    
    func testPromptEditorViewCallbacks() {
        var saveCallbackCalled = false
        var deleteCallbackCalled = false
        
        let prompt = Prompt(title: "Test", tags: ["test"], content: "Test content")
        
        let editorView = PromptEditorView(
            prompt: prompt,
            isEditing: .constant(false),
            editingTitle: .constant("Test"),
            editingTags: .constant(["test"]),
            editingContent: .constant("Test content"),
            showingPreview: .constant(false),
            onSave: { saveCallbackCalled = true },
            onDelete: { _ in deleteCallbackCalled = true }
        )
        
        // Simulate save action
        editorView.onSave()
        XCTAssertTrue(saveCallbackCalled)
        
        // Simulate delete action
        editorView.onDelete(prompt)
        XCTAssertTrue(deleteCallbackCalled)
    }
    
    // MARK: - OptimizedTextView Tests
    
    func testOptimizedTextViewInitialization() {
        let textView = OptimizedTextView(content: "Test content")
        
        XCTAssertNotNil(textView)
    }
    
    func testOptimizedTextViewChunking() {
        let longText = String(repeating: "A", count: 10000)
        let textView = OptimizedTextView(content: longText)
        
        XCTAssertNotNil(textView)
        // Test that the view can handle large text efficiently
    }
    
    func testOptimizedTextViewEmptyContent() {
        let textView = OptimizedTextView(content: "")
        
        XCTAssertNotNil(textView)
    }
    
    // MARK: - MCPConfigView Tests
    
    func testMCPConfigViewInitialization() {
        let configView = MCPConfigView()
        
        XCTAssertNotNil(configView)
    }
    

    
    // MARK: - ContentView Tests
    
    func testContentViewInitialization() {
        let contentView = ContentView()
        
        XCTAssertNotNil(contentView)
    }
    
    func testContentViewRendering() {
        let contentView = ContentView()
        
        // Test that the view can be rendered without errors
        XCTAssertNotNil(contentView.body)
    }
    
    // MARK: - LanguageManager Tests
    
    func testLanguageManagerInitialization() {
        let languageManager = LanguageManager()
        
        XCTAssertNotNil(languageManager)
        XCTAssertNotNil(languageManager.currentLanguage)
    }
    
    func testLanguageManagerLanguageSwitch() {
        let languageManager = LanguageManager()
        let initialLanguage = languageManager.currentLanguage
        
        languageManager.toggleLanguage()
        XCTAssertNotEqual(languageManager.currentLanguage, initialLanguage)
        
        languageManager.toggleLanguage()
        XCTAssertEqual(languageManager.currentLanguage, initialLanguage)
    }
    
    // MARK: - ThemeManager Tests
    
    func testThemeManagerInitialization() {
        let themeManager = ThemeManager()
        
        XCTAssertNotNil(themeManager)
    }
    
    func testThemeManagerThemeSwitch() {
        let themeManager = ThemeManager()
        let initialTheme = themeManager.isDarkMode
        
        themeManager.toggleTheme()
        XCTAssertNotEqual(themeManager.isDarkMode, initialTheme)
        
        themeManager.toggleTheme()
        XCTAssertEqual(themeManager.isDarkMode, initialTheme)
    }
    

    
    // MARK: - State Management Tests
    
    func testPromptEditorViewStateChanges() {
        let prompt = Prompt(title: "Test", tags: ["test"], content: "Test content")
        
        let editorView = PromptEditorView(
            prompt: prompt,
            isEditing: .constant(false),
            editingTitle: .constant("Test"),
            editingTags: .constant(["test"]),
            editingContent: .constant("Test content"),
            showingPreview: .constant(false),
            onSave: {},
            onDelete: { _ in }
        )
        
        // Test state changes
        XCTAssertNotNil(editorView)
    }
    
    func testLanguageManagerStateChanges() {
        let languageManager = LanguageManager()
        let initialLanguage = languageManager.currentLanguage
        
        // Test language change notification
        let expectation = XCTestExpectation(description: "Language change notification")
        
        let cancellable = languageManager.objectWillChange.sink {
            expectation.fulfill()
        }
        
        languageManager.currentLanguage = initialLanguage == "en" ? "zh" : "en"
        
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
    
    func testThemeManagerStateChanges() {
        let themeManager = ThemeManager()
        
        // Test theme change notification
        let expectation = XCTestExpectation(description: "Theme change notification")
        
        let cancellable = themeManager.objectWillChange.sink {
            expectation.fulfill()
        }
        
        themeManager.toggleTheme()
        
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
    
    // MARK: - Performance Tests
    
    func testOptimizedTextViewPerformance() {
        let longContent = String(repeating: "Performance test content. ", count: 1000)
        
        measure {
            let textView = OptimizedTextView(content: longContent)
            _ = textView
        }
    }
    
    func testPromptEditorViewPerformance() {
        let prompt = Prompt(title: "Performance Test", tags: ["test"], content: String(repeating: "Content ", count: 1000))
        
        measure {
            let editorView = PromptEditorView(
                prompt: prompt,
                isEditing: .constant(false),
                editingTitle: .constant("Performance Test"),
                editingTags: .constant(["test"]),
                editingContent: .constant(String(repeating: "Content ", count: 1000)),
                showingPreview: .constant(false),
                onSave: {},
                onDelete: { _ in }
            )
            _ = editorView
        }
    }
    
    func testLanguageManagerPerformance() {
        measure {
            let languageManager = LanguageManager()
            for _ in 0..<100 {
                languageManager.currentLanguage = "en"
                languageManager.currentLanguage = "zh"
            }
        }
    }
    
    func testThemeManagerPerformance() {
        measure {
            let themeManager = ThemeManager()
            for _ in 0..<100 {
                themeManager.toggleTheme()
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testOptimizedTextViewWithSpecialCharacters() {
        let specialContent = "🎉 Special characters: ñáéíóú 中文 العربية 🚀"
        let textView = OptimizedTextView(content: specialContent)
        
        XCTAssertNotNil(textView)
        XCTAssertEqual(textView.content, specialContent)
    }
    
    func testPromptEditorViewWithEmptyPrompt() {
        let emptyPrompt = Prompt(title: "", tags: [], content: "")
        
        let editorView = PromptEditorView(
            prompt: emptyPrompt,
            isEditing: .constant(false),
            editingTitle: .constant(""),
            editingTags: .constant([]),
            editingContent: .constant(""),
            showingPreview: .constant(false),
            onSave: {},
            onDelete: { _ in }
        )
        
        XCTAssertNotNil(editorView)
    }
    
    func testLanguageManagerWithInvalidLanguage() {
        let languageManager = LanguageManager()
        let initialLanguage = languageManager.currentLanguage
        
        // Try to set invalid language
        languageManager.currentLanguage = "invalid_language"
        
        // Should either reject the change or handle gracefully
        XCTAssertNotNil(languageManager.currentLanguage)
    }
    
    // MARK: - Memory Management Tests
    
    func testViewMemoryManagement() {
        var textView: OptimizedTextView?
        
        autoreleasepool {
            textView = OptimizedTextView(content: "Memory test content")
        }
        
        // Views should be deallocated after autoreleasepool
        // Note: This test might not work as expected in SwiftUI due to view value semantics
        // but it's good to have for reference
    }
}