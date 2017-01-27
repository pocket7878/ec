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
import RxSwift

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
    
    let pref: Variable<Preference?> = Variable(nil)
    let disposeBag = DisposeBag()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        pref.asObservable()
            .subscribe(onNext: { pref in
                if pref != nil {
                    self.setDefaultSelectionAttributes()
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    
    //Selected color setup
    func setDefaultSelectionAttributes() {
        if let bg = pref.value?.leftBgColor,
            let fg = pref.value?.leftFgColor {
            self.selectedTextAttributes = [
                NSBackgroundColorAttributeName: bg,
                NSForegroundColorAttributeName: fg
            ]
        }
    }
    
    func setRightSelectionAttributes() {
        if let bg = pref.value?.rightBgColor,
            let fg = pref.value?.rightFgColor {
            self.selectedTextAttributes = [
                NSBackgroundColorAttributeName: bg,
                NSForegroundColorAttributeName: fg
            ]
        }
    }
    
    func setOtherSelectionAttributes() {
        if let bg = pref.value?.otherBgColor,
            let fg = pref.value?.otherFgColor {
            self.selectedTextAttributes = [
                NSBackgroundColorAttributeName: bg,
                NSForegroundColorAttributeName: fg
            ]
        }
    }
    
    //MARK: Expand Selection
    func resolveFilePath(_ filename: String) -> String? {
        if let workingFolder = self.workingFolderDataSource?.workingFolder() {
            let fileManager = FileManager.default
            var filePath = ""
            if filename.hasPrefix("/") {
                filePath = filename
            } else {
                filePath = workingFolder.appendingPathComponent(filename)
            }
            if fileManager.fileExists(atPath: filePath) {
                return filePath
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func parseFileAddr(str: String) -> FileAddr? {
        let charview = str.characters
        let topIndex = charview.startIndex
        let topChar = charview[topIndex]
        if isFileChar(topChar) {
            var colon: String.CharacterView.Index? = nil
            var fileBottomIndex = topIndex
            if topChar != ":" {
                while fileBottomIndex != charview.index(before: charview.endIndex) {
                    let nextIdx = charview.index(after: fileBottomIndex)
                    let nextChar = charview[nextIdx]
                    if isFileChar(nextChar), nextChar != ":" {
                        fileBottomIndex = nextIdx
                    } else if isFileChar(nextChar), nextChar == ":" {
                        colon = nextIdx
                        break
                    } else {
                        break
                    }
                }
            } else {
                colon = topIndex
            }
            //Get File Path
            var filePath: String? = nil
            if colon != topIndex,
                fileBottomIndex >= topIndex {
                let filename = str.substring(with: topIndex ..< charview.index(after: fileBottomIndex))
                if let resolvedPath = resolveFilePath(filename) {
                    filePath = resolvedPath
                } else {
                    NSLog("File \(filename) not found")
                    return nil
                }
            }
            //Get address if colon is exists
            var addr: Addr? = nil
            if let colon = colon, colon != charview.index(before: charview.endIndex) {
                let addressTopIndex = charview.index(after: colon)
                let addressTopChar = charview[addressTopIndex]
                var addressBottomIndex = addressTopIndex
                if isAddrChar(addressTopChar) || isRegexChar(addressTopChar) {
                    while addressBottomIndex != charview.index(before: charview.endIndex) {
                        let nextIdx = charview.index(after: addressBottomIndex)
                        let nextChar = charview[nextIdx]
                        if isAddrChar(nextChar) || isRegexChar(nextChar) {
                            addressBottomIndex = nextIdx
                        } else {
                            break
                        }
                    }
                }
                if addressBottomIndex >= addressTopIndex {
                    let addrStr = str.substring(with: addressTopIndex ..< charview.index(after: addressBottomIndex))
                    do {
                        addr = try addrParser.run(sourceName: "addrStr", input: addrStr)
                    } catch {
                        NSLog("\(error)")
                        return nil
                    }
                }
            }
            
            if filePath != nil || addr != nil {
                return FileAddr(filepath: filePath, addr: addr)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func expandFile(_ charIdx: Int) -> FileAddr? {
        if let charview = self.string?.characters {
            
            var baseIdx = charview.index(charview.startIndex, offsetBy: charIdx, limitedBy: charview.endIndex) ?? charview.index(before: charview.endIndex)
            if baseIdx == charview.endIndex {
                baseIdx = charview.index(before: charview.endIndex)
            }
            let baseChar = charview[baseIdx]
            
            var topIndex = baseIdx
            if isFileChar(baseChar) {
                while topIndex != charview.startIndex {
                    let beforeIdx = charview.index(before: topIndex)
                    let beforeChar = charview[beforeIdx]
                    if isFileChar(beforeChar) {
                        topIndex = beforeIdx
                    } else {
                        break
                    }
                }
            }
            
            if topIndex == charview.endIndex {
                return nil
            } else {
                var colon: String.CharacterView.Index? = nil
                var fileBottomIndex = topIndex
                let topChar = charview[topIndex]
                if topChar != ":" {
                    while fileBottomIndex != charview.index(before: charview.endIndex) {
                        let nextIdx = charview.index(after: fileBottomIndex)
                        let nextChar = charview[nextIdx]
                        if isFileChar(nextChar), nextChar != ":" {
                            fileBottomIndex = nextIdx
                        } else if isFileChar(nextChar), nextChar == ":" {
                            colon = nextIdx
                            break
                        } else {
                            break
                        }
                    }
                } else {
                    colon = topIndex
                }
                //Get File Path
                var filePath: String? = nil
                if colon != topIndex,
                    fileBottomIndex >= topIndex,
                    let filename = self.string?.substring(with: topIndex ..< charview.index(after: fileBottomIndex)) {
                    if let resolvedPath = resolveFilePath(filename) {
                        filePath = resolvedPath
                    } else {
                        NSLog("File \(filename) not found")
                        return nil
                    }
                }
                //Get address if colon is exists
                var addr: Addr? = nil
                if let colon = colon, colon != charview.index(before: charview.endIndex) {
                    let addressTopIndex = charview.index(after: colon)
                    let addressTopChar = charview[addressTopIndex]
                    var addressBottomIndex = addressTopIndex
                    if isAddrChar(addressTopChar) || isRegexChar(addressTopChar) {
                        while addressBottomIndex != charview.index(before: charview.endIndex) {
                            let nextIdx = charview.index(after: addressBottomIndex)
                            let nextChar = charview[nextIdx]
                            if isAddrChar(nextChar) || isRegexChar(nextChar) {
                                addressBottomIndex = nextIdx
                            } else {
                                break
                            }
                        }
                    }
                    if addressBottomIndex >= addressTopIndex,
                        let addrStr = self.string?.substring(with: addressTopIndex ..< charview.index(after: addressBottomIndex)) {
                        do {
                            addr = try addrParser.run(sourceName: "addrStr", input: addrStr)
                        } catch {
                            NSLog("\(error)")
                            return nil
                        }
                    }
                }
                
                if filePath != nil || addr != nil {
                    return FileAddr(filepath: filePath, addr: addr)
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
                    if let fileAddr = self.parseFileAddr(str: selectedStr) {
                        self.setSelectedRange(selectedRange)
                        self.selectionDelegate?.onFileAddrSelection(fileAddr, by: theEvent)
                    } else {
                        self.setSelectedRange(selectedRange)
                        self.selectionDelegate?.onRightMouseSelection(selectedStr, by: theEvent)
                    }
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
            if let expandTab = pref.value?.expandTab, expandTab, let tabWidth = pref.value?.tabWidth {
                newString = newString.stringByExpandTab(tabWidth)
            }
            return super.shouldChangeText(in: affectedCharRange, replacementString: newString)
        }
        
        var newString = replacementString
        if let expandTab = pref.value?.expandTab, expandTab, let tabWidth = pref.value?.tabWidth {
            newString = newString.stringByExpandTab(tabWidth)
        }
        return super.shouldChangeText(in: affectedCharRange, replacementString: newString)
    }
    
    override func insertTab(_ sender: Any?) {
        if let expandTab = pref.value?.expandTab, expandTab, let tabWidth = pref.value?.tabWidth {
            let tabWidth = tabWidth
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
        
        if let autoIndent = pref.value?.autoIndent, !autoIndent {
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
    
    //MARK: Find String
    func findBackwardString(_ str: String) {
        do {
            let regex = try NSRegularExpression(pattern: str, options: [
                NSRegularExpression.Options.ignoreMetacharacters
                ])
            var selectedRange = self.selectedRange()
            if selectedRange.location == NSNotFound {
                selectedRange = NSMakeRange(0, 0)
            }
            let selectionHead = selectedRange.location
            let selectionEnd = selectedRange.location + selectedRange.length
            let forwardRange = NSMakeRange(selectionEnd, self.string!.characters.count - selectionEnd)
            let backwardRange = NSMakeRange(0, selectionHead)
            if let lastBackwardMatch = regex.matches(in: self.string!, options: [], range: backwardRange).last {
                self.setSelectedRange(lastBackwardMatch.range)
                self.scrollToSelection()
                self.moveMouseCursorToSelectedRange()
            } else if let lastForwardMatch = regex.matches(in: self.string!, options: [], range: forwardRange).last {
                self.setSelectedRange(lastForwardMatch.range)
                self.scrollToSelection()
                self.moveMouseCursorToSelectedRange()
            }
        } catch {
            NSLog("\(error)")
        }
    }
    
    func findString(_ str: String) {
        do {
            let regex = try NSRegularExpression(pattern: str, options: [
                NSRegularExpression.Options.ignoreMetacharacters
                ])
            var selectedRange = self.selectedRange()
            if selectedRange.location == NSNotFound {
                selectedRange = NSMakeRange(0, 0)
            }
            let selectionHead = selectedRange.location
            let selectionEnd = selectedRange.location + selectedRange.length
            let forwardRange = NSMakeRange(selectionEnd, self.string!.characters.count - selectionEnd)
            let backwardRange = NSMakeRange(0, selectionHead)
            if let firstMatchRange: NSRange = regex.firstMatch(in: self.string!, options: [], range: forwardRange)?.range {
                self.setSelectedRange(firstMatchRange)
                self.scrollToSelection()
                self.moveMouseCursorToSelectedRange()
            } else if let firstMatchRange: NSRange = regex.firstMatch(in: self.string!, options: [], range: backwardRange)?.range {
                self.setSelectedRange(firstMatchRange)
                self.scrollToSelection()
                self.moveMouseCursorToSelectedRange()
            }
        } catch {
            NSLog("\(error)")
        }
    }
}
