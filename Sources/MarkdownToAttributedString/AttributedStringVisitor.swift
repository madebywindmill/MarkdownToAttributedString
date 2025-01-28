//
//  AttributedStringVisitor.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 1/18/25.
//

#if os(macOS)
import AppKit
#elseif os(iOS) || os(watchOS)
import UIKit
#endif
import Markdown

struct AttributedStringVisitor: MarkupVisitor {
    var markdown: String
    var markdownAttributes: MarkdownAttributes

    private var attributedString = NSMutableAttributedString()
    private var currentAttributes: StringAttrs

    init(markdown: String,
                attributes: MarkdownAttributes? = nil) {
        self.markdown = markdown
        self.markdownAttributes = attributes ?? MarkdownAttributes.default
        self.currentAttributes = self.markdownAttributes.baseAttributes
    }

    mutating func convert() -> NSAttributedString {
        MarkdownDebugLog("Raw markdown to process:\n\(markdown)\n")
        let document = Document(parsing: markdown)
        visit(document)
        MarkdownDebugLog("Final plain text render:\n\(attributedString.string)\n\n")
        MarkdownDebugLog("Final text+attrs:\n\(attributedString.debugDescription)")
        return attributedString
    }

    mutating func defaultVisit(_ markup: any Markup) {
        visitChildren(of: markup)
    }

    mutating func visitText(_ text: Text) {
        MarkdownDebugLog("<open>", file: "")
        appendToAttrStr(string: text.string)
        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        MarkdownDebugLog("<open>", file: "")
        appendToAttrStr(string: "\n")
        MarkdownDebugLog("<close>", file: "")
    }
    
    // NB: I've never seen this called!
    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        MarkdownDebugLog("<open>", file: "")
        appendToAttrStr(string: "\n")
        MarkdownDebugLog("<close>", file: "")
    }
        
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        if inlineHTML.rawHTML == "<br>" {
            appendToAttrStr(string: "\n")
        }
    }
    
    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        print("*** [MarkdownToAttributedString] warning: HTML blocks aren't yet support. (HTML: \(html.rawHTML))")
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) {
        MarkdownDebugLog("<open>", file: "")

        let isInListItem = paragraph.parent is ListItem

        if !isInListItem
            && attributedString.length > 0 // don't add newlines at the very beginning
        {
            appendNewlinesIfNeeded(1)
        }

        visitChildren(of: paragraph)

        // *do* add newlines within the list
        if isInListItem {
            appendNewlinesIfNeeded(1)
        }

        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitStrong(_ strong: Strong) {
        MarkdownDebugLog("<open>", file: "")
        visitWithTemporaryAttributes(markdownAttributes.styleAttributes[.strong] ?? markdownAttributes.baseAttributes, strong)
        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        MarkdownDebugLog("<open>", file: "")
        visitWithTemporaryAttributes(markdownAttributes.styleAttributes[.emphasis] ?? markdownAttributes.baseAttributes, emphasis)
        MarkdownDebugLog("<close>", file: "")
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        MarkdownDebugLog("<open>", file: "")
        var styleAttrs = markdownAttributes.attributesForType(.inlineCode)

        var currentParent = inlineCode.parent
        while let parent = currentParent {
            if parent is Strong {
                if let baseFont = styleAttrs[.font] as? CocoaFont {
#if os(iOS) || os(watchOS)
                    styleAttrs[.font] = CocoaFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.traitBold) ?? baseFont.fontDescriptor, size: baseFont.pointSize)
#elseif os(macOS)
                    styleAttrs[.font] = CocoaFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.bold), size: baseFont.pointSize)
#endif
                }
            } else if parent is Emphasis {
                if let baseFont = styleAttrs[.font] as? CocoaFont {
#if os(iOS) || os(watchOS)
                    styleAttrs[.font] = CocoaFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.traitItalic) ?? baseFont.fontDescriptor, size: baseFont.pointSize)
#elseif os(macOS)
                    styleAttrs[.font] = CocoaFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.italic), size: baseFont.pointSize)
