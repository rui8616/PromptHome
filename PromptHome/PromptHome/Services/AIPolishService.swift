//
//  AIPolishService.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import Foundation
import SwiftData

struct AIPolishRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int?
    
    init(model: String, content: String) {
        self.model = model
        self.messages = [
            ChatMessage(role: "system", content: "你是一个专业的提示词优化专家。请帮助用户优化和润色提示词，使其更加清晰、准确和有效。请保持原意的同时，改进表达方式、逻辑结构和专业性。直接返回优化后的Markdown格式的提示词内容，不需要额外的解释。"),
            ChatMessage(role: "user", content: "请优化以下提示词：\n\n\(content)")
        ]
        self.temperature = 0.7
        self.max_tokens = 10000
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct AIPolishResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: ChatMessage
    }
}

class AIPolishService: ObservableObject {
    @Published var isPolishing = false
    @Published var errorMessage: String?
    
    func polishContent(_ content: String, using config: AIModelConfig) async -> String? {
        await MainActor.run {
            isPolishing = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isPolishing = false
            }
        }
        
        guard !config.baseURL.isEmpty else {
            await MainActor.run {
                errorMessage = "Base URL 未配置"
            }
            return nil
        }
        
        guard !config.selectedModel.isEmpty else {
            await MainActor.run {
                errorMessage = "未选择模型"
            }
            return nil
        }
        
        // For providers that require API key
        if config.modelProvider.requiresAPIKey && config.apiKey.isEmpty {
            await MainActor.run {
                errorMessage = "API Key 未配置"
            }
            return nil
        }
        
        do {
            let result = try await callAIAPI(content: content, config: config)
            return result
        } catch {
            await MainActor.run {
                if let urlError = error as? URLError {
                    print("Network error details: \(urlError)")
                    print("Failed URL: \(urlError.failingURL?.absoluteString ?? "Unknown")")
                    
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMessage = "网络连接失败，请检查网络设置"
                    case .cannotFindHost:
                        errorMessage = "DNS解析失败，无法找到服务器 \(urlError.failingURL?.host ?? "")。请检查：\n1. 网络连接是否正常\n2. API地址是否正确\n3. 是否需要VPN或代理"
                    case .timedOut:
                        errorMessage = "请求超时，请稍后重试或检查网络连接"
                    case .cannotConnectToHost:
                        errorMessage = "无法连接到服务器 \(urlError.failingURL?.host ?? "")，请检查：\n1. 服务器是否可用\n2. 网络防火墙设置\n3. API地址是否正确"
                    case .dnsLookupFailed:
                        errorMessage = "DNS查询失败，请检查网络设置或尝试更换DNS服务器"
                    case .networkConnectionLost:
                        errorMessage = "网络连接中断，请检查网络稳定性"
                    default:
                        errorMessage = "网络错误 (\(urlError.code.rawValue)): \(urlError.localizedDescription)"
                    }
                } else {
                    errorMessage = "AI润色失败: \(error.localizedDescription)"
                }
            }
            return nil
        }
    }
    
    private func callAIAPI(content: String, config: AIModelConfig) async throws -> String {
        let endpoint: String
        if config.modelProvider == .ollama {
            endpoint = "\(config.baseURL)/api/chat"
        } else {
            endpoint = "\(config.baseURL)/chat/completions"
        }
        
        guard let url = URL(string: endpoint) else {
            print("Invalid URL: \(endpoint)")
            throw AIPolishError.invalidURL
        }
        
        print("Making request to: \(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header for providers that require API key
        if config.modelProvider.requiresAPIKey {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: Data
        if config.modelProvider == .ollama {
            // Ollama API format
            let ollamaRequest = OllamaRequest(
                model: config.selectedModel,
                messages: [
                    ChatMessage(role: "system", content: "你是一个专业的提示词优化专家。请帮助用户优化和润色提示词，使其更加清晰、准确和有效。请保持原意的同时，改进表达方式、逻辑结构和专业性。直接返回优化后的提示词内容，不需要额外的解释。"),
                    ChatMessage(role: "user", content: "请优化以下提示词：\n\n\(content)")
                ],
                stream: false
            )
            requestBody = try JSONEncoder().encode(ollamaRequest)
        } else {
            // OpenAI/Deepseek API format
            let aiRequest = AIPolishRequest(model: config.selectedModel, content: content)
            requestBody = try JSONEncoder().encode(aiRequest)
        }
        
        request.httpBody = requestBody
        
        // Create custom URLSession with proper configuration
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 60.0
        sessionConfig.waitsForConnectivity = true
        sessionConfig.allowsCellularAccess = true
        sessionConfig.allowsConstrainedNetworkAccess = true
        sessionConfig.allowsExpensiveNetworkAccess = true
        
        let session = URLSession(configuration: sessionConfig)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIPolishError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIPolishError.httpError(httpResponse.statusCode)
        }
        
        if config.modelProvider == .ollama {
            let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
            return ollamaResponse.message.content
        } else {
            let aiResponse = try JSONDecoder().decode(AIPolishResponse.self, from: data)
            guard let firstChoice = aiResponse.choices.first else {
                throw AIPolishError.noResponse
            }
            return firstChoice.message.content
        }
    }
}

struct OllamaRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let stream: Bool
}

struct OllamaResponse: Codable {
    let message: ChatMessage
}

enum AIPolishError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .noResponse:
            return "未收到有效响应"
        }
    }
}