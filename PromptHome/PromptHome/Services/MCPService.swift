//
//  MCPService.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import Foundation
import SwiftData
import OSLog

/// Legacy MCP Service wrapper that uses the new MCP implementation
class MCPService: ObservableObject {
    @Published var isRunning = false
    @Published var serverAddress = "http://localhost:3001"
    @Published var errorMessage: String?
    
    private let mcpServer = MCPServer()
    private let mcpClient = MCPClient()
    private let logger = Logger(subsystem: "PromptHome", category: "MCPService")
    
    private var modelContext: ModelContext?
    
    init() {
        // Observe server state changes
        mcpServer.$isRunning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRunning)
        
        mcpServer.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        mcpServer.configure(with: modelContext)
    }
    
    func startServer() {
        guard !isRunning else { return }
        mcpServer.start()
    }
    
    func stopServer() {
        mcpServer.stop()
    }
    
    // Client functionality for testing
    func testConnection() async throws -> String {
        var results = "正在连接到 MCP 服务器..."
        
        // 连接到服务器
        try await mcpClient.connect(to: "localhost", port: 3001)
        results += "\n✓ 连接成功"
        
        // 测试获取提示词列表
        let prompts = try await mcpClient.listPrompts()
        results += "\n✓ 获取提示词列表成功，共 \(prompts.count) 个提示词"
        
        if !prompts.isEmpty {
            results += "\n提示词列表:"
            for prompt in prompts.prefix(3) {
                results += "\n  - \(prompt.name): \(prompt.description ?? "无描述")"
            }
            if prompts.count > 3 {
                results += "\n  ... 还有 \(prompts.count - 3) 个提示词"
            }
            
            // 测试获取第一个提示词的详细内容
            if let firstPrompt = prompts.first {
                do {
                    let promptDetail = try await mcpClient.getPrompt(name: firstPrompt.name, arguments: [:])
                    results += "\n✓ 获取提示词详情成功: \(promptDetail.description ?? "无描述")"
                    results += "\n  消息数量: \(promptDetail.messages.count)"
                } catch {
                    results += "\n⚠ 获取提示词详情失败: \(error.localizedDescription)"
                }
            }
        } else {
            results += "\n⚠ 提示词列表为空"
        }
        
        return results
    }

}