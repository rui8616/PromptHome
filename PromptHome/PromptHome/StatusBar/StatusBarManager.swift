//
//  StatusBarManager.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import AppKit
import SwiftData

@Observable
class StatusBarManager {
    static let shared = StatusBarManager()
    
    private var statusBarItem: NSStatusItem?
    private var popover: NSPopover?
    private var modelContext: ModelContext?
    private var mcpService: MCPService?
    
    // 状态数据
    var promptCount: Int = 0
    var isAIServiceConnected: Bool = false
    
    private init() {}
    
    func setup(modelContext: ModelContext, mcpService: MCPService) {
        self.modelContext = modelContext
        self.mcpService = mcpService
        
        setupStatusBarItem()
        setupPopover()
        updatePromptCount()
        updateAIServiceStatus()
        
        // 监听数据变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataDidChange),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            // 使用SF Symbol作为默认图标
            button.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "PromptHome")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
            
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            
            updateStatusBarTitle()
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: QuickAccessView(
                modelContext: modelContext,
                mcpService: mcpService,
                onDismiss: { [weak self] in
                    self?.hidePopover()
                }
            )
        )
    }
    
    @objc private func statusBarButtonClicked() {
        guard let button = statusBarItem?.button else { return }
        
        if popover?.isShown == true {
            hidePopover()
        } else {
            showPopover(relativeTo: button)
        }
    }
    
    private func showPopover(relativeTo view: NSView) {
        // 每次显示时重新创建内容视图以确保数据最新
        popover?.contentViewController = NSHostingController(
            rootView: QuickAccessView(
                modelContext: modelContext,
                mcpService: mcpService,
                onDismiss: { [weak self] in
                    self?.hidePopover()
                }
            )
        )
        
        popover?.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
    
    private func hidePopover() {
        popover?.performClose(nil)
    }
    
    @objc private func dataDidChange() {
        DispatchQueue.main.async {
            self.updatePromptCount()
        }
    }
    
    private func updatePromptCount() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Prompt>()
            let prompts = try modelContext.fetch(descriptor)
            promptCount = prompts.count
            updateStatusBarTitle()
        } catch {
            print("Failed to fetch prompt count: \(error)")
        }
    }
    
    private func updateAIServiceStatus() {
        // 这里可以根据实际的AI服务状态来更新
        // 暂时设置为true，后续可以根据mcpService的状态来判断
        isAIServiceConnected = mcpService?.isRunning ?? false
        updateStatusBarTitle()
    }
    
    private func updateStatusBarTitle() {
        guard let button = statusBarItem?.button else { return }
        
        // 设置工具提示
        let statusText = isAIServiceConnected ? "已启动" : "未启动"
        button.toolTip = "PromptHome - \(promptCount) 个提示词 | AI服务: \(statusText)"
    }
    
    func showMainWindow() {
        // 显示主窗口
        NSApp.activate(ignoringOtherApps: true)
        
        // 如果主窗口被最小化，恢复它
        for window in NSApp.windows {
            if window.title.contains("PromptHome") || window.contentViewController is NSHostingController<ContentView> {
                window.makeKeyAndOrderFront(nil)
                window.deminiaturize(nil)
                break
            }
        }
    }
    
    func createNewPrompt() {
        showMainWindow()
        
        // 发送通知来触发新建提示词
        NotificationCenter.default.post(name: .createNewPrompt, object: nil)
    }
    
    func openPrompt(with id: UUID) {
        showMainWindow()
        
        // 发送通知来打开特定提示词
        NotificationCenter.default.post(name: .openPrompt, object: id)
    }
    
    func openSearch() {
        showMainWindow()
        
        // 发送通知来聚焦搜索框
        NotificationCenter.default.post(name: .focusSearch, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let createNewPrompt = Notification.Name("createNewPrompt")
    static let openPrompt = Notification.Name("openPrompt")
    static let focusSearch = Notification.Name("focusSearch")
}
