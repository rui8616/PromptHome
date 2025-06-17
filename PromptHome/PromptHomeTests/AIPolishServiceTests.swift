//
//  AIPolishServiceTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import XCTest
import Foundation
@testable import PromptHome

class AIPolishServiceTests: XCTestCase {
    
    // MARK: - AIPolishRequest Tests
    
    func testAIPolishRequestInitialization() async throws {
        let request = AIPolishRequest(model: "gpt-4o", content: "Test content")
        
        XCTAssertEqual(request.model, "gpt-4o")
        XCTAssertEqual(request.temperature, 0.7)
        XCTAssertEqual(request.max_tokens, 10000)
        XCTAssertEqual(request.messages.count, 2)
        XCTAssertEqual(request.messages[0].role, "system")
        XCTAssertEqual(request.messages[1].role, "user")
        XCTAssertTrue(request.messages[1].content.contains("Test content"))
    }
    
    func testAIPolishRequestSystemMessage() async throws {
        let request = AIPolishRequest(model: "gpt-4o", content: "Test")
        let systemMessage = request.messages[0]
        
        XCTAssertEqual(systemMessage.role, "system")
        XCTAssertTrue(systemMessage.content.contains("专业的提示词优化专家"))
        XCTAssertTrue(systemMessage.content.contains("优化"))
        XCTAssertTrue(systemMessage.content.contains("改进"))
    }
    
    func testAIPolishRequestUserMessage() async throws {
        let testContent = "This is a test prompt that needs polishing"
        let request = AIPolishRequest(model: "gpt-4o", content: testContent)
        let userMessage = request.messages[1]
        
        XCTAssertEqual(userMessage.role, "user")
        XCTAssertTrue(userMessage.content.contains(testContent))
        XCTAssertTrue(userMessage.content.contains("请优化以下提示词"))
    }
    
    func testAIPolishRequestCodable() async throws {
        let request = AIPolishRequest(model: "gpt-4o", content: "Test content")
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        XCTAssertGreaterThan(data.count, 0)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedRequest = try decoder.decode(AIPolishRequest.self, from: data)
        
        XCTAssertEqual(decodedRequest.model, request.model)
        XCTAssertEqual(decodedRequest.temperature, request.temperature)
        XCTAssertEqual(decodedRequest.max_tokens, request.max_tokens)
        XCTAssertEqual(decodedRequest.messages.count, request.messages.count)
    }
    
    // MARK: - AIPolishResponse Tests
    
    func testAIPolishResponseCodable() async throws {
        let jsonString = """
        {
            "choices": [
                {
                    "message": {
                        "role": "assistant",
                        "content": "This is a polished prompt."
                    }
                }
            ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AIPolishResponse.self, from: data)
        
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].message.role, "assistant")
        XCTAssertEqual(response.choices[0].message.content, "This is a polished prompt.")
    }
    
    func testAIPolishResponseWithEmptyChoices() async throws {
        let jsonString = """
        {
            "choices": []
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AIPolishResponse.self, from: data)
        
        XCTAssertTrue(response.choices.isEmpty)
    }
    
    // MARK: - ChatMessage Tests
    
    func testChatMessageInitialization() async throws {
        let message = ChatMessage(role: "user", content: "Test message")
        
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Test message")
    }
    
    func testChatMessageCodable() async throws {
        let message = ChatMessage(role: "assistant", content: "AI response")
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        XCTAssertGreaterThan(data.count, 0)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
        
        XCTAssertEqual(decodedMessage.role, message.role)
        XCTAssertEqual(decodedMessage.content, message.content)
    }
    
    // MARK: - AIPolishService Tests
    
    func testAIPolishServiceInitialization() async throws {
        let service = AIPolishService()
        
        // Service should be initialized successfully
        XCTAssertNotNil(service)
    }
    
    func testAIPolishRequestCreation() async throws {
        let service = AIPolishService()
        let content = "Test prompt content"
        
        // This would typically test the request creation logic
        // For now, we'll test that we can create a request with the expected structure
        let request = AIPolishRequest(model: "gpt-4o", content: content)
        
        XCTAssertEqual(request.messages.count, 2)
        XCTAssertEqual(request.messages[0].role, "system")
        XCTAssertEqual(request.messages[1].role, "user")
        XCTAssertTrue(request.messages[1].content.contains(content))
    }
    
