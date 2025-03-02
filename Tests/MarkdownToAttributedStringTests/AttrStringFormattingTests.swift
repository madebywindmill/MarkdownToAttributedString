//
//  MarkdownToAttributedStringTests.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 1/18/25.
//

import XCTest
@testable import MarkdownToAttributedString
import Markdown

final class MarkdownToAttributedStringTests: XCTestCase {
    
    static let defaultMDStyles = MarkdownStyles.default
    static let options = FormattingOptions(addCustomMarkdownElementAttributes: true, debugLogging: true)
    static let trimWhitespaceOptions = FormattingOptions(addCustomMarkdownElementAttributes: true, debugLogging: true, trimWhitespace: true)
    
    var defaultFormatter: AttributedStringFormatter!
    var trimWhitespaceFormatter: AttributedStringFormatter!
    
    override func setUp() {
        defaultFormatter = AttributedStringFormatter(styles: Self.defaultMDStyles, options: Self.options)
        trimWhitespaceFormatter = AttributedStringFormatter(styles: Self.defaultMDStyles, options: Self.trimWhitespaceOptions)
    }
    
    func testBoldText() {
        var md = "This is **bold** text.\n"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This is bold text.\n")

        var styledRange = (attrStr.string as NSString).range(of: "bold")
        var attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        var font = attributes[.font] as! CocoaFont
        var expectedFont = Self.defaultMDStyles.fontAttributeForType(.strong)
        
        XCTAssertTrue(font.customIsEqual(to: expectedFont))

        md = "This is 😈 **bold 💯** text with 🎈 emoji.\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This is 😈 bold 💯 text with 🎈 emoji.\n")

        styledRange = (attrStr.string as NSString).range(of: "bold 💯")
        attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        font = attributes[.font] as! CocoaFont
        expectedFont = Self.defaultMDStyles.fontAttributeForType(.strong)
        
