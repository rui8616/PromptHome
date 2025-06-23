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
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isNewButtonHovered = hovering
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(isSearchFieldHovered ? .primary : .secondary)
                    TextField(NSLocalizedString("search_prompts"), text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
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
                        .stroke(isSearchFieldHovered ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: 4)
                )
                .cornerRadius(6)
                .scaleEffect(isSearchFieldHovered ? 1.01 : 1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
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
                            showingToolsMenu.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isToolsButtonHovered ? .accentColor : .secondary)
                                .scaleEffect(isToolsButtonHovered ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isToolsButtonHovered)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { hovering in
                            isToolsButtonHovered = hovering
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
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.windowBackgroundColor))
                                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                            )
                                            .offset(x: 5, y: -120)
                                            .transition(.move(edge: .bottom).combined(with: .opacity))
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
                    languageManager.toggleLanguage()
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
                        .animation(.easeInOut(duration: 0.2), value: isLanguageButtonHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isLanguageButtonHovered = hovering
                }
                
                // 主题切换按钮
                Button(action: {
                    themeManager.toggleTheme()
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
                        .animation(.easeInOut(duration: 0.2), value: isThemeButtonHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isThemeButtonHovered = hovering
                }
                
                // AI 模型选择按钮
                Button(action: {
                    showingAIModelConfig = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.system(size: 12, weight: .medium))
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
                    .animation(.easeInOut(duration: 0.2), value: isAIModelButtonHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isAIModelButtonHovered = hovering
                }
                
                // MCP 服务示例按钮
                Button(action: {
                    showingMCPConfig = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "network")
                            .font(.system(size: 12, weight: .medium))
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
                    .animation(.easeInOut(duration: 0.2), value: isMCPServiceButtonHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isMCPServiceButtonHovered = hovering
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
        .onChange(of: searchText) { _, newValue in
            // 搜索文本变化时重新加载数据
            paginationManager.loadInitialData(searchText: newValue)
            selectedPrompt = nil
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
        
        // 确保编辑状态正确初始化
        DispatchQueue.main.async {
            self.isEditing = true
            self.editingTitle = newPrompt.title
            self.editingTags = newPrompt.tags
            self.editingContent = newPrompt.content
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
                    .foregroundColor(isHovered ? .primary : .primary)
                
                if !prompt.tags.isEmpty {
                    TagsView(
                        tags: prompt.tags,
                        isEditing: false,
                        onTagsChanged: { _ in }
                    )
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
                    if isHovered {
                        LinearGradient(gradient: Gradient(colors: [Color(NSColor.controlBackgroundColor).opacity(0.5), Color(NSColor.controlBackgroundColor).opacity(0.2)]), startPoint: .leading, endPoint: .trailing)
                    } else {
                        LinearGradient(gradient: Gradient(colors: [Color(NSColor.controlBackgroundColor).opacity(0.2), Color(NSColor.controlBackgroundColor).opacity(0.1)]), startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHovered ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: 4)
        )
        .cornerRadius(6)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .shadow(color: isHovered ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
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
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                showingExportDialog = true
                showingToolsMenu = false // Close menu after action
            }) {
                HStack {
                    Image(systemName: "arrow.up.doc")
                    Text(NSLocalizedString("export_prompts"))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isExportButtonHovered ? Color.gray.opacity(0.2) : Color.clear)
                .cornerRadius(5)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isExportButtonHovered = hovering
            }

            Divider()

            Button(action: {
                showingImportDialog = true
                showingToolsMenu = false // Close menu after action
            }) {
                HStack {
                    Image(systemName: "arrow.down.doc")
                    Text(NSLocalizedString("import_prompts"))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isImportButtonHovered ? Color.gray.opacity(0.2) : Color.clear)
                .cornerRadius(5)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isImportButtonHovered = hovering
            }
        }
        .frame(width: 150, height: 90) // Test with slightly larger height
    }
}