    // MARK: - Edge Cases Tests
    
    func testAIPolishRequestWithEmptyContent() async throws {
        let request = AIPolishRequest(model: "gpt-4o", content: "")
        
        XCTAssertEqual(request.messages.count, 2)
        XCTAssertEqual(request.messages[0].role, "system")
        XCTAssertEqual(request.messages[1].role, "user")
        // The user message should still contain the template text even with empty content
        XCTAssertTrue(request.messages[1].content.contains("请优化以下提示词"))
    }
    
    func testAIPolishRequestWithLongContent() async throws {
        let longContent = String(repeating: "This is a very long prompt content that exceeds normal limits. ", count: 100)
        let request = AIPolishRequest(model: "gpt-4o", content: longContent)
        
        XCTAssertEqual(request.messages.count, 2)
        XCTAssertTrue(request.messages[1].content.contains(longContent))
        XCTAssertGreaterThan(request.messages[1].content.count, 1000)
    }
    
    func testAIPolishRequestWithSpecialCharacters() async throws {
        let specialContent = "Test with special chars: 你好世界! @#$%^&*()_+ 🚀🎉"
        let request = AIPolishRequest(model: "gpt-4o", content: specialContent)
        
        XCTAssertEqual(request.messages.count, 2)
        XCTAssertTrue(request.messages[1].content.contains(specialContent))
        XCTAssertTrue(request.messages[1].content.contains("你好世界"))
        XCTAssertTrue(request.messages[1].content.contains("🚀🎉"))
    }
    
    // MARK: - JSON Parsing Tests
    
    func testInvalidJSONResponse() async throws {
        let invalidJSON = "{ invalid json }"
        let data = invalidJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        do {
            _ = try decoder.decode(AIPolishResponse.self, from: data)
            XCTFail("Should have thrown an error for invalid JSON")
        } catch {
            // Expected to throw an error
            XCTAssertNotNil(error)
        }
    }
    
    func testPartialJSONResponse() async throws {
        let partialJSON = """
        {
            "choices": [
                {
                    "message": {
                        "role": "assistant",
                        "content": "First response"
                    }
                },
                {
                    "message": {
                        "role": "assistant",
                        "content": "Second response"
                    }
                }
            ]
        }
        """
        
        let data = partialJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AIPolishResponse.self, from: data)
        
        XCTAssertEqual(response.choices.count, 2)
        XCTAssertEqual(response.choices[0].message.content, "First response")
        XCTAssertEqual(response.choices[1].message.content, "Second response")
    }
    
    // MARK: - Performance Tests
    
    func testAIPolishRequestCreationPerformance() async throws {
        let content = "Test content for performance measurement"
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<1000 {
            _ = AIPolishRequest(model: "gpt-4o", content: content)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete within reasonable time (less than 1 second for 1000 requests)
        XCTAssertLessThan(timeElapsed, 1.0)
    }
    
    func testJSONEncodingPerformance() async throws {
        let request = AIPolishRequest(model: "gpt-4o", content: "Performance test content")
        let encoder = JSONEncoder()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<1000 {
            _ = try encoder.encode(request)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should encode 1000 requests within reasonable time
        XCTAssertLessThan(timeElapsed, 1.0)
    }
    
    // MARK: - Edge Cases Tests
    
    func testAIPolishRequestWithNilValues() async throws {
        // Test that the initializer handles edge cases properly
        let request = AIPolishRequest(model: "", content: "")
        
        XCTAssertEqual(request.model, "")
        XCTAssertEqual(request.messages.count, 2)
        XCTAssertEqual(request.temperature, 0.7)
        XCTAssertEqual(request.max_tokens, 10000)
    }
    
    func testChatMessageWithEmptyContent() async throws {
        let message = ChatMessage(role: "user", content: "")
        
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "")
        XCTAssertTrue(message.content.isEmpty)
        
        // Should still be encodable
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        XCTAssertGreaterThan(data.count, 0)
    }
}