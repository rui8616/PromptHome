//
//  PromptEditorView.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import SwiftData

struct PromptEditorView: View {
    let prompt: Prompt
    @Binding var isEditing: Bool
    @Binding var editingTitle: String
    @Binding var editingTags: [String]
    @Binding var editingContent: String
    @Binding var showingPreview: Bool
    
    @State private var tagInputText: String = ""
    
    let onSave: () -> Void
    let onDelete: (Prompt) -> Void
    
    @State private var showingDeleteAlert = false
    @State private var showingLengthLimitAlert = false
    @State private var polishedContent = ""
    @StateObject private var aiPolishService = AIPolishService()
    @Query private var aiConfigs: [AIModelConfig]
    @State private var refreshTrigger = false
    
    // Toast notification states
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .info
    
    private var activeAIConfig: AIModelConfig? {
        aiConfigs.first { $0.isActive }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                // 标题编辑
                if isEditing {
                    TextField(NSLocalizedString("prompt_title"), text: $editingTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .textFieldStyle(PlainTextFieldStyle())
                } else {
                    Text(prompt.title)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AIConfigUpdated"))) { _ in
                // Force refresh of the view to update AI polish button text
                refreshTrigger.toggle()
            }
            
            Divider()
            
            // 标签编辑区域
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    // 标签标题和输入框在同一行
                    HStack(alignment: .center) {
                        Text(NSLocalizedString("tags_label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("enter_new_tag"), text: $tagInputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 180) // 设置固定最大宽度
                            .onSubmit {
                                addTag()
                            }
                        
                        Button(NSLocalizedString("add")) {
                            addTag()
                        }
                        .disabled(tagInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Spacer() // 确保左对齐
                    }
                    
                    // 现有标签显示在下方，左对齐
                    if !editingTags.isEmpty {
                        VStack(alignment: .leading) {
                            EditableTagsView(
                                tags: editingTags,
                                isEditing: true,
                                onTagsChanged: { updatedTags in
                                    editingTags = updatedTags
                                }
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
            } else if !prompt.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        Text(NSLocalizedString("tags_label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 阅览模式下，现有标签直接显示在标签label后面
                        EditableTagsView(tags: prompt.tags, isEditing: false, onTagsChanged: { _ in })
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // 内容编辑/预览区域
            if isEditing {
                if showingPreview {
                    // Markdown 预览
                    if editingContent.isEmpty {
                        VStack {
                            Text(NSLocalizedString("no_content"))
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.textBackgroundColor))
                    } else {
                        OptimizedTextView(content: editingContent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.textBackgroundColor))
                    }
                } else {
                    // 编辑器
                    TextEditor(text: $editingContent)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(.textBackgroundColor))
                        .onChange(of: editingContent) { oldValue, newValue in
                            if newValue.count > 10000 {
                                editingContent = String(newValue.prefix(10000))
                                showingLengthLimitAlert = true
                            }
                        }
                }
            } else {
                // 只读预览
                if prompt.content.isEmpty {
                    VStack {
                        Text(NSLocalizedString("no_content"))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.textBackgroundColor))
                } else {
                    OptimizedTextView(content: prompt.content)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.textBackgroundColor))
                }
            }
            
            // 底部状态栏
            HStack {
                if isEditing {
                    Text("\(NSLocalizedString("word_count")): \(editingContent.count) / 10,000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(NSLocalizedString("word_count")): \(prompt.content.count) / 10,000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 当前使用的AI模型显示
                if let config = activeAIConfig {
                    Text(config.provider + "(" + config.selectedModel + ")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.controlBackgroundColor))
                                .stroke(Color(.separatorColor), lineWidth: 0.5)
                        )
                } else {
                    Text(NSLocalizedString("ai_model_not_set"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.controlBackgroundColor))
                                .stroke(Color(.separatorColor), lineWidth: 0.5)
                        )
                }
                
                Spacer()
                
                Text("\(NSLocalizedString("updated_at")) \(prompt.updatedAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 悬浮按钮组
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if isEditing {
                            // 编辑模式下的按钮
                            Group {
                                // AI 润色按钮
                                FloatingButton(
                                    icon: aiPolishService.isPolishing ? "arrow.triangle.2.circlepath" : "wand.and.stars",
                                    title: aiPolishService.isPolishing ? NSLocalizedString("polishing") : NSLocalizedString("polish_with_ai"),
                                    isDisabled: activeAIConfig == nil || aiPolishService.isPolishing,
                                    isLoading: aiPolishService.isPolishing
                                ) {
                                    polishContent()
                                }
                                
                                // 预览按钮
                                FloatingButton(
                                    icon: showingPreview ? "eye.slash" : "eye",
                                    title: showingPreview ? NSLocalizedString("hide_preview") : NSLocalizedString("preview")
                                ) {
                                    showingPreview.toggle()
                                }
                                
                                // 保存按钮
                                FloatingButton(
                                    icon: "checkmark",
                                    title: NSLocalizedString("save"),
                                    isPrimary: true
                                ) {
                                    onSave()
                                }
                                
                                // 取消按钮
                                FloatingButton(
                                    icon: "xmark",
                                    title: NSLocalizedString("cancel")
                                ) {
                                    isEditing = false
                                    editingTitle = prompt.title
                                    editingTags = prompt.tags
                                    editingContent = prompt.content
                                    showingPreview = false
                                    tagInputText = ""
                                }
                            }
                        } else {
                            // 查看模式下的按钮
                            Group {
                                // 编辑按钮
                                FloatingButton(
                                    icon: "pencil",
                                    title: NSLocalizedString("edit"),
                                    isPrimary: true
                                ) {
                                    isEditing = true
                                    editingTitle = prompt.title
                                    editingTags = prompt.tags
                                    editingContent = prompt.content
                                    tagInputText = ""
                                }
                                
                                // 删除按钮
                                FloatingButton(
                                    icon: "trash",
                                    title: NSLocalizedString("delete"),
                                    isDestructive: true
                                ) {
                                    showingDeleteAlert = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    )
                    .padding(.trailing, 16)
                    .padding(.bottom, 60)
                }
            }
        }
        .overlay(
            // Toast notification overlay
            VStack {
                Spacer()
                if showingToast {
                    ToastView(message: toastMessage, type: toastType)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 120) // Position above floating buttons
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showingToast)
        )
        .alert(NSLocalizedString("confirm_delete"), isPresented: $showingDeleteAlert) {
            Button(NSLocalizedString("delete"), role: .destructive) {
                onDelete(prompt)
            }
            Button(NSLocalizedString("cancel"), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("delete_prompt_message").replacingOccurrences(of: "%@", with: prompt.title))
        }

        .alert(NSLocalizedString("length_limit"), isPresented: $showingLengthLimitAlert) {
            Button(NSLocalizedString("ok")) {
                showingLengthLimitAlert = false
            }
        } message: {
            Text(NSLocalizedString("length_limit_message"))
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    private func addTag() {
        let newTag = tagInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newTag.isEmpty && !editingTags.contains(newTag) {
            editingTags.append(newTag)
            tagInputText = ""
        }
    }
    
    private func polishContent() {
        guard let config = activeAIConfig else {
            showToast(NSLocalizedString("please_configure_ai_model"), type: .error)
            return
        }
        
        // Use editingContent if in editing mode, otherwise use prompt.content
        // If both are empty, prompt user to add content first
        let contentToPolish = isEditing ? editingContent : prompt.content
        guard !contentToPolish.isEmpty else {
            showToast(NSLocalizedString("prompt_content_empty"), type: .error)
            return
        }
        
        // Show start toast
        showToast(NSLocalizedString("polish_started"), type: .info)
        
        Task {
            if let polished = await aiPolishService.polishContent(contentToPolish, using: config) {
                await MainActor.run {
                    polishedContent = polished
                    // Show completion toast and apply content directly
                    showToast(NSLocalizedString("polish_completed"), type: .success)
                    applyPolishedContent()
                }
            } else {
                await MainActor.run {
                    // Show error toast if polish failed
                    let errorMsg = aiPolishService.errorMessage ?? NSLocalizedString("polish_failed")
                    showToast(errorMsg, type: .error)
                    aiPolishService.errorMessage = nil
                }
            }
        }
    }
    
    private func showToast(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        withAnimation(.easeInOut(duration: 0.3)) {
            showingToast = true
        }
        
        // Auto hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingToast = false
            }
        }
    }
    
    private func getPolishButtonText() -> String {
        return "AI 润色"
    }
    
    private func applyPolishedContent() {
        isEditing = true
        editingTitle = prompt.title
        editingTags = prompt.tags
        editingContent = polishedContent
        showingPreview = false
        tagInputText = ""
    }
}



// 标签视图组件
struct EditableTagsView: View {
    let tags: [String]
    let isEditing: Bool
    let onTagsChanged: ([String]) -> Void
    
    init(tags: [String], isEditing: Bool, onTagsChanged: @escaping ([String]) -> Void) {
        self.tags = tags
        self.isEditing = isEditing
        self.onTagsChanged = onTagsChanged
    }
    
    var body: some View {
        FlowLayout(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 4) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Text(tag)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                        .layoutPriority(1)
                        .truncationMode(.tail)
                    
                    if isEditing {
                        Button(action: {
                            removeTag(tag)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 14, height: 14)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
    
    private func removeTag(_ tagToRemove: String) {
        let updatedTags = tags.filter { $0 != tagToRemove }
        onTagsChanged(updatedTags)
    }

}

struct FloatingButton: View {
    let icon: String
    let title: String
    let isPrimary: Bool
    let isDestructive: Bool
    let isDisabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var rotationAngle: Double = 0
    
    init(
        icon: String,
        title: String,
        isPrimary: Bool = false,
        isDestructive: Bool = false,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .rotationEffect(.degrees(rotationAngle))
                
                if isHovered || isLoading {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, (isHovered || isLoading) ? 8 : 6)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColorForButton)
                    .stroke(borderColorForButton, lineWidth: 1)
                    .overlay(
                        // Loading pulse effect
                        isLoading ? 
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                            .scaleEffect(isLoading ? 1.1 : 1.0)
                            .opacity(isLoading ? 0.5 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isLoading)
                        : nil
                    )
            )
            .foregroundColor(foregroundColorForButton)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            if isLoading {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
        .onChange(of: isLoading) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            } else {
                withAnimation(.default) {
                    rotationAngle = 0
                }
            }
        }
    }
    
    private var backgroundColorForButton: Color {
        if isDisabled {
            return Color(.controlBackgroundColor)
        }
        
        if isPrimary {
            return isHovered ? Color.accentColor.opacity(0.9) : Color.accentColor
        } else if isDestructive {
            return isHovered ? Color.red.opacity(0.9) : Color.red.opacity(0.8)
        } else {
            return isHovered ? Color(.controlAccentColor).opacity(0.2) : Color(.controlBackgroundColor)
        }
    }
    
    private var borderColorForButton: Color {
        if isDisabled {
            return Color(.separatorColor)
        }
        
        if isPrimary {
            return Color.accentColor
        } else if isDestructive {
            return Color.red
        } else {
            return isHovered ? Color(.controlAccentColor) : Color(.separatorColor)
        }
    }
    
    private var foregroundColorForButton: Color {
        if isDisabled {
            return Color(.disabledControlTextColor)
        }
        
        if isPrimary || isDestructive {
            return Color.white
        } else {
            return isHovered ? Color(.controlAccentColor) : Color(.controlTextColor)
        }
    }
}

// Toast notification types
enum ToastType {
    case info
    case success
    case error
    
    var color: Color {
        switch self {
        case .info:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

// Toast notification view
struct ToastView: View {
    let message: String
    let type: ToastType
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 16, weight: .medium))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    let prompt = Prompt(title: "示例提示词", tags: ["示例", "测试"], content: "这是一个示例提示词的内容。\n\n支持 **Markdown** 格式。")
    
    return PromptEditorView(
        prompt: prompt,
        isEditing: .constant(false),
        editingTitle: .constant(prompt.title),
        editingTags: .constant(prompt.tags),
        editingContent: .constant(prompt.content),
        showingPreview: .constant(false),
        onSave: {},
        onDelete: { _ in }
    )
    .frame(width: 600, height: 400)
    .modelContainer(for: Prompt.self, inMemory: true)
}
