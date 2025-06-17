//
//  Prompt.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import Foundation
import SwiftData

@Model
final class Prompt: Codable {
    var id: UUID
    var title: String
    var tags: [String]
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String, tags: [String] = [], content: String = "") {
        self.id = UUID()
        self.title = title
        self.tags = tags
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateContent(title: String? = nil, tags: [String]? = nil, content: String? = nil) {
        if let title = title {
            self.title = title
        }
        if let tags = tags {
            self.tags = tags
        }
        if let content = content {
            self.content = content
        }
        self.updatedAt = Date()
    }
    
    // 为了兼容性，提供tag属性的计算属性
    var tag: String {
        get {
            return tags.joined(separator: ", ")
        }
        set {
            tags = newValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, title, tags, content, createdAt, updatedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.content = try container.decode(String.self, forKey: .content)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(tags, forKey: .tags)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
