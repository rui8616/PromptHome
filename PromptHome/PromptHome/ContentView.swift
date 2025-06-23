//
//  ContentView.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// 语言管理类
class LanguageManager: ObservableObject {
    @Published var currentLanguage: String = "zh-Hans" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            // 更新应用语言
            Bundle.setLanguage(currentLanguage)
        }
    }
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            currentLanguage = savedLanguage
            Bundle.setLanguage(currentLanguage)
        }
    }
    
    func toggleLanguage() {
        currentLanguage = currentLanguage == "zh-Hans" ? "en" : "zh-Hans"
    }
}

// 主题管理类
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "AppTheme")
        }
    }
    
    init() {
        // 检查是否有保存的主题设置
        if UserDefaults.standard.object(forKey: "AppTheme") != nil {
            isDarkMode = UserDefaults.standard.bool(forKey: "AppTheme")
        } else {
            // 如果没有保存的设置，使用系统当前主题
            isDarkMode = NSApp.effectiveAppearance.name == .darkAqua
        }
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}

// Bundle扩展用于动态语言切换
extension Bundle {
    private static var bundle: Bundle!
    
    public static func localizedBundle() -> Bundle! {
        if bundle == nil {
            return Bundle.main
        }
        return bundle
    }
    
    public static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {
            bundle = Bundle.main
            return
        }
        
        bundle = Bundle(path: path)
    }
}

class AnyLanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = Bundle.localizedBundle() else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

// 本地化字符串函数
func NSLocalizedString(_ key: String) -> String {
    return Bundle.localizedBundle().localizedString(forKey: key, value: key, table: nil)
}

// 分页管理器
class PaginationManager: ObservableObject {
    @Published var prompts: [Prompt] = []
    @Published var isLoading = false
    @Published var hasMoreData = true
    
    private let pageSize = 20
    private var currentPage = 0
    private var modelContext: ModelContext?
    private var searchText = ""
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func loadInitialData(searchText: String = "") {
        self.searchText = searchText
        currentPage = 0
        prompts.removeAll()
        hasMoreData = true
        loadMoreData()
    }
    
