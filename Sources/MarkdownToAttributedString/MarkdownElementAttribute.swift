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
/// By default, converting markdown to NSAttributedString is non-invertible – it can't be converted back to markdown without some potential lossiness. For example, a heading span converted to attributed string will likely be bold and of a certain font size, but based on those attributes alone it's impossible to know whether the associated markdown is `heading` or `strong`.
///
/// Custom markdown element attributes allow fully invertible conversions because they specifically mark the source markdown in the NSAttributedString.
///
/// When present, the key is `NSAttributedString.Key.MTASMarkdownElements` and the value is a MarkdownElementAttributes dictionary.
open class MarkdownElementAttribute: Equatable {
    public var elementType: MarkupType
    public var associatedMarkup: Markup?
    
    public static func == (lhs: MarkdownElementAttribute, rhs: MarkdownElementAttribute) -> Bool {
        // NB: `Markup` is not Equatable.
        return lhs.elementType == rhs.elementType
    }

    public init(elementType: MarkupType,
                associtatedMarkup: Markup? = nil) {
        self.elementType = elementType
        self.associatedMarkup = associtatedMarkup
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
    public var level: Int
    
    public init(level: Int) {
        self.level = level
        super.init(elementType: .heading)
    }
    
    public override var betterDescriptionMarker: String {
        return "<Heading level=\(level)>"
    }

}

public class LinkMarkdownElementAttribute: MarkdownElementAttribute {
    public var url: URL
    
    public init(url: URL) {
        self.url = url
        super.init(elementType: .link)
    }
    
    public override var betterDescriptionMarker: String {
        return "<Link url=\(url.absoluteURL)>"
    }
}


/// See `FormattingOptions.addCustomMarkdownElementAttributes`.
public extension NSAttributedString.Key {
    static let markdownElements: NSAttributedString.Key = .init("MTASMarkdownElements")
}

public typealias MarkdownElementAttributes = Dictionary<MarkupType, MarkdownElementAttribute>

public extension StringAttrs {
    var hasMTASMarkdownElements: Bool {
        return self[.markdownElements] != nil
    }
            
    func markdownElementAttrForElementType(_ elementType: MarkupType) -> MarkdownElementAttribute? {
        guard let val = self[.markdownElements] as? MarkdownElementAttributes else {
            return nil
        }
        return val[elementType]
    }
    
    func hasMarkdownElementType(_ elementType: MarkupType) -> Bool {
        return markdownElementAttrForElementType(elementType) != nil
    }
    
    mutating func addMarkdownElementAttr(_ attr: MarkdownElementAttribute) {
        var d = (self[.markdownElements] as? MarkdownElementAttributes) ?? MarkdownElementAttributes()
        d[attr.elementType] = attr
        self[.markdownElements] = d
    }

}
