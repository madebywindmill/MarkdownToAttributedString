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
    
    static let defaultMDAttrs = MarkdownAttributes.default
    static let options = FormattingOptions(addCustomMarkdownElementAttributes: true, debugLogging: true)
    
    var defaultFormatter: AttributedStringFormatter!
    
    override func setUp() {
        defaultFormatter = AttributedStringFormatter(attributes: Self.defaultMDAttrs, options: Self.options)
    }
    
    func testBoldText() {
        let md = "This is **bold** text."
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This is bold text.")

        let styledRange = (attrStr.string as NSString).range(of: "bold")
        let attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        let expectedFont = Self.defaultMDAttrs.fontAttributeForType(.strong)
        
        XCTAssertTrue(font.customIsEqual(to: expectedFont))
    }
    
    func testItalicText() {
        let md = "This is *italic* text."
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This is italic text.")

        let styledRange = (attrStr.string as NSString).range(of: "italic")
        let attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        let expectedFont = Self.defaultMDAttrs.fontAttributeForType(.emphasis)

        XCTAssertTrue(font.customIsEqual(to: expectedFont))
    }
    
    func testBoldItalics() {
        let md = "This has **_both_**."
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "This has both.")
        
        let styledRange = (attrStr.string as NSString).range(of: "both")
        let attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        XCTAssertTrue(font.containsBoldTrait())
        XCTAssertTrue(font.containsItalicsTrait())
    }
    
    func testInlineCode() {
        let md = "Here is `inline code`."
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertTrue(attrStr.string.contains("inline code"))
        
        let styledRange = (attrStr.string as NSString).range(of: "inline code")
        let attributes = attrStr.attributes(at: styledRange.location, effectiveRange: nil)
        XCTAssertEqual(attributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.inlineCode))
    }
    
    func testNestedInlineCode() {
        let md = "Here is **`nested inline code`**."
        let attrStr = defaultFormatter.format(markdown: md)
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
        
        guard let expectedStrikeColor: CocoaColor = Self.defaultMDAttrs.valueForAttribute(.strikethroughColor, type: .strikethrough) else {
            XCTFail(); return
        }
        guard let expectedFontColor: CocoaColor = Self.defaultMDAttrs.valueForAttribute(.foregroundColor, type: .strikethrough) else {
            XCTFail(); return
        }

        XCTAssertEqual(attributes[.strikethroughColor] as? CocoaColor, expectedStrikeColor)
        XCTAssertEqual(attributes[.foregroundColor] as? CocoaColor, expectedFontColor)
    }
    
    func testOneOff() {

    }

    func testUnorderedLists() {
        // with trailing \n
        var md = "- Item 1\n- Item 2\n"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "• Item 1\n• Item 2\n")
        XCTAssert(attrStr.hasAttribute(key: .paragraphStyle, at: 0))
        XCTAssert(attrStr.hasAttribute(key: .paragraphStyle, at: 9))
        XCTAssert(!attrStr.hasAttribute(key: .paragraphStyle, at: 8))
        XCTAssert(!attrStr.hasAttribute(key: .paragraphStyle, at: 17))

        // nested styles
        md = "- **Item 1**\n- *Item 2*\n"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "• Item 1\n• Item 2\n")
        XCTAssert(!attrStr.fontAt(location: 0)!.hasBold)
        XCTAssert(!attrStr.fontAt(location: 1)!.hasBold)
        XCTAssert(attrStr.fontAt(location: 2)!.hasBold)
        XCTAssert(attrStr.fontAt(location: 7)!.hasBold)
        XCTAssert(!attrStr.fontAt(location: 9)!.hasItalic)
        XCTAssert(!attrStr.fontAt(location: 10)!.hasItalic)
        XCTAssert(attrStr.fontAt(location: 11)!.hasItalic)
        XCTAssert(attrStr.fontAt(location: 16)!.hasItalic)

        // without trailing \n -- I'm not sure it's possible to make this pass, and it's a weird edge case.
//        md = "- Item 1\n- Item 2"
//        attrStr = defaultFormatter.format(markdown: md)
//        XCTAssertEqual(attrStr.string, "• Item 1\n• Item 2")
//        XCTAssert(attrStr.hasAttribute(key: .paragraphStyle, at: 0))
//        XCTAssert(attrStr.hasAttribute(key: .paragraphStyle, at: 9))
//        XCTAssert(!attrStr.hasAttribute(key: .paragraphStyle, at: 8))

    }
    
