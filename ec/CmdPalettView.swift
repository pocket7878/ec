//
//  CmdPalettView.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/03.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

protocol CmdPalettSelectionDelgate: class {
    func onEditPalett(_ row: Int)
    func onFindPalett(_ sender: Tagger, row: Int)
    func onRunPalett(_ row: Int)
    func onDeletePalett(_ row: Int)
}


class CmdPalettView: NSTableView {
    
    weak var selectionDelegate: CmdPalettSelectionDelgate?
    var editorWC: NSWindowController?
    
    
    override func mouseDown(with theEvent: NSEvent) {
        if theEvent.modifierFlags.contains(NSEventModifierFlags.option) {
            self.rightMouseDown(with: theEvent)
        } else if theEvent.modifierFlags.contains(.command) {
            self.otherMouseDown(with: theEvent)
        } else {
            super.mouseDown(with: theEvent)
            if theEvent.clickCount >= 2 {
                let mp = self.convert(theEvent.locationInWindow, from: nil)
                let row = self.row(at: mp)
                if row >= 0 {
                    self.selectionDelegate?.onEditPalett(row)
                }
            }
        }
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        let mp = self.convert(theEvent.locationInWindow, from: nil)
        let row = self.row(at: mp)
        if row >= 0 {
            self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            self.selectionDelegate?.onFindPalett(Tagger(), row: row)
        }
    }
    
    override func otherMouseDown(with theEvent: NSEvent) {
        let mp = self.convert(theEvent.locationInWindow, from: nil)
        let row = self.row(at: mp)
        if row >= 0 {
            self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            self.selectionDelegate?.onRunPalett(row)
        }
    }
    
    override func keyDown(with theEvent: NSEvent) {
        if selectedRow >= 0 {
            let modifierCharacters = theEvent.charactersIgnoringModifiers!.unicodeScalars
            let key = Int(modifierCharacters[modifierCharacters.startIndex].value)
            if (key == NSDeleteCharacter) {
                self.selectionDelegate?.onDeletePalett(selectedRow)
            }
        }
    }
    
}
