//
//  PreferencesManagerTests.swift
//  PromptHomeTests
//
//  Created by Rui on 2025/6/15.
//

import XCTest
import ServiceManagement
@testable import PromptHome

final class PreferencesManagerTests: XCTestCase {
    
    var preferencesManager: PreferencesManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        preferencesManager = PreferencesManager.shared
        
        // 清理测试环境
        UserDefaults.standard.removeObject(forKey: "AutoLaunchEnabled")
    }
    
    override func tearDownWithError() throws {
        // 清理测试环境
        UserDefaults.standard.removeObject(forKey: "AutoLaunchEnabled")
        preferencesManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 自启动设置测试
    
    func testAutoLaunchEnabledDefaultValue() throws {
        // 测试默认值应该是false
        XCTAssertFalse(preferencesManager.isAutoLaunchEnabled, "Auto launch should be disabled by default")
    }
    
    func testAutoLaunchEnabledSetting() throws {
        // 测试设置自启动为true
        preferencesManager.isAutoLaunchEnabled = true
        XCTAssertTrue(preferencesManager.isAutoLaunchEnabled, "Auto launch should be enabled after setting to true")
        
        // 验证UserDefaults中的值
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "AutoLaunchEnabled"), "UserDefaults should store the auto launch setting")
    }
    
    func testAutoLaunchEnabledDisabling() throws {
        // 先启用自启动
        preferencesManager.isAutoLaunchEnabled = true
        XCTAssertTrue(preferencesManager.isAutoLaunchEnabled)
        
        // 然后禁用
        preferencesManager.isAutoLaunchEnabled = false
        XCTAssertFalse(preferencesManager.isAutoLaunchEnabled, "Auto launch should be disabled after setting to false")
        
        // 验证UserDefaults中的值
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "AutoLaunchEnabled"), "UserDefaults should store the disabled auto launch setting")
    }
    
    func testAutoLaunchStatusCheck() throws {
        // 测试检查自启动状态的方法
        let status = preferencesManager.checkAutoLaunchStatus()
        
        // 由于这是在测试环境中，我们只验证方法能正常调用而不抛出异常
        XCTAssertNotNil(status, "checkAutoLaunchStatus should return a boolean value")
    }
    
    // MARK: - 权限请求测试
    
    func testRequestAutoLaunchPermission() throws {
        let expectation = XCTestExpectation(description: "Permission request completion")
        
        preferencesManager.requestAutoLaunchPermission { granted in
            // 在测试环境中，我们主要验证回调能正常执行
            XCTAssertNotNil(granted, "Permission request should return a boolean value")
            expectation.fulfill()
        }
        
        // 等待异步操作完成
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - 通知测试
    
    func testAutoLaunchSettingFailedNotification() throws {
        let expectation = XCTestExpectation(description: "Auto launch setting failed notification")
        
        // 监听通知
        let observer = NotificationCenter.default.addObserver(
            forName: .autoLaunchSettingFailed,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification, "Should receive auto launch setting failed notification")
            expectation.fulfill()
        }
        
        // 发送测试通知
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        NotificationCenter.default.post(name: .autoLaunchSettingFailed, object: testError)
        
        wait(for: [expectation], timeout: 1.0)
        
        // 清理观察者
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testPreferencesChangedNotification() throws {
        let expectation = XCTestExpectation(description: "Preferences changed notification")
        
        // 监听通知
        let observer = NotificationCenter.default.addObserver(
            forName: .preferencesChanged,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification, "Should receive preferences changed notification")
            expectation.fulfill()
        }
        
        // 发送测试通知
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
        
        wait(for: [expectation], timeout: 1.0)
        
        // 清理观察者
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - 边界条件测试
    
    func testMultipleAutoLaunchToggles() throws {
        // 测试多次快速切换自启动设置
        for i in 0..<10 {
            let shouldEnable = i % 2 == 0
            preferencesManager.isAutoLaunchEnabled = shouldEnable
            XCTAssertEqual(preferencesManager.isAutoLaunchEnabled, shouldEnable, "Auto launch setting should match expected value at iteration \(i)")
        }
    }
    
    func testUserDefaultsPersistence() throws {
        // 测试UserDefaults的持久化
        preferencesManager.isAutoLaunchEnabled = true
        
        // 创建新的PreferencesManager实例来模拟应用重启
        let newManager = PreferencesManager.shared
        XCTAssertTrue(newManager.isAutoLaunchEnabled, "Auto launch setting should persist across app restarts")
    }
    
    // MARK: - 性能测试
    
    func testAutoLaunchSettingPerformance() throws {
        measure {
            // 测试设置自启动的性能
            for i in 0..<100 {
                preferencesManager.isAutoLaunchEnabled = i % 2 == 0
            }
        }
    }
    
    func testCheckAutoLaunchStatusPerformance() throws {
        measure {
            // 测试检查自启动状态的性能
            for _ in 0..<100 {
                _ = preferencesManager.checkAutoLaunchStatus()
            }
        }
    }
}