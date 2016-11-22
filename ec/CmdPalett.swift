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
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return palett.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return palett[row]
    }
    
    func replaceCmd(_ cmd: String, at: Int) {
        palett[at] = cmd
        let notification = Notification(name: Notification.Name(rawValue: "CmdPalettChangedNotification"), object: nil)
        NotificationCenter.default.post(notification)
    }
    
    func addCmd(_ cmd: String) {
        palett.append(cmd)
        let notification = Notification(name: Notification.Name(rawValue: "CmdPalettChangedNotification"), object: nil)
        NotificationCenter.default.post(notification)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.make(withIdentifier: "cell", owner: nil) as! CmdPalettCellView
        cellView.cmdLabel.stringValue = palett[row]
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let cellView = tableView.make(withIdentifier: "cell", owner: nil) as! CmdPalettCellView
        cellView.cmdLabel.stringValue = palett[row]
        return cellView.fittingSize.height
    }
}
