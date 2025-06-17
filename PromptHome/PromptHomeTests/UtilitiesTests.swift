//
//  UtilitiesTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import XCTest
import AppKit
@testable import PromptHome

final class UtilitiesTests: XCTestCase {
    
    // MARK: - String Extensions Tests
    
    func testStringTrimming() {
        let testString = "  Hello World  "
        let trimmed = testString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        XCTAssertEqual(trimmed, "Hello World")
    }
    
    func testStringIsEmpty() {
        XCTAssertTrue("".isEmpty)
        XCTAssertFalse("Hello".isEmpty)
        XCTAssertTrue("   ".trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    func testStringContains() {
        let testString = "Hello World"
        
        XCTAssertTrue(testString.contains("Hello"))
        XCTAssertTrue(testString.contains("World"))
        XCTAssertFalse(testString.contains("Goodbye"))
        XCTAssertTrue(testString.lowercased().contains("hello"))
    }
    
    // MARK: - Date Formatting Tests
    
    func testDateFormatting() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let formattedDate = formatter.string(from: date)
        XCTAssertFalse(formattedDate.isEmpty)
    }
    
    func testRelativeDateFormatting() {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)
        
        let formatter = RelativeDateTimeFormatter()
        
        let oneHourAgoString = formatter.localizedString(for: oneHourAgo, relativeTo: now)
        let oneDayAgoString = formatter.localizedString(for: oneDayAgo, relativeTo: now)
        
        XCTAssertFalse(oneHourAgoString.isEmpty)
        XCTAssertFalse(oneDayAgoString.isEmpty)
    }
    
    // MARK: - URL Validation Tests
    
    func testValidURLs() {
        let validURLs = [
            "https://api.openai.com/v1",
            "http://localhost:11434",
            "https://api.anthropic.com",
            "https://example.com/api",
            "http://192.168.1.1:8080"
        ]
        
        for urlString in validURLs {
            let url = URL(string: urlString)
            XCTAssertNotNil(url, "Failed to create URL from: \(urlString)")
        }
    }
    
    func testInvalidURLs() {
        let invalidURLs = [
            "",
            "not a url",
            "ftp://invalid",
            "://missing-scheme",
            "https://"
        ]
        
        for urlString in invalidURLs {
            if urlString.isEmpty {
                let url = URL(string: urlString)
                XCTAssertNil(url, "Should not create URL from empty string")
            } else {
                // Some invalid URLs might still create URL objects but be invalid
                let url = URL(string: urlString)
                if let url = url {
                    // Check if it's a valid HTTP/HTTPS URL
                    XCTAssertFalse(url.scheme == "http" || url.scheme == "https", "Invalid URL should not have valid HTTP scheme: \(urlString)")
                }
            }
        }
    }
    
    // MARK: - JSON Utilities Tests
    
