//
//  QuickActionsSection.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import AppKit

struct QuickActionsSection: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("快速操作")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 4) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "新建提示词",
                    action: {
                        StatusBarManager.shared.createNewPrompt()
                        onDismiss()
                    }
                )
                
                QuickActionButton(
                    icon: "magnifyingglass",
                    title: "搜索提示词",
                    action: {
                        StatusBarManager.shared.openSearch()
                        onDismiss()
                    }
                )
                
                QuickActionButton(
                    icon: "eye",
                    title: "显示主窗口",
                    action: {
                        StatusBarManager.shared.showMainWindow()
                        onDismiss()
                    }
                )
                
                QuickActionButton(
                    icon: "gearshape.fill",
                    title: "偏好设置",
                    action: {
                        openPreferences()
                        onDismiss()
                    }
                )
                
                Divider()
                    .padding(.vertical, 4)
                
                QuickActionButton(
                    icon: "power",
                    title: "退出应用",
                    isDestructive: true,
                    action: {
                        NSApp.terminate(nil)
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private func openPreferences() {
        // 显示主窗口并发送打开偏好设置的通知
        StatusBarManager.shared.showMainWindow()
        NotificationCenter.default.post(name: .openPreferences, object: nil)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    init(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : .accentColor)
                    .frame(width: 16, height: 16)
                
                Text(title)
                    .foregroundColor(isDestructive ? .red : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
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
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let openPreferences = Notification.Name("openPreferences")
}