//    func testOrderedLists() {
//        var md = "1. Item 1\n2. Item 2"
//        var attrStr = defaultFormatter.format(markdown: md)
//        XCTAssertEqual(attrStr.string, "1. Item 1\n2. Item 2\n")
//
//        // Ordered list with different starting number
//        md = "3. Item 3\n4. Item 4"
//        attrStr = defaultFormatter.format(markdown: md)
//        XCTAssertEqual(attrStr.string, "1. Item 3\n2. Item 4\n")
//    }
        
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
        XCTAssertEqual(boldAttributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.strong))
        
        let italicRange = (attrStr.string as NSString).range(of: "italic")
        let italicAttributes = attrStr.attributes(at: italicRange.location, effectiveRange: nil)
        XCTAssertEqual(italicAttributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.emphasis))
        
        let codeRange = (attrStr.string as NSString).range(of: "inline code")
        let codeAttributes = attrStr.attributes(at: codeRange.location, effectiveRange: nil)
        XCTAssertEqual(codeAttributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.inlineCode))
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

        let headingFont = Self.defaultMDAttrs.fontAttributeForType(.heading)
        
        for i in 1...6 {
            let headingText = "Heading \(i)"
            let headingRange = (attrStr.string as NSString).range(of: headingText)
            let attributes = attrStr.attributes(at: headingRange.location, effectiveRange: nil)

            let actualFont = attributes[.font] as! CocoaFont
            XCTAssertEqual(actualFont.fontDescriptor.postscriptName, headingFont.fontDescriptor.postscriptName)
            XCTAssertEqual(actualFont.pointSize, Self.defaultMDAttrs.headingPointSizes[i-1], "Font point size for \(headingText) doesn't match.")
        }
    }
    
    // https://github.com/madebywindmill/MarkdownToAttributedString/issues/1
    func testHeadingLineBreaks() {
        var md = "# Heading 1"
        var attrStr = defaultFormatter.format(markdown: md)
        XCTAssertFalse(attrStr.string.starts(with: "\n"), attrStr.string)
        
        md = "# H1<br>\n​"
        attrStr = defaultFormatter.format(markdown: md)
        // SwiftMarkdown adds a non-breakable space here?
        XCTAssertEqual(attrStr.string, "H1\n\n\u{200B}")

        md = "# Heading 1\nSome text"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertTrue(attrStr.string == "Heading 1\nSome text")
        
        md = "# Heading 1"
        attrStr = defaultFormatter.format(markdown: md)
        XCTAssertFalse(attrStr.string.hasSuffix("\n\n"), attrStr.string)
    }

    // Line break testing -- general idea is to ignore newlines at the beginning and ends of markdown. This is due to CommonMark 4.9 Blank Lines: "Blank lines between block-level elements are ignored, except for the role they play in determining whether a list is tight or loose."
    func testLineBreaks1() {
        let md = "Line1\nLine2"
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, md)
    }

    func testLineBreaks2() {
        let md = "Line1\nLine2\n"
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\nLine2")
    }

    func testLineBreaks3() {
        let md = "\nLine1\nLine2\n"
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\nLine2")
    }

    func testLineBreaks4() {
        let md = "\n\nLine1\nLine2\n\n"
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\nLine2")
    }

    func testLineBreaks5() {
        let md = "Line1\n\n\nLine2"
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\nLine2")
    }

    func testLineBreaks6() {
        let md = "Line1<br><br><br>Line2"
        let attrStr = defaultFormatter.format(markdown: md)
        XCTAssertEqual(attrStr.string, "Line1\n\n\nLine2")
    }
    
    // Fails.
    // I haven't tested extensively but I don't think SwiftMarkdown is handling hard line breaks as described by CommonMark (using 2+ spaces or a \ before the newline) correctly, or at all. On the other hand they don't work in CommonMark's own playground so maybe I'm misunderstanding.
//    func testLineBreaks6() {
//        let md = "Line1  \n  \n  \nLine2"
//        let attrStr = defaultFormatter.format(markdown: md)
//        XCTAssertEqual(attrStr.string, "Line1\n\n\nLine2")
//    }

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
