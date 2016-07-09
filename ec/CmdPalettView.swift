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
    func find(sender: Tagger, row: Int)
    func run(row: Int)
    func delete(row: Int)
}


class CmdPalettView: NSTableView {
    
    weak var selectionDelegate: CmdPalettSelectionDelgate?
    
    override func rightMouseDown(theEvent: NSEvent) {
        let mp = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        let row = self.rowAtPoint(mp)
        self.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
        self.selectionDelegate?.find(Tagger(), row: row)
    }
    
    override func otherMouseDown(theEvent: NSEvent) {
        let mp = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        let row = self.rowAtPoint(mp)
        self.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
        self.selectionDelegate?.run(row)
    }
    
}