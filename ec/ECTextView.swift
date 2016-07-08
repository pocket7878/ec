//
//  ECTextView.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/06.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class ECTextView: CodeTextView {
    
    override func insertTab(sender: AnyObject?) {
        if (Preference.expandTab()) {
            let tabWidth = Preference.tabWidth()
            let spaces = String(count: tabWidth, repeatedValue: Character(" "))
            self.insertText(spaces)
        } else {
            super.insertTab(sender)
        }
    }
    
    override func insertNewline(sender: AnyObject?) {
        guard let string = self.string else {
            return super.insertNewline(sender)
        }
        
        if !Preference.autoIndent() {
            return super.insertNewline(sender)
        }
        
        let selectedRange = self.selectedRange()
        let indentRange = string.indentRange(selectedRange.location)
        
        if (NSEqualRanges(selectedRange, indentRange)) {
            return super.insertNewline(sender)
        }
        
        var indent = ""
        
        if indentRange.location != NSNotFound {
            let baseIndentRange = NSIntersectionRange(indentRange, NSMakeRange(0, selectedRange.location))
            indent = string.substringWithRange(string.startIndex.advancedBy(baseIndentRange.location) ..< string.startIndex.advancedBy(baseIndentRange.location + baseIndentRange.length))
        }
        
        super.insertNewline(sender)
        
        if (indent.characters.count > 0) {
            super.insertText(indent, replacementRange: self.selectedRange())
        }
    }
}