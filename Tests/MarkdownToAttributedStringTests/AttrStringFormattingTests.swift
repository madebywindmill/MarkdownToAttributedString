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
    
    func testBoldText() {
        let markdown = "This is **bold** text."
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertTrue(attributedString.string.contains("bold"))
        
        let boldRange = (attributedString.string as NSString).range(of: "bold")
        let attributes = attributedString.attributes(at: boldRange.location, effectiveRange: nil)
        XCTAssertEqual(attributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.strong))
        
        XCTAssertEqual(attributedString.string, "This is bold text.")
    }
    
    func testItalicText() {
        let markdown = "This is *italic* text."
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertTrue(attributedString.string.contains("italic"))
        
        let italicRange = (attributedString.string as NSString).range(of: "italic")
        let attributes = attributedString.attributes(at: italicRange.location, effectiveRange: nil)
        XCTAssertEqual(attributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.emphasis))
    }
    
    func testInlineCode() {
        let markdown = "Here is `inline code`."
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertTrue(attributedString.string.contains("inline code"))
        
        let codeRange = (attributedString.string as NSString).range(of: "inline code")
        let attributes = attributedString.attributes(at: codeRange.location, effectiveRange: nil)
        XCTAssertEqual(attributes[.font] as? CocoaFont, Self.defaultMDAttrs.fontAttributeForType(.inlineCode))
    }
    
    // Currently fails: Missing newline at end.
    func testUnorderedList() {
        let markdown = "- Item 1\n- Item 2"
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertTrue(attributedString.string.contains("Item 1"))
        XCTAssertTrue(attributedString.string.contains("Item 2"))
        
        let newlineCount = attributedString.string.filter { $0 == "\n" }.count
        XCTAssertEqual(newlineCount, 5) // 2 at beginning, 1 in the middle, 2 at end
    }
        
    func testCompositeMarkdown() {
        let markdown = "This is **bold** and *italic*, and here is `inline code`.\n- An unordered list item."
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        
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
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)

        for i in 1...6 {
            XCTAssertTrue(attributedString.string.contains("Heading \(i)"), "Heading \(i) not found in output string.")
        }

        let headingFont = Self.defaultMDAttrs.fontAttributeForType(.heading)
        
        for i in 1...6 {
            let headingText = "Heading \(i)"
            let headingRange = (attributedString.string as NSString).range(of: headingText)
            let attributes = attributedString.attributes(at: headingRange.location, effectiveRange: nil)

            let actualFont = attributes[.font] as? CocoaFont
            XCTAssertEqual(actualFont?.displayName, headingFont.displayName, "Font name for \(headingText) doesn't match.")
            XCTAssertEqual(actualFont?.pointSize, Self.defaultMDAttrs.headingPointSizes[i-1], "Font point size for \(headingText) doesn't match.")
        }
    }

    // Line break testing -- general idea is to ignore newlines at the beginning and ends of markdown. This is due to CommonMark 4.9 Blank Lines: "Blank lines between block-level elements are ignored, except for the role they play in determining whether a list is tight or loose."
    func testLineBreaks1() {
        let markdown = "Line1\nLine2"
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertEqual(attributedString.string, markdown)
    }

    func testLineBreaks2() {
        let markdown = "Line1\nLine2\n"
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertEqual(attributedString.string, "Line1\nLine2")
    }

    func testLineBreaks3() {
        let markdown = "\nLine1\nLine2\n"
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertEqual(attributedString.string, "Line1\nLine2")
    }

    func testLineBreaks4() {
        let markdown = "\n\nLine1\nLine2\n\n"
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertEqual(attributedString.string, "Line1\nLine2")
    }

    func testLineBreaks5() {
        let markdown = "Line1\n\n\nLine2"
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertEqual(attributedString.string, "Line1\nLine2")
    }

    func testLineBreaks6() {
        let markdown = "Line1<br><br><br>Line2"
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertEqual(attributedString.string, "Line1\n\n\nLine2")
    }

    // Fails.
    // I haven't tested extensively but I don't think SwiftMarkdown is handling hard line breaks as described by CommonMark (using 2+ spaces or a \ before the newline) correctly, or at all. On the other hand they don't work in CommonMark's own playground so maybe I'm misunderstanding.
//    func testLineBreaks6() {
//        let markdown = "Line1  \n  \n  \nLine2"
//        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
//        XCTAssertEqual(attributedString.string, "Line1\n\n\nLine2")
//    }

}
