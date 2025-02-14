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
/// By default, converting markdown to NSAttributedString is non-invertible – it can't be converted back to markdown without some potential lossiness. For example, a heading span converted to attributed string will likely be bold and of a certain font size, but based on those attributes alone it's impossible to know whether the associated markdown was `heading` or `strong`.
///
/// Custom markdown element attributes allow fully invertible conversions because they specifically mark the source markdown in the NSAttributedString.
///
/// When present, the key is `NSAttributedString.Key.MTASMarkdownElements` and the value is a `MarkdownElementAttributes` object.
open class MarkdownElementAttribute: NSObject, NSCopying {
    public var elementType: MarkupType
    
    public static func == (lhs: MarkdownElementAttribute, rhs: MarkdownElementAttribute) -> Bool {
        // NB: `Markup` is not Equatable.
        return lhs.elementType == rhs.elementType
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MarkdownElementAttribute else { return false }
        return self == other
    }
    
    public init(elementType: MarkupType) {
        self.elementType = elementType
    }
    
    public override var description: String {
        let addr = "\(Unmanaged.passUnretained(self).toOpaque())"
        return "MarkdownElementAttribute<\(elementType): \(addr)>"
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return MarkdownElementAttribute(elementType: elementType)
    }

    public var betterDescriptionMarker: String {
        switch elementType {
            case .strong:
                return "<Strong>"
            case .emphasis:
                return "<Emphasis>"
            case .strikethrough:
                return "<Strikethrough>"
            case .inlineCode:
                return "<InlineCode>"
            case .codeBlock:
                return "<CodeBlock>"
            case .heading:
                assertionFailure() // should be a HeadingMarkdownElementAttribute
                return "<Heading>"
            case .unorderedList:
                return "<UnorderedList>"
            case .orderedList:
                return "<OrderedList>"
            case .listItem:
                return "<ListItem>"
            case .link:
                assertionFailure() // should be a LinkMarkdownElementAttribute
                return "<Link>"
            case .unknown:
                return "<Unknown>"

        }
    }
}

public class HeadingMarkdownElementAttribute: MarkdownElementAttribute {
    public let level: Int
    
    public static func == (lhs: HeadingMarkdownElementAttribute, rhs: HeadingMarkdownElementAttribute) -> Bool
    {
        return lhs.elementType == rhs.elementType
            && lhs.level == rhs.level
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HeadingMarkdownElementAttribute else { return false }
        return self == other
    }

    public init(level: Int) {
        self.level = level
        super.init(elementType: .heading)
    }
    
    public override var betterDescriptionMarker: String {
        return "<Heading level=\(level)>"
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        return HeadingMarkdownElementAttribute(level: level)
    }

}

public class LinkMarkdownElementAttribute: MarkdownElementAttribute {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
        super.init(elementType: .link)
    }
    
    public static func == (lhs: LinkMarkdownElementAttribute, rhs: LinkMarkdownElementAttribute) -> Bool
    {
        return lhs.elementType == rhs.elementType
            && lhs.url == rhs.url
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LinkMarkdownElementAttribute else { return false }
        return self == other
    }

    public override var betterDescriptionMarker: String {
        return "<Link url=\(url.absoluteURL)>"
    }
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        return LinkMarkdownElementAttribute(url: url)
    }
}

public class ListItemMarkdownElementAttribute: MarkdownElementAttribute {
    public var listDepth: Int // 0 indexed
    public var indexInParent: Int
    public var prefix: String
    public var typedDelimiter: String
    public var renderedDelimiter: String
    
    public override var description: String {
        let addr = "\(Unmanaged.passUnretained(self).toOpaque())"
        return "ListItemMarkdownElementAttribute<\(addr)> (listDepth: \(listDepth), indexInParent: \(indexInParent), prefix: \(prefix))"
    }

    public override var betterDescriptionMarker: String {
        return "<ListItem depth=\(listDepth) index=\(indexInParent) prefix=\"\(prefix.replacingUnprintableCharacters)\">"
    }

    public static func == (lhs: ListItemMarkdownElementAttribute, rhs: ListItemMarkdownElementAttribute) -> Bool
    {
        return lhs.elementType == rhs.elementType
            && lhs.listDepth == rhs.listDepth
            && lhs.indexInParent == rhs.indexInParent
            && lhs.prefix == rhs.prefix
            && lhs.typedDelimiter == rhs.typedDelimiter
            && lhs.renderedDelimiter == rhs.renderedDelimiter
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ListItemMarkdownElementAttribute else { return false }
        return self == other
    }

    public init(listDepth: Int, indexInParent: Int, prefix: String, typedDelimiter: String, renderedDelimiter: String) {
        self.listDepth = listDepth
        self.indexInParent = indexInParent
        self.prefix = prefix
        self.typedDelimiter = typedDelimiter
        self.renderedDelimiter = renderedDelimiter
        super.init(elementType: .listItem)
    }
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        return ListItemMarkdownElementAttribute(listDepth: listDepth, indexInParent: indexInParent, prefix: prefix, typedDelimiter: typedDelimiter, renderedDelimiter: renderedDelimiter)
    }

    
}


/// See `FormattingOptions.addCustomMarkdownElementAttributes`.
public extension NSAttributedString.Key {
    static let markdownElements: NSAttributedString.Key = .init("MTASMarkdownElements")
}

public class MarkdownElementAttributes: NSObject, NSCopying {
    private var storage: [MarkupType: MarkdownElementAttribute]

    public init(_ attributes: [MarkupType: MarkdownElementAttribute] = [:]) {
        self.storage = attributes
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MarkdownElementAttributes else { return false }
        return self.storage == other.storage
    }

    public override var hash: Int {
        return storage.hashValue
    }

    public override var description: String {
        let addr = "\(Unmanaged.passUnretained(self).toOpaque())"
        return "<MarkdownElementAttributes: \(addr)> \(storage.description)"
    }
    
    public var allAttributes: [(MarkupType, MarkdownElementAttribute)] {
        return Array(storage)
    }
}

public extension MarkdownElementAttributes {
    func copy(with zone: NSZone? = nil) -> Any {
        return MarkdownElementAttributes(self.storage)
    }

    func get(_ key: MarkupType) -> MarkdownElementAttribute? {
        return storage[key]
    }

    func set(_ key: MarkupType, value: MarkdownElementAttribute) {
        storage[key] = value
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
            
    func markdownElementAttrForElementType(_ elementType: MarkupType) -> MarkdownElementAttribute? {
        guard let val = self[.markdownElements] as? MarkdownElementAttributes else {
            return nil
        }
        return val.get(elementType)
    }
    
    func hasMarkdownElementType(_ elementType: MarkupType) -> Bool {
        return markdownElementAttrForElementType(elementType) != nil
    }
    
    mutating func addMarkdownElementAttr(_ attr: MarkdownElementAttribute) {
        var d = (self[.markdownElements] as? MarkdownElementAttributes) ?? MarkdownElementAttributes()
        d.set(attr.elementType, value: attr)
        self[.markdownElements] = d
    }

}
