//
//  StringExtension.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/01.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation

enum NewLineType {
    case lf
    case crlf
    case cr
    case none
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
    
    func indentRange(_ idx: Int) -> NSRange {
        let nsStr = NSString(string: self)
        let lineRange = nsStr.lineRange(for: NSMakeRange(idx, 0))
        return nsStr.range(of: "^[ \\t]+", options: NSString.CompareOptions.regularExpression, range: lineRange)
    }
    
    //MARK: New Line
    
    func newLineCharacterForType(_ type: NewLineType) -> String {
        switch(type) {
        case .cr:
            return "\r"
        case .crlf:
            return "\r\n"
        case .lf:
            return "\n"
        case .none:
            return ""
        }
    }
    
    func detectNewLineType() -> NewLineType {
        //New Line Character set
        let newLineCharacterSet = CharacterSet(charactersIn: "\n\r")
        let characterView = self.characters
        if let newLineRange = self.rangeOfCharacter(from: newLineCharacterSet) {
            let matchedChar = characterView[newLineRange.lowerBound]
            switch(matchedChar) {
            case "\n":
                return .lf
            case "\r\n":
                    return .crlf
            case "\r":
                return .cr
            default:
                return .none
            }
        } else {
            return .none
        }
    }
    
    func stringByReplaceNewLineCharacterWith(_ type: NewLineType) -> String {
        return self.replacingOccurrences(
            of: "\\r\\n|[\\n\\r]",
            with: self.newLineCharacterForType(type),
            options: NSString.CompareOptions.regularExpression,
            range: self.characters.startIndex ..< self.characters.endIndex)
    }
    
    func stringByRemovingNewLineCharacters() -> String {
        return self.stringByReplaceNewLineCharacterWith(.none)
    }
    
    func stringByExpandTab(_ tabWidth: Int) -> String {
        return self.replacingOccurrences(
            of: "\t",
            with: String(repeating: " ", count: tabWidth),
            options:  NSString.CompareOptions.regularExpression,
            range: self.characters.startIndex ..< self.characters.endIndex)
    }
}
