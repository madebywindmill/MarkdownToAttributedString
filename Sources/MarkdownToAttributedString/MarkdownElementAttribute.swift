//
//  MarkdownElementAttribute.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 2/8/25.
//

import Foundation

/// **Experimental**
///
/// By default, converting markdown to NSAttributedString is non-invertible – it can't be converted back to markdown without some potential lossiness. For example, a heading span converted to attributed string will likely be bold and of a certain font size, but based on those attributes alone it's impossible to know whether the associated markdown is `heading` or `strong`.
///
/// Custom markdown element attributes allow fully invertible conversions because they specifically mark the source markdown in the NSAttributedString.
///
/// When present, the key is `NSAttributedString.Key.MTASMarkdownElement` and the value is an `MarkdownElementAttribute` instance.
public struct MarkdownElementAttribute {
    public var elementTypes = [MarkupType]()
    public var parameters = Dictionary<AnyHashable, AnyHashable>()
    
    public init(elementTypes: [MarkupType] = [MarkupType](),
                parameters: Dictionary<AnyHashable, AnyHashable> = Dictionary<AnyHashable, AnyHashable>()) {
        self.elementTypes = elementTypes
        self.parameters = parameters
    }
    
    public init(elementType: MarkupType) {
        self.init(elementTypes: [elementType])
    }
    
    mutating func addElementType(_ elementType: MarkupType) {
        elementTypes.append(elementType)
    }
    
    mutating func addParameter(_ name: String, _ value: AnyHashable) {
        parameters[name] = value
    }
    
    public func includesType(_ elementType: MarkupType) -> Bool {
        return elementTypes.contains(elementType)
    }
}

/// See `FormattingOptions.addCustomMarkdownElementAttributes`.
public extension NSAttributedString.Key {
    static let markdownElement: NSAttributedString.Key = .init("MTASMarkdownElement")
}

public extension StringAttrs {
    var hasMarkdownElementAttr: Bool {
        return self[.markdownElement] != nil
    }
    
    func getMarkdownElementAttribute() -> MarkdownElementAttribute? {
        return self[.markdownElement] as? MarkdownElementAttribute
    }
    
    func hasMarkdownElementType(_ elementType: MarkupType) -> Bool {
        guard let attr = self[.markdownElement] as? MarkdownElementAttribute else {
            return false
        }
        return attr.includesType(elementType)
    }
    
    func markdownElementAttrForElementType(_ elementType: MarkupType) -> MarkdownElementAttribute? {
        guard let attr = self[.markdownElement] as? MarkdownElementAttribute else {
            return nil
        }
        return attr.includesType(elementType) ? attr : nil
    }
    
    mutating func addMarkdownElementType(_ elementType: MarkupType) {
        var attr = self[.markdownElement] as? MarkdownElementAttribute ?? MarkdownElementAttribute()
        attr.addElementType(elementType)
        self[.markdownElement] = attr
    }
    
    mutating func addMarkdownParameter(_ name: String, _ value: AnyHashable) {
        var attr = self[.markdownElement] as? MarkdownElementAttribute ?? MarkdownElementAttribute()
        attr.addParameter(name, value)
        self[.markdownElement] = attr
    }
    
}
