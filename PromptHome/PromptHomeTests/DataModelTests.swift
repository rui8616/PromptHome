//
//  DataModelTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import XCTest
@testable import PromptHome

final class DataModelTests: XCTestCase {
    
    // MARK: - Prompt Model Tests
    
    func testPromptInitialization() {
        let prompt = Prompt(title: "Test Title", tags: ["test"], content: "Test Content")
        
        XCTAssertEqual(prompt.title, "Test Title")
        XCTAssertEqual(prompt.content, "Test Content")
        XCTAssertEqual(prompt.tags, ["test"])
        XCTAssertNotNil(prompt.id)
        XCTAssertNotNil(prompt.createdAt)
        XCTAssertNotNil(prompt.updatedAt)
    }
    
    func testPromptDefaultValues() {
        let prompt = Prompt(title: "")
        
        XCTAssertEqual(prompt.title, "")
        XCTAssertEqual(prompt.content, "")
        XCTAssertEqual(prompt.tags, [])
        XCTAssertNotNil(prompt.id)
        XCTAssertNotNil(prompt.createdAt)
        XCTAssertNotNil(prompt.updatedAt)
    }
    
    func testPromptUniqueIDs() {
        let prompt1 = Prompt(title: "Test 1", tags: ["tag1"], content: "Content 1")
        let prompt2 = Prompt(title: "Test 2", tags: ["tag2"], content: "Content 2")
        
        XCTAssertNotEqual(prompt1.id, prompt2.id)
    }
    
    func testPromptUpdateTimestamp() {
        let prompt = Prompt(title: "Original Title", tags: ["original"], content: "Original Content")
        let originalUpdatedAt = prompt.updatedAt
        
        // Simulate a small delay
        Thread.sleep(forTimeInterval: 0.01)
        
        prompt.updateContent(content: "Updated content")
        
        XCTAssertGreaterThan(prompt.updatedAt, originalUpdatedAt)
    }
    
    func testPromptCodable() throws {
        let originalPrompt = Prompt(title: "Codable Test", tags: ["test"], content: "Test Content")
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPrompt)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedPrompt = try decoder.decode(Prompt.self, from: data)
        
