//
//  StringExtension.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/01.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation

enum NewLineType {
    case LF
    case CRLF
    case CR
    case None
}

extension String {
    
    var lineCount: Int {
        var cnt = 0
        self.enumerateLines { (_, _) in
            cnt += 1
        }
        return cnt
    }
    
    var lines: [String] {
        var lines = [String]()
        self.enumerateLines { (line, stop) in
            lines.append(line)
        }
        return lines
    }
    
    func indentRange(idx: Int) -> NSRange {
        let nsStr = NSString(string: self)
        let lineRange = nsStr.lineRangeForRange(NSMakeRange(idx, 0))
        return nsStr.rangeOfString("^[ \\t]+", options: NSStringCompareOptions.RegularExpressionSearch, range: lineRange)
    }
    
    //MARK: New Line
    
    func newLineCharacterForType(type: NewLineType) -> String {
        switch(type) {
        case .CR:
            return "\r"
        case .CRLF:
            return "\r\n"
        case .LF:
            return "\n"
        case .None:
            return ""
        }
    }
    
    func detectNewLineType() -> NewLineType {
        //New Line Character set
        let newLineCharacterSet = NSCharacterSet(charactersInString: "\n\r")
        let characterView = self.characters
        if let newLineRange = self.rangeOfCharacterFromSet(newLineCharacterSet) {
            let matchedChar = characterView[newLineRange.startIndex]
            switch(matchedChar) {
            case "\n":
                return .LF
            case "\r\n":
                    return .CRLF
            case "\r":
                return .CR
            default:
                return .None
            }
        } else {
            return .None
        }
    }
    
    func stringByReplaceNewLineCharacterWith(type: NewLineType) -> String {
        return self.stringByReplacingOccurrencesOfString(
            "\\r\\n|[\\n\\r]",
            withString: self.newLineCharacterForType(type),
            options: NSStringCompareOptions.RegularExpressionSearch,
            range: self.characters.startIndex ..< self.characters.endIndex)
    }
    
    func stringByRemovingNewLineCharacters() -> String {
        return self.stringByReplaceNewLineCharacterWith(.None)
    }
    
    func stringByExpandTab(tabWidth: Int) -> String {
        return self.stringByReplacingOccurrencesOfString(
            "\t",
            withString: String(count: tabWidth, repeatedValue: Character(" ")),
            options:  NSStringCompareOptions.RegularExpressionSearch,
            range: self.characters.startIndex ..< self.characters.endIndex)
    }
}