    func testJSONEncoding() throws {
        let testData = ["key": "value", "number": "123"]
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(testData)
        
        XCTAssertGreaterThan(jsonData.count, 0)
        
        let jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("key"))
        XCTAssertTrue(jsonString!.contains("value"))
    }
    
    func testJSONDecoding() throws {
        let jsonString = "{\"key\":\"value\",\"number\":\"123\"}"
        let jsonData = jsonString.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode([String: String].self, from: jsonData)
        
        XCTAssertEqual(decodedData["key"], "value")
        XCTAssertEqual(decodedData["number"], "123")
    }
    
    func testInvalidJSONDecoding() {
        let invalidJSON = "invalid json string"
        let jsonData = invalidJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode([String: String].self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - File System Utilities Tests
    
    func testDocumentsDirectory() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        XCTAssertNotNil(documentsURL)
        
        let documentsPath = documentsURL?.path
        XCTAssertNotNil(documentsPath)
        XCTAssertFalse(documentsPath!.isEmpty)
    }
    
    func testTemporaryDirectory() {
        let tempURL = FileManager.default.temporaryDirectory
        XCTAssertNotNil(tempURL)
        
        let tempPath = tempURL.path
        XCTAssertFalse(tempPath.isEmpty)
    }
    
    func testFileExists() {
        let fileManager = FileManager.default
        
        // Test with a file that should exist (app bundle)
        let bundlePath = Bundle.main.bundlePath
        XCTAssertTrue(fileManager.fileExists(atPath: bundlePath))
        
        // Test with a file that shouldn't exist
        let nonExistentPath = "/path/that/does/not/exist"
        XCTAssertFalse(fileManager.fileExists(atPath: nonExistentPath))
    }
    
    // MARK: - UserDefaults Utilities Tests
    
    func testUserDefaultsStorage() {
        let userDefaults = UserDefaults.standard
        let testKey = "test_key_\(UUID().uuidString)"
        let testValue = "test_value"
        
        // Store value
        userDefaults.set(testValue, forKey: testKey)
        
        // Retrieve value
        let retrievedValue = userDefaults.string(forKey: testKey)
        XCTAssertEqual(retrievedValue, testValue)
        
        // Clean up
        userDefaults.removeObject(forKey: testKey)
        
        // Verify cleanup
        let cleanedValue = userDefaults.string(forKey: testKey)
        XCTAssertNil(cleanedValue)
    }
    
    func testUserDefaultsBoolStorage() {
        let userDefaults = UserDefaults.standard
        let testKey = "test_bool_key_\(UUID().uuidString)"
        
        // Store true
        userDefaults.set(true, forKey: testKey)
        XCTAssertTrue(userDefaults.bool(forKey: testKey))
        
        // Store false
        userDefaults.set(false, forKey: testKey)
        XCTAssertFalse(userDefaults.bool(forKey: testKey))
        
        // Clean up
        userDefaults.removeObject(forKey: testKey)
    }
    
    // MARK: - Array Utilities Tests
    
    func testArraySafeAccess() {
        let testArray = ["first", "second", "third"]
        
        // Valid indices
        XCTAssertEqual(testArray[safe: 0], "first")
        XCTAssertEqual(testArray[safe: 1], "second")
        XCTAssertEqual(testArray[safe: 2], "third")
        
        // Invalid indices
        XCTAssertNil(testArray[safe: -1])
        XCTAssertNil(testArray[safe: 3])
        XCTAssertNil(testArray[safe: 100])
    }
    
    func testArrayChunking() {
        let testArray = Array(1...10)
        let chunkSize = 3
        
        let chunks = testArray.chunked(into: chunkSize)
        
        XCTAssertEqual(chunks.count, 4) // [1,2,3], [4,5,6], [7,8,9], [10]
        XCTAssertEqual(chunks[0], [1, 2, 3])
        XCTAssertEqual(chunks[1], [4, 5, 6])
        XCTAssertEqual(chunks[2], [7, 8, 9])
        XCTAssertEqual(chunks[3], [10])
    }
    
    func testEmptyArrayChunking() {
        let emptyArray: [Int] = []
        let chunks = emptyArray.chunked(into: 3)
        
        XCTAssertEqual(chunks.count, 0)
    }
    
    // MARK: - Color Utilities Tests
    
    func testColorFromHex() {
        // Test valid hex colors
        let redColor = NSColor(hex: "#FF0000")
        XCTAssertNotNil(redColor)
        
        let greenColor = NSColor(hex: "00FF00")
        XCTAssertNotNil(greenColor)
        
        let blueColor = NSColor(hex: "#0000FF")
        XCTAssertNotNil(blueColor)
    }
    
    func testInvalidHexColor() {
        let invalidColor = NSColor(hex: "invalid")
        XCTAssertNil(invalidColor)
        
        let shortColor = NSColor(hex: "#FF")
        XCTAssertNil(shortColor)
        
        let longColor = NSColor(hex: "#FF00000000")
        XCTAssertNil(longColor)
    }
    
    // MARK: - Validation Utilities Tests
    
    func testEmailValidation() {
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "test+tag@example.org"
        ]
        
        let invalidEmails = [
            "invalid-email",
            "@example.com",
            "test@",
            "test..test@example.com"
        ]
        
        for email in validEmails {
            XCTAssertTrue(email.isValidEmail, "Should be valid email: \(email)")
        }
        
        for email in invalidEmails {
            XCTAssertFalse(email.isValidEmail, "Should be invalid email: \(email)")
        }
    }
    
    func testAPIKeyValidation() {
        // Test API key format validation
        let validAPIKeys = [
            "sk-1234567890abcdef", // OpenAI format
            "claude-api-key-123", // Claude format
            "custom-key-format"
        ]
        
        let invalidAPIKeys = [
            "",
            "   ",
            "short"
        ]
        
        for key in validAPIKeys {
            XCTAssertTrue(key.isValidAPIKey, "Should be valid API key: \(key)")
        }
        
        for key in invalidAPIKeys {
            XCTAssertFalse(key.isValidAPIKey, "Should be invalid API key: \(key)")
        }
    }
    
    // MARK: - Performance Utilities Tests
    
    func testPerformanceMeasurement() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate some work
        Thread.sleep(forTimeInterval: 0.01)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        XCTAssertGreaterThan(duration, 0.009) // Should be at least 10ms
        XCTAssertLessThan(duration, 0.1) // Should be less than 100ms
    }
    
    func testMemoryUsage() {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        XCTAssertEqual(result, KERN_SUCCESS)
    }
    
    // MARK: - Concurrency Utilities Tests
    
    func testDispatchQueueUtilities() {
        let expectation = XCTestExpectation(description: "Async operation")
        
        DispatchQueue.global(qos: .background).async {
            // Simulate background work
            Thread.sleep(forTimeInterval: 0.01)
            
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testOperationQueueUtilities() {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        
        let expectation = XCTestExpectation(description: "Operation completion")
        expectation.expectedFulfillmentCount = 3
        
        for i in 0..<3 {
            operationQueue.addOperation {
                Thread.sleep(forTimeInterval: 0.01)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Utilities Tests
    
    func testCustomErrorTypes() {
        enum TestError: Error, LocalizedError {
            case testCase
            
            var errorDescription: String? {
                return "Test error description"
            }
        }
        
        let error = TestError.testCase
        XCTAssertEqual(error.localizedDescription, "Test error description")
    }
    
    func testErrorWrapping() {
        let originalError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Original error"])
        
        let wrappedError = NSError(
            domain: "WrapperDomain",
            code: 456,
            userInfo: [
                NSLocalizedDescriptionKey: "Wrapped error",
                NSUnderlyingErrorKey: originalError
            ]
        )
        
        XCTAssertEqual(wrappedError.localizedDescription, "Wrapped error")
        XCTAssertNotNil(wrappedError.userInfo[NSUnderlyingErrorKey])
    }
    
    // MARK: - Localization Utilities Tests
    
    func testLocalizationKeys() {
        // Test that localization keys return non-empty strings
        let testKeys = [
            "app.name",
            "button.save",
            "button.cancel",
            "error.network"
        ]
        
        for key in testKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertFalse(localizedString.isEmpty, "Localized string should not be empty for key: \(key)")
        }
    }
    
    func testCurrentLocale() {
        let currentLocale = Locale.current
        XCTAssertNotNil(currentLocale.identifier)
        XCTAssertFalse(currentLocale.identifier.isEmpty)
        
        let languageCode = currentLocale.languageCode
        XCTAssertNotNil(languageCode)
    }
    
    // MARK: - Network Utilities Tests
    
    func testNetworkReachability() {
        // Basic network reachability test
        // Note: This is a simplified test and might not work in all environments
        let url = URL(string: "https://www.apple.com")!
        let request = URLRequest(url: url, timeoutInterval: 5.0)
        
        let expectation = XCTestExpectation(description: "Network request")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertGreaterThanOrEqual(httpResponse.statusCode, 200)
                XCTAssertLessThan(httpResponse.statusCode, 500)
            }
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Cleanup Tests
    
    override func tearDown() {
        // Clean up any test data
        let userDefaults = UserDefaults.standard
        let testKeys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("test_") }
        
        for key in testKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        super.tearDown()
    }
}

// MARK: - Extensions for Testing

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension NSColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidAPIKey: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 8
    }
}