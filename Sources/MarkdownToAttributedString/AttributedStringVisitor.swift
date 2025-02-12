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
    private var formattingOptions: FormattingOptions?
    private var shouldAddCustomAttr: Bool {
        return formattingOptions?.addCustomMarkdownElementAttributes ?? false
    }
    private let loggingQ = DispatchQueue(label: "MTAS.logging")

    init(markdown: String,
         attributes: MarkdownAttributes? = nil,
         options: FormattingOptions? = nil) {
        self.markdown = markdown
        self.markdownAttributes = attributes ?? MarkdownAttributes.default
        self.currentAttributes = self.markdownAttributes.baseAttributes
        self.formattingOptions = options
    }

    mutating func convert() -> NSAttributedString {
        debugLog("Raw markdown to process:\n\(markdown)\n")
        let document = Document(parsing: markdown)
        visit(document)
        debugLog("Final plain text:\n\(attributedString.string)\n\n")
        debugLog("Final text+attrs:\n\(attributedString.betterDescription)")
        return attributedString
    }

    mutating func defaultVisit(_ markup: any Markup) {
        visitChildren(of: markup)
    }

    mutating func visitText(_ text: Text) {
        debugLog("<open>", file: "")
        appendToAttrStr(string: text.string)
        debugLog("<close>", file: "")
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        debugLog("<open>", file: "")
        appendToAttrStr(string: "\n")
        debugLog("<close>", file: "")
    }
    
    // NB: I've never seen this called!
    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        debugLog("<open>", file: "")
        appendToAttrStr(string: "\n")
        debugLog("<close>", file: "")
    }
        
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        if inlineHTML.rawHTML == "<br>" {
            appendToAttrStr(string: "\n")
        }
    }
    
    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        print("*** [MarkdownToAttributedString] warning: HTML blocks aren't yet supported. (HTML: \(html.rawHTML))")
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) {
        debugLog("<open>", file: "")

        let isInListItem = paragraph.parent is ListItem

        // don't add newlines at the start of file or if in a list
        // (seems like a bug that the parser opens a paragraph _within_ the list item?)
        if !isInListItem
            && attributedString.length > 0
        {
            appendNewline()
        }

        visitChildren(of: paragraph)

        debugLog("<close>", file: "")
    }

    mutating func visitStrong(_ strong: Strong) {
        guard optionsSupportEl(.strong) else {
            appendPlainText(strong.plainText)
            debugLog("Skipping unsupported: strong"); return
        }
        debugLog("<open>", file: "")
        let newAttributes = markdownAttributes.styleAttributes[.strong] ?? [:]
        visitWithMergedAttributes(newAttributes, strong, markupType: .strong)
        debugLog("<close>", file: "")
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) {
        guard optionsSupportEl(.emphasis) else {
            appendPlainText(emphasis.plainText)
            debugLog("Skipping unsupported: emphasis"); return
        }
        debugLog("<open>", file: "")
        let newAttributes = markdownAttributes.styleAttributes[.emphasis] ?? [:]
        visitWithMergedAttributes(newAttributes, emphasis, markupType: .emphasis)
        debugLog("<close>", file: "")
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        guard optionsSupportEl(.inlineCode) else {
            appendPlainText(inlineCode.plainText)
            debugLog("Skipping unsupported: inlineCode"); return
        }
        debugLog("<open>", file: "")
        var styleAttrs = markdownAttributes.attributesForType(.inlineCode)

        var currentParent = inlineCode.parent
        while let parent = currentParent {
            if parent is Strong {
                if let baseFont = styleAttrs[.font] as? CocoaFont {
                    if shouldAddCustomAttr {
                        
                        styleAttrs.addMarkdownElementAttr(
                            MarkdownElementAttribute(elementType: .strong)
                        )
                    }
#if os(iOS) || os(watchOS)
                    styleAttrs[.font] = CocoaFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.traitBold) ?? baseFont.fontDescriptor, size: baseFont.pointSize)
#elseif os(macOS)
                    styleAttrs[.font] = CocoaFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.bold), size: baseFont.pointSize)
