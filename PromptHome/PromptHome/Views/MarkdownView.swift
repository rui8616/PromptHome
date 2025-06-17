//
//  MarkdownView.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI

struct MarkdownView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(parseMarkdown(content), id: \.id) { element in
                    renderElement(element)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element.type {
        case .heading1:
            Text(element.content)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.vertical, 4)
        case .heading2:
            Text(element.content)
                .font(.title)
                .fontWeight(.bold)
                .padding(.vertical, 4)
        case .heading3:
            Text(element.content)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 4)
        case .paragraph:
            Text(parseInlineMarkdown(element.content))
                .font(.body)
                .padding(.vertical, 2)
        case .code:
            Text(element.content)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(4)
        case .bulletPoint:
            HStack(alignment: .top) {
                Text("•")
                    .font(.body)
                    .padding(.trailing, 4)
                Text(parseInlineMarkdown(element.content))
                    .font(.body)
                Spacer()
            }
            .padding(.vertical, 1)
        }
    }
    
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        // 简化处理，直接返回基本的AttributedString
        // 在未来版本中可以添加更复杂的Markdown解析
        return AttributedString(text)
    }
    
    private func parseMarkdown(_ content: String) -> [MarkdownElement] {
        let lines = content.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        var currentParagraph = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                continue
            }
            
            if trimmedLine.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .heading1, content: String(trimmedLine.dropFirst(2))))
            } else if trimmedLine.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .heading2, content: String(trimmedLine.dropFirst(3))))
            } else if trimmedLine.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .heading3, content: String(trimmedLine.dropFirst(4))))
            } else if trimmedLine.hasPrefix("```") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                // 简单的代码块处理
                elements.append(MarkdownElement(type: .code, content: "代码块"))
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .bulletPoint, content: String(trimmedLine.dropFirst(2))))
            } else {
                if !currentParagraph.isEmpty {
                    currentParagraph += " "
                }
                currentParagraph += trimmedLine
            }
        }
        
        if !currentParagraph.isEmpty {
            elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
        }
        
        return elements
    }
}

struct MarkdownElement {
    let id = UUID()
    let type: MarkdownElementType
    let content: String
}

enum MarkdownElementType {
    case heading1
    case heading2
    case heading3
    case paragraph
    case code
    case bulletPoint
}

#Preview {
    MarkdownView(content: """
    # 标题 1
    
    这是一个段落，包含 **粗体** 和 *斜体* 文本。
    
    ## 标题 2
    
    - 列表项 1
    - 列表项 2
    - 列表项 3
    
    ### 标题 3
    
    另一个段落。
    """)
    .frame(width: 400, height: 300)
}