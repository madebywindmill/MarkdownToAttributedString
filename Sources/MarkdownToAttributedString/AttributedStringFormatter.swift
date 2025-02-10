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
    
    public var options: FormattingOptions?

    private var attributes: MarkdownAttributes?
    
    /// Initialize the formatter with a Markdown string and optional styling attributes.
    ///
    /// - Parameters:
    ///   - markdown: The Markdown content to be converted.
    ///   - attributes: An optional `MarkdownAttributes` object defining styles for the formatted output.
    public init(
        attributes: MarkdownAttributes? = nil,
        options: FormattingOptions? = nil)
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
        options: FormattingOptions? = nil) -> NSAttributedString
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
        
        return asv.convert()
    }
}
