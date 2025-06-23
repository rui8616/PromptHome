//
//  OptimizedTextView.swift
//  PromptHome
//
//  Created by Assistant on 2025/6/16.
//

import SwiftUI
import Down

struct OptimizedTextView: View {
    let content: String
    @State private var visibleChunks: Set<Int> = []
    @State private var renderedChunks: [Int: AttributedString] = [:]
    
    private let chunkSize = 2000 // 增加块大小以减少分割对Markdown的影响
    private var chunks: [String] {
        // 如果内容较小，直接返回整个内容
        if content.count <= chunkSize {
            return [content]
        }
        
        let text = content
        var result: [String] = []
        let totalLength = text.count
        
        for i in stride(from: 0, to: totalLength, by: chunkSize) {
            let startIndex = text.index(text.startIndex, offsetBy: i)
            let endIndex = text.index(startIndex, offsetBy: min(chunkSize, totalLength - i))
            result.append(String(text[startIndex..<endIndex]))
        }
        
        return result
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(chunks.enumerated()), id: \.offset) { index, chunk in
                    Group {
                        if visibleChunks.contains(index) {
                            if let attributedString = renderedChunks[index] {
                                Text(attributedString)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .textSelection(.enabled)
                            } else {
                                Text("正在渲染...")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .foregroundColor(.secondary)
                                    .task {
                                        await renderChunk(index: index, content: chunk)
                                    }
                            }
                        } else {
                            // 占位符，保持布局稳定
                            Text("")
                                .frame(height: estimatedHeight(for: chunk))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .onAppear {
                        visibleChunks.insert(index)
                    }
                    .onDisappear {
                        // 保留一些已渲染的块以提供更好的滚动体验
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if !isChunkVisible(index) {
                                visibleChunks.remove(index)
                                renderedChunks.removeValue(forKey: index)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            // 预加载前几个块
            for i in 0..<min(2, chunks.count) {
                visibleChunks.insert(i)
            }
        }
        .onChange(of: content) { _, _ in
            // 内容变化时清除缓存并重新渲染
            visibleChunks.removeAll()
            renderedChunks.removeAll()
            // 重新预加载前几个块
            for i in 0..<min(2, chunks.count) {
                visibleChunks.insert(i)
            }
        }
    }
    
    @MainActor
    private func renderChunk(index: Int, content: String) async {
        Task.detached {
            do {
                // 预处理内容以保留空行
                let processedContent = self.preprocessMarkdownForBlankLines(content)
                let down = Down(markdownString: processedContent)
                // 配置Down选项以保留换行符
                var options: DownOptions = [.hardBreaks, .validateUTF8]
                let nsAttributedString = try down.toAttributedString(options)
                
                await MainActor.run {
                    self.renderedChunks[index] = AttributedString(nsAttributedString)
                }
            } catch {
                print("Markdown渲染失败 (chunk \(index)): \(error)")
                await MainActor.run {
                    // 降级到纯文本
                    self.renderedChunks[index] = AttributedString(content)
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
    
    private func estimatedHeight(for chunk: String) -> CGFloat {
        // 估算文本高度，基于字符数和行高
        let lineHeight: CGFloat = 22
        let charactersPerLine: CGFloat = 70
        let estimatedLines = max(1, CGFloat(chunk.count) / charactersPerLine)
        return estimatedLines * lineHeight + 20 // 额外间距
    }
    
    private func isChunkVisible(_ index: Int) -> Bool {
        // 这里可以添加更复杂的可见性检测逻辑
        // 目前简单返回true，让onDisappear处理清理
        return true
    }
}

#Preview {
    OptimizedTextView(content: "This is a sample text for preview. ".repeated(100))
}

fileprivate extension String {
    func repeated(_ times: Int) -> String {
        return String(repeating: self, count: times)
    }
}
