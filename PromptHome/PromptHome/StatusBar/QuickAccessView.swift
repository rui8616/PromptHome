//
//  QuickAccessView.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import SwiftData

struct QuickAccessView: View {
    let modelContext: ModelContext?
    let mcpService: MCPService?
    let onDismiss: () -> Void
    
    @State private var promptCount: Int = 0
    @State private var isAIServiceConnected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部状态信息
            headerSection
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 最近使用的提示词
                    RecentPromptsSection(
                        modelContext: modelContext,
                        onDismiss: onDismiss
                    )
                    
                    Divider()
                    
                    // 快速操作
                    QuickActionsSection(onDismiss: onDismiss)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(width: 320, height: 520)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            updateStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            updateStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recentPromptsDidChange)) { _ in
            updateStatus()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                
                Text("PromptHome")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 状态指示器
            HStack(spacing: 16) {
                StatusIndicator(
                    icon: "doc.text",
                    title: "提示词",
                    value: "\(promptCount)",
                    color: .blue
                )
                
                StatusIndicator(
                    icon: "brain",
                    title: "AI服务",
                    value: isAIServiceConnected ? "已启动" : "未启动",
                    color: isAIServiceConnected ? .green : .orange
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func updateStatus() {
        updatePromptCount()
        updateAIServiceStatus()
    }
    
    private func updatePromptCount() {
        guard let modelContext = modelContext else {
            promptCount = 0
            return
        }
        
        do {
            let descriptor = FetchDescriptor<Prompt>()
            let prompts = try modelContext.fetch(descriptor)
            promptCount = prompts.count
        } catch {
            print("Failed to fetch prompt count: \(error)")
            promptCount = 0
        }
    }
    
    private func updateAIServiceStatus() {
        isAIServiceConnected = mcpService?.isRunning ?? false
    }
}

struct StatusIndicator: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    QuickAccessView(
        modelContext: nil,
        mcpService: nil,
        onDismiss: {}
    )
}