    func loadMoreData() {
        guard !isLoading, hasMoreData, let context = modelContext else { return }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let offset = self.currentPage * self.pageSize
            
            do {
                var descriptor = FetchDescriptor<Prompt>(
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
                descriptor.fetchLimit = self.pageSize
                descriptor.fetchOffset = offset
                
                // 如果有搜索文本，添加过滤条件
                if !self.searchText.isEmpty {
                    let searchTerm = self.searchText
                    descriptor.predicate = #Predicate<Prompt> { prompt in
                        prompt.title.localizedStandardContains(searchTerm) ||
                        prompt.content.localizedStandardContains(searchTerm)
                    }
                }
                
                let newPrompts = try context.fetch(descriptor)
                
                DispatchQueue.main.async {
                    if newPrompts.count < self.pageSize {
                        self.hasMoreData = false
                    }
                    
                    self.prompts.append(contentsOf: newPrompts)
                    self.currentPage += 1
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    print("分页查询错误: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func refresh() {
        loadInitialData(searchText: searchText)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var mcpService: MCPService
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var paginationManager = PaginationManager()
    @State private var selectedPrompt: Prompt?
    @State private var searchText = ""
    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var editingTags: [String] = []
    @State private var editingContent = ""
    @State private var showingPreview = false
    @State private var showingAIModelConfig = false
    @State private var showingMCPConfig = false
    @State private var isNewButtonHovered = false
    @State private var isSearchFieldHovered = false
    @State private var isAIModelButtonHovered = false
    @State private var isMCPServiceButtonHovered = false
    @State private var isLanguageButtonHovered = false
    @State private var isThemeButtonHovered = false
    @State private var showingToolsMenu = false
    @State private var isToolsButtonHovered = false
    @State private var showingExportDialog = false
    @State private var showingImportDialog = false
    @State private var showingDuplicateAlert = false
    @State private var duplicatePrompts: [Prompt] = []
    @State private var importedPrompts: [Prompt] = []
    @State private var isExportButtonHovered = false
    @State private var isImportButtonHovered = false
    
    var filteredPrompts: [Prompt] {
        return paginationManager.prompts
    }
    
    var body: some View {
        NavigationSplitView {
            // 左侧导航栏
            VStack(spacing: 0) {
                // 新建提示词按钮
                Button(action: createNewPrompt) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .rotationEffect(.degrees(isNewButtonHovered ? 90 : 0))
                        Text(NSLocalizedString("new_prompt"))
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: isNewButtonHovered ? 
                                [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.7)] :
                                [Color.accentColor, Color.accentColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.accentColor.opacity(isNewButtonHovered ? 0.5 : 0.3), 
                           radius: isNewButtonHovered ? 6 : 4, x: 0, y: 2)
                    .scaleEffect(isNewButtonHovered ? 1.02 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .pressAction {
                    // 按下时的反馈
                } onRelease: {
                    // 释放时的反馈
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isNewButtonHovered = hovering
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(isSearchFieldHovered ? .accentColor : .secondary)
                        .scaleEffect(isSearchFieldHovered ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearchFieldHovered)
                    TextField(NSLocalizedString("search_prompts"), text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                paginationManager.loadInitialData(searchText: newValue)
                            }
                        }
                }
                .padding(8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isSearchFieldHovered ? 
                            [Color(.controlBackgroundColor), Color(.controlBackgroundColor).opacity(0.8)] :
                            [Color(.controlBackgroundColor), Color(.controlBackgroundColor)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSearchFieldHovered ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: 2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFieldHovered)
                )
                .cornerRadius(6)
                .scaleEffect(isSearchFieldHovered ? 1.01 : 1.0)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSearchFieldHovered = hovering
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // 提示词列表
                ScrollViewReader { proxy in
                    List(selection: $selectedPrompt) {
                        ForEach(filteredPrompts, id: \.id) { prompt in
                            PromptListItem(prompt: prompt, selectedPrompt: $selectedPrompt)
                                .tag(prompt)
                                .id(prompt.id)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                                .onAppear {
                                    // 当显示到倒数第3个项目时，加载更多数据
                                    if prompt == filteredPrompts.suffix(3).first {
                                        paginationManager.loadMoreData()
                                    }
                                }
                        }
                        
                        // 加载状态指示器
                        if paginationManager.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(NSLocalizedString("loading"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        }
                        
                        // 没有更多数据提示
                        if !paginationManager.hasMoreData && !filteredPrompts.isEmpty {
                            HStack {
                                Spacer()
                                Text(NSLocalizedString("no_more_data"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .onChange(of: selectedPrompt) { _, newValue in
                        if let newPromptID = newValue?.id {
                            withAnimation {
                                proxy.scrollTo(newPromptID, anchor: .center)
                            }
                        }
                        // 重置编辑状态
                        isEditing = false
                        if let prompt = newValue {
                            editingTitle = prompt.title
                            editingTags = prompt.tags
                            editingContent = prompt.content
                        } else {
                            editingTitle = ""
                            editingTags = []
                            editingContent = ""
                        }
                    }
                    .refreshable {
                        paginationManager.refresh()
                    }
                }
                
                // 底部工具栏
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal)
                    
                    HStack {
                        // 齿轮按钮
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingToolsMenu.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isToolsButtonHovered || showingToolsMenu ? .accentColor : .secondary)
                                .scaleEffect(isToolsButtonHovered ? 1.2 : (showingToolsMenu ? 1.1 : 1.0))
                                .rotationEffect(.degrees(showingToolsMenu ? 180 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isToolsButtonHovered)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingToolsMenu)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isToolsButtonHovered = hovering
                            }
                        }
                        .overlay(
                            Group {
                                if showingToolsMenu {
                                    ZStack {
                                        // 工具菜单
                                        ToolsMenuView(showingToolsMenu: $showingToolsMenu, 
                                                      showingExportDialog: $showingExportDialog, 
                                                      showingImportDialog: $showingImportDialog,
                                                      isExportButtonHovered: $isExportButtonHovered,
                                                      isImportButtonHovered: $isImportButtonHovered)
                                            .offset(x: 5, y: -140)
                                            .transition(
                                                .asymmetric(
                                                    insertion: .scale(scale: 0.8, anchor: .bottomLeading)
                                                        .combined(with: .opacity)
                                                        .combined(with: .move(edge: .bottom)),
                                                    removal: .scale(scale: 0.9, anchor: .bottomLeading)
                                                        .combined(with: .opacity)
                                                        .combined(with: .move(edge: .bottom))
                                                )
                                            )
                                            .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.1), value: showingToolsMenu)
                                    }
                                }
                            }, alignment: .topLeading
                        )
                        .background(
                            Group {
                                if showingToolsMenu {
                                    // 全屏透明覆盖层用于捕获点击事件
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            showingToolsMenu = false
                                        }
                                        .ignoresSafeArea(.all)
                                }
                            }
                        )
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // 中间内容区域
            if let prompt = selectedPrompt {
                PromptEditorView(
                    prompt: prompt,
                    isEditing: $isEditing,
                    editingTitle: $editingTitle,
                    editingTags: $editingTags,
                    editingContent: $editingContent,
                    showingPreview: $showingPreview,
                    onSave: savePrompt,
                    onDelete: deletePrompt
                )
            } else {
                // 空状态 - Welcome页面
                VStack(spacing: 20) {
                    Spacer()
                    
                    // 标题
                    Text(NSLocalizedString("welcome_title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // 功能介绍卡片
                    HStack(spacing: 20) {
                        // Prompt管理卡片
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("prompt_management"))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(NSLocalizedString("prompt_management_desc"))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: 300, maxHeight: 100)
                        .padding(20)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(12)
                        
                        // Prompt调用卡片
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("prompt_calling"))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(NSLocalizedString("prompt_calling_desc"))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: 300, maxHeight: 100)
                        .padding(20)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // 语言切换按钮
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        languageManager.toggleLanguage()
                    }
                }) {
                    Text(languageManager.currentLanguage == "zh-Hans" ? "CN" : "EN")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isLanguageButtonHovered ? Color.orange.opacity(0.2) : Color.clear)
                                .stroke(isLanguageButtonHovered ? Color.orange : Color.clear, lineWidth: 1)
                        )
                        .foregroundColor(isLanguageButtonHovered ? Color.orange : Color.primary)
                        .scaleEffect(isLanguageButtonHovered ? 1.05 : 1.0)
                        .rotationEffect(.degrees(isLanguageButtonHovered ? 5 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isLanguageButtonHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .pressAction {
                    // 按下反馈
                } onRelease: {
                    // 释放反馈
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isLanguageButtonHovered = hovering
                    }
                }
                
                // 主题切换按钮
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        themeManager.toggleTheme()
                    }
                }) {
                    Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isThemeButtonHovered ? Color.blue.opacity(0.2) : Color.clear)
                                .stroke(isThemeButtonHovered ? Color.blue : Color.clear, lineWidth: 1)
                        )
                        .foregroundColor(isThemeButtonHovered ? Color.blue : Color.primary)
                        .scaleEffect(isThemeButtonHovered ? 1.05 : 1.0)
                        .rotationEffect(.degrees(isThemeButtonHovered ? 15 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isThemeButtonHovered)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: themeManager.isDarkMode)
                }
                .buttonStyle(PlainButtonStyle())
                .pressAction {
                    // 按下反馈
                } onRelease: {
                    // 释放反馈
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isThemeButtonHovered = hovering
                    }
                }
                
                // AI 模型选择按钮
                Button(action: {
                    showingAIModelConfig = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.system(size: 12, weight: .medium))
                            .scaleEffect(isAIModelButtonHovered ? 1.1 : 1.0)
                        Text(NSLocalizedString("ai_model"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isAIModelButtonHovered ? Color.accentColor.opacity(0.2) : Color.clear)
                            .stroke(isAIModelButtonHovered ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
                    .foregroundColor(isAIModelButtonHovered ? Color.accentColor : Color.primary)
                    .scaleEffect(isAIModelButtonHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isAIModelButtonHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .pressAction {
                    // 按下反馈
                } onRelease: {
                    // 释放反馈
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isAIModelButtonHovered = hovering
                    }
                }
                
                // MCP 服务示例按钮
                Button(action: {
                    showingMCPConfig = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "network")
                            .font(.system(size: 12, weight: .medium))
                            .scaleEffect(isMCPServiceButtonHovered ? 1.1 : 1.0)
                        Text(NSLocalizedString("mcp_service"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isMCPServiceButtonHovered ? Color.accentColor.opacity(0.2) : Color.clear)
                            .stroke(isMCPServiceButtonHovered ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
                    .foregroundColor(isMCPServiceButtonHovered ? Color.accentColor : Color.primary)
                    .scaleEffect(isMCPServiceButtonHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isMCPServiceButtonHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .pressAction {
                    // 按下反馈
                } onRelease: {
                    // 释放反馈
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isMCPServiceButtonHovered = hovering
                    }
                }
            }
        }
        .onAppear {
            // 初始化分页管理器
            paginationManager.setModelContext(modelContext)
            paginationManager.loadInitialData()
            
            // 如果有提示词但没有选中，选中第一个
            if selectedPrompt == nil && !paginationManager.prompts.isEmpty {
                selectedPrompt = paginationManager.prompts.first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewPrompt)) { _ in
            createNewPrompt()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPrompt)) { notification in
            if let promptId = notification.object as? UUID {
                openPrompt(with: promptId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            // 聚焦搜索框的逻辑可以在这里实现
            // 由于SwiftUI的限制，这里暂时留空
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPreferences)) { _ in
            // 打开偏好设置，这里可以显示相关配置界面
            showingAIModelConfig = true
        }
        .onChange(of: searchText) { _, newValue in
            // 搜索文本变化时重新加载数据
            paginationManager.loadInitialData(searchText: newValue)
            selectedPrompt = nil
        }
        .onChange(of: selectedPrompt) { _, newPrompt in
            // 当选择提示词时，添加到最近使用列表
            if let prompt = newPrompt {
                RecentPromptsManager.shared.addRecentPrompt(prompt)
            }
        }
        .sheet(isPresented: $showingAIModelConfig) {
            AIModelConfigView()
        }
        .sheet(isPresented: $showingMCPConfig) {
            MCPConfigView()
                .environmentObject(mcpService)
        }
        .fileExporter(
            isPresented: $showingExportDialog,
            document: ExportDocument(prompts: paginationManager.prompts),
            contentType: .json,
            defaultFilename: "prompts_backup_\(DateFormatter.yyyyMMdd.string(from: Date()))"
        ) { result in
            switch result {
            case .success(let url):
                print("导出成功: \(url)")
            case .failure(let error):
                print("导出失败: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importPrompts(from: url)
            case .failure(let error):
                print("导入失败: \(error)")
            }
        }
        .alert(NSLocalizedString("duplicate_prompts_found"), isPresented: $showingDuplicateAlert) {
            Button(NSLocalizedString("overwrite")) {
                overwritePrompts()
            }
            Button(NSLocalizedString("cancel"), role: .cancel) {
                duplicatePrompts.removeAll()
                importedPrompts.removeAll()
            }
        } message: {
            Text(NSLocalizedString("duplicate_prompts_message") + "\n" + duplicatePrompts.map { $0.title }.joined(separator: ", "))
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
    
    private func createNewPrompt() {
        let newPrompt = Prompt(title: NSLocalizedString("new_prompt_title"), tags: [], content: "")
        modelContext.insert(newPrompt)
        try? modelContext.save()
        
        // 刷新分页数据以包含新创建的提示词
        paginationManager.refresh()
        
        selectedPrompt = newPrompt
        
        // 添加到最近使用列表
        RecentPromptsManager.shared.addRecentPrompt(newPrompt)
        
        // 确保编辑状态正确初始化
        DispatchQueue.main.async {
            self.isEditing = true
            self.editingTitle = newPrompt.title
            self.editingTags = newPrompt.tags
            self.editingContent = newPrompt.content
        }
    }
    
    private func openPrompt(with id: UUID) {
        // 在当前加载的提示词中查找
        if let prompt = paginationManager.prompts.first(where: { $0.id == id }) {
            selectedPrompt = prompt
            RecentPromptsManager.shared.addRecentPrompt(prompt)
            return
        }
        
        // 如果在当前列表中没找到，从数据库中查找
        do {
            let descriptor = FetchDescriptor<Prompt>(
                predicate: #Predicate<Prompt> { prompt in
                    prompt.id == id
                }
            )
            let prompts = try modelContext.fetch(descriptor)
            if let prompt = prompts.first {
                selectedPrompt = prompt
                RecentPromptsManager.shared.addRecentPrompt(prompt)
            }
        } catch {
            print("Failed to fetch prompt with id \(id): \(error)")
        }
    }
    
    private func savePrompt() {
        guard let prompt = selectedPrompt else { return }
        prompt.updateContent(
            title: editingTitle.isEmpty ? "无标题" : editingTitle,
            tags: editingTags,
            content: editingContent
        )
        try? modelContext.save()
        
        // 刷新分页数据以反映更新
        paginationManager.refresh()
        
        isEditing = false
    }
    
    private func deletePrompt(_ prompt: Prompt) {
        modelContext.delete(prompt)
        try? modelContext.save()
        
        // 刷新分页数据
        paginationManager.refresh()
        
        // 如果删除的是当前选中的提示词，选择下一个
        if selectedPrompt?.id == prompt.id {
            selectedPrompt = paginationManager.prompts.first { $0.id != prompt.id }
        }
    }
    
    // MARK: - 导入导出功能
    private func importPrompts(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let exportData = try decoder.decode(ExportData.self, from: data)
            let newPrompts = exportData.prompts
            
            // 检查重复的UUID
            let existingIDs = Set(paginationManager.prompts.map { $0.id })
            let duplicates = newPrompts.filter { existingIDs.contains($0.id) }
            
            if !duplicates.isEmpty {
                duplicatePrompts = duplicates
                importedPrompts = newPrompts
                showingDuplicateAlert = true
            } else {
                // 没有重复，直接导入
                addImportedPrompts(newPrompts)
            }
        } catch {
            print("导入失败: \(error)")
        }
    }
    
    private func overwritePrompts() {
        addImportedPrompts(importedPrompts)
        duplicatePrompts.removeAll()
        importedPrompts.removeAll()
    }
    
    private func addImportedPrompts(_ prompts: [Prompt]) {
        for prompt in prompts {
            // 检查是否已存在相同ID的提示词
            if let existingPrompt = paginationManager.prompts.first(where: { $0.id == prompt.id }) {
                // 更新现有提示词
                existingPrompt.title = prompt.title
                existingPrompt.tags = prompt.tags
                existingPrompt.content = prompt.content
                existingPrompt.updatedAt = Date() // 更新时间戳
            } else {
                // 添加新提示词
                modelContext.insert(prompt)
            }
        }
        
        try? modelContext.save()
        paginationManager.refresh()
    }
}

// MARK: - 导出文档类型
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    let data: Data

    init(prompts: [Prompt]) {
        let exportData = ExportData(prompts: prompts)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            self.data = try encoder.encode(exportData)
        } catch {
            // Log the error or handle it more gracefully if needed
            print("Error encoding prompts for export: \(error)")
            self.data = Data() // Fallback to empty data
        }
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            // You might want to throw a more specific error here
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = fileData
        // If you need to decode the prompts immediately after reading, you would do it here.
        // For example:
        // let decoder = JSONDecoder()
        // decoder.dateDecodingStrategy = .iso8601
        // let decodedExportData = try decoder.decode(ExportData.self, from: fileData)
        // This would require a way to store/access the decoded prompts if needed.
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - 导出数据结构
struct ExportData: Codable {
    let prompts: [Prompt]
}

// MARK: - 日期格式化扩展
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// 简单标签视图组件
struct FlowLayout: Layout {
    var alignment: Alignment = .leading
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 4

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var calculatedWidth: CGFloat = 0

        if subviews.isEmpty { return .zero }

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if currentRowWidth + subviewSize.width + (currentRowWidth.isZero ? 0 : horizontalSpacing) > maxWidth {
                height += rowHeight + (height.isZero ? 0 : verticalSpacing)
                rowHeight = 0
                currentRowWidth = 0
            }
            currentRowWidth += subviewSize.width + (currentRowWidth.isZero ? 0 : horizontalSpacing)
            rowHeight = max(rowHeight, subviewSize.height)
            calculatedWidth = max(calculatedWidth, currentRowWidth)
        }
        height += rowHeight // Add height of the last row
        return CGSize(width: calculatedWidth, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard !subviews.isEmpty else { return }

        var rows: [[LayoutSubview]] = [[]]
        var currentRowWidth: CGFloat = 0
        let maxWidth = bounds.width

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if currentRowWidth + subviewSize.width + (rows.last?.isEmpty == true ? 0 : horizontalSpacing) > maxWidth && !(rows.last?.isEmpty == true) {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentRowWidth += subviewSize.width + (rows.last?.count == 1 ? 0 : horizontalSpacing)
        }

        var currentY = bounds.minY

        for row in rows {
            guard !row.isEmpty else { continue }
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var currentX: CGFloat
            
            let totalRowWidth = row.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width } + CGFloat(max(0, row.count - 1)) * horizontalSpacing

            switch alignment {
            case .leading:
                currentX = bounds.minX
            case .center:
                currentX = bounds.minX + (maxWidth - totalRowWidth) / 2
            case .trailing:
                currentX = bounds.maxX - totalRowWidth
            default:
                currentX = bounds.minX
            }

            for subview in row {
                let subviewSize = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: currentX, y: currentY), anchor: .topLeading, proposal: .unspecified)
                currentX += subviewSize.width + horizontalSpacing
            }
            currentY += rowHeight + verticalSpacing
        }
    }
}

