//
//  Platform.swift
//  MarkdownToAttributedString
//
//  Created by John Scalo on 1/19/25.
//

#if os(iOS)  || os(watchOS)
import UIKit
public typealias CocoaFont = UIFont
public typealias CocoaImage = UIImage
public typealias CocoaColor = UIColor
public typealias FontDescriptor = UIFontDescriptor
#elseif os(OSX)
import AppKit
public typealias CocoaFont = NSFont
public typealias CocoaImage = NSImage
public typealias CocoaColor = NSColor
public typealias FontDescriptor = NSFontDescriptor
#endif

#if os(iOS)  || os(watchOS)
public extension UIFont {
    static func monospacedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if #available(iOS 13.0, watchOS 6.0, *) {
            return UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        } else {
            if let menloFont = UIFont(name: "Menlo", size: size) {
                return menloFont
            } else if let courierFont = UIFont(name: "Courier", size: size) {
                return courierFont
            } else {
                return UIFont.systemFont(ofSize: size, weight: weight)
            }
        }
    }

    static func systemItalicFont(ofSize fontSize: CGFloat) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        guard let descriptor = systemFont.fontDescriptor.withSymbolicTraits(.traitItalic) else {
            return systemFont
        }
        return UIFont(descriptor: descriptor, size: fontSize)
    }
    
    // NSFont parity
    func displayName() -> String? {
        return fontName
    }
}
#elseif os(OSX)
public extension NSFont {
    static func monospacedFont(ofSize size: CGFloat, weight: NSFont.Weight) -> NSFont {
        if #available(macOS 10.15, *) {
            return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        } else {
            return NSFont.userFixedPitchFont(ofSize: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
        }
    }

    static func systemItalicFont(ofSize fontSize: CGFloat) -> NSFont {
        let systemFont = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        let descriptor = systemFont.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: fontSize) ?? systemFont
    }
}
#endif
