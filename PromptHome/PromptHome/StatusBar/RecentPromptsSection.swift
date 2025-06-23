//
//  RecentPromptsSection.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import SwiftData

struct RecentPromptsSection: View {
    let modelContext: ModelContext?
    let onDismiss: () -> Void
    
    @ObservedObject private var recentManager = RecentPromptsManager.shared
    
    private var recentPrompts: [RecentPromptItem] {
        recentManager.recentPrompts
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("最近使用")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !recentPrompts.isEmpty {
                    Button("清除") {
                        clearRecentPrompts()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            if recentPrompts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Text("暂无最近使用的提示词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 2) {
                    ForEach(recentPrompts) { item in
                        RecentPromptRow(
                            item: item,
                            onTap: {
                                openPrompt(item.id)
                            }
                        )
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func clearRecentPrompts() {
        RecentPromptsManager.shared.clearRecentPrompts()
    }
    
    private func openPrompt(_ id: UUID) {
        StatusBarManager.shared.openPrompt(with: id)
        onDismiss()
    }
}

struct RecentPromptRow: View {
    let item: RecentPromptItem
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .foregroundColor(.accentColor)
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(formatAccessTime(item.accessedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                if isHovered {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func formatAccessTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}