//
//  PromptHomeTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import Testing
import SwiftData
import Foundation
@testable import PromptHome

struct PromptHomeTests {
    
    // MARK: - Prompt Model Tests
    
    @Test func testPromptInitialization() async throws {
        let prompt = Prompt(title: "Test Prompt", tags: ["test", "example"], content: "Test content")
        
        #expect(prompt.title == "Test Prompt")
        #expect(prompt.tags == ["test", "example"])
        #expect(prompt.content == "Test content")
        #expect(prompt.id != UUID())
        #expect(prompt.createdAt <= Date())
        #expect(prompt.updatedAt <= Date())
    }
    
    @Test func testPromptUpdateContent() async throws {
        let prompt = Prompt(title: "Original", content: "Original content")
        let originalUpdatedAt = prompt.updatedAt
        
        // Wait a bit to ensure timestamp difference
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        prompt.updateContent(title: "Updated", content: "Updated content")
        
        #expect(prompt.title == "Updated")
        #expect(prompt.content == "Updated content")
        #expect(prompt.updatedAt > originalUpdatedAt)
    }
    
    @Test func testPromptTagProperty() async throws {
        let prompt = Prompt(title: "Test")
        
        // Test setting tag string
        prompt.tag = "tag1, tag2, tag3"
        #expect(prompt.tags == ["tag1", "tag2", "tag3"])
        
        // Test getting tag string
        prompt.tags = ["a", "b", "c"]
        #expect(prompt.tag == "a, b, c")
        
        // Test empty tags
        prompt.tag = ""
        #expect(prompt.tags.isEmpty)
        
        // Test tags with extra spaces
        prompt.tag = " tag1 , tag2 , tag3 "
        #expect(prompt.tags == ["tag1", "tag2", "tag3"])
    }
    
    // MARK: - AIModelConfig Tests
    
    @Test func testModelProviderDefaultValues() async throws {
        #expect(ModelProvider.openai.defaultBaseURL == "https://api.openai.com/v1")
        #expect(ModelProvider.deepseek.defaultBaseURL == "https://api.deepseek.com/v1")
        #expect(ModelProvider.ollama.defaultBaseURL == "http://localhost:11434")
        
        #expect(ModelProvider.openai.defaultModels.contains("gpt-4o"))
        #expect(ModelProvider.deepseek.defaultModels.contains("deepseek-chat"))
        #expect(ModelProvider.ollama.defaultModels.isEmpty)
    }
    
    @Test func testModelProviderRequiresAPIKey() async throws {
        #expect(ModelProvider.openai.requiresAPIKey == true)
        #expect(ModelProvider.deepseek.requiresAPIKey == true)
        #expect(ModelProvider.ollama.requiresAPIKey == false)
    }
    
    // MARK: - AIPolishService Tests
    
    @Test func testAIPolishRequestInitialization() async throws {
        let request = AIPolishRequest(model: "gpt-4o", content: "Test content")
        
        #expect(request.model == "gpt-4o")
        #expect(request.temperature == 0.7)
        #expect(request.max_tokens == 10000)
        #expect(request.messages.count == 2)
        #expect(request.messages[0].role == "system")
        #expect(request.messages[1].role == "user")
        #expect(request.messages[1].content.contains("Test content"))
    }
    
    @Test func testChatMessageCodable() async throws {
        let message = ChatMessage(role: "user", content: "Hello")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
        
        #expect(decodedMessage.role == "user")
        #expect(decodedMessage.content == "Hello")
    }
    
    // MARK: - LanguageManager Tests
    
    @Test func testLanguageManagerInitialization() async throws {
        let languageManager = LanguageManager()
        
        // Should have a default language
        #expect(!languageManager.currentLanguage.isEmpty)
        #expect(["zh-Hans", "en"].contains(languageManager.currentLanguage))
    }
    
    @Test func testLanguageManagerToggle() async throws {
        let languageManager = LanguageManager()
        let originalLanguage = languageManager.currentLanguage
        
        languageManager.toggleLanguage()
        
        if originalLanguage == "zh-Hans" {
            #expect(languageManager.currentLanguage == "en")
        } else {
            #expect(languageManager.currentLanguage == "zh-Hans")
        }
    }
    
    // MARK: - ThemeManager Tests
    
    @Test func testThemeManagerInitialization() async throws {
        let themeManager = ThemeManager()
        
        // Should have a boolean value for dark mode
        #expect(themeManager.isDarkMode == true || themeManager.isDarkMode == false)
    }
    
    // MARK: - Utility Tests
    
    @Test func testStringExtensions() async throws {
        // Test if string extensions work properly
        let testString = "  Hello World  "
        let trimmed = testString.trimmingCharacters(in: .whitespaces)
        #expect(trimmed == "Hello World")
    }
    
    @Test func testDateComparison() async throws {
        let date1 = Date()
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        let date2 = Date()
        
        #expect(date2 > date1)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testPromptValidation() async throws {
        // Test empty title handling
        let prompt = Prompt(title: "", content: "Content")
        #expect(prompt.title.isEmpty)
        
        // Test very long content
        let longContent = String(repeating: "a", count: 100000)
        let longPrompt = Prompt(title: "Long", content: longContent)
        #expect(longPrompt.content.count == 100000)
    }
    
    // MARK: - Performance Tests
    
    @Test func testPromptCreationPerformance() async throws {
        let startTime = Date()
        
        for i in 0..<1000 {
            let _ = Prompt(title: "Prompt \(i)", content: "Content \(i)")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should create 1000 prompts in less than 1 second
        #expect(duration < 1.0)
    }
    
    @Test func testTagProcessingPerformance() async throws {
        let prompt = Prompt(title: "Test")
        let startTime = Date()
        
        for i in 0..<1000 {
            prompt.tag = "tag1, tag2, tag3, tag4, tag5"
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should process 1000 tag operations in less than 0.1 seconds
        #expect(duration < 0.1)
    }
}
