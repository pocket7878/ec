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
    var dragged: Bool = false
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
            NSBackgroundColorAttributeName: NSColor(red: 0.003, green: 0.356, blue: 0.0, alpha: 1.0),
            NSForegroundColorAttributeName: NSColor.whiteColor()
        ]
    }
    
    func setOtherSelectionAttributes() {
        self.selectedTextAttributes = [
            NSBackgroundColorAttributeName: NSColor(red: 0.627, green: 0.0, blue: 0.0, alpha: 1.0),
            NSForegroundColorAttributeName: NSColor.whiteColor()
        ]
    }
    
    //MARK: Expand Selection
    func isAlnum(char: Character) -> Bool {
        let symbolCharacterSet = NSCharacterSet(
            charactersInString: "!\"#$%&'()*+,-./:;<=>?@[\\]^`{|}~")
        let whiteSpaceCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        if isChar(char, inSet: whiteSpaceCharacterSet) {
            return false
        } else if isChar(char, inSet: symbolCharacterSet) {
            return false
        }
        return true
    }
    
    func isChar(char: Character, inSet set: NSCharacterSet) -> Bool {
        if String(char).rangeOfCharacterFromSet(set, options: [], range: nil) != nil {
            return true
        }
        return false
    }
    
    func expandSelection(charIdx: Int) -> NSRange? {
        if let charview = self.string?.characters {
            var topIndex = charview.startIndex.advancedBy(charIdx)
            while true {
                let c = charview[topIndex]
                if isAlnum(c) {
                    if topIndex == charview.startIndex {
                        break
                    } else {
                        topIndex = topIndex.predecessor()
                    }
                } else {
                    topIndex = topIndex.successor()
                    break
                }
            }
            var bottomIndex = charview.startIndex.advancedBy(charIdx)
            while true {
                let c = charview[bottomIndex]
                if isAlnum(c) {
                    if bottomIndex == charview.endIndex {
                        break
                    } else {
                        bottomIndex = bottomIndex.successor()
                    }
                } else {
                    bottomIndex = bottomIndex.predecessor()
                    break
                }
            }
            let loc = charview.startIndex.distanceTo(topIndex)
            if topIndex >= bottomIndex {
                return nil
            } else {
                let len = topIndex.distanceTo(bottomIndex)
                return NSMakeRange(loc, len + 1)
            }
        } else {
            return nil
        }
    }
    
    
    //MARK: Mouse Handlers
    override func mouseDown(theEvent: NSEvent) {
        if (theEvent.modifierFlags.contains(NSEventModifierFlags.AlternateKeyMask)) {
            //Emulate other mouse Down
            self.rightMouseDown(theEvent)
        } else if (theEvent.modifierFlags.contains(.CommandKeyMask)){
            //Emulate other mouse down
            self.otherMouseDown(theEvent)
        } else {
            super.mouseDown(theEvent)
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        if (theEvent.modifierFlags.contains(NSEventModifierFlags.AlternateKeyMask)) {
            //Emulate other mouse Down
            self.rightMouseUp(theEvent)
        } else if (theEvent.modifierFlags.contains(.CommandKeyMask)){
            //Emulate other mouse down
            self.otherMouseUp(theEvent)
        } else {
            super.mouseUp(theEvent)
        }
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        if (theEvent.modifierFlags.contains(NSEventModifierFlags.AlternateKeyMask)) {
            //Emulate other mouse Down
            self.rightMouseDragged(theEvent)
        } else if (theEvent.modifierFlags.contains(.CommandKeyMask)){
            //Emulate other mouse down
            self.otherMouseDragged(theEvent)
        } else {
            super.mouseDragged(theEvent)
        }
    }
    
    override func rightMouseUp(theEvent: NSEvent) {
        selecting = false
        setDefaultSelectionAttributes()
        let selectedRange = self.selectedRange()
        let selectedRangeRect = self.firstRectForCharacterRange(selectedRange, actualRange: nil)
        let eventLoc = theEvent.locationInWindow
        let eventRect = self.window!.convertRectToScreen(NSMakeRect(eventLoc.x, eventLoc.y, 0, 0))
        let inSelectionRange = selectedRangeRect.contains(eventRect)
        if selectedRange.location != NSNotFound {
            if selectedRange.length > 0 && (self.dragged || inSelectionRange) {
                if let str = self.string {
                    let selectedStr = str.substringWithRange(str.startIndex.advancedBy(selectedRange.location) ..< str.startIndex.advancedBy(selectedRange.location + selectedRange.length))
                    self.setSelectedRange(selectedRange)
                    self.selectionDelegate?.onRightMouseSelection(selectedStr)
                }
            } else {
                if let str = self.string {
                    if let newRange = expandSelection(firstIdx) {
                        self.setSelectedRange(newRange)
                        let selectedStr = str.substringWithRange(str.startIndex.advancedBy(newRange.location) ..< str.startIndex.advancedBy(newRange.location + newRange.length))
                        self.selectionDelegate?.onRightMouseSelection(selectedStr)
                    }
                }
            }
        }
        self.dragged = false
    }
    
    override func rightMouseDown(theEvent: NSEvent) {
        self.selecting = true
        self.dragged = false
        let winP = theEvent.locationInWindow
        let pp = self.convertPoint(winP, fromView: nil)
        let rangeStartIndex = self.characterIndexForInsertionAtPoint(pp)
        self.firstIdx = rangeStartIndex
        setRightSelectionAttributes()
    }
    
    override func rightMouseDragged(theEvent: NSEvent) {
        self.dragged = true
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
    
    //MARK: Utils
    func scrollToSelection() {
        let selectedRange = self.selectedRange()
        if selectedRange.location != NSNotFound {
            self.scrollRangeToVisible(selectedRange)
        }
    }
    
    func moveMouseCursorToSelectedRange() {
        let selectedRange = self.selectedRange()
        if selectedRange.location != NSNotFound {
            let rect = self.firstRectForCharacterRange(selectedRange, actualRange: nil)
            let pt = NSMakePoint(rect.origin.x, rect.origin.y)
            let y = pt.y;
            let screenY = CGDisplayBounds(CGMainDisplayID()).size.height - y
            CGWarpMouseCursorPosition(CGPointMake(pt.x + rect.width / 2, screenY - rect.height / 2))
        }
    }
    

    
    //MARK: TextInsert Action Overrides
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