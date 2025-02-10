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
    /// When true, `MarkdownElementAttribute`s are added to the NSAttributedString indicating the source markdown. See the `MarkdownElementAttribute` description for more info.
    public var addCustomMarkdownElementAttributes = false
    
    public var debugLogging = false
    
    /// **Experimental**
    ///
    /// When `supportedElementTypes` is a subset of `MarkupType.allCases`, the converter will try to skip any unsupported element types.
    public var supportedElementTypes = MarkupType.allCases
    
    public init(addCustomMarkdownElementAttributes: Bool = false,
                debugLogging: Bool = false,
                supportedElementTypes: [MarkupType] = MarkupType.allCases)
    {
        self.addCustomMarkdownElementAttributes = addCustomMarkdownElementAttributes
        self.debugLogging = debugLogging
        self.supportedElementTypes = supportedElementTypes
    }
}
