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
    func onFindPalett(sender: Tagger, row: Int)
    func onRunPalett(row: Int)
    func onDeletePalett(row: Int)
}


class CmdPalettView: NSTableView {
    
    weak var selectionDelegate: CmdPalettSelectionDelgate?
    
    override func rightMouseDown(theEvent: NSEvent) {
        let mp = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        let row = self.rowAtPoint(mp)
        if row >= 0 {
            self.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
            self.selectionDelegate?.onFindPalett(Tagger(), row: row)
        }
    }
    
    override func otherMouseDown(theEvent: NSEvent) {
        let mp = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        let row = self.rowAtPoint(mp)
        if row >= 0 {
            self.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
            self.selectionDelegate?.onRunPalett(row)
        }
    }
    
    override func keyDown(theEvent: NSEvent) {
        if selectedRow >= 0 {
            let modifierCharacters = theEvent.charactersIgnoringModifiers!.unicodeScalars
            let key = Int(modifierCharacters[modifierCharacters.startIndex].value)
            if (key == NSDeleteCharacter) {
                self.selectionDelegate?.onDeletePalett(selectedRow)
            }
        }
    }
    
}