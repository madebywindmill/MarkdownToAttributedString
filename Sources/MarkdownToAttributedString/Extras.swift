//
//  Extras.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 2/10/25.
//

import Foundation

public extension NSAttributedString {
    // wip
    var betterDescription: String {
        var returnStr = ""
        var location = 0
        while location < length {
            let nextStr = self.nextContinuousAttrString(from: location)
            var str = "\(location): "
            if nextStr.hasAttribute(key: .paragraphStyle, at: 0) {
                str += "<NSParagraphStyle>"
            }
            if let font = nextStr.attribute(.font, at: 0, effectiveRange: nil) as? CocoaFont {
                str += "<Font name=“\(font.compatibleDisplayName)”>"
            }
            
            if let markdownEls = nextStr.attribute(.markdownElements, at: 0, effectiveRange: nil) as? MarkdownElementAttributes {
                for (_, val) in markdownEls {
                    str += val.betterDescriptionMarker
                }
            }
            
            str += nextStr.string.replacingUnprintableCharacters

            returnStr += "\(str)\n"
            location += nextStr.length
        }
        return returnStr
    }
    
    private var wholeRange: NSRange {
        return NSRange(location: 0, length: self.length)
    }

    func hasAttribute(key: NSAttributedString.Key, at location: Int) -> Bool {
        guard location < string.length else {
            return false
        }
        if nil != attributes(at: location, effectiveRange: nil)[key] as? AnyHashable {
            return true
        } else {
            return false
        }
    }

    func nextContinuousAttrString(from location: Int) -> NSAttributedString {
        var longestRange = NSRange(location: 0, length: 0)
        let _ = self.attributes(at: location, longestEffectiveRange: &longestRange, in: self.wholeRange)
        return self.attributedSubstring(from: longestRange)
    }
}

extension String {
    var nsString: NSString {
        return self as NSString
    }
    
    var length: Int {
        return utf16.count
    }
    
    var replacingUnprintableCharacters: String {
        var escapedString = ""
        for char in self {
            switch char {
                case "\n": escapedString += "\\n"
                case "\t": escapedString += "\\t"
                case "\r": escapedString += "\\r"
                case "\r\n": escapedString += "\\r\\n"
                case "\u{fffc}": escapedString += "\\ufffc"
                case "\u{200B}": escapedString += "\\u{200B}"
                default: escapedString += String(char)
            }
        }
        return escapedString
    }

}