        XCTAssertTrue(font.customIsEqual(to: expectedFont))
    }
    
    func testItalicText() {
        let md = "This is *italic* text.\n"
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This is italic text.\n")

        let styledRange = (attrStr.string as NSString).range(of: "italic")
        let attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        let expectedFont = Self.defaultMDStyles.fontAttributeForType(.emphasis)

        XCTAssertTrue(font.customIsEqual(to: expectedFont))
    }
    
    func testBoldItalics() {
        var md = "This has **_both_**.\n"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This has both.\n")
        
        var styledRange = (attrStr.string as NSString).range(of: "both")
        var attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        var font = attributes[.font] as! CocoaFont
        XCTAssertTrue(font.containsBoldTrait())
        XCTAssertTrue(font.containsItalicsTrait())
        XCTAssertTrue(attributes.hasMarkdownElementType(.strong))
        XCTAssertTrue(attributes.hasMarkdownElementType(.emphasis))

        
        md = "**bold *nested italics***\n"
        attrStr = defaultFormatter.format(markdown: md)
        styledRange = (attrStr.string as NSString).range(of: "bold")
        attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        font = attributes[.font] as! CocoaFont
        XCTAssertTrue(font.containsBoldTrait())
        XCTAssertFalse(font.containsItalicsTrait())
        XCTAssertTrue(attributes.hasMarkdownElementType(.strong))
        XCTAssertFalse(attributes.hasMarkdownElementType(.emphasis))
        styledRange = (attrStr.string as NSString).range(of: "nested italics")
        attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        font = attributes[.font] as! CocoaFont
        XCTAssertTrue(font.containsBoldTrait())
        XCTAssertTrue(font.containsItalicsTrait())
        XCTAssertTrue(attributes.hasMarkdownElementType(.strong))
        XCTAssertTrue(attributes.hasMarkdownElementType(.emphasis))
    }
    
    func testInlineCode() {
        let md = "Here is `inline code`."
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertTrue(attrStr.string.contains("inline code"))
        
        let styledRange = (attrStr.string as NSString).range(of: "inline code")
        let attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        XCTAssertEqual(attributes[.font] as? CocoaFont, Self.defaultMDStyles.fontAttributeForType(.inlineCode))
    }
    
    func testNestedInlineCode() {
        var md = "Here is **`nested inline code`**."
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertTrue(attrStr.string.contains("nested inline code"))
        
        let styledRange = (attrStr.string as NSString).range(of: "nested inline code")
        
        let attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        XCTAssertTrue(font.containsBoldTrait())
        XCTAssertTrue(font.isMonospaced())
    }

    func testCodeBlocks() {
        var md: String
        var attrStr: NSAttributedString

        // Fenced code block with triple backticks
        md = """
        ```
        let x = 10
        print(x)
        ```
        """
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "let x = 10\nprint(x)\n")

        // Indented code block (4 spaces)
        md = """
            let y = 20
            print(y)
        """
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "let y = 20\nprint(y)\n")

        // Code block with language specification
        md = """
        ```swift
        let z = 30
        print(z)
        ```
        """
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "let z = 30\nprint(z)\n")
    }
    
    func testStrikethrough() {
        let md = "Here's some ~~strikethrough~~ text."
        let attrStr = defaultFormatter.format(markdown: md)
        let styleRange = (attrStr.string as NSString).range(of: "strikethrough")
        let attributes = attrStr.attributes(at: styleRange.location, effectiveRange: nil)
        XCTAssertEqual(attributes[.strikethroughStyle] as? Int, 1)
        
        guard let expectedStrikeColor: CocoaColor = Self.defaultMDStyles.valueForAttribute(.strikethroughColor, type: .strikethrough) else {
            XCTFail(); return
        }
        guard let expectedFontColor: CocoaColor = Self.defaultMDStyles.valueForAttribute(.foregroundColor, type: .strikethrough) else {
            XCTFail(); return
        }

        XCTAssertEqual(attributes[.strikethroughColor] as? CocoaColor, expectedStrikeColor)
        XCTAssertEqual(attributes[.foregroundColor] as? CocoaColor, expectedFontColor)
    }
    

    func testListEquality() {
        func uoListAt(_ loc: Int) -> MarkdownElementAttribute {
            return attrStr.attrsAt(loc).markdownElementAttrForElementType(.unorderedList)!
        }
        func oListAt(_ loc: Int) -> MarkdownElementAttribute {
            return attrStr.attrsAt(loc).markdownElementAttrForElementType(.orderedList)!
        }

        var md = "- li\n  - li\n    - li\n  - li\n- li\n"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• li\n\t\t◦ li\n\t\t\t▪ li\n\t\t◦ li\n\t• li\n")
        for i in 0..<attrStr.string.count - 1 {
            XCTAssertEqual(uoListAt(i), uoListAt(i+1))
        }
        
        md = "1. li\n2. li\n3. li\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t1. li\n\t2. li\n\t3. li\n")
        for i in 0..<attrStr.string.count - 1 {
            XCTAssertEqual(oListAt(i), oListAt(i+1))
        }
    }
    
    func testUnorderedLists() {
        // with trailing \n
        var md = "- Item 1\n- Item 2\n"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• Item 1\n\t• Item 2\n")
        XCTAssertTrue(attrStr.hasAttribute(key: .paragraphStyle, at: 0))
        XCTAssertTrue(attrStr.hasAttribute(key: .paragraphStyle, at: 10))
        XCTAssertTrue(attrStr.hasAttribute(key: .paragraphStyle, at: 9))
        XCTAssertTrue(attrStr.hasAttribute(key: .paragraphStyle, at: 19))

        // nested styles
        md = "- **Item 1**\n- *Item 2*\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• Item 1\n\t• Item 2\n")
        XCTAssertFalse(attrStr.fontAt(location: 0)!.hasBold)
        XCTAssertFalse(attrStr.fontAt(location: 1)!.hasBold)
        XCTAssertTrue(attrStr.fontAt(location: 3)!.hasBold)
        XCTAssertTrue(attrStr.fontAt(location: 8)!.hasBold)
        XCTAssertFalse(attrStr.fontAt(location: 10)!.hasItalic)
        XCTAssertFalse(attrStr.fontAt(location: 11)!.hasItalic)
        XCTAssertTrue(attrStr.fontAt(location: 13)!.hasItalic)
        XCTAssertTrue(attrStr.fontAt(location: 18)!.hasItalic)

        md = "* li1\n  * li1.1\n"
        attrStr = defaultFormatter.format(markdown: md)
        var listItemAttr = attrStr.startingAttrs.markdownElementAttrForElementType(.listItem) as! ListItemMarkdownElementAttribute
        XCTAssertEqual(listItemAttr.prefix, "\t• ")
        XCTAssertEqual(listItemAttr.listDepth, 0)
        listItemAttr = attrStr.attributes(at: 7, effectiveRange: nil).markdownElementAttrForElementType(.listItem) as! ListItemMarkdownElementAttribute
        XCTAssertEqual(listItemAttr.prefix, "\t\t◦ ")
        XCTAssertEqual(listItemAttr.listDepth, 1)
        
        md = "- li1\n  - li1.1\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• li1\n\t\t◦ li1.1\n")

        // According to spec, the "foo" is actually part of the list. In fact it's part of the _first list item_. But our parser doesn't handle that to spec because for external compatibility reasons we treat soft breaks as newlines.
        md = "- li1\nfoo\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• li1\nfoo\n")
        XCTAssert(attrStr.startingAttrs.hasMarkdownElementType(.listItem))
        // foo is also part of the list!
        XCTAssert(attrStr.attributes(at: 8, effectiveRange: nil).hasMarkdownElementType(.listItem))

        // Here there are two line breaks closing the list, so foo is not part of it.
        md = "- li1\n\nfoo\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• li1\n\nfoo\n")
        XCTAssert(attrStr.startingAttrs.hasMarkdownElementType(.listItem))
        // foo is not part of the list
        XCTAssertFalse(attrStr.attributes(at: 8, effectiveRange: nil).hasMarkdownElementType(.listItem))
        
        // Demonstrates how to use a "  \n\n" instead of "<br>\n" to end the list.
        md = "- li1  \n\nfoo\n​"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• li1\n\nfoo\n")
        XCTAssert(attrStr.startingAttrs.hasMarkdownElementType(.listItem))
        // foo is not part of the list
        XCTAssertFalse(attrStr.attributes(at: 8, effectiveRange: nil).hasMarkdownElementType(.listItem))

        // Capturing delimiters
        md = "- Item 1\n  - Item 1.1\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• Item 1\n\t\t◦ Item 1.1\n")
        
        var liAttr = attrStr.attrsAt(0).markdownElementAttrForElementType(.listItem) as! ListItemMarkdownElementAttribute
        XCTAssertEqual(liAttr.typedDelimiter, "-")
        XCTAssertEqual(liAttr.renderedDelimiter, "•")
        liAttr = attrStr.attrsAt(10).markdownElementAttrForElementType(.listItem) as! ListItemMarkdownElementAttribute
        XCTAssertEqual(liAttr.typedDelimiter, "-")
        XCTAssertEqual(liAttr.renderedDelimiter, "◦")

        // Ensure newline attr is in the list block
        md = "- Item1\n- Item2\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t• Item1\n\t• Item2\n")
        XCTAssertTrue(attrStr.attrsAt(0).hasMarkdownElementType(.unorderedList))
        XCTAssertTrue(attrStr.attrsAt(8).hasMarkdownElementType(.unorderedList))

    }
    
    func testOrderedLists() {
        var md = "1. Item 1\n2. Item 2\n"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t1. Item 1\n\t2. Item 2\n")

        // Ordered list with different starting number
        md = "3. Item 3\n4. Item 4\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t3. Item 3\n\t4. Item 4\n")
        
        // nested styles
        md = "1. **Item 1**\n2. *Item 2*\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "\t1. Item 1\n\t2. Item 2\n")
        XCTAssertFalse(attrStr.fontAt(location: 0)!.hasBold)
        XCTAssertFalse(attrStr.fontAt(location: 1)!.hasBold)
        XCTAssertTrue(attrStr.fontAt(location: 4)!.hasBold)
        XCTAssertTrue(attrStr.fontAt(location: 9)!.hasBold)
        XCTAssertFalse(attrStr.fontAt(location: 12)!.hasItalic)
        XCTAssertFalse(attrStr.fontAt(location: 13)!.hasItalic)
        XCTAssertTrue(attrStr.fontAt(location: 15)!.hasItalic)
        XCTAssertTrue(attrStr.fontAt(location: 20)!.hasItalic)
    }
        
    func testCompositeMarkdown() {
        let md = "This is **bold** and *italic*, and here is `inline code`.\n- An unordered list item."
        let attrStr = defaultFormatter.format(markdown: md)
        
        XCTAssertTrue(attrStr.string.contains("bold"))
        XCTAssertTrue(attrStr.string.contains("italic"))
        XCTAssertTrue(attrStr.string.contains("inline code"))
        XCTAssertTrue(attrStr.string.contains("An unordered list item."))
        
        // Validate attributes for each type
        let boldRange = (attrStr.string as NSString).range(of: "bold")
        let boldAttributes = attrStr.attributes(at: boldRange.location, effectiveRange: nil)
        XCTAssertEqual(boldAttributes[.font] as? CocoaFont, Self.defaultMDStyles.fontAttributeForType(.strong))
        
        let italicRange = (attrStr.string as NSString).range(of: "italic")
        let italicAttributes = attrStr.attributes(at: italicRange.location, effectiveRange: nil)
        XCTAssertEqual(italicAttributes[.font] as? CocoaFont, Self.defaultMDStyles.fontAttributeForType(.emphasis))
        
        let codeRange = (attrStr.string as NSString).range(of: "inline code")
        let codeAttributes = attrStr.attributes(at: codeRange.location, effectiveRange: nil)
        XCTAssertEqual(codeAttributes[.font] as? CocoaFont, Self.defaultMDStyles.fontAttributeForType(.inlineCode))
    }
    
    func testHeadings() {
        let md = """
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6
        """
        let attrStr = defaultFormatter.format(markdown: md)

        for i in 1...6 {
            XCTAssertTrue(attrStr.string.contains("Heading \(i)"), "Heading \(i) not found in output string.")
        }

        let headingFont = Self.defaultMDStyles.fontAttributeForType(.heading)
        
        for i in 1...6 {
            let headingText = "Heading \(i)"
            let headingRange = (attrStr.string as NSString).range(of: headingText)
            let attributes = attrStr.attributes(at: headingRange.location, effectiveRange: nil)

            let actualFont = attributes[.font] as! CocoaFont
            XCTAssertEqual(actualFont.fontDescriptor.postscriptName, headingFont.fontDescriptor.postscriptName)
            XCTAssertEqual(actualFont.pointSize, Self.defaultMDStyles.headingPointSizes[i-1], "Font point size for \(headingText) doesn't match.")
        }
    }
        
    // https://github.com/madebywindmill/MarkdownToAttributedString/issues/1
    func testHeadingLineBreaks() {
        var md = "# Heading 1"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertFalse(attrStr.string.starts(with: "\n"), attrStr.string)
        
        md = "# H1<br>\n​"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "H1\n\n")

        md = "# Heading 1\nSome text"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertTrue(attrStr.string == "Heading 1\nSome text\n")
        
        md = "# Heading 1"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertFalse(attrStr.string.hasSuffix("\n\n"), attrStr.string)
    }

    func testLineBreaks1() {
        var md = "Line1\nLine2\n"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\nLine2\n")
        
        md = "\nLine1\nLine2\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\nLine2\n")

        md = "\n\nLine1\nLine2\n\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\nLine2\n")

        md = "Line1\n\n\nLine2\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\nLine2\n")

        md = "Line1<br><br><br>Line2\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\n\n\nLine2\n")
        
        md = "Line1<br>\nLine2\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\n\nLine2\n")
        
        // Surprising? But the CommonMark dingus confirms this is correct.
        md = "Line1<br>\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\n")

        
        // Fails. I haven't tested extensively but I don't think SwiftMarkdown is handling hard line breaks as described by CommonMark (using 2+ spaces or a \ before the newline) correctly, or at all. On the other hand they don't work in CommonMark's own playground so maybe I'm misunderstanding.
