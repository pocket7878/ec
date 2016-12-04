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
    func onFileAddrSelection(_ fileAddr: FileAddr, by: NSEvent)
    func onRightMouseSelection(_ str: String, by: NSEvent)
    func onOtherMouseSelection(_ str: String, by: NSEvent)
}

protocol WorkingFolderDataSource: class {
    func workingFolder() -> String?
}

class ECTextView: CodeTextView {
    
    //Right mouse
    
    var selecting: Bool = false
    var dragged: Bool = false
    var firstIdx: Int!
    
    weak var selectionDelegate: ECTextViewSelectionDelegate?
    weak var workingFolderDataSource: WorkingFolderDataSource?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setDefaultSelectionAttributes()
    }
    
    
    //Selected color setup
    func setDefaultSelectionAttributes() {
        self.selectedTextAttributes = [
            NSBackgroundColorAttributeName: Preference.leftBgColor,
            NSForegroundColorAttributeName: Preference.leftFgColor
        ]
    }
    
    func setRightSelectionAttributes() {
        self.selectedTextAttributes = [
            NSBackgroundColorAttributeName: Preference.rightBgColor,
            NSForegroundColorAttributeName: Preference.rightFgColor
        ]
    }
    
    func setOtherSelectionAttributes() {
        self.selectedTextAttributes = [
            NSBackgroundColorAttributeName: Preference.otherBgColor,
            NSForegroundColorAttributeName: Preference.otherFgColor
        ]
    }
    
    //MARK: Expand Selection
    func expandFile(_ charIdx: Int) -> FileAddr? {
        if let charview = self.string?.characters {
            var topIndex = charview.index(charview.startIndex, offsetBy: charIdx)
            while true {
                let c = charview[topIndex]
                if isFileChar(c) {
                    if topIndex == charview.startIndex {
                        break
                    } else {
                        topIndex = charview.index(before: topIndex)
                    }
                } else {
                    topIndex = charview.index(after: topIndex)
                    break
                }
            }
            var bottomIndex = charview.index(charview.startIndex, offsetBy: charIdx)
            while true {
                let c = charview[bottomIndex]
                if isFileChar(c) {
                    if charview.index(after: bottomIndex) == charview.endIndex {
                        break
                    } else {
                        bottomIndex = charview.index(after: bottomIndex)
                    }
                } else {
                    bottomIndex = charview.index(before: bottomIndex)
                    break
                }
            }
            _ = charview.distance(from: charview.startIndex, to: topIndex)
            if topIndex >= bottomIndex {
                return nil
            } else {
                let q0 = topIndex
                var q1 = topIndex
                //Separate before colon and after colon
                for var i in charview.indices[topIndex ... bottomIndex] {
                    let c = charview[i]
                    q1 = i
                    if c == ":" {
                        if i == topIndex {
                            return nil
                        } else {
                            q1 = charview.index(before: i)
                            break
                        }
                    }
                }
                let filename = self.string?.substring(with: self.string!.index(q0, offsetBy: 0) ..< self.string!.index(q1, offsetBy: 1))
                var addrStr: String? = nil
                let amin = charview.index(q1, offsetBy: 2, limitedBy: charview.endIndex)
                var amax: String.CharacterView.Index? = nil
                if let amin = amin, amin <= bottomIndex {
                    for i in charview.indices[amin ... bottomIndex] {
                        let c: Character = charview[i]
                        amax = i
                        if !(isAddrChar(c) || isRegexChar(c)) {
                            amax = charview.index(before: amax!)
                            break
                        }
                    }
                    addrStr = self.string?.substring(with: self.string!.index(amin, offsetBy: 0) ..< self.string!.index(amax!, offsetBy: 1))
                }
                if let filename = filename,
                    let workingFolder = workingFolderDataSource?.workingFolder() {
                    let fileManager = FileManager.default
                    var filePath: String = ""
                    if filename.hasPrefix("/") {
                        filePath = filename
                    } else {
                        filePath = workingFolder.appendingPathComponent(filename)
                    }
                    if fileManager.fileExists(atPath: filePath) {
                        if let addrStr = addrStr {
                            do {
                                let res = try addrParser.run(
                                    userState: (),
                                    sourceName: "addrStr",
                                    input: addrStr)
                                let addr = res
                                return FileAddr(filepath: filePath, addr: addr)
                            } catch {
                                return nil
                            }
                        } else {
                            return FileAddr(filepath: filePath, addr: nil)
                        }
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            }
        } else {
            return nil
        }
    }
    
    func expandSelectionBy(_ charIdx: Int, checker: (Character) -> Bool) -> NSRange? {
        if let charview = self.string?.characters {
            var topIndex = charview.index(charview.startIndex, offsetBy: charIdx)
            while true {
                let c = charview[topIndex]
                if checker(c) {
                    if topIndex == charview.startIndex {
                        break
                    } else {
                        topIndex = charview.index(before: topIndex)
                    }
                } else {
                    topIndex = charview.index(after: topIndex)
                    break
                }
            }
            var bottomIndex = charview.index(charview.startIndex, offsetBy: charIdx)
            while true {
                let c = charview[bottomIndex]
                if checker(c) {
                    if charview.index(after: bottomIndex) == charview.endIndex {
                        break
                    } else {
                        bottomIndex = charview.index(after: bottomIndex)
                    }
                } else {
                    bottomIndex = charview.index(before: bottomIndex)
                    break
                }
            }
            let loc = charview.distance(from: charview.startIndex, to: topIndex)
            if topIndex >= bottomIndex {
                return nil
            } else {
                let len = charview.distance(from: topIndex, to: bottomIndex)
                return NSMakeRange(loc, len + 1)
            }
        } else {
            return nil
        }
    }
    
    func expandSelection(_ charIdx: Int, by theEvent: NSEvent) -> NSRange? {
        if let fileAddr = expandFile(charIdx) {
            self.selectionDelegate?.onFileAddrSelection(fileAddr, by: theEvent)
            return nil
        } else {
            return expandSelectionBy(charIdx, checker: { (c) -> Bool in
                return isAlnum(c)
            })
        }
    }
    
    
    //MARK: Mouse Handlers
    override func mouseDown(with theEvent: NSEvent) {
        if (theEvent.modifierFlags.contains(.command)) {
            //Emulate other mouse Down
            self.rightMouseDown(with: theEvent)
        } else if (theEvent.modifierFlags.contains(.option)){
            //Emulate other mouse down
            self.otherMouseDown(with: theEvent)
        } else {
            super.mouseDown(with: theEvent)
        }
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        if (theEvent.modifierFlags.contains(.command)) {
            //Emulate other mouse Down
            self.rightMouseUp(with: theEvent)
        } else if (theEvent.modifierFlags.contains(.option)){
            //Emulate other mouse down
            self.otherMouseUp(with: theEvent)
        } else {
            super.mouseUp(with: theEvent)
        }
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        if (theEvent.modifierFlags.contains(.command)) {
            //Emulate other mouse Down
            self.rightMouseDragged(with: theEvent)
        } else if (theEvent.modifierFlags.contains(.option)){
            //Emulate other mouse down
            self.otherMouseDragged(with: theEvent)
        } else {
            super.mouseDragged(with: theEvent)
        }
    }
    
    override func rightMouseUp(with theEvent: NSEvent) {
        selecting = false
        setDefaultSelectionAttributes()
        let selectedRange = self.selectedRange()
        let selectedRangeRect = self.firstRect(forCharacterRange: selectedRange, actualRange: nil)
        let eventLoc = theEvent.locationInWindow
        let eventRect = self.window!.convertToScreen(NSMakeRect(eventLoc.x, eventLoc.y, 0, 0))
        let inSelectionRange = selectedRangeRect.contains(eventRect)
        if selectedRange.location != NSNotFound {
            if selectedRange.length > 0 && (self.dragged || inSelectionRange) {
                if let str = self.string {
                    let selectedStr = str.substring(with: str.characters.index(str.startIndex, offsetBy: selectedRange.location) ..< str.characters.index(str.startIndex, offsetBy: selectedRange.location + selectedRange.length))
                    self.setSelectedRange(selectedRange)
                    self.selectionDelegate?.onRightMouseSelection(selectedStr, by: theEvent)
                }
            } else {
                if let str = self.string {
                    if let newRange = expandSelection(firstIdx, by: theEvent) {
                        self.setSelectedRange(newRange)
                        let selectedStr = str.substring(with: str.characters.index(str.startIndex, offsetBy: newRange.location) ..< str.characters.index(str.startIndex, offsetBy: newRange.location + newRange.length))
                        self.selectionDelegate?.onRightMouseSelection(selectedStr, by: theEvent)
                    }
                }
            }
        }
        self.dragged = false
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        self.selecting = true
        self.dragged = false
        let winP = theEvent.locationInWindow
        let pp = self.convert(winP, from: nil)
        let rangeStartIndex = self.characterIndexForInsertion(at: pp)
        self.firstIdx = rangeStartIndex
        setRightSelectionAttributes()
    }
    
    override func rightMouseDragged(with theEvent: NSEvent) {
        self.dragged = true
        let winP = theEvent.locationInWindow
        let pp = self.convert(winP, from: nil)
        let cidx = self.characterIndexForInsertion(at: pp)
        if (cidx > firstIdx) {
            self.setSelectedRange(NSMakeRange(firstIdx, cidx - firstIdx))
        } else {
            self.setSelectedRange(NSMakeRange(cidx, firstIdx - cidx))
        }
    }
    
    //Other mouse
    override func otherMouseUp(with theEvent: NSEvent) {
        selecting = false
        setDefaultSelectionAttributes()
        let selectedRange = self.selectedRange()
        if selectedRange.location != NSNotFound {
            if let str = self.string {
                let selectedStr = str.substring(with: str.characters.index(str.startIndex, offsetBy: selectedRange.location) ..< str.characters.index(str.startIndex, offsetBy: selectedRange.location + selectedRange.length))
                self.setSelectedRange(NSMakeRange(firstIdx, 0))
                self.selectionDelegate?.onOtherMouseSelection(selectedStr, by: theEvent)
            }
        }
    }
    
    override func otherMouseDown(with theEvent: NSEvent) {
        self.selecting = true
        let winP = theEvent.locationInWindow
        let pp = self.convert(winP, from: nil)
        let rangeStartIndex = self.characterIndexForInsertion(at: pp)
        self.setSelectedRange(NSMakeRange(rangeStartIndex, 0))
        self.firstIdx = rangeStartIndex
        setOtherSelectionAttributes()
    }

    override func otherMouseDragged(with theEvent: NSEvent) {
        let winP = theEvent.locationInWindow
        let pp = self.convert(winP, from: nil)
        let cidx = self.characterIndexForInsertion(at: pp)
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
            let rect = self.firstRect(forCharacterRange: selectedRange, actualRange: nil)
            let pt = NSMakePoint(rect.origin.x, rect.origin.y)
            let y = pt.y;
            let screenY = CGDisplayBounds(CGMainDisplayID()).size.height - y
            CGWarpMouseCursorPosition(CGPoint(x: pt.x + rect.width / 2, y: screenY - rect.height / 2))
        }
    }
    
    
    
    //MARK: TextInsert Action Overrides
    override func shouldChangeText(in affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let replacementString = replacementString else 
        {
            return true
        }
        
        let nl = replacementString.detectNewLineType()
        if nl != .none || nl != .lf {
            var newString = replacementString.stringByReplaceNewLineCharacterWith(.lf)
            if (Preference.expandTab) {
                newString = newString.stringByExpandTab(Preference.tabWidth)
            }
            return super.shouldChangeText(in: affectedCharRange, replacementString: newString)
        }
        
        var newString = replacementString
        if (Preference.expandTab) {
            newString = newString.stringByExpandTab(Preference.tabWidth)
        }
        return super.shouldChangeText(in: affectedCharRange, replacementString: newString)
    }
    
    override func insertTab(_ sender: Any?) {
        if (Preference.expandTab) {
            let tabWidth = Preference.tabWidth
            let spaces = String(repeating: " ", count: tabWidth)
            self.insertText(spaces)
        } else {
            super.insertTab(sender)
        }
    }
    
    override func insertNewline(_ sender: Any?) {
        guard let string = self.string else {
            return super.insertNewline(sender)
        }
        
        if !Preference.autoIndent {
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
            indent = string.substring(with: string.characters.index(string.startIndex, offsetBy: baseIndentRange.location) ..< string.characters.index(string.startIndex, offsetBy: baseIndentRange.location + baseIndentRange.length))
        }
        
        super.insertNewline(sender)
        
        if (indent.characters.count > 0) {
            super.insertText(indent, replacementRange: self.selectedRange())
        }
    }
}