struct TagsView: View {
    let tags: [String]
    let isEditing: Bool
    let onTagsChanged: ([String]) -> Void
    
    var body: some View {
        FlowLayout(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 4) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

// 提示词列表项组件
struct PromptListItem: View {
    let prompt: Prompt
    @Binding var selectedPrompt: Prompt?
    @State private var isHovered = false
    @State private var isPressed = false
    
    private var isSelected: Bool {
        selectedPrompt?.id == prompt.id
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(prompt.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                if !prompt.tags.isEmpty {
                    TagsView(
                        tags: prompt.tags,
                        isEditing: false,
                        onTagsChanged: { _ in }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                Text(prompt.content)
                    .font(.caption)
                    .foregroundColor(isHovered ? .secondary.opacity(0.8) : .secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor.opacity(0.15),
                            Color.accentColor.opacity(0.08)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else if isHovered {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(NSColor.controlBackgroundColor).opacity(0.5),
                            Color(NSColor.controlBackgroundColor).opacity(0.2)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(NSColor.controlBackgroundColor).opacity(0.2),
                            Color(NSColor.controlBackgroundColor).opacity(0.1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isSelected ? Color.accentColor.opacity(0.6) :
                    isHovered ? Color.accentColor.opacity(0.4) : Color.clear,
                    lineWidth: isSelected ? 2 : 1
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        )
        .cornerRadius(6)
        .scaleEffect(
            isPressed ? 0.98 :
            isHovered ? 1.02 :
            isSelected ? 1.01 : 1.0
        )
        .shadow(
            color: isSelected ? Color.accentColor.opacity(0.2) :
                   isHovered ? Color.black.opacity(0.1) : Color.clear,
            radius: isSelected ? 4 : 2,
            x: 0,
            y: isSelected ? 2 : 1
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}

// MARK: - 按压动画修饰符
struct PressAction: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            }, perform: {})
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressAction(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Prompt.self, inMemory: true)
}

// MARK: - 工具菜单视图
struct ToolsMenuView: View {
    @Binding var showingToolsMenu: Bool
    @Binding var showingExportDialog: Bool
    @Binding var showingImportDialog: Bool
    @Binding var isExportButtonHovered: Bool
    @Binding var isImportButtonHovered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 导出按钮
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingExportDialog = true
                    showingToolsMenu = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isExportButtonHovered ? .white : .accentColor)
                        .scaleEffect(isExportButtonHovered ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExportButtonHovered)
                    
                    Text(NSLocalizedString("export_prompts"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isExportButtonHovered ? .white : .primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isExportButtonHovered ? 
                              LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isExportButtonHovered)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isExportButtonHovered ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                        .animation(.easeInOut(duration: 0.2), value: isExportButtonHovered)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExportButtonHovered = hovering
                }
            }

            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            // 导入按钮
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingImportDialog = true
                    showingToolsMenu = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isImportButtonHovered ? .white : .accentColor)
                        .scaleEffect(isImportButtonHovered ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isImportButtonHovered)
                    
                    Text(NSLocalizedString("import_prompts"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isImportButtonHovered ? .white : .primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isImportButtonHovered ? 
                              LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isImportButtonHovered)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isImportButtonHovered ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                        .animation(.easeInOut(duration: 0.2), value: isImportButtonHovered)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isImportButtonHovered = hovering
                }
            }
        }
        .padding(8)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}