        XCTAssertEqual(originalPrompt.id, decodedPrompt.id)
        XCTAssertEqual(originalPrompt.title, decodedPrompt.title)
        XCTAssertEqual(originalPrompt.content, decodedPrompt.content)
        XCTAssertEqual(originalPrompt.tags, decodedPrompt.tags)
    }
    
    func testPromptEquality() {
        let prompt1 = Prompt(title: "Test", tags: ["tag"], content: "Content")
        let prompt2 = Prompt(title: "Test", tags: ["tag"], content: "Content")
        
        // Different instances should not be equal (different IDs)
        XCTAssertNotEqual(prompt1, prompt2)
        
        // Same instance should be equal to itself
        XCTAssertEqual(prompt1, prompt1)
    }
    
    func testPromptHashable() {
        let prompt1 = Prompt(title: "Test", tags: ["tag"], content: "Content")
        let prompt2 = Prompt(title: "Test", tags: ["tag"], content: "Content")
        
        let set = Set([prompt1, prompt2])
        XCTAssertEqual(set.count, 2) // Different IDs, so both should be in set
    }
    
    // MARK: - AIModelConfig Tests
    
    func testAIModelConfigInitialization() {
        let config = AIModelConfig(provider: .openai)
        
        XCTAssertEqual(config.provider, "OpenAI")
        XCTAssertEqual(config.apiKey, "")
        XCTAssertEqual(config.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(config.selectedModel, "gpt-4o")
        XCTAssertFalse(config.isActive)
    }
    
    func testAIModelConfigCustomInitialization() {
        let config = AIModelConfig(
            provider: .openai,
            baseURL: "https://api.openai.com/v1",
            apiKey: "test-key",
            selectedModel: "gpt-4o"
        )
        
        XCTAssertEqual(config.provider, "OpenAI")
        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertEqual(config.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(config.selectedModel, "gpt-4o")
        XCTAssertFalse(config.isActive)
    }
    
    func testAIModelConfigProperties() {
        let config = AIModelConfig(
            provider: .ollama,
            baseURL: "http://localhost:11434",
            apiKey: "test-key",
            selectedModel: "llama2"
        )
        
        XCTAssertEqual(config.provider, "Ollama")
        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertEqual(config.baseURL, "http://localhost:11434")
        XCTAssertEqual(config.selectedModel, "llama2")
        XCTAssertFalse(config.isActive)
    }
    
    // MARK: - ModelProvider Tests
    
    func testModelProviderCases() {
        XCTAssertEqual(ModelProvider.openai.rawValue, "OpenAI")
        XCTAssertEqual(ModelProvider.deepseek.rawValue, "Deepseek")
        XCTAssertEqual(ModelProvider.ollama.rawValue, "Ollama")
    }
    
    func testModelProviderDefaultURL() {
        XCTAssertEqual(ModelProvider.openai.defaultBaseURL, "https://api.openai.com/v1")
        XCTAssertEqual(ModelProvider.deepseek.defaultBaseURL, "https://api.deepseek.com/v1")
        XCTAssertEqual(ModelProvider.ollama.defaultBaseURL, "http://localhost:11434")
    }
    
    func testModelProviderDefaultModel() {
        XCTAssertEqual(ModelProvider.openai.defaultModels.first, "gpt-4o")
        XCTAssertEqual(ModelProvider.deepseek.defaultModels.first, "deepseek-chat")
        XCTAssertTrue(ModelProvider.ollama.defaultModels.isEmpty)
    }
    
    func testModelProviderCodable() throws {
        let providers: [ModelProvider] = [.openai, .deepseek, .ollama]
        
        for provider in providers {
            // Encode
            let encoder = JSONEncoder()
            let data = try encoder.encode(provider)
            
            // Decode
            let decoder = JSONDecoder()
            let decodedProvider = try decoder.decode(ModelProvider.self, from: data)
            
            XCTAssertEqual(provider, decodedProvider)
        }
    }
    
    // MARK: - Data Validation Tests
    
    func testPromptValidation() {
        // Test empty title
        let emptyTitlePrompt = Prompt(title: "", tags: ["tag"], content: "Content")
        XCTAssertEqual(emptyTitlePrompt.title, "")
        
        // Test empty content
        let emptyContentPrompt = Prompt(title: "Title", tags: ["tag"], content: "")
        XCTAssertEqual(emptyContentPrompt.content, "")
        
        // Test empty tags
        let emptyTagsPrompt = Prompt(title: "Title", tags: [], content: "Content")
        XCTAssertEqual(emptyTagsPrompt.tags, [])
    }
    
    func testAIModelConfigValidation() {
        // Test basic config creation
        let config = AIModelConfig(
            provider: .openai,
            baseURL: "https://api.openai.com/v1",
            apiKey: "test-key",
            selectedModel: "gpt-4o"
        )
        XCTAssertEqual(config.provider, "OpenAI")
        XCTAssertEqual(config.selectedModel, "gpt-4o")
        XCTAssertFalse(config.isActive)
    }
    
    // MARK: - Edge Cases Tests
    
    func testPromptWithSpecialCharacters() {
        let specialPrompt = Prompt(
            title: "🎉 Special Title with émojis and ñ characters",
            tags: ["symbols", "@#$%^&*()"],
            content: "Content with 中文 and العربية text"
        )
        
        XCTAssertEqual(specialPrompt.title, "🎉 Special Title with émojis and ñ characters")
        XCTAssertEqual(specialPrompt.content, "Content with 中文 and العربية text")
        XCTAssertEqual(specialPrompt.tags, ["symbols", "@#$%^&*()"])
    }
    
    func testPromptWithVeryLongContent() {
        let longContent = String(repeating: "This is a very long content. ", count: 1000)
        let longPrompt = Prompt(title: "Long Content Test", tags: ["test"], content: longContent)
        
        XCTAssertEqual(longPrompt.content, longContent)
        XCTAssertEqual(longPrompt.content.count, longContent.count)
    }
    
    func testAIModelConfigWithEmptyValues() {
        let emptyConfig = AIModelConfig(
            provider: .openai,
            baseURL: "",
            apiKey: "",
            selectedModel: ""
        )
        
        XCTAssertEqual(emptyConfig.provider, "OpenAI")
        XCTAssertEqual(emptyConfig.apiKey, "")
        XCTAssertEqual(emptyConfig.baseURL, "")
        XCTAssertEqual(emptyConfig.selectedModel, "")
        XCTAssertFalse(emptyConfig.isActive)
    }
    
    // MARK: - Performance Tests
    
    func testPromptCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let prompt = Prompt(
                    title: "Performance Test \(i)",
                    tags: ["performance"],
                    content: "Content for prompt \(i)"
                )
                _ = prompt.id
            }
        }
    }
    
    func testPromptEncodingPerformance() throws {
        let prompts = (0..<100).map { i in
            Prompt(
                title: "Performance Test \(i)",
                tags: ["performance"],
                content: "Content for prompt \(i)"
            )
        }
        
        measure {
            let encoder = JSONEncoder()
            for prompt in prompts {
                do {
                    _ = try encoder.encode(prompt)
                } catch {
                    XCTFail("Encoding failed: \(error)")
                }
            }
        }
    }
    
    func testAIModelConfigCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let config = AIModelConfig(
                    provider: .openai,
                    baseURL: "https://api.openai.com/v1",
                    apiKey: "test-key",
                    selectedModel: "gpt-4o"
                )
                _ = config.provider
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testPromptMemoryUsage() {
        // Create many prompts to test memory usage
        var prompts: [Prompt] = []
        
        for i in 0..<10000 {
            let prompt = Prompt(
                title: "Memory Test \(i)",
                tags: ["memory"],
                content: "Content \(i)"
            )
            prompts.append(prompt)
        }
        
        XCTAssertEqual(prompts.count, 10000)
        
        // Clear prompts
        prompts.removeAll()
        XCTAssertEqual(prompts.count, 0)
    }
    
    // MARK: - Thread Safety Tests
    
    func testPromptCreationThreadSafety() {
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for i in 0..<10 {
            queue.async {
                let prompt = Prompt(
                    title: "Thread Test \(i)",
                    tags: ["thread"],
                    content: "Content \(i)"
                )
                XCTAssertNotNil(prompt.id)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - JSON Compatibility Tests
    
    func testPromptJSONCompatibility() throws {
        let prompt = Prompt(title: "JSON Test", tags: ["test"], content: "Test Content")
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(prompt)
        
        // Convert to string and back
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let backToData = jsonString.data(using: .utf8)!
        
        // Decode back
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPrompt = try decoder.decode(Prompt.self, from: backToData)
        
        XCTAssertEqual(prompt.id, decodedPrompt.id)
        XCTAssertEqual(prompt.title, decodedPrompt.title)
        XCTAssertEqual(prompt.content, decodedPrompt.content)
        XCTAssertEqual(prompt.tags, decodedPrompt.tags)
    }
    
    func testAIModelConfigJSONCompatibility() throws {
        let config = AIModelConfig(
            provider: .openai,
            baseURL: "https://api.openai.com/v1",
            apiKey: "test-key",
            selectedModel: "gpt-4o"
        )
        
        // Test basic properties
        XCTAssertEqual(config.provider, "OpenAI")
        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertEqual(config.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(config.selectedModel, "gpt-4o")
        XCTAssertFalse(config.isActive)
        XCTAssertNotNil(config.id)
        XCTAssertNotNil(config.createdAt)
        XCTAssertNotNil(config.updatedAt)
    }
}
