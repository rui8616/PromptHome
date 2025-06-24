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
        
        // 配置 Application Support 目录
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Could not find Application Support directory")
        }
        
        // 创建应用专属目录
        let directoryURL = appSupportURL.appendingPathComponent("PromptHome")
        let fileURL = directoryURL.appendingPathComponent("PromptHome.store")
        
        do {
            // 确保目录存在
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            
            // 创建自定义配置，指定存储位置
            let modelConfiguration = ModelConfiguration(url: fileURL)
            
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
