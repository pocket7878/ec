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

protocol ECTextViewSelectionDelegate: class {
    func onRightMouseSelection(str: String)
    func onOtherMouseSelection(str: String)
}

class ECTextView: CodeTextView {
    
    //Right mouse
    
    var selecting: Bool = false
    var firstIdx: Int!
    
    weak var selectionDelegate: ECTextViewSelectionDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setDefaultSelectionAttributes()
    }
    
    
    //Selected color setup
    func setDefaultSelectionAttributes() {
        self.selectedTextAttributes = [
            NSBackgroundColorAttributeName: NSColor(red: 0.933, green: 0.921, blue: 0.570, alpha: 1.0),
            NSForegroundColorAttributeName: NSColor.blackColor()
        ]
    }
    
    func setRightSelectionAttributes() {
        self.selectedTextAttributes = [
            NSBackgroundColorAttributeName: NSColor(red: 0.627, green: 0.0, blue: 0.0, alpha: 1.0),
            NSForegroundColorAttributeName: NSColor.whiteColor()
        ]
    }
    
    func setOtherSelectionAttributes() {
        self.selectedTextAttributes = [
            NSBackgroundColorAttributeName: NSColor(red: 0.003, green: 0.356, blue: 0.0, alpha: 1.0),
            NSForegroundColorAttributeName: NSColor.whiteColor()
        ]
    }
    
    override func rightMouseUp(theEvent: NSEvent) {
        selecting = false
        setDefaultSelectionAttributes()
        let selectedRange = self.selectedRange()
        if selectedRange.location != NSNotFound {
            if let str = self.string {
                let selectedStr = str.substringWithRange(str.startIndex.advancedBy(selectedRange.location) ..< str.startIndex.advancedBy(selectedRange.location + selectedRange.length))
                self.setSelectedRange(NSMakeRange(firstIdx, 0))
                self.selectionDelegate?.onRightMouseSelection(selectedStr)
            }
        }
    }
    
    override func rightMouseDown(theEvent: NSEvent) {
        self.selecting = true
        let winP = theEvent.locationInWindow
        let pp = self.convertPoint(winP, fromView: nil)
        let rangeStartIndex = self.characterIndexForInsertionAtPoint(pp)
        self.setSelectedRange(NSMakeRange(rangeStartIndex, 0))
        self.firstIdx = rangeStartIndex
        setRightSelectionAttributes()
    }
    
    override func rightMouseDragged(theEvent: NSEvent) {
        let winP = theEvent.locationInWindow
        let pp = self.convertPoint(winP, fromView: nil)
        let cidx = self.characterIndexForInsertionAtPoint(pp)
        if (cidx > firstIdx) {
            self.setSelectedRange(NSMakeRange(firstIdx, cidx - firstIdx))
        } else {
            self.setSelectedRange(NSMakeRange(cidx, firstIdx - cidx))
        }
    }
    
    //Other mouse
    override func otherMouseUp(theEvent: NSEvent) {
        selecting = false
        setDefaultSelectionAttributes()
        let selectedRange = self.selectedRange()
        if selectedRange.location != NSNotFound {
            if let str = self.string {
                let selectedStr = str.substringWithRange(str.startIndex.advancedBy(selectedRange.location) ..< str.startIndex.advancedBy(selectedRange.location + selectedRange.length))
                self.setSelectedRange(NSMakeRange(firstIdx, 0))
                self.selectionDelegate?.onOtherMouseSelection(selectedStr)
            }
        }
    }
    
    override func otherMouseDown(theEvent: NSEvent) {
        self.selecting = true
        let winP = theEvent.locationInWindow
        let pp = self.convertPoint(winP, fromView: nil)
        let rangeStartIndex = self.characterIndexForInsertionAtPoint(pp)
        self.setSelectedRange(NSMakeRange(rangeStartIndex, 0))
        self.firstIdx = rangeStartIndex
        setOtherSelectionAttributes()
    }

    override func otherMouseDragged(theEvent: NSEvent) {
        let winP = theEvent.locationInWindow
        let pp = self.convertPoint(winP, fromView: nil)
        let cidx = self.characterIndexForInsertionAtPoint(pp)
        if (cidx > firstIdx) {
            self.setSelectedRange(NSMakeRange(firstIdx, cidx - firstIdx))
        } else {
            self.setSelectedRange(NSMakeRange(cidx, firstIdx - cidx))
        }
    }
    
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