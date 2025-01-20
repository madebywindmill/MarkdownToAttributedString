//
//  MarkdownUtility.swift
//
//  Created by John Scalo on 1/18/24.
//

import Foundation

let markdownDebugLogging = false

// Debug logging
#if DEBUG
    func MarkdownDebugLog(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        if markdownDebugLogging {
            let shortenedFile = file.components(separatedBy: "/").last ?? ""
            let strForNSLog = "[\(shortenedFile):\(function):\(line)] \(message)"
            NSLog("%@", strForNSLog)
        }
    }
#else
    func MarkdownDebugLog(_ message: String, _ args: CVarArg...) {}
#endif
