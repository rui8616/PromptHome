//
//  PreferencesManager.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import Foundation
import ServiceManagement
import AppKit

@Observable
class PreferencesManager {
    static let shared = PreferencesManager()
    
    // 自启动设置
    var isAutoLaunchEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "AutoLaunchEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "AutoLaunchEnabled")
            updateAutoLaunchSetting(enabled: newValue)
        }
    }
    
    private init() {}
    
    // 更新自启动设置
    private func updateAutoLaunchSetting(enabled: Bool) {
        //let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.prompthome.app"
        
        do {
            if enabled {
                // 启用自启动
                if #available(macOS 13.0, *) {
                    try SMAppService.mainApp.register()
                } else {
                    // 对于较旧的macOS版本，使用LaunchAgent方式
                    createLaunchAgent()
                }
            } else {
                // 禁用自启动
                if #available(macOS 13.0, *) {
                    try SMAppService.mainApp.unregister()
                } else {
                    // 移除LaunchAgent
                    removeLaunchAgent()
                }
            }
        } catch {
            print("Failed to update auto launch setting: \(error)")
            // 发送错误通知
            NotificationCenter.default.post(
                name: .autoLaunchSettingFailed,
                object: error
            )
        }
    }
    
    // 检查当前自启动状态
    func checkAutoLaunchStatus() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return launchAgentExists()
        }
    }
    
    // 为旧版本macOS创建LaunchAgent
    private func createLaunchAgent() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        
        let launchAgentsPath = "\(homeDirectory)/Library/LaunchAgents"
        let plistPath = "\(launchAgentsPath)/com.prompthome.app.plist"
        
        // 确保LaunchAgents目录存在
        try? FileManager.default.createDirectory(
            atPath: launchAgentsPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let bundlePath = Bundle.main.bundlePath
        let executablePath = "\(bundlePath)/Contents/MacOS/PromptHome"
        
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.prompthome.app</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """
        
        try? plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
    }
    
    // 移除LaunchAgent
    private func removeLaunchAgent() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        
        let plistPath = "\(homeDirectory)/Library/LaunchAgents/com.prompthome.app.plist"
        try? FileManager.default.removeItem(atPath: plistPath)
    }
    
    // 检查LaunchAgent是否存在
    private func launchAgentExists() -> Bool {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        
        let plistPath = "\(homeDirectory)/Library/LaunchAgents/com.prompthome.app.plist"
        return FileManager.default.fileExists(atPath: plistPath)
    }
    
    // 请求自启动权限（仅用于用户提示）
    func requestAutoLaunchPermission(completion: @escaping (Bool) -> Void) {
        // 在macOS中，自启动权限通常不需要特殊请求
        // 但我们可以显示一个信息对话框来告知用户
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("auto_launch_permission_title", comment: "")
            alert.informativeText = NSLocalizedString("auto_launch_permission_message", comment: "")
            alert.addButton(withTitle: NSLocalizedString("allow", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("cancel", comment: ""))
            alert.alertStyle = .informational
            
            let response = alert.runModal()
            completion(response == .alertFirstButtonReturn)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let autoLaunchSettingFailed = Notification.Name("autoLaunchSettingFailed")
    static let preferencesChanged = Notification.Name("preferencesChanged")
}
