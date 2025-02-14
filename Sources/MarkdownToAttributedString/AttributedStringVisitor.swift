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
    var markdownStyles: MarkdownStyles

    private var attributedString = NSMutableAttributedString()
    private var currentAttributes: StringAttrs
    private var formattingOptions: FormattingOptions?
    private var shouldAddCustomAttr: Bool {
        return formattingOptions?.addCustomMarkdownElementAttributes ?? false
    }
    private let loggingQ = DispatchQueue(label: "MTAS.logging")

    init(markdown: String,
         styles: MarkdownStyles? = nil,
         options: FormattingOptions? = nil) {
        self.markdown = markdown
        self.markdownStyles = styles ?? MarkdownStyles.default
        self.currentAttributes = self.markdownStyles.baseAttributes.deepCopy()
        self.formattingOptions = options
    }

    mutating func convert() -> NSAttributedString {
        debugLog("Raw markdown to process:\n\(markdown)\n")
        let document = Document(parsing: markdown)
        visit(document)
        
        // Apparently something in SwiftMarkdown is sometimes adding a non-breakable space at the end. Remove it.
        if attributedString.string.hasSuffix("\u{200B}") {
            attributedString.deleteCharacters(in: NSRange(location: attributedString.length - 1, length: 1))
        }
        
        // Ensure the output ends in a newline otherwise trailing newlines in the input get ignored.
        if attributedString.length > 0 && !attributedString.string.hasSuffix("\n") {
            appendNewline()
        }
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

    // We deviate from spec here by inserting newlines for soft breaks. This makes dealing with external input, which may not have been crafted for markdown specifically, better. In the future this could be gated by a `strict` options flag.
    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        debugLog("<open>", file: "")
        appendNewline()
        debugLog("<close>", file: "")
    }
    
    // This is for hard line breaks, but SwiftMarkdown only seems to support the "\\\n" variety, not "  \n".
    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        debugLog("<open>", file: "")
        appendNewline()
        debugLog("<close>", file: "")
    }
        
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        if inlineHTML.rawHTML == "<br>" {
            appendNewline()
        }
    }
    
    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        print("*** [MarkdownToAttributedString] warning: HTML blocks aren't yet supported. (HTML: \(html.rawHTML))")
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) {
        debugLog("<open>", file: "")

        visitChildren(of: paragraph)
        
        if paragraph.hasSuccessor {
            appendNewline()
        }

        debugLog("<close>", file: "")
    }

    mutating func visitStrong(_ strong: Strong) {
        guard optionsSupportEl(.strong) else {
            appendPlainText(strong.plainText)
            debugLog("Skipping unsupported: strong"); return
        }
        debugLog("<open>", file: "")
        let newAttributes = markdownStyles.styleAttributes[.strong] ?? [:]
        visitWithMergedAttributes(newAttributes, strong, markupType: .strong)
        debugLog("<close>", file: "")
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) {
        guard optionsSupportEl(.emphasis) else {
            appendPlainText(emphasis.plainText)
            debugLog("Skipping unsupported: emphasis"); return
        }
        debugLog("<open>", file: "")
        let newAttributes = markdownStyles.styleAttributes[.emphasis] ?? [:]
        visitWithMergedAttributes(newAttributes, emphasis, markupType: .emphasis)
        debugLog("<close>", file: "")
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        guard optionsSupportEl(.inlineCode) else {
            appendPlainText(inlineCode.plainText)
            debugLog("Skipping unsupported: inlineCode"); return
        }
        debugLog("<open>", file: "")
        var styleAttrs = markdownStyles.attributesForType(.inlineCode)

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
        
        let previousAttributes = currentAttributes.deepCopy()
        var styleAttrs = markdownStyles.attributesForType(.codeBlock)
        
        if shouldAddCustomAttr {
            styleAttrs.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: .codeBlock)
            )
        }

        appendToAttrStr(string: codeBlock.code, attrs: styleAttrs)
                
        currentAttributes = previousAttributes.deepCopy()
        
        if codeBlock.hasSuccessor {
            appendNewline()
        }
        
        debugLog("<close>", file: "")
    }

    /// NB about lists and SwiftMarkdown: SM considers *each* top level list item a separate list, so you can expect this to be called recursively once for each top level item. (Which yes, makes handling newlines a challenge.)
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        guard optionsSupportEl(.unorderedList) else {
            appendNewline()
            debugLog("Skipping unsupported: unorderedList"); return
        }
        debugLog("<open>", file: "")
        
        var styleAttrs = markdownStyles.attributesForType(.unorderedList)
        let previousAttributes = currentAttributes.deepCopy()

        if shouldAddCustomAttr {
            styleAttrs.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: .unorderedList)
            )
        }

        currentAttributes.mergeAttributes(styleAttrs)

        for child in unorderedList.children {
            if let listItem = child as? ListItem {
                visitListItem(listItem)
            } else {
                visit(child)
            }
        }
        
        if unorderedList.hasSuccessor {
            appendNewline()
        }

        currentAttributes = previousAttributes.deepCopy()

        debugLog("<close>", file: "")
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        guard optionsSupportEl(.orderedList) else {
            debugLog("Skipping unsupported: orderedList")
            appendNewline()
            return
        }
        debugLog("<open>", file: "")
        var styleAttrs = markdownStyles.attributesForType(.orderedList)
        let previousAttributes = currentAttributes.deepCopy()
        
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

        currentAttributes = previousAttributes.deepCopy()

        debugLog("<close>", file: "")
    }
    

    mutating func visitListItem(_ listItem: ListItem, index: Int? = nil) {
        guard optionsSupportEl(.listItem) else {
            debugLog("Skipping unsupported: listItem")
            appendNewline()
            return
        }
        debugLog("<open>", file: "")
        var styleAttrs = markdownStyles.attributesForType(.listItem)
        let previousAttributes = currentAttributes.deepCopy()

        currentAttributes.mergeAttributes(styleAttrs)
        
        let prefix: String
        let renderedDelimiter: String
        if let index = index {
            prefix = "\(index). "
            renderedDelimiter = markdownStyles.unorderedListBullets[0]
        } else {
            let bullets = markdownStyles.unorderedListBullets
            renderedDelimiter = bullets[listItem.listDepth % bullets.count]
            let tabs = String(repeating: "\t", count: listItem.listDepth + 1)
            prefix = tabs + renderedDelimiter + " "
        }

        if shouldAddCustomAttr {
            var typedDelimiter = "-"
            if let lowerBound = listItem.range?.lowerBound,
               let char = markdown.characterAt(line: lowerBound.line, col: lowerBound.column)
            {
                typedDelimiter = String(char)
            }
            
            styleAttrs.addMarkdownElementAttr(
                ListItemMarkdownElementAttribute(
                    listDepth: listItem.listDepth,
                    indexInParent: listItem.indexInParent,
                    prefix: prefix,
                    typedDelimiter: typedDelimiter,
                    renderedDelimiter: renderedDelimiter)
            )
        }
        currentAttributes.mergeAttributes(styleAttrs)
        
        appendToAttrStr(string: "\(prefix)")

        visitChildren(of: listItem)
        
        if listItem.hasSuccessor {
            appendNewline()
        }

        currentAttributes = previousAttributes.deepCopy()
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

        let previousAttributes = currentAttributes.deepCopy()

        let level = max(1, min(heading.level, 6))

        var styleAttrs = markdownStyles.attributesForType(.heading)
        
        let baseFont: CocoaFont = (styleAttrs[.font] as? CocoaFont) ?? CocoaFont.systemFont(ofSize: 15)
        let fontSize = markdownStyles.headingPointSizes[level - 1]
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

        visitChildren(of: heading)
        
        if heading.hasSuccessor {
            appendNewline()
        }

        currentAttributes = previousAttributes.deepCopy()
        debugLog("<close>", file: "")
    }

    mutating func visitLink(_ link: Link) {
        guard optionsSupportEl(.link) else {
            appendPlainText(link.plainText)
            debugLog("Skipping unsupported: link"); return
        }
        debugLog("<open>", file: "")

        var styleAttrs = markdownStyles.attributesForType(.link)

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

        let previousAttributes = currentAttributes.deepCopy()
        currentAttributes.mergeAttributes(styleAttrs)

        visitChildren(of: link)

        currentAttributes = previousAttributes.deepCopy()

        debugLog("<close>", file: "")
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        guard optionsSupportEl(.strikethrough) else {
            appendPlainText(strikethrough.plainText)
            debugLog("Skipping unsupported: strikethrough"); return
        }
        debugLog("<open>", file: "")
        
        var styleAttrs = markdownStyles.styleAttributes[.strikethrough] ?? markdownStyles.baseAttributes
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
        let previousAttributes = currentAttributes.deepCopy()
        currentAttributes.mergeAttributes(attributes)
        visitChildren(of: markup)
        currentAttributes = previousAttributes.deepCopy()
    }
    
    private mutating func visitWithMergedAttributes(
        _ newAttributes: StringAttrs,
        _ markup: Markup,
        markupType: MarkupType
    ) {
        let previousAttributes = currentAttributes.deepCopy()
        var mergedAttributes = currentAttributes.deepCopy()
        mergedAttributes.mergeAttributes(newAttributes) // Merge general attributes
        
        if shouldAddCustomAttr {
            mergedAttributes.addMarkdownElementAttr(
                MarkdownElementAttribute(elementType: markupType)
            )
        }

        if let expectedFont = markdownStyles.fontAttributeForType(markupType) as? CocoaFont,
           let currentFont = currentAttributes[.font] as? CocoaFont {
            let newDescriptor = mergeFontDescriptors(base: currentFont.fontDescriptor, expected: expectedFont.fontDescriptor)
            mergedAttributes[.font] = CocoaFont(descriptor: newDescriptor, size: expectedFont.pointSize)
        }

        currentAttributes = mergedAttributes.deepCopy()
        visitChildren(of: markup)
        currentAttributes = previousAttributes.deepCopy()
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
        debugLog("appending newline")
        appendPlainText("\n")
    }
        
    private func appendPlainText(_ plainText: String) {
        attributedString.append(NSAttributedString(
            string: plainText,
            attributes: markdownStyles.baseAttributes))
    }

    private func debugLog(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        if self.formattingOptions?.debugLogging ?? false {
            loggingQ.sync {
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
    
    var hasSuccessor: Bool {
        guard let childCount = parent?.childCount else { return false }
        return indexInParent < childCount - 1
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
                var attrs = (self[.markdownElements] as? MarkdownElementAttributes)?.copy() as? MarkdownElementAttributes ?? MarkdownElementAttributes()
                
                for (markupType, newAttribute) in val.allAttributes {
                    attrs.set(markupType, value: newAttribute)
                }

                self[.markdownElements] = attrs
            } else {
                self[key] = val
            }
        }
    }
}

extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    func deepCopy() -> StringAttrs {
        var copy: StringAttrs = [:]
        
        for (key, value) in self {
            if let copyable = value as? NSCopying {
                copy[key] = copyable.copy()
            } else if let array = value as? [Any] {
                copy[key] = array.deepCopyArray()
            } else if let dict = value as? [AnyHashable: Any] {
                copy[key] = dict.deepCopyDict()
            } else {
                copy[key] = value // Assume it's a value type (Int, String, etc.)
            }
        }
        
        return copy
    }
}

private extension Array where Element == Any {
    func deepCopyArray() -> [Any] {
        return self.map { element in
            if let copyable = element as? NSCopying {
                return copyable.copy()
            } else if let dict = element as? [AnyHashable: Any] {
                return dict.deepCopyDict()
            } else {
                return element
            }
        }
    }
}

private extension Dictionary where Key == AnyHashable, Value == Any {
    func deepCopyDict() -> [AnyHashable: Any] {
        var copy: [AnyHashable: Any] = [:]
        for (key, value) in self {
            if let copyable = value as? NSCopying {
                copy[key] = copyable.copy()
            } else if let array = value as? [Any] {
                copy[key] = array.deepCopyArray()
            } else if let dict = value as? [AnyHashable: Any] {
                copy[key] = dict.deepCopyDict()
            } else {
                copy[key] = value
            }
        }
        return copy
    }
}

extension String {
    func characterAt(line: Int, col: Int) -> Character? {
        let lines = self.split(separator: "\n", omittingEmptySubsequences: false)
        
        let zeroIndexedLine = line - 1
        let zeroIndexedCol = col - 1
        
        guard zeroIndexedLine >= 0 && zeroIndexedLine < lines.count else {
            return nil
        }
        
        let line = lines[zeroIndexedLine]
        
        guard zeroIndexedCol >= 0 && zeroIndexedCol < line.count else {
            return nil
        }
        
        let index = line.index(line.startIndex, offsetBy: zeroIndexedCol)
        return line[index]
    }
}
