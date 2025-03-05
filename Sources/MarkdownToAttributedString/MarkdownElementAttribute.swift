//
//  MarkdownElementAttribute.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 2/8/25.
//

import Foundation
import Markdown

/// **Experimental**
///
/// By default, converting markdown to NSAttributedString is non-invertible – it can't be converted back to markdown without some potential lossiness. For example, a heading span converted to attributed string will have a bold font, but based on that alone it's impossible to know whether the associated markdown was `heading` or `strong`.
///
/// Custom markdown element attributes allow fully invertible conversions because they specifically mark the source markdown in the NSAttributedString.
///
/// When present, the key is `NSAttributedString.Key.MTASMarkdownElements` and the value is a `MarkdownElementAttributes` object.
public struct MarkdownElementAttribute: Equatable, Hashable, CustomStringConvertible {
    /// The different variants of markdown attributes
    public enum AttributeVariant: Equatable, Hashable {
        /// Basic markdown element with no additional properties
        case basic
        
        /// Heading with a level
        case heading(level: Int)
        
        /// Link with a URL
        case link(url: URL)
        
        /// List item with its properties
        case listItem(
            depth: Int,
            indexInParent: Int,
            orderedIndex: Int?,
            prefix: String,
            typedDelimiter: String,
            renderedDelimiter: String
        )
    }

    /// The type of element this attribute represents
    public var elementType: MarkupType
    
    /// The specific variant of this attribute
    public var variant: AttributeVariant
        
    // MARK: - Initializers
    
    /// Creates a basic markdown element attribute
    public init(elementType: MarkupType) {
        self.elementType = elementType
        self.variant = .basic
    }
    
    /// Creates a heading markdown element attribute
    public static func heading(level: Int) -> MarkdownElementAttribute {
        var attribute = MarkdownElementAttribute(elementType: .heading)
        attribute.variant = .heading(level: level)
        return attribute
    }
    
    /// Creates a link markdown element attribute
    public static func link(url: URL) -> MarkdownElementAttribute {
        var attribute = MarkdownElementAttribute(elementType: .link)
        attribute.variant = .link(url: url)
        return attribute
    }
    
    /// Creates a list item markdown element attribute
    public static func listItem(
        depth: Int,
        indexInParent: Int,
        orderedIndex: Int? = nil,
        prefix: String,
        typedDelimiter: String,
        renderedDelimiter: String
    ) -> MarkdownElementAttribute {
        var attribute = MarkdownElementAttribute(elementType: .listItem)
        attribute.variant = .listItem(
            depth: depth,
            indexInParent: indexInParent,
            orderedIndex: orderedIndex,
            prefix: prefix,
            typedDelimiter: typedDelimiter,
            renderedDelimiter: renderedDelimiter
        )
        return attribute
    }
    
    // MARK: - List Item Convenience Methods
    
    /// Increments the index of a list item attribute
    public mutating func incrementIndex() {
        guard case let .listItem(depth, indexInParent, orderedIndex, prefix, typedDelimiter, renderedDelimiter) = variant else {
            return
        }
        
        let newIndexInParent = indexInParent + 1
        
        if let orderedIndex = orderedIndex {
            let newOrderedIndex = orderedIndex + 1
            let newPrefix = "\t\(newOrderedIndex). "
            let newTypedDelimiter = "\(newOrderedIndex)"
            let newRenderedDelimiter = "\(newOrderedIndex)"
            
            variant = .listItem(
                depth: depth,
                indexInParent: newIndexInParent,
                orderedIndex: newOrderedIndex,
                prefix: newPrefix,
                typedDelimiter: newTypedDelimiter,
                renderedDelimiter: newRenderedDelimiter
            )
        } else {
            variant = .listItem(
                depth: depth,
                indexInParent: newIndexInParent,
                orderedIndex: nil,
                prefix: prefix,
                typedDelimiter: typedDelimiter,
                renderedDelimiter: renderedDelimiter
            )
        }
    }

    /// Increments the list depth of a list item attribute
    public mutating func incrementListDepth(unorderedListBullets: [String]? = nil) {
        guard case let .listItem(depth, _, orderedIndex, prefix, typedDelimiter, renderedDelimiter) = variant else {
            return
        }
        
        let newDepth = depth + 1
        let newIndexInParent = 0
        
        var newRenderedDelimiter = renderedDelimiter
        if let bullets = unorderedListBullets {
            newRenderedDelimiter = bullets[newDepth % bullets.count]
        }
        
        variant = .listItem(
            depth: newDepth,
            indexInParent: newIndexInParent,
            orderedIndex: orderedIndex,
            prefix: prefix,
            typedDelimiter: typedDelimiter,
            renderedDelimiter: newRenderedDelimiter
        )
    }
    
