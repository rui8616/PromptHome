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
                }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 800, height: 600)
    }
}
