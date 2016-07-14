//
//  CmdPalett.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/29.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import AppKit

class CmdPalett: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var palett: [String] = []
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return palett.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return palett[row]
    }
    
    func replaceCmd(cmd: String, at: Int) {
        palett[at] = cmd
        let notification = NSNotification(name: "CmdPalettChangedNotification", object: nil)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    func addCmd(cmd: String) {
        palett.append(cmd)
        let notification = NSNotification(name: "CmdPalettChangedNotification", object: nil)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeViewWithIdentifier("cell", owner: nil) as! CmdPalettCellView
        cellView.cmdLabel.stringValue = palett[row]
        return cellView
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let cellView = tableView.makeViewWithIdentifier("cell", owner: nil) as! CmdPalettCellView
        cellView.cmdLabel.stringValue = palett[row]
        return cellView.fittingSize.height
    }
}