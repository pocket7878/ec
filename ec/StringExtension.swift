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
    
    private var ns: NSString {
        return (self as NSString)
    }
    
    public func substring(from index: Int) -> String {
        return ns.substring(from: index)
    }
    
    public func substring(to index: Int) -> String {
        return ns.substring(to: index)
    }
    
    public func substring(with range: NSRange) -> String {
        return ns.substring(with: range)
    }
    
    public var lastPathComponent: String {
        return ns.lastPathComponent
    }
    
    public var pathExtension: String {
        return ns.pathExtension
    }
    
    public var deletingLastPathComponent: String {
        return ns.deletingLastPathComponent
    }
    
    public var deletingPathExtension: String {
        return ns.deletingPathExtension
    }
    
    public var pathComponents: [String] {
        return ns.pathComponents
    }
    
    public func appendingPathComponent(_ str: String) -> String {
        return ns.appendingPathComponent(str)
    }
    
    public func appendingPathExtension(_ str: String) -> String? {
        return ns.appendingPathExtension(str)
    }
    
    //絵文字など(2文字分)も含めた文字数を返します
    var count: Int {
        let string_NS = self as NSString
        return string_NS.length
    }
    
    //正規表現の検索をします
    func pregMatche(pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }
        let matches = regex.matches(in: self, options: [], range: NSMakeRange(0, self.count))
        return matches.count > 0
    }
    
    //正規表現の検索結果を利用できます
    func pregMatche(pattern: String, options: NSRegularExpression.Options = [], matches: inout [String]) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }
        let targetStringRange = NSRange(location: 0, length: self.count)
        let results = regex.matches(in: self, options: [], range: targetStringRange)
        for i in 0 ..< results.count {
            for j in 0 ..< results[i].numberOfRanges {
                let range = results[i].rangeAt(j)
                matches.append((self as NSString).substring(with: range))
            }
        }
        return results.count > 0
    }
    
    //正規表現の置換をします
    func pregReplace(pattern: String, with: String, options: NSRegularExpression.Options = []) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        return regex.stringByReplacingMatches(in: self, options: [], range: NSMakeRange(0, self.count), withTemplate: with)
    }
}
