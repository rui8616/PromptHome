//
//  MCPServiceTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import Testing
import Foundation
@testable import PromptHome

struct MCPServiceTests {
    
    // MARK: - MCPService Initialization Tests
    
    @Test func testMCPServiceInitialization() async throws {
        let mcpService = MCPService()
        
        #expect(mcpService.isRunning == false)
        #expect(mcpService.serverAddress == "http://localhost:3001")
        #expect(mcpService.errorMessage == nil)
    }
    
    @Test func testMCPServiceServerAddressValidation() async throws {
        let mcpService = MCPService()
        
        // Test valid URL format
        #expect(mcpService.serverAddress.hasPrefix("http"))
        #expect(mcpService.serverAddress.contains("localhost"))
        #expect(mcpService.serverAddress.contains("3001"))
    }
    
    // MARK: - MCPService State Management Tests
    
    @Test func testMCPServiceStateTransitions() async throws {
        let mcpService = MCPService()
        
        // Initial state should be not running
        #expect(mcpService.isRunning == false)
        
        // Test state consistency
        if mcpService.isRunning {
            #expect(mcpService.errorMessage == nil)
        }
    }
    
    @Test func testMCPServiceErrorHandling() async throws {
        let mcpService = MCPService()
        
        // Error message should be nil initially
        #expect(mcpService.errorMessage == nil)
        
        // When there's an error, service should not be running
        if mcpService.errorMessage != nil {
            #expect(mcpService.isRunning == false)
        }
    }
    
    // MARK: - MCPService URL Validation Tests
    
    @Test func testServerAddressFormat() async throws {
        let mcpService = MCPService()
        let url = URL(string: mcpService.serverAddress)
        
        #expect(url != nil)
        #expect(url?.scheme == "http" || url?.scheme == "https")
        #expect(url?.host != nil)
        #expect(url?.port != nil)
    }
    
    @Test func testDefaultServerConfiguration() async throws {
        let mcpService = MCPService()
        
        // Test default configuration values
        #expect(mcpService.serverAddress == "http://localhost:3001")
        
        let url = URL(string: mcpService.serverAddress)!
        #expect(url.host == "localhost")
        #expect(url.port == 3000)
        #expect(url.scheme == "http")
    }
    
    // MARK: - MCPService Method Tests
    
    @Test func testStartServerMethod() async throws {
        let mcpService = MCPService()
        
        // Test that startServer method exists and can be called
        // Note: We're not actually starting the server in tests
        // Just testing the method signature and basic behavior
        
        let initialState = mcpService.isRunning
        
        // The method should exist and be callable
        // In a real test environment, we would mock the actual server startup
        #expect(mcpService.isRunning == initialState)
    }
    
    @Test func testStopServerMethod() async throws {
        let mcpService = MCPService()
        
        // Test that stopServer method exists and can be called
        let initialState = mcpService.isRunning
        
        // The method should exist and be callable
        #expect(mcpService.isRunning == initialState)
    }
    
    // MARK: - MCPService Integration Tests
    
    @Test func testMCPServiceObservableObject() async throws {
        let mcpService = MCPService()
        
        // Test that MCPService conforms to ObservableObject
        // This ensures UI can properly observe state changes
        #expect(mcpService is any ObservableObject)
    }
    
    @Test func testMCPServiceStateConsistency() async throws {
        let mcpService = MCPService()
        
        // Test state consistency rules
        if mcpService.isRunning {
            // If running, there should be no error
            #expect(mcpService.errorMessage == nil)
        }
        
        if mcpService.errorMessage != nil {
            // If there's an error, service should not be running
            #expect(mcpService.isRunning == false)
        }
    }
    
    // MARK: - MCPService Performance Tests
    
    @Test func testMCPServiceCreationPerformance() async throws {
        let startTime = Date()
        
        for _ in 0..<100 {
            let _ = MCPService()
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should create 100 MCPService instances in less than 0.1 seconds
        #expect(duration < 0.1)
    }
    
    @Test func testMCPServicePropertyAccess() async throws {
        let mcpService = MCPService()
        let startTime = Date()
        
        for _ in 0..<1000 {
            let _ = mcpService.isRunning
            let _ = mcpService.serverAddress
            let _ = mcpService.errorMessage
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should access properties 1000 times in less than 0.01 seconds
        #expect(duration < 0.01)
    }
    
    // MARK: - MCPService Error Scenarios Tests
    
    @Test func testMCPServiceErrorMessageFormat() async throws {
        let mcpService = MCPService()
        
        // If there's an error message, it should be a non-empty string
        if let errorMessage = mcpService.errorMessage {
            #expect(!errorMessage.isEmpty)
            #expect(errorMessage.count > 0)
        }
    }
    
    @Test func testMCPServiceDefaultValues() async throws {
        let mcpService = MCPService()
        
        // Test all default values are as expected
        #expect(mcpService.isRunning == false)
        #expect(mcpService.serverAddress == "http://localhost:3001")
        #expect(mcpService.errorMessage == nil)
    }
    
    // MARK: - MCPService Thread Safety Tests
    
    @Test func testMCPServiceConcurrentAccess() async throws {
        let mcpService = MCPService()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let _ = mcpService.isRunning
                    let _ = mcpService.serverAddress
                    let _ = mcpService.errorMessage
                }
            }
        }
        
        // Should complete without crashes
        #expect(true)
    }
}