//
//  FormattingOptions.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 2/7/25.
//

import Foundation

public struct FormattingOptions {
    
    /// **Experimental**
    ///
    /// When true, `MarkdownElementAttribute`s are added to the NSAttributedString indicating the source markdown. See the `MarkdownElementAttribute` description for more info. Off by default.
    public var addCustomMarkdownElementAttributes: Bool
    
    /// Log a bunch of stuff. Off by default.
    public var debugLogging: Bool
    
    /// **Experimental**
    ///
    /// When `supportedElementTypes` is a subset of `MarkupType.allCases`, the converter will try to skip any unsupported element types.
    public var supportedElementTypes = MarkupType.allCases
    
    /// When true, any newlines at the beginning or end of the formatted attributed string is removed. Off by default.
    public var trimNewlines: Bool
    
    public init(addCustomMarkdownElementAttributes: Bool = false,
                debugLogging: Bool = false,
                supportedElementTypes: [MarkupType] = MarkupType.allCases,
                trimNewlines: Bool = false)
    {
        self.addCustomMarkdownElementAttributes = addCustomMarkdownElementAttributes
        self.debugLogging = debugLogging
        self.supportedElementTypes = supportedElementTypes
        self.trimNewlines = trimNewlines
    }
    
    public static var `default`: FormattingOptions {
        return FormattingOptions()
    }
}
