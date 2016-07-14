//
//  CmdEditorWindow.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/14.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class CmdEditorWindow: NSWindow, CmdEditDelegate {
    
    var row: Int?
    weak var palett: CmdPalett?
    
    override func cancelOperation(sender: AnyObject?) {
        closeAndStopModal()
    }
    
    override func validateUserInterfaceItem(anItem: NSValidatedUserInterfaceItem) -> Bool {
        let action = anItem.action()
        if (action == #selector(toggleToolbarShown(_:))) {
            return false
        } else {
            return super.validateUserInterfaceItem(anItem)
        }
    }
    
    func closeAndStopModal() {
        self.close()
        NSApplication.sharedApplication().stopModal()
    }
    
    //MARK: CmdEditDelegate
    func onCmdEditSave(newCmd: String) {
        if let row = row,
            let palett = palett {
            palett.replaceCmd(newCmd, at: row)
        }
        closeAndStopModal()
    }
    
    func onCmdEditCancel() {
        closeAndStopModal()
    }
}