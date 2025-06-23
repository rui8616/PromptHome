# Markdown支持升级指南

本指南说明如何将PromptHome项目升级为支持CommonMark标准的Markdown渲染。

## 升级概述

我们已经实现了以下改进：

1. **创建了新的CommonMarkView组件** - 使用Down库提供完整的CommonMark支持
2. **升级了OptimizedTextView** - 集成Down库进行高性能Markdown渲染
3. **保持了原有的分块渲染机制** - 确保大文档的性能

## 依赖配置

### 方法1：在Xcode中添加Swift Package依赖（推荐）

1. 打开PromptHome.xcodeproj
2. 选择项目根节点
3. 选择"Package Dependencies"标签
4. 点击"+"按钮
5. 输入Down库的URL：`https://github.com/johnxnguyen/Down.git`
6. 选择版本："Up to Next Major Version" 0.11.0
7. 点击"Add Package"
8. 确保Down库被添加到PromptHome target

### 方法2：使用Swift Package Manager（可选）

如果你想将项目转换为Swift Package：

1. 使用提供的`Package.swift`文件
2. 运行：`swift build`
3. 运行测试：`swift test`

## 新功能特性

升级后的Markdown支持包括：

### 基础语法
- ✅ 标题 (H1-H6)
- ✅ 段落
- ✅ 换行
- ✅ 强调 (**粗体**, *斜体*)
- ✅ 行内代码 (`code`)
- ✅ 代码块 (```)

### 高级功能
- ✅ 链接 [文本](URL)
- ✅ 图片 ![alt](URL)
- ✅ 列表（有序和无序）
- ✅ 引用块 (>)
- ✅ 表格
- ✅ 删除线 (~~text~~)
- ✅ 任务列表 (- [ ] 和 - [x])

### 性能优化
- ✅ 异步渲染
- ✅ 分块加载
- ✅ 内存管理
- ✅ 文本选择支持

## 使用示例

### 在PromptEditorView中的使用

现有的代码无需修改，OptimizedTextView会自动使用新的CommonMark渲染器：

```swift
// 预览模式
OptimizedTextView(content: editingContent)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.textBackgroundColor))

// 只读模式
OptimizedTextView(content: prompt.content)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.textBackgroundColor))
```

### 直接使用CommonMarkView

如果需要在其他地方使用Markdown渲染：

```swift
CommonMarkView(content: markdownString)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

## 测试内容

可以使用以下Markdown内容测试新功能：

```markdown
# 主标题

这是一个包含 **粗体** 和 *斜体* 的段落，还有 `行内代码`。

## 二级标题

### 列表示例

- 无序列表项 1
- 无序列表项 2 with **bold**
- 无序列表项 3 with *italic*

1. 有序列表项 1
2. 有序列表项 2
3. 有序列表项 3

### 代码块

```swift
func hello() {
    print("Hello, CommonMark!")
}
```

### 引用

> 这是一个引用块
> 可以包含多行内容
> 
> 甚至可以包含 **格式化** 文本

### 链接和图片

这是一个 [链接](https://example.com)。

### 表格

| 功能 | 支持状态 | 备注 |
|------|---------|------|
| 标题 | ✅ | H1-H6 |
| 列表 | ✅ | 有序/无序 |
| 代码 | ✅ | 行内/块 |
| 表格 | ✅ | 完整支持 |

### 任务列表

- [x] 实现CommonMark支持
- [x] 优化性能
- [ ] 添加更多测试
- [ ] 文档完善
```

## 迁移说明

1. **旧的MarkdownView.swift可以保留** - 作为备用方案
2. **OptimizedTextView已升级** - 自动使用新的渲染器
3. **向后兼容** - 现有代码无需修改
4. **性能提升** - 更好的内存管理和渲染性能

## 故障排除

### 编译错误

如果遇到"No such module 'Down'"错误：

1. 确保已正确添加Down依赖
2. 清理构建文件夹 (Product → Clean Build Folder)
3. 重新构建项目

### 渲染问题

如果Markdown渲染异常：

1. 检查控制台输出的错误信息
2. 确保Markdown语法正确
3. 大文档会分块渲染，可能有轻微延迟

### 性能问题

如果遇到性能问题：

1. 调整`chunkSize`参数（当前为2000字符）
2. 减少预加载块数量
3. 检查内存使用情况

## 后续改进

可以考虑的进一步优化：

1. **语法高亮** - 为代码块添加语法高亮
2. **数学公式** - 支持LaTeX数学公式
3. **自定义样式** - 可配置的主题和样式
4. **导出功能** - 支持导出为HTML/PDF
5. **实时预览** - 编辑时的实时Markdown预览

## 总结

通过这次升级，PromptHome现在支持完整的CommonMark标准，提供了更好的Markdown渲染体验，同时保持了原有的性能优势。用户可以使用所有标准的Markdown语法，包括表格、任务列表、代码高亮等高级功能。