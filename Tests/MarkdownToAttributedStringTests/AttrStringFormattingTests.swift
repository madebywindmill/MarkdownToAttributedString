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
    static let options = FormattingOptions(addCustomMarkdownElementAttributes: true)
    
    var defaultFormatter: AttributedStringFormatter!
    
    override func setUp() {
        defaultFormatter = AttributedStringFormatter(attributes: Self.defaultMDAttrs, options: Self.options)
    }
    
    func testBoldText() {
        let markdown = "This is **bold** text."
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, "This is bold text.")

        let styledRange = (attributedString.string as NSString).range(of: "bold")
        let attributes = attributedString.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        let expectedFont = Self.defaultMDAttrs.fontAttributeForType(.strong)
        
        XCTAssertTrue(font.customIsEqual(to: expectedFont))
    }
    
    func testItalicText() {
        let markdown = "This is *italic* text."
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, "This is italic text.")

        let styledRange = (attributedString.string as NSString).range(of: "italic")
        let attributes = attributedString.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        let expectedFont = Self.defaultMDAttrs.fontAttributeForType(.emphasis)

        XCTAssertTrue(font.customIsEqual(to: expectedFont))
    }
    
    func testBoldItalics() {
        let markdown = "This has **_both_**."
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, "This has both.")
        
        let styledRange = (attributedString.string as NSString).range(of: "both")
        let attributes = attributedString.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        XCTAssertTrue(font.containsBoldTrait())
        XCTAssertTrue(font.containsItalicsTrait())
    }
    
    func testInlineCode() {
        let markdown = "Here is `inline code`."
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertTrue(attributedString.string.contains("inline code"))
        
        let styledRange = (attributedString.string as NSString).range(of: "inline code")
        let attributes = attributedString.attributes(at: styledRange.location, effectiveRange: nil)
        XCTAssertEqual(attributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.inlineCode))
    }
    
    func testNestedInlineCode() {
        let markdown = "Here is **`nested inline code`**."
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertTrue(attributedString.string.contains("nested inline code"))
        
        let styledRange = (attributedString.string as NSString).range(of: "nested inline code")
        
        let attributes = attributedString.attributes(at: styledRange.location, effectiveRange: nil)
        let font = attributes[.font] as! CocoaFont
        XCTAssertTrue(font.containsBoldTrait())
        XCTAssertTrue(font.isMonospaced())
    }

    
    func testStrikethrough() {
        let markdown = "Here's some ~~strikethrough~~ text."
        let attributedString = defaultFormatter.format(markdown: markdown)
        let styleRange = (attributedString.string as NSString).range(of: "strikethrough")
        let attributes = attributedString.attributes(at: styleRange.location, effectiveRange: nil)
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
    
    // Currently fails: Missing newline at end.
    func testUnorderedList() {
        let markdown = "- Item 1\n- Item 2"
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertTrue(attributedString.string.contains("Item 1"))
        XCTAssertTrue(attributedString.string.contains("Item 2"))
        
        let newlineCount = attributedString.string.filter { $0 == "\n" }.count
        XCTAssertEqual(newlineCount, 5) // 2 at beginning, 1 in the middle, 2 at end
    }
        
    func testCompositeMarkdown() {
        let markdown = "This is **bold** and *italic*, and here is `inline code`.\n- An unordered list item."
        let attributedString = defaultFormatter.format(markdown: markdown)
        
        XCTAssertTrue(attributedString.string.contains("bold"))
        XCTAssertTrue(attributedString.string.contains("italic"))
        XCTAssertTrue(attributedString.string.contains("inline code"))
        XCTAssertTrue(attributedString.string.contains("An unordered list item."))
        
        // Validate attributes for each type
        let boldRange = (attributedString.string as NSString).range(of: "bold")
        let boldAttributes = attributedString.attributes(at: boldRange.location, effectiveRange: nil)
        XCTAssertEqual(boldAttributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.strong))
        
        let italicRange = (attributedString.string as NSString).range(of: "italic")
        let italicAttributes = attributedString.attributes(at: italicRange.location, effectiveRange: nil)
        XCTAssertEqual(italicAttributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.emphasis))
        
        let codeRange = (attributedString.string as NSString).range(of: "inline code")
        let codeAttributes = attributedString.attributes(at: codeRange.location, effectiveRange: nil)
        XCTAssertEqual(codeAttributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.inlineCode))
    }
    
    func testHeadings() {
        let markdown = """
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6
        """
        let attributedString = defaultFormatter.format(markdown: markdown)

        for i in 1...6 {
            XCTAssertTrue(attributedString.string.contains("Heading \(i)"), "Heading \(i) not found in output string.")
        }

        let headingFont = Self.defaultMDAttrs.fontAttributeForType(.heading)
        
        for i in 1...6 {
            let headingText = "Heading \(i)"
            let headingRange = (attributedString.string as NSString).range(of: headingText)
            let attributes = attributedString.attributes(at: headingRange.location, effectiveRange: nil)

            let actualFont = attributes[.font] as! CocoaFont
            XCTAssertEqual(actualFont.fontDescriptor.postscriptName, headingFont.fontDescriptor.postscriptName)
            XCTAssertEqual(actualFont.pointSize, Self.defaultMDAttrs.headingPointSizes[i-1], "Font point size for \(headingText) doesn't match.")
        }
    }

    // https://github.com/madebywindmill/MarkdownToAttributedString/issues/1
    func testHeadingLineBreaks1() {
        let markdown = "# Heading 1"
        let attributedString = defaultFormatter.format(markdown: markdown)
        
        XCTAssertFalse(attributedString.string.starts(with: "\n"), attributedString.string)
    }

    func testHeadingLineBreaks2() {
        let markdown = "# Heading 1\nSome text"
        let attributedString = defaultFormatter.format(markdown: markdown)
        
        XCTAssertTrue(attributedString.string == "Heading 1\n\nSome text")
    }
    
    // Fails: https://github.com/madebywindmill/MarkdownToAttributedString/issues/2
