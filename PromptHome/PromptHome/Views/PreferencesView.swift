//
//  PreferencesView.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferencesManager = PreferencesManager.shared
    @State private var showingAutoLaunchError = false
    @State private var autoLaunchErrorMessage = ""
    @State private var isRequestingPermission = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 头部
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                
                Text(NSLocalizedString("preferences"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider()
            
            // 开机自启动选项
            VStack(spacing: 16) {
                HStack {
                    Text(NSLocalizedString("auto_launch_title"))
                        .font(.headline)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { preferencesManager.isAutoLaunchEnabled },
                        set: { newValue in
                            if newValue && !preferencesManager.isAutoLaunchEnabled {
                                // 启用自启动时，先请求权限
                                requestAutoLaunchPermission { granted in
                                    if granted {
                                        preferencesManager.isAutoLaunchEnabled = newValue
                                    }
                                }
                            } else {
                                preferencesManager.isAutoLaunchEnabled = newValue
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                    .disabled(isRequestingPermission)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 底部按钮
            HStack {
                Spacer()
                
                Button(NSLocalizedString("done")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 400, height: 200)
        .onReceive(NotificationCenter.default.publisher(for: .autoLaunchSettingFailed)) { notification in
            if let error = notification.object as? Error {
                autoLaunchErrorMessage = error.localizedDescription
                showingAutoLaunchError = true
            }
        }
        .alert(NSLocalizedString("auto_launch_error_title"), isPresented: $showingAutoLaunchError) {
            Button(NSLocalizedString("ok")) {
                showingAutoLaunchError = false
            }
        } message: {
            Text(autoLaunchErrorMessage)
        }
    }
    

    
    private func requestAutoLaunchPermission(completion: @escaping (Bool) -> Void) {
        isRequestingPermission = true
        
        preferencesManager.requestAutoLaunchPermission { granted in
            DispatchQueue.main.async {
                isRequestingPermission = false
                completion(granted)
            }
        }
    }
}



#Preview {
    PreferencesView()
}