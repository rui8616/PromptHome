//
//  PromptHomeApp.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import SwiftData

@main
struct PromptHomeApp: App {
    @StateObject private var mcpService = MCPService()
    private let statusBarManager = StatusBarManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Prompt.self,
            AIModelConfig.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mcpService)
                .onAppear {
                    // 应用启动时自动启动 MCP 服务
                    mcpService.configure(modelContext: sharedModelContainer.mainContext)
                    mcpService.startServer()
                    
                    // 设置状态栏管理器
                    statusBarManager.setup(
                        modelContext: sharedModelContainer.mainContext,
                        mcpService: mcpService
                    )
                }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 800, height: 600)
        .commands {
            // 移除默认的文件菜单中的一些项目
            CommandGroup(replacing: .newItem) {
                Button("新建提示词") {
                    NotificationCenter.default.post(name: .createNewPrompt, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