    /// Decrements the list depth of a list item attribute
    public mutating func decrementListDepth(unorderedListBullets: [String]? = nil) {
        guard case let .listItem(depth, indexInParent, orderedIndex, prefix, typedDelimiter, renderedDelimiter) = variant else {
            return
        }
        
        let newDepth = max(0, depth - 1)
        
        var newRenderedDelimiter = renderedDelimiter
        if let bullets = unorderedListBullets {
            newRenderedDelimiter = bullets[newDepth % bullets.count]
        }
        
        variant = .listItem(
            depth: newDepth,
            indexInParent: indexInParent,
            orderedIndex: orderedIndex,
            prefix: prefix,
            typedDelimiter: typedDelimiter,
            renderedDelimiter: newRenderedDelimiter
        )
    }
    
    /// Checks if this list item is the first in its list
    public var isFirst: Bool {
        guard case let .listItem(depth, indexInParent, _, _, _, _) = variant else {
            return false
        }
        return indexInParent == 0 && depth == 0
    }
    
    // MARK: - List Item Accessors
    
    /// Gets the list depth of a list item attribute
    public var listDepth: Int? {
        guard case let .listItem(depth, _, _, _, _, _) = variant else {
            return nil
        }
        return depth
    }
    
    /// Gets the index in parent of a list item attribute
    public var indexInParent: Int? {
        guard case let .listItem(_, index, _, _, _, _) = variant else {
            return nil
        }
        return index
    }
    
    /// Gets the ordered index of a list item attribute
    public var orderedIndex: Int? {
        guard case let .listItem(_, _, orderedIndex, _, _, _) = variant else {
            return nil
        }
        return orderedIndex
    }
    
    /// Gets the prefix of a list item attribute
    public var prefix: String? {
        guard case let .listItem(_, _, _, prefix, _, _) = variant else {
            return nil
        }
        return prefix
    }
    
    /// Gets the typed delimiter of a list item attribute
    public var typedDelimiter: String? {
        guard case let .listItem(_, _, _, _, typedDelimiter, _) = variant else {
            return nil
        }
        return typedDelimiter
    }
    
    /// Gets the rendered delimiter of a list item attribute
    public var renderedDelimiter: String? {
        guard case let .listItem(_, _, _, _, _, renderedDelimiter) = variant else {
            return nil
        }
        return renderedDelimiter
    }
    
    /// Checks if this list item is ordered
    public var isOrdered: Bool {
        return orderedIndex != nil
    }
    
    // MARK: - Heading Accessors
    
    /// Gets the level of a heading attribute
    public var headingLevel: Int? {
        guard case let .heading(level) = variant else {
            return nil
        }
        return level
    }
    
    // MARK: - Link Accessors
    
    /// Gets the URL of a link attribute
    public var linkURL: URL? {
        guard case let .link(url) = variant else {
            return nil
        }
        return url
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(elementType)
        
        switch variant {
        case .basic:
            hasher.combine(0) // Variant type discriminator
            
        case .heading(let level):
            hasher.combine(1) // Variant type discriminator
            hasher.combine(level)
            
        case .link(let url):
            hasher.combine(2) // Variant type discriminator
            hasher.combine(url)
            
        case .listItem(let depth, let indexInParent, let orderedIndex, let prefix, let typedDelimiter, let renderedDelimiter):
            hasher.combine(3) // Variant type discriminator
            hasher.combine(depth)
            hasher.combine(indexInParent)
            hasher.combine(orderedIndex)
            hasher.combine(prefix)
            hasher.combine(typedDelimiter)
            hasher.combine(renderedDelimiter)
        }
    }
    
    // MARK: - Description
    
    public var betterDescriptionMarker: String {
        switch variant {
        case .basic:
            switch elementType {
            case .strong: return "<Strong>"
            case .emphasis: return "<Emphasis>"
            case .strikethrough: return "<Strikethrough>"
            case .inlineCode: return "<InlineCode>"
            case .codeBlock: return "<CodeBlock>"
            case .unorderedList: return "<UnorderedList>"
            case .orderedList: return "<OrderedList>"
            case .unknown: return "<Unknown>"
            case .heading, .link, .listItem:
                // Should never happen with proper initialization
                assertionFailure("Basic variant used with specialized element type")
                return "<\(elementType)>"
            }
            
        case .heading(let level):
            return "<Heading level=\(level)>"
            
        case .link(let url):
            return "<Link url=\(url.absoluteURL)>"
            
        case .listItem(let depth, let index, let orderedIndex, let prefix, _, _):
            if let orderedIndex = orderedIndex {
                return "<ListItem depth=\(depth) index=\(index) orderedIndex=\(orderedIndex) prefix=\"\(prefix.replacingUnprintableCharacters)\">"
            } else {
                return "<ListItem depth=\(depth) index=\(index) prefix=\"\(prefix.replacingUnprintableCharacters)\">"
            }
        }
    }
    
