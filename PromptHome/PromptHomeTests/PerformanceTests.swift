//
//  PerformanceTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import XCTest
import Combine
@testable import PromptHome

final class PerformanceTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Prompt Model Performance Tests
    
    func testPromptCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let prompt = Prompt(
                    title: "Performance Test Prompt \(i)",
                    tags: ["performance"],
                    content: "This is a performance test prompt with content number \(i). It contains some text to simulate real usage."
                )
                XCTAssertNotNil(prompt.id)
            }
        }
    }
    
    func testPromptEncodingPerformance() {
        let prompts = (0..<1000).map { i in
            Prompt(
                title: "Encoding Test \(i)",
                tags: ["encoding"],
                content: "Content for encoding test \(i)"
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
    
    func testPromptDecodingPerformance() {
        let prompts = (0..<1000).map { i in
            Prompt(
                title: "Decoding Test \(i)",
                tags: ["decoding"],
                content: "Content for decoding test \(i)"
            )
        }
        
        let encoder = JSONEncoder()
        let encodedData = prompts.compactMap { prompt in
            try? encoder.encode(prompt)
        }
        
        measure {
            let decoder = JSONDecoder()
            for data in encodedData {
                do {
                    _ = try decoder.decode(Prompt.self, from: data)
                } catch {
                    XCTFail("Decoding failed: \(error)")
                }
            }
        }
    }
    
    func testPromptUpdatePerformance() {
        var prompts = (0..<1000).map { i in
            Prompt(
                title: "Update Test \(i)",
                tags: ["update"],
                content: "Original content \(i)"
            )
        }
        
        measure {
            for i in 0..<prompts.count {
                prompts[i].title = "Updated Title \(i)"
                prompts[i].content = "Updated content \(i)"
                prompts[i].updateContent(content: "Updated content")
            }
        }
    }
    
    // MARK: - AI Model Config Performance Tests
    
    func testAIModelConfigCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let config = AIModelConfig(
                    provider: i % 2 == 0 ? .openai : .deepseek,
                    apiKey: "test-key-\(i)",
                    baseURL: "https://api.example.com/v\(i % 3 + 1)",
                    model: "model-\(i)",
                    temperature: Double(i % 10) / 10.0,
                    maxTokens: 1000 + (i % 1000)
                )
                XCTAssertNotNil(config)
            }
        }
    }
    
    func testAIModelConfigEncodingPerformance() {
        let configs = (0..<1000).map { i in
            AIModelConfig(
                provider: .openai,
                apiKey: "performance-key-\(i)",
                baseURL: "https://api.openai.com/v1",
                model: "gpt-3.5-turbo",
                temperature: 0.7,
                maxTokens: 1500
            )
        }
        
        measure {
            let encoder = JSONEncoder()
            for config in configs {
                do {
                    _ = try encoder.encode(config)
                } catch {
                    XCTFail("Config encoding failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - AI Polish Service Performance Tests
    
    func testAIPolishRequestCreationPerformance() {
        let messages = (0..<100).map { i in
            ChatMessage(role: "user", content: "Test message \(i) for performance testing")
        }
        
        measure {
            for i in 0..<100 {
                let request = AIPolishRequest(
                    model: "gpt-3.5-turbo",
                    messages: Array(messages[0...min(i, messages.count - 1)]),
                    temperature: 0.7,
                    maxTokens: 1500
                )
                XCTAssertNotNil(request)
            }
        }
    }
    
    func testAIPolishResponseParsingPerformance() {
        let sampleResponses = (0..<100).map { i in
            AIPolishResponse(
                id: "response-\(i)",
                object: "chat.completion",
                created: Int(Date().timeIntervalSince1970),
                model: "gpt-3.5-turbo",
                choices: [
                    AIPolishResponse.Choice(
                        index: 0,
                        message: ChatMessage(role: "assistant", content: "Polished response \(i)"),
                        finishReason: "stop"
                    )
                ]
            )
        }
        
        measure {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            for response in sampleResponses {
                do {
                    let data = try encoder.encode(response)
                    _ = try decoder.decode(AIPolishResponse.self, from: data)
                } catch {
                    XCTFail("Response parsing failed: \(error)")
                }
            }
        }
    }
    
    func testChatMessagePerformance() {
        measure {
            for i in 0..<1000 {
                let message = ChatMessage(
                    role: i % 2 == 0 ? "user" : "assistant",
                    content: "Performance test message \(i) with some content to simulate real usage scenarios."
                )
                XCTAssertNotNil(message)
            }
        }
    }
    
    // MARK: - MCP Service Performance Tests
    
    func testMCPServiceCreationPerformance() {
        measure {
            for _ in 0..<100 {
                let mcpService = MCPService()
                XCTAssertFalse(mcpService.isRunning)
                XCTAssertEqual(mcpService.serverAddress, "http://localhost:3001")
            }
        }
    }
    
    func testMCPServiceStateChangePerformance() {
        let mcpService = MCPService()
        
        measure {
            for _ in 0..<50 {
                mcpService.startServer()
                mcpService.stopServer()
            }
        }
    }
    
    // MARK: - Language Manager Performance Tests
    
    func testLanguageManagerPerformance() {
        measure {
            for _ in 0..<100 {
                let languageManager = LanguageManager()
                languageManager.currentLanguage = "en"
                languageManager.currentLanguage = "zh"
                languageManager.currentLanguage = "ja"
                languageManager.currentLanguage = "fr"
            }
        }
    }
    
    func testLanguageManagerObservationPerformance() {
        let languageManager = LanguageManager()
        var observationCount = 0
        
        let expectation = XCTestExpectation(description: "Language observation performance")
        expectation.expectedFulfillmentCount = 100
        
        languageManager.$currentLanguage
            .sink { _ in
                observationCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        measure {
            for i in 0..<100 {
                languageManager.currentLanguage = i % 2 == 0 ? "en" : "zh"
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThanOrEqual(observationCount, 100)
    }
    
    // MARK: - Theme Manager Performance Tests
    
    func testThemeManagerPerformance() {
        measure {
            for _ in 0..<100 {
                let themeManager = ThemeManager()
                themeManager.toggleTheme()
                themeManager.toggleTheme()
                themeManager.toggleTheme()
            }
        }
    }
    
    func testThemeManagerObservationPerformance() {
        let themeManager = ThemeManager()
        var observationCount = 0
        
        let expectation = XCTestExpectation(description: "Theme observation performance")
        expectation.expectedFulfillmentCount = 100
        
        themeManager.$isDarkMode
            .sink { _ in
                observationCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        measure {
            for _ in 0..<100 {
                themeManager.toggleTheme()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThanOrEqual(observationCount, 100)
    }
    
    // MARK: - OptimizedTextView Performance Tests
    
    func testOptimizedTextViewChunkingPerformance() {
        let largeContent = String(repeating: "This is a line of text for performance testing. ", count: 10000)
        
        measure {
            let textView = OptimizedTextView(content: largeContent)
            let chunks = textView.chunks
            XCTAssertGreaterThan(chunks.count, 1)
        }
    }
    
    func testOptimizedTextViewWithVaryingSizes() {
        let sizes = [100, 500, 1000, 5000, 10000]
        
        for size in sizes {
            let content = String(repeating: "Text ", count: size)
            
            measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
                let textView = OptimizedTextView(content: content)
                let chunks = textView.chunks
                XCTAssertGreaterThan(chunks.count, 0)
                
                // Verify content integrity
                let reconstructed = chunks.joined()
                XCTAssertEqual(reconstructed, content)
            }
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageWithLargeDatasets() {
        measure(metrics: [XCTMemoryMetric()]) {
            // Create large dataset
            let prompts = (0..<10000).map { i in
                Prompt(
                    title: "Memory Test \(i)",
                    tags: ["memory"],
                    content: String(repeating: "Content \(i) ", count: 100)
                )
            }
            
            // Process dataset
            let encoder = JSONEncoder()
            var encodedData: [Data] = []
            
            for prompt in prompts {
                if let data = try? encoder.encode(prompt) {
                    encodedData.append(data)
                }
            }
            
            XCTAssertEqual(encodedData.count, prompts.count)
            
            // Decode back
            let decoder = JSONDecoder()
            var decodedPrompts: [Prompt] = []
            
            for data in encodedData {
                if let prompt = try? decoder.decode(Prompt.self, from: data) {
                    decodedPrompts.append(prompt)
                }
            }
            
            XCTAssertEqual(decodedPrompts.count, prompts.count)
        }
    }
    
    func testMemoryLeakPrevention() {
        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 0..<1000 {
                autoreleasepool {
                    let languageManager = LanguageManager()
                    let themeManager = ThemeManager()
                    let aiService = AIPolishService()
                    let mcpService = MCPService()
                    
                    // Use the objects
                    languageManager.currentLanguage = "en"
                    themeManager.toggleTheme()
                    mcpService.startServer()
                    mcpService.stopServer()
                    
                    // Objects should be deallocated when autoreleasepool ends
                }
            }
        }
    }
    
    // MARK: - Concurrent Performance Tests
    
    func testConcurrentPromptCreation() {
        let expectation = XCTestExpectation(description: "Concurrent prompt creation")
        expectation.expectedFulfillmentCount = 100
        
        measure {
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            for i in 0..<100 {
                queue.async {
                    let prompt = Prompt(
                        title: "Concurrent \(i)",
                        tags: ["concurrent"],
                        content: "Concurrent content \(i)"
                    )
                    XCTAssertNotNil(prompt.id)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testConcurrentServiceOperations() {
        let expectation = XCTestExpectation(description: "Concurrent service operations")
        expectation.expectedFulfillmentCount = 50
        
        measure {
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            for i in 0..<50 {
                queue.async {
                    let mcpService = MCPService()
                    let aiService = AIPolishService()
                    
                    // Perform operations
                    mcpService.startServer()
                    mcpService.stopServer()
                    
                    let config = AIModelConfig()
                    XCTAssertNotNil(config)
                    
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - JSON Performance Tests
    
    func testLargeJSONEncodingPerformance() {
        let largePrompt = Prompt(
            title: "Large JSON Test",
            tags: ["performance"],
            content: String(repeating: "This is a very long content for testing JSON encoding performance. ", count: 1000)
        )
        
        measure {
            let encoder = JSONEncoder()
            for _ in 0..<100 {
                do {
                    _ = try encoder.encode(largePrompt)
                } catch {
                    XCTFail("Large JSON encoding failed: \(error)")
                }
            }
        }
    }
    
    func testComplexJSONStructurePerformance() {
        let complexResponse = AIPolishResponse(
            id: "complex-test",
            object: "chat.completion",
            created: Int(Date().timeIntervalSince1970),
            model: "gpt-4",
            choices: (0..<100).map { i in
                AIPolishResponse.Choice(
                    index: i,
                    message: ChatMessage(
                        role: "assistant",
                        content: "Complex response choice \(i) with detailed content for performance testing."
                    ),
                    finishReason: "stop"
                )
            }
        )
        
        measure {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            for _ in 0..<50 {
                do {
                    let data = try encoder.encode(complexResponse)
                    _ = try decoder.decode(AIPolishResponse.self, from: data)
                } catch {
                    XCTFail("Complex JSON processing failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - String Processing Performance Tests
    
    func testStringProcessingPerformance() {
        let testStrings = (0..<1000).map { i in
            "Test string \(i) with some content for processing performance evaluation."
        }
        
        measure {
            for string in testStrings {
                // Simulate common string operations
                let uppercased = string.uppercased()
                let lowercased = string.lowercased()
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                let components = string.components(separatedBy: " ")
                
                XCTAssertNotNil(uppercased)
                XCTAssertNotNil(lowercased)
                XCTAssertNotNil(trimmed)
                XCTAssertGreaterThan(components.count, 0)
            }
        }
    }
    
    // MARK: - Collection Performance Tests
    
    func testArrayOperationsPerformance() {
        let prompts = (0..<10000).map { i in
            Prompt(
                title: "Array Test \(i)",
                tags: ["array"],
                content: "Content \(i)"
            )
        }
        
        measure {
            // Test filtering
            let filtered = prompts.filter { $0.tags.contains("array") }
            XCTAssertEqual(filtered.count, prompts.count)
            
            // Test mapping
            let titles = prompts.map { $0.title }
            XCTAssertEqual(titles.count, prompts.count)
            
            // Test sorting
            let sorted = prompts.sorted { $0.title < $1.title }
            XCTAssertEqual(sorted.count, prompts.count)
            
            // Test searching
            let found = prompts.first { $0.title.contains("5000") }
            XCTAssertNotNil(found)
        }
    }
    
    // MARK: - Real-world Scenario Performance Tests
    
    func testCompleteWorkflowPerformance() {
        measure {
            // Simulate complete user workflow
            
            // 1. Create multiple prompts
            let prompts = (0..<100).map { i in
                Prompt(
                    title: "Workflow \(i)",
                    tags: ["workflow"],
                    content: "Workflow content \(i)"
                )
            }
            
            // 2. Configure AI settings
            let configs = (0..<10).map { i in
                AIModelConfig(
                    provider: .openai,
                    apiKey: "workflow-key-\(i)",
                    baseURL: "https://api.openai.com/v1",
                    model: "gpt-3.5-turbo"
                )
            }
            
            // 3. Create AI requests
            var requests: [AIPolishRequest] = []
            for (prompt, config) in zip(prompts.prefix(10), configs) {
                let request = AIPolishRequest(
                    model: config.model,
                    messages: [
                        ChatMessage(role: "user", content: "Polish: \(prompt.content)")
                    ],
                    temperature: config.temperature,
                    maxTokens: config.maxTokens
                )
                requests.append(request)
            }
            
            // 4. Encode/decode for persistence
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            for prompt in prompts {
                if let data = try? encoder.encode(prompt),
                   let _ = try? decoder.decode(Prompt.self, from: data) {
                    // Successfully processed
                }
            }
            
            // 5. Service operations
            let mcpService = MCPService()
            mcpService.startServer()
            mcpService.stopServer()
            
            // 6. Manager operations
            let languageManager = LanguageManager()
            let themeManager = ThemeManager()
            
            languageManager.currentLanguage = "en"
            themeManager.toggleTheme()
            
            XCTAssertEqual(prompts.count, 100)
            XCTAssertEqual(configs.count, 10)
            XCTAssertEqual(requests.count, 10)
        }
    }
    
    func testHighVolumeDataProcessing() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Process high volume of data
            let dataVolume = 50000
            
            // Create large dataset
            let prompts = (0..<dataVolume).map { i in
                Prompt(
                    title: "Volume Test \(i)",
                    tags: ["volume"],
                    content: "High volume content \(i) for stress testing the application performance."
                )
            }
            
            // Process in batches
            let batchSize = 1000
            var processedCount = 0
            
            for batch in stride(from: 0, to: prompts.count, by: batchSize) {
                let endIndex = min(batch + batchSize, prompts.count)
                let batchPrompts = Array(prompts[batch..<endIndex])
                
                // Simulate processing
                let encoder = JSONEncoder()
                for prompt in batchPrompts {
                    if let _ = try? encoder.encode(prompt) {
                        processedCount += 1
                    }
                }
            }
            
            XCTAssertEqual(processedCount, dataVolume)
        }
    }
}