//    func testHeadingLineBreaks3() {
//        let markdown = "# Heading 1"
//        let attributedString = defaultFormatter.format(markdown: markdown)
//        
//        XCTAssertFalse(attributedString.string.hasSuffix("\n\n"), attributedString.string)
//    }


    // Line break testing -- general idea is to ignore newlines at the beginning and ends of markdown. This is due to CommonMark 4.9 Blank Lines: "Blank lines between block-level elements are ignored, except for the role they play in determining whether a list is tight or loose."
    func testLineBreaks1() {
        let markdown = "Line1\nLine2"
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, markdown)
    }

    func testLineBreaks2() {
        let markdown = "Line1\nLine2\n"
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, "Line1\nLine2")
    }

    func testLineBreaks3() {
        let markdown = "\nLine1\nLine2\n"
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, "Line1\nLine2")
    }

    func testLineBreaks4() {
        let markdown = "\n\nLine1\nLine2\n\n"
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, "Line1\nLine2")
    }

    func testLineBreaks5() {
        let markdown = "Line1\n\n\nLine2"
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, "Line1\nLine2")
    }

    func testLineBreaks6() {
        let markdown = "Line1<br><br><br>Line2"
        let attributedString = defaultFormatter.format(markdown: markdown)
        XCTAssertEqual(attributedString.string, "Line1\n\n\nLine2")
    }
    
    // Fails.
    // I haven't tested extensively but I don't think SwiftMarkdown is handling hard line breaks as described by CommonMark (using 2+ spaces or a \ before the newline) correctly, or at all. On the other hand they don't work in CommonMark's own playground so maybe I'm misunderstanding.
//    func testLineBreaks6() {
//        let markdown = "Line1  \n  \n  \nLine2"
//        let attributedString = defaultFormatter.format(markdown: markdown)
//        XCTAssertEqual(attributedString.string, "Line1\n\n\nLine2")
//    }

}

extension CocoaFont {
    
    // Sometimes we can't just compare fonts because they can end up with slightly different names, e.g. "SFNS-Bold" vs "AppleSystemUIFontBold". The postscript name is usually consistent though.
    func customIsEqual(to other: CocoaFont) -> Bool {
        return self.fontDescriptor.postscriptName == other.fontDescriptor.postscriptName
            && self.pointSize == other.pointSize
    }
}
