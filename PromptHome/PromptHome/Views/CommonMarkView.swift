//
//  CommonMarkView.swift
//  PromptHome
//
//  Created by Assistant on 2025/6/16.
//

import SwiftUI
import Down

struct CommonMarkView: View {
    let content: String
    @State private var attributedString: AttributedString?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if isLoading {
                    ProgressView("正在渲染...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let attributedString = attributedString {
                    Text(attributedString)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                } else {
                    // 降级到纯文本显示
                    Text(content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await renderMarkdown()
        }
        .onChange(of: content) { oldValue, newValue in
            Task {
                await renderMarkdown()
            }
        }
    }
    
    @MainActor
    private func renderMarkdown() async {
        isLoading = true
        
        Task.detached {
            do {
                // 预处理内容以保留空行
                let processedContent = self.preprocessMarkdownForBlankLines(content)
                let down = Down(markdownString: processedContent)
                // 配置Down选项以保留换行符和空行
                var options: DownOptions = [.hardBreaks, .validateUTF8]
                let nsAttributedString = try down.toAttributedString(options)
                
                await MainActor.run {
                    self.attributedString = AttributedString(nsAttributedString)
                    self.isLoading = false
                }
            } catch {
                print("Markdown渲染失败: \(error)")
                await MainActor.run {
                    self.attributedString = nil
                    self.isLoading = false
                }
            }
        }
    }
    
    // 预处理 Markdown 内容以保留空行
    private func preprocessMarkdownForBlankLines(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var processedLines: [String] = []
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // 空行替换为包含不可见字符的行，使用 HTML 实体
                processedLines.append("&nbsp;")
            } else {
                processedLines.append(line)
            }
        }
        
        return processedLines.joined(separator: "\n")
    }
}

#Preview {
    CommonMarkView(content: """
    # 标题 1
    
    这是一个段落，包含 **粗体** 和 *斜体* 文本，还有 `行内代码`。
    
    ## 标题 2
    
    - 列表项 1
    - 列表项 2 with **bold**
    - 列表项 3 with *italic*
    
    ### 标题 3
    
    这是一个 [链接](https://example.com)。
    
    ```swift
    func hello() {
        print("Hello, World!")
    }
    ```
    
    > 这是一个引用块
    > 可以包含多行内容
    
    | 表格 | 列1 | 列2 |
    |------|-----|-----|
    | 行1  | 数据1 | 数据2 |
    | 行2  | 数据3 | 数据4 |
    """)
    .frame(width: 400, height: 600)
}