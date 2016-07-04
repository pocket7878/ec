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
    func find(sender: NSMenuItem, row: Int)
    func run(row: Int)
    func delete(row: Int)
}


class CmdPalettView: NSTableView {
    
    weak var selectionDelegate: CmdPalettSelectionDelgate?
    
    override func menuForEvent(event: NSEvent) -> NSMenu? {
        let mp = self.convertPoint(event.locationInWindow, fromView: nil)
        let row = self.rowAtPoint(mp)
        
        if (row >= 0) {
            self.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Find", action: #selector(CmdPalettView.find(_:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Run", action: #selector(CmdPalettView.run), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Delete", action: #selector(CmdPalettView.delete), keyEquivalent: ""))
            return menu
        } else {
            return nil
        }
        return nil
    }
    

    func find(sender: NSMenuItem) {
        let row = self.selectedRow
        self.selectionDelegate?.find(sender, row: row)
    }
    
    func run(sender: NSMenuItem) {
        let row = self.selectedRow
        self.selectionDelegate?.run(row)
    }
    
    func delete(sender: NSMenuItem) {
        let row = self.selectedRow
        self.selectionDelegate?.delete(row)
    }
}