#endif
                }
            } else if parent is Emphasis {
                if let baseFont = styleAttrs[.font] as? CocoaFont {
                    if shouldAddCustomAttr {
                        styleAttrs.addMarkdownElementAttr(
                            MarkdownElementAttribute(elementType: .emphasis)
                        )
                    }
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
        debugLog("<close>", file: "")
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        guard optionsSupportEl(.codeBlock) else {
            appendPlainText(codeBlock.code)
            debugLog("Skipping unsupported: codeBlock"); return
        }
        debugLog("<open>", file: "")
        
        let previousAttributes = currentAttributes
        var styleAttrs = markdownAttributes.attributesForType(.codeBlock)
        
        if shouldAddCustomAttr {
            styleAttrs.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: .codeBlock)
            )
        }

        appendToAttrStr(string: codeBlock.code, attrs: styleAttrs)
                
        currentAttributes = previousAttributes
        debugLog("<close>", file: "")
    }

    /// NB about lists and SwiftMarkdown: SM considers *each* top level list item a separate list, so you can expect this to be called recursively once for each top level item. (Which yes, makes handling newlines a challenge.)
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        guard optionsSupportEl(.unorderedList) else {
            appendPlainText("\n")
            debugLog("Skipping unsupported: unorderedList"); return
        }
        debugLog("<open>", file: "")
        
        var styleAttrs = markdownAttributes.attributesForType(.unorderedList)
        let previousAttributes = currentAttributes

        if shouldAddCustomAttr {
            styleAttrs.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: .unorderedList)
            )
        }

        currentAttributes.mergeAttributes(styleAttrs)

        if !(unorderedList.parent is ListItem) && !unorderedList.isFirstLine {
            appendNewline()
        }

        for child in unorderedList.children {
            if let listItem = child as? ListItem {
                visitListItem(listItem)
                appendNewline()
            } else {
                visit(child)
            }
        }

        currentAttributes = previousAttributes

        debugLog("<close>", file: "")
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        guard optionsSupportEl(.orderedList) else {
            appendPlainText("\n")
            debugLog("Skipping unsupported: orderedList"); return
        }
        debugLog("<open>", file: "")
        var styleAttrs = markdownAttributes.attributesForType(.orderedList)
        let previousAttributes = currentAttributes
        
        if shouldAddCustomAttr {
            styleAttrs.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: .orderedList)
            )
        }

        currentAttributes.mergeAttributes(styleAttrs)

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

        debugLog("<close>", file: "")
    }
    

    mutating func visitListItem(_ listItem: ListItem, index: Int? = nil) {
        guard optionsSupportEl(.listItem) else {
            appendPlainText("\n")
            debugLog("Skipping unsupported: listItem"); return
        }
        debugLog("<open>", file: "")
        var styleAttrs = markdownAttributes.attributesForType(.listItem)
        let previousAttributes = currentAttributes

        currentAttributes.mergeAttributes(styleAttrs)

        let prefix: String
        if let index = index {
            prefix = "\(index). "
        } else {
            let bullets = ["•", "◦", "▪", "▫"]
            prefix = bullets[listItem.listDepth % bullets.count] + " "
        }

        let indentation = String(repeating: "  ", count: listItem.listDepth)

        if shouldAddCustomAttr
            && listItem.rangeWithinLine.location - listItem.listDepth == 0
        {
            styleAttrs.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: .listItem)
            )
        }
        currentAttributes.mergeAttributes(styleAttrs)
        
        appendToAttrStr(string: "\(indentation)\(prefix)")

        visitChildren(of: listItem)

        currentAttributes = previousAttributes
        debugLog("<close>", file: "")
    }

    mutating func visitHeading(_ heading: Heading) {
        func delimiters(_ level: Int) -> String {
            return String(repeating: "#", count: level)
        }
        
        guard optionsSupportEl(.heading) else {
            debugLog("Skipping unsupported: heading")

            // If we really want to preserve headings then we need to add back the delimiters...
            var str = delimiters(heading.level) + " "
            if let range = heading.range, range.lowerBound.line > 1 {
                //  ...and possibly a prefixed newline
                str = "\n" + str
            }

            appendPlainText(str)
            
            // This will get the actual text + possible <br>s
            visitChildren(of: heading)
            
            return
        }
        debugLog("<open>", file: "")

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
        
        if shouldAddCustomAttr {
            styleAttrs.addMarkdownElementAttr(
                HeadingMarkdownElementAttribute(level: heading.level)
            )
        }
        
        currentAttributes.mergeAttributes(styleAttrs)

        if attributedString.length > 0 { // don't add newlines at the very beginning
            appendNewlinesIfNeeded(1)
        }
        visitChildren(of: heading)

        currentAttributes = previousAttributes
        debugLog("<close>", file: "")
    }

    mutating func visitLink(_ link: Link) {
        guard optionsSupportEl(.link) else {
            appendPlainText(link.plainText)
            debugLog("Skipping unsupported: link"); return
        }
        debugLog("<open>", file: "")

        var styleAttrs = markdownAttributes.attributesForType(.link)

        if let urlstr = link.destination {
            guard let url = URL(string: urlstr) else {
                assertionFailure("Invalid URL string \(urlstr)"); return
            }
            if shouldAddCustomAttr {
                styleAttrs.addMarkdownElementAttr(
                    LinkMarkdownElementAttribute(url: url)
                )
            }
            styleAttrs[.link] = url
        }

        let previousAttributes = currentAttributes
        currentAttributes.mergeAttributes(styleAttrs)

        visitChildren(of: link)

        currentAttributes = previousAttributes

        debugLog("<close>", file: "")
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        guard optionsSupportEl(.strikethrough) else {
            appendPlainText(strikethrough.plainText)
            debugLog("Skipping unsupported: strikethrough"); return
        }
        debugLog("<open>", file: "")
        
        var styleAttrs = markdownAttributes.styleAttributes[.strikethrough] ?? markdownAttributes.baseAttributes
        if shouldAddCustomAttr {
            styleAttrs.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: .strikethrough)
            )
        }

        visitWithTemporaryAttributes(styleAttrs, strikethrough)
        debugLog("<close>", file: "")
    }
    
    private mutating func visitChildren(of markup: Markup) {
        debugLog("<open>", file: "")
        for child in markup.children {
            visit(child)
        }
        debugLog("<close>", file: "")
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
    
    private mutating func visitWithMergedAttributes(
        _ newAttributes: StringAttrs,
        _ markup: Markup,
        markupType: MarkupType
    ) {
        let previousAttributes = currentAttributes
        var mergedAttributes = currentAttributes
        mergedAttributes.mergeAttributes(newAttributes) // Merge general attributes
        
        if shouldAddCustomAttr {
            mergedAttributes.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: markupType)
            )
        }

        if let expectedFont = markdownAttributes.fontAttributeForType(markupType) as? CocoaFont,
           let currentFont = currentAttributes[.font] as? CocoaFont {
            let newDescriptor = mergeFontDescriptors(base: currentFont.fontDescriptor, expected: expectedFont.fontDescriptor)
            mergedAttributes[.font] = CocoaFont(descriptor: newDescriptor, size: expectedFont.pointSize)
        }

        currentAttributes = mergedAttributes
        visitChildren(of: markup)
        currentAttributes = previousAttributes
    }

    private func mergeFontDescriptors(base: FontDescriptor, expected: FontDescriptor) -> FontDescriptor {
        var traits = base.symbolicTraits

        // Preserve italics if the expected font has it
#if os(iOS) || os(watchOS)
        if expected.symbolicTraits.contains(.traitItalic) {
            traits.insert(.traitItalic)
        }
#elseif os(macOS)
        if expected.symbolicTraits.contains(.italic) {
            traits.insert(.italic)
        }
#endif
        
        // Preserve bold if the expected font has it
#if os(iOS) || os(watchOS)
        if expected.symbolicTraits.contains(.traitBold) {
            traits.insert(.traitBold)
        }
#elseif os(macOS)
        if expected.symbolicTraits.contains(.bold) {
            traits.insert(.bold)
        }
#endif
        
#if os(iOS) || os(watchOS)
        return expected.withSymbolicTraits(traits) ?? expected
#elseif os(macOS)
        return expected.withSymbolicTraits(traits)
#endif
    }

    private mutating func appendToAttrStr(string: String, attrs: StringAttrs? = nil) {
        let actualAttrs = attrs ?? currentAttributes
        debugLog("Appending:\n\(string)", file: "")
        attributedString.append(NSAttributedString(string: string, attributes: actualAttrs))
    }
    
    private mutating func appendNewline() {
        debugLog("Manually appending newline")
        appendPlainText("\n")
    }
    
    private mutating func appendNewlinesIfNeeded(_ count: Int) {
        let currentString = attributedString.string
        let newlineCount = currentString.reversed().prefix(while: { $0 == "\n" }).count

        let newlinesToAppend = count - newlineCount

        if newlinesToAppend > 0 {
            let newlines = String(repeating: "\n", count: newlinesToAppend)
            debugLog("Manually appending \(newlinesToAppend) newlines to reach \(count) total", file: "")
            attributedString.append(NSAttributedString(
                string: newlines,
                attributes: markdownAttributes.baseAttributes))
        }
    }
    
    private func appendPlainText(_ plainText: String) {
        attributedString.append(NSAttributedString(
            string: plainText,
            attributes: markdownAttributes.baseAttributes))
    }

    private func debugLog(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        if self.formattingOptions?.debugLogging ?? false {
            loggingQ.async {
                MarkdownDebugLog(message, file: file, line: line, function: function)
            }
        }
    }
    
    private func optionsSupportEl(_ elType: MarkupType) -> Bool {
        guard let formattingOptions else { return true }
        return formattingOptions.supportedElementTypes.contains(elType)
    }
}

extension ListItem {
    
    // Nesting depth of the list item; 0 indexed.
    var listDepth: Int {
        var depth = 0
        var current: Markup? = self
        while let parent = current?.parent {
            if parent is UnorderedList || parent is OrderedList {
                depth += 1
            }
            current = parent
        }
        return max(0, depth - 1)
    }
}

extension Markup {
    var isFirstLine: Bool {
        guard let range else { return false }
        return range.lowerBound.line == 1
    }
    
    var rangeWithinLine: NSRange {
        guard let range else { return NSRange(location: NSNotFound, length: 0) }
        let start = range.lowerBound.column - 1
        return NSRange(location: start,
                       length: range.upperBound.column - start - 1)
    }
}

extension StringAttrs {
    mutating func mergeAttributes(_ otherAttrs: StringAttrs) {
        for (key, val) in otherAttrs {
            if key == .markdownElements, let val = val as? MarkdownElementAttributes {
                var attrs = self[.markdownElements] as? MarkdownElementAttributes
                    ?? MarkdownElementAttributes()
                
                attrs.merge(val) { (_, new) in new }
                
                self[.markdownElements] = attrs
            } else {
                self[key] = val
            }
        }
    }
}
