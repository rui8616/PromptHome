//
//  StressTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import XCTest
import Combine
@testable import PromptHome

final class StressTests: XCTestCase {
    
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
    
    // MARK: - Memory Stress Tests
    
    func testMemoryStressWithMassivePrompts() {
        let massiveCount = 100000
        
        measure(metrics: [XCTMemoryMetric(), XCTClockMetric()]) {
            autoreleasepool {
                var prompts: [Prompt] = []
                prompts.reserveCapacity(massiveCount)
                
                for i in 0..<massiveCount {
                    let prompt = Prompt(
                        title: "Stress Test \(i)",
                        tags: ["stress"],
                        content: "This is stress test content \(i) designed to test memory usage under extreme conditions. " +
                                "It contains multiple sentences to simulate real-world usage patterns. " +
                                "The content is intentionally verbose to increase memory pressure."
                    )
                    prompts.append(prompt)
                }
                
                XCTAssertEqual(prompts.count, massiveCount)
                
                // Test operations on massive dataset
                let filtered = prompts.filter { $0.tags.contains("stress") }
                XCTAssertEqual(filtered.count, massiveCount)
                
                // Clear memory
                prompts.removeAll()
            }
        }
    }
    
    func testMemoryStressWithLargeContent() {
        let largeContentSize = 1000000 // 1MB of text per prompt
        let promptCount = 100
        
        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                var prompts: [Prompt] = []
                
                for i in 0..<promptCount {
                    let largeContent = String(repeating: "Large content stress test \(i). ", count: largeContentSize / 30)
                    let prompt = Prompt(
                        title: "Large Content \(i)",
                        tags: ["largecontent"],
                        content: largeContent
                    )
                    prompts.append(prompt)
                }
                
                XCTAssertEqual(prompts.count, promptCount)
                
                // Test encoding large content
                let encoder = JSONEncoder()
                var encodedCount = 0
                
                for prompt in prompts {
                    if let _ = try? encoder.encode(prompt) {
                        encodedCount += 1
                    }
                }
                
                XCTAssertEqual(encodedCount, promptCount)
                prompts.removeAll()
            }
        }
    }
    
    func testMemoryLeakStress() {
        let iterations = 10000
        
        measure(metrics: [XCTMemoryMetric()]) {
            for i in 0..<iterations {
                autoreleasepool {
                    // Create and immediately release objects
                    let languageManager = LanguageManager()
                    let themeManager = ThemeManager()
                    let aiService = AIPolishService()
                    let mcpService = MCPService()
                    
                    // Use objects to prevent optimization
                    languageManager.currentLanguage = i % 2 == 0 ? "en" : "zh"
                    themeManager.toggleTheme()
                    mcpService.startServer()
                    mcpService.stopServer()
                    
                    // Create temporary prompt
                    let prompt = Prompt(
                        title: "Leak Test \(i)",
                        tags: ["leak"],
                        content: "Content \(i)"
                    )
                    
                    XCTAssertNotNil(prompt.id)
                }
            }
        }
    }
    
    // MARK: - CPU Stress Tests
    
    func testCPUStressWithComplexOperations() {
        let complexityLevel = 10000
        
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()]) {
            var results: [String] = []
            
            for i in 0..<complexityLevel {
                // Complex string operations
                let baseString = "CPU stress test iteration \(i) with complex operations"
                let processed = baseString
                    .uppercased()
                    .lowercased()
                    .replacingOccurrences(of: "\(i)", with: "[\(i)]")
                    .components(separatedBy: " ")
                    .sorted()
                    .joined(separator: "-")
                
                results.append(processed)
                
                // Complex calculations
                let calculation = (0..<100).reduce(0) { sum, j in
                    sum + (i * j) % 1000
                }
                
                XCTAssertGreaterThanOrEqual(calculation, 0)
            }
            
            XCTAssertEqual(results.count, complexityLevel)
        }
    }
    
    func testCPUStressWithJSONProcessing() {
        let jsonProcessingCount = 50000
        
        measure(metrics: [XCTCPUMetric()]) {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            var processedCount = 0
            
            for i in 0..<jsonProcessingCount {
                let prompt = Prompt(
                    title: "JSON Stress \(i)",
                    tags: ["jsonstress"],
                    content: "JSON processing stress test content \(i)"
                )
                
                do {
                    let data = try encoder.encode(prompt)
                    let decoded = try decoder.decode(Prompt.self, from: data)
                    
                    XCTAssertEqual(decoded.id, prompt.id)
                    processedCount += 1
                } catch {
                    XCTFail("JSON processing failed at iteration \(i): \(error)")
                }
            }
            
            XCTAssertEqual(processedCount, jsonProcessingCount)
        }
    }
    
    func testCPUStressWithConcurrentOperations() {
        let concurrentTasks = 100
        let operationsPerTask = 1000
        
        measure(metrics: [XCTCPUMetric()]) {
            let expectation = XCTestExpectation(description: "Concurrent CPU stress")
            expectation.expectedFulfillmentCount = concurrentTasks
            
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            for taskId in 0..<concurrentTasks {
                queue.async {
                    var localResults: [Int] = []
                    
                    for i in 0..<operationsPerTask {
                        // CPU-intensive calculations
                        let result = (0..<100).reduce(0) { sum, j in
                            sum + (taskId * i * j) % 10000
                        }
                        localResults.append(result)
                    }
                    
                    XCTAssertEqual(localResults.count, operationsPerTask)
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    // MARK: - I/O Stress Tests
    
    func testIOStressWithMassiveEncoding() {
        let massiveDataCount = 25000
        
        measure(metrics: [XCTStorageTrackingMetric(), XCTClockMetric()]) {
            let encoder = JSONEncoder()
            var encodedData: [Data] = []
            encodedData.reserveCapacity(massiveDataCount)
            
            for i in 0..<massiveDataCount {
                let prompt = Prompt(
                    title: "IO Stress \(i)",
                    tags: ["iostress"],
                    content: "IO stress test content \(i) with additional data to increase encoding overhead"
                )
                
                do {
                    let data = try encoder.encode(prompt)
                    encodedData.append(data)
                } catch {
                    XCTFail("Encoding failed at iteration \(i): \(error)")
                }
            }
            
            XCTAssertEqual(encodedData.count, massiveDataCount)
            
            // Test decoding
            let decoder = JSONDecoder()
            var decodedCount = 0
            
            for data in encodedData {
                if let _ = try? decoder.decode(Prompt.self, from: data) {
                    decodedCount += 1
                }
            }
            
            XCTAssertEqual(decodedCount, massiveDataCount)
        }
    }
    
    func testIOStressWithUserDefaults() {
        let userDefaultsOperations = 10000
        let testKeyPrefix = "stress_test_"
        
        measure {
            // Write operations
            for i in 0..<userDefaultsOperations {
                let key = "\(testKeyPrefix)\(i)"
                let value = "Stress test value \(i) with some content"
                UserDefaults.standard.set(value, forKey: key)
            }
            
            // Read operations
            var readCount = 0
            for i in 0..<userDefaultsOperations {
                let key = "\(testKeyPrefix)\(i)"
                if let _ = UserDefaults.standard.string(forKey: key) {
                    readCount += 1
                }
            }
            
            XCTAssertEqual(readCount, userDefaultsOperations)
            
            // Cleanup
            for i in 0..<userDefaultsOperations {
                let key = "\(testKeyPrefix)\(i)"
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    // MARK: - Concurrency Stress Tests
    
    func testConcurrencyStressWithMultipleServices() {
        let serviceCount = 50
        let operationsPerService = 100
        
        measure {
            let expectation = XCTestExpectation(description: "Multiple services stress")
            expectation.expectedFulfillmentCount = serviceCount
            
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            for serviceId in 0..<serviceCount {
                queue.async {
                    var operationCount = 0
                    
                    for i in 0..<operationsPerService {
                        autoreleasepool {
                            let mcpService = MCPService()
                            let aiService = AIPolishService()
                            let languageManager = LanguageManager()
                            let themeManager = ThemeManager()
                            
                            // Perform operations
                            mcpService.startServer()
                            languageManager.currentLanguage = i % 2 == 0 ? "en" : "zh"
                            themeManager.toggleTheme()
                            mcpService.stopServer()
                            
                            operationCount += 1
                        }
                    }
                    
                    XCTAssertEqual(operationCount, operationsPerService)
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 60.0)
        }
    }
    
    func testConcurrencyStressWithSharedResources() {
        let threadCount = 20
        let accessCount = 1000
        
        measure {
            let languageManager = LanguageManager()
            let themeManager = ThemeManager()
            
            let expectation = XCTestExpectation(description: "Shared resources stress")
            expectation.expectedFulfillmentCount = threadCount
            
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            for threadId in 0..<threadCount {
                queue.async {
                    for i in 0..<accessCount {
                        // Concurrent access to shared resources
                        if threadId % 2 == 0 {
                            languageManager.currentLanguage = i % 3 == 0 ? "en" : (i % 3 == 1 ? "zh" : "ja")
                        } else {
                            themeManager.toggleTheme()
                        }
                    }
                    
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    func testConcurrencyStressWithPromptOperations() {
        let concurrentPromptOperations = 1000
        
        measure {
            let expectation = XCTestExpectation(description: "Concurrent prompt operations")
            expectation.expectedFulfillmentCount = concurrentPromptOperations
            
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            for i in 0..<concurrentPromptOperations {
                queue.async {
                    autoreleasepool {
                        // Create prompt
                        var prompt = Prompt(
                            title: "Concurrent \(i)",
                            tags: ["concurrent"],
                            content: "Concurrent content \(i)"
                        )
                        
                        // Modify prompt
                        prompt.title = "Modified \(i)"
                        prompt.updateContent(content: "Updated content")
                        
                        // Encode/decode
                        let encoder = JSONEncoder()
                        let decoder = JSONDecoder()
                        
                        do {
                            let data = try encoder.encode(prompt)
                            let decoded = try decoder.decode(Prompt.self, from: data)
                            XCTAssertEqual(decoded.id, prompt.id)
                        } catch {
                            XCTFail("Concurrent operation failed: \(error)")
                        }
                        
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    // MARK: - Edge Case Stress Tests
    
    func testStressWithExtremelyLongStrings() {
        let extremeLength = 10000000 // 10MB string
        
        measure(metrics: [XCTMemoryMetric(), XCTClockMetric()]) {
            autoreleasepool {
                let extremeContent = String(repeating: "Extreme stress test content. ", count: extremeLength / 30)
                
                let prompt = Prompt(
                    title: "Extreme Length Test",
                    tags: ["extreme"],
                    content: extremeContent
                )
                
                XCTAssertEqual(prompt.content.count, extremeContent.count)
                
                // Test operations on extreme content
                let textView = OptimizedTextView(content: extremeContent)
                let chunks = textView.chunks
                
                XCTAssertGreaterThan(chunks.count, 1)
                
                // Verify content integrity
                let reconstructed = chunks.joined()
                XCTAssertEqual(reconstructed.count, extremeContent.count)
            }
        }
    }
    
    func testStressWithSpecialCharacters() {
        let specialCharacterCount = 50000
        
        measure {
            let specialChars = "🚀💻🎯🔥⚡️🌟💡🎨🎭🎪🎨🎯🔮🎲🎰🎳🎸🎺🎻🎹🥁🎤🎧🎬🎮🕹️🎯🎲"
            var content = ""
            
            for i in 0..<specialCharacterCount {
                let randomChar = specialChars.randomElement() ?? "🚀"
                content += "\(randomChar) Test \(i) "
            }
            
            let prompt = Prompt(
                title: "Special Characters Stress",
                tags: ["specialchars"],
                content: content
            )
            
            // Test encoding with special characters
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            do {
                let data = try encoder.encode(prompt)
                let decoded = try decoder.decode(Prompt.self, from: data)
                
                XCTAssertEqual(decoded.content, prompt.content)
                XCTAssertEqual(decoded.title, prompt.title)
            } catch {
                XCTFail("Special character encoding failed: \(error)")
            }
        }
    }
    
    func testStressWithRapidStateChanges() {
        let rapidChanges = 10000
        
        measure {
            let languageManager = LanguageManager()
            let themeManager = ThemeManager()
            let mcpService = MCPService()
            
            var changeCount = 0
            
            for i in 0..<rapidChanges {
                // Rapid language changes
                languageManager.currentLanguage = i % 4 == 0 ? "en" : 
                                                  i % 4 == 1 ? "zh" : 
                                                  i % 4 == 2 ? "ja" : "fr"
                
                // Rapid theme changes
                if i % 2 == 0 {
                    themeManager.toggleTheme()
                }
                
                // Rapid service state changes
                if i % 10 == 0 {
                    mcpService.startServer()
                    mcpService.stopServer()
                }
                
                changeCount += 1
            }
            
            XCTAssertEqual(changeCount, rapidChanges)
        }
    }
    
    // MARK: - Resource Exhaustion Tests
    
    func testResourceExhaustionWithMassiveArrays() {
        let massiveArraySize = 1000000
        
        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                var massiveArray: [Prompt] = []
                massiveArray.reserveCapacity(massiveArraySize)
                
                for i in 0..<massiveArraySize {
                    if i % 10000 == 0 {
                        // Periodic memory pressure relief
                        autoreleasepool {
                            let prompt = Prompt(
                                title: "Massive \(i)",
                                tags: ["massive"],
                                content: "Content \(i)"
                            )
                            massiveArray.append(prompt)
                        }
                    } else {
                        let prompt = Prompt(
                            title: "Massive \(i)",
                            tags: ["massive"],
                            content: "Content \(i)"
                        )
                        massiveArray.append(prompt)
                    }
                }
                
                XCTAssertEqual(massiveArray.count, massiveArraySize)
                
                // Test operations on massive array
                let firstHalf = Array(massiveArray.prefix(massiveArraySize / 2))
                XCTAssertEqual(firstHalf.count, massiveArraySize / 2)
                
                massiveArray.removeAll()
            }
        }
    }
    
    func testResourceExhaustionWithDeepNesting() {
        let nestingDepth = 1000
        
        measure {
            // Create deeply nested structure simulation
            var nestedContent = "Base content"
            
            for i in 0..<nestingDepth {
                nestedContent = "Level \(i): {\(nestedContent)}"
            }
            
            let prompt = Prompt(
                title: "Deep Nesting Test",
                tags: ["deepnesting"],
                content: nestedContent
            )
            
            // Test encoding deeply nested content
            let encoder = JSONEncoder()
            
            do {
                let data = try encoder.encode(prompt)
                XCTAssertGreaterThan(data.count, 0)
                
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(Prompt.self, from: data)
                XCTAssertEqual(decoded.content, nestedContent)
            } catch {
                XCTFail("Deep nesting encoding failed: \(error)")
            }
        }
    }
    
    // MARK: - Stability Stress Tests
    
    func testLongRunningStabilityTest() {
        let longRunningOperations = 100000
        
        measure {
            var operationCount = 0
            var errorCount = 0
            
            for i in 0..<longRunningOperations {
                autoreleasepool {
                    do {
                        // Mix of different operations
                        switch i % 5 {
                        case 0:
                            let prompt = Prompt(
                                title: "Stability \(i)",
                                tags: ["stability"],
                                content: "Stability test \(i)"
                            )
                            let encoder = JSONEncoder()
                            _ = try encoder.encode(prompt)
                            
                        case 1:
                            let config = AIModelConfig(
                                provider: .openai,
                                baseURL: "https://api.openai.com/v1",
                                apiKey: "stability-key-\(i)",
                                selectedModel: "gpt-4o-mini"
                            )
                            let encoder = JSONEncoder()
                            _ = try encoder.encode(config)
                            
                        case 2:
                            let languageManager = LanguageManager()
                            languageManager.currentLanguage = i % 2 == 0 ? "en" : "zh"
                            
                        case 3:
                            let themeManager = ThemeManager()
                            themeManager.toggleTheme()
                            
                        case 4:
                            let mcpService = MCPService()
                            mcpService.startServer()
                            mcpService.stopServer()
                            
                        default:
                            break
                        }
                        
                        operationCount += 1
                        
                    } catch {
                        errorCount += 1
                    }
                }
            }
            
            XCTAssertEqual(operationCount + errorCount, longRunningOperations)
            XCTAssertLessThan(errorCount, longRunningOperations / 100) // Less than 1% error rate
        }
    }
    
    func testStabilityUnderMemoryPressure() {
        let memoryPressureIterations = 1000
        
        measure(metrics: [XCTMemoryMetric()]) {
            for i in 0..<memoryPressureIterations {
                autoreleasepool {
                    // Create memory pressure
                    let largeContent = String(repeating: "Memory pressure test \(i). ", count: 10000)
                    
                    var prompts: [Prompt] = []
                    for j in 0..<100 {
                        let prompt = Prompt(
                            title: "Pressure \(i)-\(j)",
                            tags: ["pressure"],
                            content: largeContent
                        )
                        prompts.append(prompt)
                    }
                    
                    // Test operations under pressure
                    let encoder = JSONEncoder()
                    var encodedCount = 0
                    
                    for prompt in prompts {
                        if let _ = try? encoder.encode(prompt) {
                            encodedCount += 1
                        }
                    }
                    
                    XCTAssertEqual(encodedCount, prompts.count)
                    
                    // Force memory cleanup
                    prompts.removeAll()
                }
            }
        }
    }
    
    // MARK: - Recovery Stress Tests
    
    func testRecoveryFromExtremeConditions() {
        measure {
            // Simulate extreme conditions and recovery
            
            // 1. Memory exhaustion simulation
            autoreleasepool {
                var extremeData: [Data] = []
                let encoder = JSONEncoder()
                
                for i in 0..<10000 {
                    let largePrompt = Prompt(
                        title: "Recovery \(i)",
                        tags: ["recovery"],
                        content: String(repeating: "Recovery test \(i). ", count: 1000)
                    )
                    
                    if let data = try? encoder.encode(largePrompt) {
                        extremeData.append(data)
                    }
                }
                
                // Force cleanup
                extremeData.removeAll()
            }
            
            // 2. Test normal operations after extreme conditions
            let normalPrompt = Prompt(
                title: "Normal After Extreme",
                tags: ["normal"],
                content: "Normal content after extreme conditions"
            )
            
            XCTAssertNotNil(normalPrompt.id)
            
            // 3. Test service recovery
            let mcpService = MCPService()
            let languageManager = LanguageManager()
            let themeManager = ThemeManager()
            
            // Rapid state changes
            for _ in 0..<100 {
                mcpService.startServer()
                mcpService.stopServer()
                languageManager.currentLanguage = "en"
                themeManager.toggleTheme()
            }
            
            // Verify services are still functional
            XCTAssertFalse(mcpService.isRunning)
            XCTAssertNotNil(languageManager.currentLanguage)
            XCTAssertNotNil(themeManager.isDarkMode)
        }
    }
}