# PromptHome - AI提示词管理平台

## 项目概述

PromptHome 是一个基于 SwiftUI + SwiftData 开发的原生 macOS 应用，用于管理和组织 AI 提示词。支持 AI 润色、MCP 服务集成、分页显示等高级功能。

## 已实现功能

### 核心功能
- ✅ 提示词创建、编辑、删除
- ✅ 提示词搜索和过滤
- ✅ Markdown 格式支持
- ✅ 标签管理
- ✅ 响应式界面设计
- ✅ 分页显示功能
- ✅ 列表选择和详细内容显示

### AI 集成功能
- ✅ AI 模型配置管理
- ✅ 多种 AI 服务提供商支持（OpenAI、Deepseek、Ollama 等）
- ✅ 提示词 AI 润色功能

### MCP 服务功能
- ✅ MCP 服务器集成
- ✅ MCP 客户端实现
- ✅ HTTP 传输协议支持
- ✅ MCP 配置管理界面

### 界面特性
- ✅ 左侧导航栏：新建按钮、搜索框、提示词列表
- ✅ 中间编辑区：Markdown 编辑器和预览
- ✅ 顶部工具栏：模型提供商设定和 MCP 服务配置
- ✅ 底部状态栏：字数统计、更新时间
- ✅ 优化的文本渲染性能
- ✅ 懒加载和分块渲染

### 性能优化
- ✅ OptimizedTextView 组件
- ✅ 长文本分块渲染
- ✅ 懒加载机制
- ✅ 内存使用优化

### 数据模型
- ✅ Prompt 模型：包含 ID、标题、标签、内容、创建时间、更新时间
- ✅ AIModelConfig 模型：AI 模型配置管理
- ✅ SwiftData 持久化存储
- ✅ 多语言支持（中文、英文）

## 项目结构

```
PromptHome/
├── Models/
│   ├── Prompt.swift              # 提示词数据模型
│   └── AIModelConfig.swift       # AI 模型配置模型
├── Views/
│   ├── PromptEditorView.swift     # 编辑器视图
│   ├── MarkdownView.swift         # Markdown 渲染视图
│   ├── AIModelConfigView.swift    # AI 模型配置视图
│   ├── MCPConfigView.swift        # MCP 配置视图
│   └── OptimizedTextView.swift    # 优化文本渲染组件
├── Services/
│   ├── AIPolishService.swift      # AI 润色服务
│   ├── MCPService.swift           # MCP 服务管理
│   ├── MCPServer.swift            # MCP 服务器实现
│   ├── MCPClient.swift            # MCP 客户端实现
│   └── MCPProtocol.swift          # MCP 协议定义
├── ContentView.swift              # 主界面
├── PromptHomeApp.swift           # 应用入口
├── Assets.xcassets/              # 资源文件
├── design/                       # 设计原型
├── docs/                         # 文档
├── en.lproj/                     # 英文本地化
└── zh-Hans.lproj/               # 中文本地化
```

## 技术栈

- **SwiftUI**: 用户界面框架
- **SwiftData**: 数据持久化
- **Foundation**: 基础框架
- **macOS 14.0+**: 目标平台

## 构建和运行

1. 使用 Xcode 打开 `PromptHome.xcodeproj`
2. 选择目标设备为 Mac
3. 点击运行按钮或使用快捷键 `Cmd+R`

### 命令行构建

```bash
# 清理项目
xcodebuild clean -project PromptHome.xcodeproj -scheme PromptHome

# 构建项目（跳过代码签名）
xcodebuild -project PromptHome.xcodeproj -scheme PromptHome -destination "platform=macOS" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO build
```

## 待实现功能

### 高优先级
- [X] 更完善的 Markdown 渲染（粗体、斜体、代码块等）
- [ ] 导入/导出功能
- [ ] 提示词分类和文件夹管理
- [ ] 快捷键支持

### 中优先级
- [X] 主题切换（浅色/深色模式）
- [ ] 提示词模板
- [ ] 批量操作功能
- [ ] 高级搜索和过滤

### 低优先级
- [ ] 云同步功能
- [ ] 协作功能
- [ ] 插件系统
- [ ] 版本历史管理

## 设计参考

项目实现基于以下设计文档：
- PRD 文档：`docs/PRD.md`
- 界面设计：`design/prototypes/`

## 开发说明

### 数据模型设计

```swift
@Model
final class Prompt {
    var id: UUID
    var title: String
    var tag: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
}
```

### 主要视图组件

1. **ContentView**: 主界面，包含导航分割视图和分页功能
2. **PromptEditorView**: 编辑器视图，支持编辑和预览模式，集成 AI 润色功能
3. **MarkdownView**: Markdown 渲染组件
4. **AIModelConfigView**: AI 模型配置界面，支持多种服务提供商
5. **MCPConfigView**: MCP 服务配置界面
6. **OptimizedTextView**: 优化的文本渲染组件，支持长文本高性能显示

### 核心服务组件

1. **AIPolishService**: AI 润色服务，支持多种 AI 模型
2. **MCPService**: MCP 服务管理器
3. **MCPServer**: MCP 服务器实现
4. **MCPClient**: MCP 客户端实现

### 数据模型

1. **Prompt**: 提示词数据模型
2. **AIModelConfig**: AI 模型配置数据模型
3. **ModelProvider**: AI 服务提供商枚举

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证。