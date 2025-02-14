//
//  AttributedStringFormatter.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 1/18/25.
//

import Markdown
import Foundation

/// A formatter for converting Markdown strings into `NSAttributedString` objects with customizable styling.
///
/// Provides an interface for rendering Markdown content as rich text, allowing you to apply custom styles Markdown elements like headings, links, and lists. Uses `MarkdownAttributes` for style definitions and `AttributedStringVisitor` for traversing and rendering the Markdown structure.
///
public class AttributedStringFormatter {
    
    public var options: FormattingOptions

    private var attributes: MarkdownAttributes?
    
    /// Initialize the formatter with a Markdown string and optional styling attributes.
    ///
    /// - Parameters:
    ///   - markdown: The Markdown content to be converted.
    ///   - attributes: An optional `MarkdownAttributes` object defining styles for the formatted output.
    public init(
        attributes: MarkdownAttributes? = nil,
        options: FormattingOptions = FormattingOptions.default)
    {
        self.attributes = attributes
        self.options = options
    }

    /// Immediately converts a Markdown string into an `NSAttributedString` with the given styling attributes.
    ///
    /// - Parameters:
    ///   - markdown: The Markdown content to be converted.
    ///   - attributes: An optional `MarkdownAttributes` object defining styles for the Markdown elements.
    /// - Returns: An `NSAttributedString` representing the formatted Markdown content.
    public static func format(
        markdown: String,
        attributes: MarkdownAttributes? = nil,
        options: FormattingOptions = FormattingOptions.default) -> NSAttributedString
    {
        let asf = AttributedStringFormatter(
            attributes: attributes,
            options: options)
        return asf.format(markdown: markdown)
    }
    
    /// Converts the given Markdown content into an `NSAttributedString`.
    ///
    /// - Parameters:
    ///   - markdown: The Markdown content to be converted.
    ///
    /// - Returns: An `NSAttributedString` representing the formatted Markdown content.
    public func format(markdown: String) -> NSAttributedString {
        var asv = AttributedStringVisitor(
            markdown: markdown,
            attributes: attributes,
            options: options)
        
        var result = asv.convert()
        
        if options.trimWhitespace {
            // Taking care not to butcher a trailing emoji 😅
            let nsString = result.string as NSString
            let nonWhitespace = CharacterSet.whitespacesAndNewlines.inverted
            
            let startRange = nsString.rangeOfCharacter(from: nonWhitespace)
            let endRange = nsString.rangeOfCharacter(from: nonWhitespace, options: .backwards)
            
            // If we actually found some non‐whitespace, trim
            if startRange.location != NSNotFound, endRange.location != NSNotFound {
                // Expand the start and end to cover full grapheme clusters
                let startCluster = nsString.rangeOfComposedCharacterSequence(at: startRange.location)
                let endCluster   = nsString.rangeOfComposedCharacterSequence(at: endRange.location)
                
                let newStart = startCluster.location
                // endCluster.location + endCluster.length gives the first character AFTER the cluster, so subtract 1 to get inclusive end
                let newEnd = endCluster.location + endCluster.length - 1
                
                let trimmedRange = NSRange(location: newStart, length: newEnd - newStart + 1)
                result = result.attributedSubstring(from: trimmedRange)
            } else {
                // The entire string is whitespace
                return NSAttributedString(string: "", attributes: attributes?.baseAttributes)
            }
        }

        return result
    }
}
