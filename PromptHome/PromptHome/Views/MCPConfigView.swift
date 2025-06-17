//
//  MCPConfigView.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import SwiftData

struct MCPConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var mcpService: MCPService
    @State private var isCopyButtonHovered = false

    
    private let mcpConfiguration = """
{
  "mcpServers": {
    "prompt-home": {
      "url": "http://localhost:3001/api/mcp",
      "transport": "http"
    }
  }
}
"""
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text(NSLocalizedString("mcp_configuration", comment: ""))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(.windowBackgroundColor))
            
            // 配置内容区域
            VStack(spacing: 20) {
                // 服务状态区域
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(NSLocalizedString("mcp_service_status", comment: ""))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(mcpService.isRunning ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(mcpService.isRunning ? NSLocalizedString("running", comment: "") : NSLocalizedString("stopped", comment: ""))
                                .font(.caption)
                                .foregroundColor(mcpService.isRunning ? .green : .red)
                        }
                    }
                    
                    if mcpService.isRunning {
                        Text(String(format: NSLocalizedString("service_address_format", comment: ""), mcpService.serverAddress))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let errorMessage = mcpService.errorMessage {
                        Text(String(format: NSLocalizedString("error_format", comment: ""), errorMessage))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(16)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                

                
                // JSON 配置显示区域
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("configuration_example", comment: ""))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ScrollView {
                        Text(mcpConfiguration)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                    }
                    .frame(height: 150)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
                }
                
                // 复制按钮
                Button(action: copyConfiguration) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                        Text(NSLocalizedString("copy_configuration", comment: ""))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: isCopyButtonHovered ?
                                [Color.black.opacity(0.9), Color.black.opacity(0.7)] :
                                [Color.black, Color.black.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .scaleEffect(isCopyButtonHovered ? 1.02 : 1.0)
                    .shadow(color: Color.black.opacity(isCopyButtonHovered ? 0.3 : 0.2),
                           radius: isCopyButtonHovered ? 6 : 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCopyButtonHovered = hovering
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(Color(.windowBackgroundColor))
        }
        .frame(width: 500, height: 450)
        .background(Color(.windowBackgroundColor))
    }
    
    private func copyConfiguration() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(mcpConfiguration, forType: .string)
        
        // 可以添加一个临时的成功提示
        // TODO: 添加复制成功的视觉反馈
    }
    

}

#Preview {
    MCPConfigView()
}