//        md = "Line1  \n  \n  \nLine2"
//        attrStr = defaultFormatter.format(markdown: md)
//        XCTAssertEqual(attrStr.string, "Line1\n\n\nLine2")

    }
        
    func testWhitespaceTrimming() {
        var md = "This is 😈 **bold 💯** text with 🎈 emoji.\n"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This is 😈 bold 💯 text with 🎈 emoji.\n")
        attrStr = trimWhitespaceFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This is 😈 bold 💯 text with 🎈 emoji.")

        md = "😈"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "😈\n")
        attrStr = trimWhitespaceFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "😈")

        md = "\n😈"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "😈\n")
        attrStr = trimWhitespaceFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "😈")

        md = "\n\t😈\t\t"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "😈\t\t\n")
        attrStr = trimWhitespaceFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "😈")

    }

}

extension CocoaFont {
    
    // Sometimes we can't just compare fonts because they can end up with slightly different names, e.g. "SFNS-Bold" vs "AppleSystemUIFontBold". The postscript name is usually consistent though.
    func customIsEqual(to other: CocoaFont) -> Bool {
        return self.fontDescriptor.postscriptName == other.fontDescriptor.postscriptName
            && self.pointSize == other.pointSize
    }
}

extension NSAttributedString {
    func fontAt(location: Int) -> CocoaFont? {
        let attrs = self.attributes(at: location, effectiveRange: nil)
        return attrs[.font] as? CocoaFont
    }
}

public extension CocoaFont {
    var hasBold: Bool {
#if os(macOS)
        return self.fontDescriptor.symbolicTraits.contains(.bold)
#elseif os(iOS) || os(watchOS)
        return self.fontDescriptor.symbolicTraits.contains(.traitBold)
#endif
    }
    
    var hasItalic: Bool {
#if os(macOS)
        return self.fontDescriptor.symbolicTraits.contains(.italic)
#elseif os(iOS) || os(watchOS)
        return self.fontDescriptor.symbolicTraits.contains(.traitItalic)
#endif
    }
}
