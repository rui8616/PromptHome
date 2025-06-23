//
//  RecentPromptsManager.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import Foundation
import SwiftData

class RecentPromptsManager: ObservableObject {
    static let shared = RecentPromptsManager()
    
    private let maxRecentCount = 5
    private let userDefaults = UserDefaults.standard
    private let recentPromptsKey = "RecentPrompts"
    
    @Published private(set) var recentPrompts: [RecentPromptItem] = []
    
    private init() {
        loadRecentPrompts()
    }
    
    func addRecentPrompt(_ prompt: Prompt) {
        let recentItem = RecentPromptItem(
            id: prompt.id,
            title: prompt.title,
            accessedAt: Date()
        )
        
        // 移除已存在的相同项目
        recentPrompts.removeAll { $0.id == prompt.id }
        
        // 添加到开头
        recentPrompts.insert(recentItem, at: 0)
        
        // 保持最大数量限制
        if recentPrompts.count > maxRecentCount {
            recentPrompts = Array(recentPrompts.prefix(maxRecentCount))
        }
        
        saveRecentPrompts()
    }
    
    func clearRecentPrompts() {
        recentPrompts.removeAll()
        saveRecentPrompts()
    }
    
    private func loadRecentPrompts() {
        if let data = userDefaults.data(forKey: recentPromptsKey),
           let decoded = try? JSONDecoder().decode([RecentPromptItem].self, from: data) {
            recentPrompts = decoded
        }
    }
    
    private func saveRecentPrompts() {
        if let encoded = try? JSONEncoder().encode(recentPrompts) {
            userDefaults.set(encoded, forKey: recentPromptsKey)
            
            // 发送通知，通知UI更新
            NotificationCenter.default.post(name: .recentPromptsDidChange, object: nil)
        }
    }
}

struct RecentPromptItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let accessedAt: Date
    
    var displayTitle: String {
        if title.count > 30 {
            return String(title.prefix(30)) + "..."
        }
        return title
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let recentPromptsDidChange = Notification.Name("recentPromptsDidChange")
}