//
//  Types.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 1/20/25.
//

import Foundation
import Markdown

public typealias StringAttrs = [NSAttributedString.Key: Any]

/// MarkupType, since `Markup` itself isn't hashable.
public enum MarkupType: Hashable, CaseIterable {
    case strong
    case emphasis
    case strikethrough
    case inlineCode
    case codeBlock
    case heading
    case unorderedList
    case orderedList
    case listItem
    case link
    case unknown
    
    // Yes, according to CommonMark semantics list items are blocks (and container blocks at that)
    public var isBlock: Bool {
        return [.codeBlock, .heading, .unorderedList, .orderedList, .listItem].contains(self)
    }
    
    public var isContainerBlock: Bool {
        return [.unorderedList, .orderedList, .listItem].contains(self)
    }
    
    public var isLeafBlock: Bool {
        return [.heading, .codeBlock].contains(self)
    }
}

public extension MarkupType {
    static var all: [MarkupType] {
        return Self.allCases
    }    
}

extension Markup {
    var markupType: MarkupType {
        switch self {
            case is Strong:
                return .strong
            case is Emphasis:
                return .emphasis
            case is InlineCode:
                return .inlineCode
            case is Strikethrough:
                return .strikethrough
            case is CodeBlock:
                return .codeBlock
            case is Heading:
                return .heading
            case is UnorderedList:
                return .unorderedList
            case is OrderedList:
                return .orderedList
            case is ListItem:
                return .listItem
            case is Link:
                return .link
            default:
                print("Unsupported type: \(self)")
                return .unknown
        }
    }
}