#endif
                }
            }
            currentParent = parent.parent
        }

        appendToAttrStr(string: inlineCode.code, attrs: styleAttrs)
        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        MarkdownDebugLog("<open>", file: "")
        appendNewlinesIfNeeded(2)
        let styleAttrs = markdownAttributes.attributesForType(.codeBlock)
        appendToAttrStr(string: codeBlock.code, attrs: styleAttrs)
        
        appendNewlinesIfNeeded(2)
        MarkdownDebugLog("<close>", file: "")
    }

    /// NB about lists and SwiftMarkdown: SM considers *each* top level list item a separate list, so you can expect this to be called recursively once for each top level item. (Which yes, makes handling newlines a challenge.)
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        MarkdownDebugLog("<open>", file: "")
        let styleAttrs = markdownAttributes.attributesForType(.unorderedList)
        let previousAttributes = currentAttributes

        currentAttributes.mergeAttributes(styleAttrs)

        if !(unorderedList.parent is ListItem) {
            appendNewlinesIfNeeded(2)
        }

        for child in unorderedList.children {
            if let listItem = child as? ListItem {
                visitListItem(listItem)
            } else {
                visit(child)
            }
        }

        currentAttributes = previousAttributes

        if !(unorderedList.parent is ListItem) {
            appendNewlinesIfNeeded(2)
        }

        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        MarkdownDebugLog("<open>", file: "")
        let styleAttrs = markdownAttributes.attributesForType(.orderedList)
        let previousAttributes = currentAttributes

        currentAttributes.mergeAttributes(styleAttrs)

        if !(orderedList.parent is ListItem) {
            appendNewlinesIfNeeded(2)
        }

        var itemIndex = 1
        for child in orderedList.children {
            if let listItem = child as? ListItem {
                visitListItem(listItem, index: itemIndex)
                itemIndex += 1
            } else {
                visit(child)
            }
        }

        currentAttributes = previousAttributes

        if !(orderedList.parent is ListItem) {
            appendNewlinesIfNeeded(2)
        }

        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitListItem(_ listItem: ListItem, index: Int? = nil) {
        MarkdownDebugLog("<open>", file: "")
        let styleAttrs = markdownAttributes.attributesForType(.listItem)
        let previousAttributes = currentAttributes

        currentAttributes.mergeAttributes(styleAttrs)

        let prefix: String
        if let index = index {
            prefix = "\(index). "
        } else {
            let bullets = ["•", "◦", "▪", "▫"]
            prefix = bullets[(listItem.listDepth - 1) % bullets.count] + " "
        }

        let indentation = String(repeating: "  ", count: max(0, listItem.listDepth - 1))

        appendToAttrStr(string: "\(indentation)\(prefix)")

        visitChildren(of: listItem)

        currentAttributes = previousAttributes
        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitHeading(_ heading: Heading) {
        MarkdownDebugLog("<open>", file: "")

        let previousAttributes = currentAttributes

        let level = max(1, min(heading.level, 6))

        var styleAttrs = markdownAttributes.attributesForType(.heading)
        
        let baseFont: CocoaFont = (styleAttrs[.font] as? CocoaFont) ?? CocoaFont.systemFont(ofSize: 15)
        let fontSize = markdownAttributes.headingPointSizes[level - 1]
        let headingFont: CocoaFont
#if os(macOS)
        headingFont = CocoaFont(descriptor: baseFont.fontDescriptor, size: fontSize) ?? baseFont
#else // iOS/watchOS
        headingFont = CocoaFont(descriptor: baseFont.fontDescriptor, size: fontSize)
#endif
        
        styleAttrs[.font] = headingFont
        
        currentAttributes.mergeAttributes(styleAttrs)

        appendNewlinesIfNeeded(2)
        visitChildren(of: heading)
        appendNewlinesIfNeeded(2)

        currentAttributes = previousAttributes
        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitLink(_ link: Link) {
        MarkdownDebugLog("<open>", file: "")

        var styleAttrs = markdownAttributes.attributesForType(.link)

        if let url = link.destination {
            styleAttrs[.link] = URL(string: url)
        }

        let previousAttributes = currentAttributes
        currentAttributes.mergeAttributes(styleAttrs)

        visitChildren(of: link)

        currentAttributes = previousAttributes

        MarkdownDebugLog("<close>", file: "")
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        MarkdownDebugLog("<open>", file: "")

        var styleAttrs = markdownAttributes.baseAttributes
        styleAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue

        let previousAttributes = currentAttributes
        currentAttributes.mergeAttributes(styleAttrs)

        visitChildren(of: strikethrough)

        currentAttributes = previousAttributes

        MarkdownDebugLog("<close>", file: "")
    }
    
    private mutating func visitChildren(of markup: Markup) {
        MarkdownDebugLog("<open>", file: "")
        for child in markup.children {
            visit(child)
        }
        MarkdownDebugLog("<close>", file: "")
    }

    private mutating func visitWithTemporaryAttributes(
        _ attributes: StringAttrs,
        _ markup: Markup
    ) {
        let previousAttributes = currentAttributes
        currentAttributes.mergeAttributes(attributes)
        visitChildren(of: markup)
        currentAttributes = previousAttributes
    }
    
    private mutating func appendToAttrStr(string: String, attrs: StringAttrs? = nil) {
        let actualAtts = attrs ?? currentAttributes
        MarkdownDebugLog("Appending:\n\(string)", file: "")
        attributedString.append(NSAttributedString(string: string, attributes: actualAtts))
    }
    
    private mutating func appendNewlinesIfNeeded(_ count: Int) {
        let currentString = attributedString.string
        let newlineCount = currentString.reversed().prefix(while: { $0 == "\n" }).count

        let newlinesToAppend = count - newlineCount

        if newlinesToAppend > 0 {
            let newlines = String(repeating: "\n", count: newlinesToAppend)
            MarkdownDebugLog("Manually appending \(newlinesToAppend) newlines to reach \(count) total", file: "")
            attributedString.append(NSAttributedString(string: newlines))
        }
    }
}

extension ListItem {
    var listDepth: Int {
        var depth = 0
        var current: Markup? = self
        while let parent = current?.parent {
            if parent is UnorderedList || parent is OrderedList {
                depth += 1
            }
            current = parent
        }
        return max(1, depth)
    }
}