    public var description: String {
        let id = Unmanaged.passUnretained(self as AnyObject).toOpaque()
        
        switch variant {
        case .basic:
            return "MarkdownElementAttribute<\(elementType): \(id)>"
            
        case .heading(let level):
            return "HeadingMarkdownElementAttribute<\(id)> (level: \(level))"
            
        case .link(let url):
            return "LinkMarkdownElementAttribute<\(id)> (url: \(url))"
            
        case .listItem(let depth, let index, let orderedIndex, let prefix, _, _):
            var desc = "ListItemMarkdownElementAttribute<\(id)> (listDepth: \(depth), indexInParent: \(index)"
            if let orderedIndex = orderedIndex {
                desc += ", orderedIndex: \(orderedIndex)"
            }
            desc += ", prefix: \(prefix))"
            return desc
        }
    }
}

/// See `FormattingOptions.addCustomMarkdownElementAttributes`.
public extension NSAttributedString.Key {
    static let markdownElements: NSAttributedString.Key = .init("MTASMarkdownElements")
    static let forcedLineBreak: NSAttributedString.Key = .init("MTASForcedLineBreak")
    
    // Not used here but potentially useful to clients performing live editing as a semantic marker.
    static let paragraphBreak: NSAttributedString.Key = .init("MTASParagraphBreak")
}

/// A container for custom markdown element attributes, for use in string attributes where the key is `NSAttributedString.Key.MTASMarkdownElements`.
public struct MarkdownElementAttributes: Equatable, Hashable, CustomStringConvertible {
    private var storage: [MarkupType: MarkdownElementAttribute]

    public init(_ attributes: [MarkupType: MarkdownElementAttribute] = [:]) {
        self.storage = attributes
    }

    static public func == (lhs: MarkdownElementAttributes, rhs: MarkdownElementAttributes) -> Bool {
        return lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }

    public var description: String {
        return "<MarkdownElementAttributes> \(storage.description)"
    }
    
    public var allAttributes: [(MarkupType, MarkdownElementAttribute)] {
        return Array(storage)
    }
            
    public var hasAnyBlock: Bool {
        storage.keys.contains { $0.isBlock }
    }
}

public extension MarkdownElementAttributes {
    func copy(with zone: NSZone? = nil) -> Any {
        return MarkdownElementAttributes(self.storage)
    }

    func get(_ key: MarkupType) -> MarkdownElementAttribute? {
        return storage[key]
    }

    mutating func add(_ mdElAttr: MarkdownElementAttribute) {
        storage[mdElAttr.elementType] = mdElAttr
    }

    mutating func remove(_ type: MarkupType) {
        storage[type] = nil
    }
    
    func merging(_ other: MarkdownElementAttributes) -> MarkdownElementAttributes {
        var merged = self.storage
        for (key, value) in other.storage {
            merged[key] = value
        }
        return MarkdownElementAttributes(merged)
    }
    
    func includesElementType(_ elementType: MarkupType) -> Bool {
        return storage[elementType] != nil
    }

}

public extension StringAttrs {
    var markdownElementAttributes: MarkdownElementAttributes? {
        return self[.markdownElements] as? MarkdownElementAttributes
    }
    
    var hasMTASMarkdownElements: Bool {
        return markdownElementAttributes != nil
    }
    
    // Returns true if the attrs includes a container block element.
    var hasContainerBlock: Bool {
        return hasMarkdownElementType(.orderedList)
            || hasMarkdownElementType(.unorderedList)
            || hasMarkdownElementType(.listItem)
            || hasMarkdownElementType(.codeBlock)
    }
            
    func markdownElementAttrForElementType(_ elementType: MarkupType) -> MarkdownElementAttribute? {
        guard let val = self[.markdownElements] as? MarkdownElementAttributes else {
            return nil
        }
        return val.get(elementType)
    }
    
    func containerBlockElementAttr() -> MarkdownElementAttribute? {
        if let v = markdownElementAttrForElementType(.unorderedList) {
            return v
        } else if let v = markdownElementAttrForElementType(.orderedList) {
            return v
        } else if let v = markdownElementAttrForElementType(.codeBlock) {
            return v
        } else {
            return nil
        }
    }
    
    func hasMarkdownElementType(_ elementType: MarkupType) -> Bool {
        return markdownElementAttrForElementType(elementType) != nil
    }
    
    mutating func addMarkdownElementAttr(_ attr: MarkdownElementAttribute) {
        var d = (self[.markdownElements] as? MarkdownElementAttributes) ?? MarkdownElementAttributes()
        d.add(attr)
        self[.markdownElements] = d
    }

}
