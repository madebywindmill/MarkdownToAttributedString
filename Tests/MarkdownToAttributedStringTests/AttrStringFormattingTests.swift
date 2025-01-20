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
    
    func testUnorderedList() {
        let markdown = "- Item 1\n- Item 2"
        let attributedString = AttributedStringFormatter.format(markdown: markdown, attributes: Self.defaultMDAttrs)
        XCTAssertTrue(attributedString.string.contains("Item 1"))
        XCTAssertTrue(attributedString.string.contains("Item 2"))
        
        let newlineCount = attributedString.string.filter { $0 == "\n" }.count
        XCTAssertEqual(newlineCount, 5) // 2 at beginning, 2 at end, 1 in the middle
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

    
}
