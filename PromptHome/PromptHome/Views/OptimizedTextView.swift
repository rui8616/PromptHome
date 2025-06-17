//
//  OptimizedTextView.swift
//  PromptHome
//
//  Created by Assistant on 2025/6/16.
//

import SwiftUI

struct OptimizedTextView: View {
    let content: String
    @State private var visibleChunks: Set<Int> = []
    
    private let chunkSize = 1000 // 每个块的字符数
    private var chunks: [String] {
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
                            Text(LocalizedStringKey(chunk))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if !isChunkVisible(index) {
                                visibleChunks.remove(index)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            // 预加载前几个块
            for i in 0..<min(3, chunks.count) {
                visibleChunks.insert(i)
            }
        }
    }
    
    private func estimatedHeight(for chunk: String) -> CGFloat {
        // 估算文本高度，基于字符数和行高
        let lineHeight: CGFloat = 20
        let charactersPerLine: CGFloat = 80
        let estimatedLines = max(1, CGFloat(chunk.count) / charactersPerLine)
        return estimatedLines * lineHeight
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