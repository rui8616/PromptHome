//
//  AIModelConfig.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import Foundation
import SwiftData

enum ModelProvider: String, CaseIterable, Codable {
    case openai = "OpenAI"
    case deepseek = "Deepseek"
    case ollama = "Ollama"
    
    var defaultBaseURL: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1"
        case .deepseek:
            return "https://api.deepseek.com/v1"
        case .ollama:
            return "http://localhost:11434"
        }
    }
    
    var defaultModels: [String] {
        switch self {
        case .openai:
            return ["gpt-4o", "gpt-4o-mini", "gpt-4.1"]
        case .deepseek:
            return ["deepseek-chat", "deepseek-reasoner"]
        case .ollama:
            return [] // Ollama models will be fetched dynamically
        }
    }
    
    // Fetch available models from Ollama API
    static func fetchOllamaModels(baseURL: String = "http://localhost:11434") async -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            return ["qwen3:8b", "llama3:8b"] // fallback
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
            return response.models.map { $0.name }
        } catch {
            print("Failed to fetch Ollama models: \(error)")
            return ["qwen3:8b", "llama3:8b"] // fallback
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .openai, .deepseek:
            return true
        case .ollama:
            return false
        }
    }
}

@Model
final class AIModelConfig: Codable {
    var id: UUID
    var provider: String
    var baseURL: String
    var apiKey: String
    var selectedModel: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(provider: ModelProvider, baseURL: String? = nil, apiKey: String = "", selectedModel: String? = nil) {
        self.id = UUID()
        self.provider = provider.rawValue
        self.baseURL = baseURL ?? provider.defaultBaseURL
        self.apiKey = apiKey
        self.selectedModel = selectedModel ?? provider.defaultModels.first ?? ""
        self.isActive = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var modelProvider: ModelProvider {
        return ModelProvider(rawValue: provider) ?? .openai
    }
    
    func updateConfig(baseURL: String? = nil, apiKey: String? = nil, selectedModel: String? = nil, isActive: Bool? = nil) {
        if let baseURL = baseURL {
            self.baseURL = baseURL
        }
        if let apiKey = apiKey {
            self.apiKey = apiKey
        }
        if let selectedModel = selectedModel {
            self.selectedModel = selectedModel
        }
        if let isActive = isActive {
            self.isActive = isActive
        }
        self.updatedAt = Date()
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, provider, baseURL, apiKey, selectedModel, isActive, createdAt, updatedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.provider = try container.decode(String.self, forKey: .provider)
        self.baseURL = try container.decode(String.self, forKey: .baseURL)
        self.apiKey = try container.decode(String.self, forKey: .apiKey)
        self.selectedModel = try container.decode(String.self, forKey: .selectedModel)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(provider, forKey: .provider)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(selectedModel, forKey: .selectedModel)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// Response structure for Ollama models API
struct OllamaModelsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
    let size: Int?
    let digest: String?
    let modified_at: String?
    
    enum CodingKeys: String, CodingKey {
        case name, size, digest
        case modified_at = "modified_at"
    }
}
