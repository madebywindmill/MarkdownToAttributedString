//
//  MarkdownStyles.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 1/18/25.
//

#if os(macOS)
import AppKit
#elseif os(iOS) || os(watchOS)
import UIKit
#endif
import Markdown

/// Encapsulates styling for rendering Markdown elements with `AttributedStringFormatter`.
///
/// - Parameters:
///   - baseAttributes: A dictionary of default text attributes (`StringAttrs`) applied to all Markdown content
///     that does not have specific styling defined in `styleAttributes`.
///
///   - styleAttributes: A dictionary mapping `MarkupType` (e.g., `.strong`, `.emphasis`, `.link`) to specific
///     text attributes. These attributes override `baseAttributes` for the corresponding Markdown elements.
///
///   - headingPointSizes: An array of `CGFloat` values specifying font sizes for headings. The first value applies
///     to level 1 headings (`#`), the second to level 2 headings (`##`), and so on. If there are fewer values than
///     heading levels, the last size in the array is reused for remaining levels.
///
///   - unorderedListBullets: An array of "bullet" strings to be used for unordered lists. The index of the array = the indentation of the list item, wrapping back to the 1st if the indentation > array.count.
public struct MarkdownStyles {
    public var baseAttributes: StringAttrs
    public var styleAttributes: [MarkupType: StringAttrs]
    public var headingPointSizes: [CGFloat] = [22, 18, 15, 14, 13, 11]
    public var unorderedListBullets: [String] = ["•", "◦", "▪", "▫"]

    public init(baseAttributes: StringAttrs, styleAttributes: [MarkupType : StringAttrs]) {
        self.baseAttributes = baseAttributes
        self.styleAttributes = styleAttributes
    }
    
    /// Returns the specified attributes for the given markup type, or, if none are found, the base attributes.
    public func attributesForType(_ type: MarkupType) -> StringAttrs {
        var combinedAttributes = baseAttributes
        
        if let styleAttributesForType = styleAttributes[type] {
            combinedAttributes.merge(styleAttributesForType) { (_, new) in new }
        }
        
        return combinedAttributes
    }

    public mutating func setBaseAttribute(_ attribute: NSAttributedString.Key, _ value: Any) {
        var attrs = baseAttributes
        attrs[attribute] = value
        baseAttributes = attrs
    }

    public mutating func setStyleAttribute(_ attribute: NSAttributedString.Key, _ value: Any, forType type: MarkupType) {
        var attrs = styleAttributes[type] ?? [:]
        attrs[attribute] = value
        styleAttributes[type] = attrs
    }
}

/// A default set of MarkdownStyles, intended mainly for tests, debugging, and demonstration.
public extension MarkdownStyles {
    static var `default`: MarkdownStyles {
        let indentedPStyle = NSMutableParagraphStyle()
        indentedPStyle.firstLineHeadIndent = 20
        indentedPStyle.headIndent = 20
        
        return MarkdownStyles(
            baseAttributes: [
                .font: CocoaFont.systemFont(ofSize: 13),
                .foregroundColor: CocoaColor.darkGray
            ],
            styleAttributes: [
                .strong: [
                    .font: CocoaFont.systemFont(ofSize: 13, weight: .bold)
                ],
                .emphasis: [
                    .font: CocoaFont.systemItalicFont(ofSize: 13)
                ],
                .strikethrough: [
                    .strikethroughStyle: 1,
                    .strikethroughColor: CocoaColor.lightGray
                ],
                .inlineCode: [
                    .font: CocoaFont.monospacedFont(ofSize: 12, weight: .regular),
                    .backgroundColor: CocoaColor.black.withAlphaComponent(0.05),
                ],
                .codeBlock: [
                    .font: CocoaFont.monospacedFont(ofSize: 11, weight: .regular),
                    .foregroundColor: CocoaColor.lightGray,
                    .paragraphStyle: indentedPStyle
                ],
                .listItem: [
                    .font: CocoaFont.monospacedFont(ofSize: 13, weight: .regular),
                    .foregroundColor: CocoaColor.lightGray
                ],
                .heading: [
                    .paragraphStyle: indentedPStyle
                ],
                .unorderedList: [
                    .paragraphStyle: indentedPStyle
                ],
                .orderedList: [
                    .paragraphStyle: indentedPStyle
                ],
                .link: [
                    .font: CocoaFont.systemFont(ofSize: 13, weight: .regular),
                    .foregroundColor: CocoaColor.blue
                ]
            ])
    }
    
    func fontAttributeForType(_ type: MarkupType) -> CocoaFont {
        return (attributesForType(type)[.font] as? CocoaFont) ?? CocoaFont.systemFont(ofSize: 13)
    }
    
    func valueForAttribute<T>(_ attribute: NSAttributedString.Key, type: MarkupType) -> T? {
        if let styleAttributeValue = styleAttributes[type]?[attribute] as? T {
            return styleAttributeValue
        }
        return baseAttributes[attribute] as? T
    }
}
