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
    func onRightClick(idx: Int)
}


class CmdPalettView: NSTableView {
    
    weak var selectionDelegate: CmdPalettSelectionDelgate?
    
    override func menuForEvent(event: NSEvent) -> NSMenu? {
        let mp = self.convertPoint(event.locationInWindow, fromView: nil)
        let row = self.rowAtPoint(mp)
        
        self.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
        
        switch(event.type) {
        case .RightMouseDown:
            self.selectionDelegate?.onRightClick(row)
        default:
            break
        }
        
        return nil
    }
}