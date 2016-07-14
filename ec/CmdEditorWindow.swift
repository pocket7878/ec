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

class CmdEditorWindow: NSWindow {
    override func cancelOperation(sender: AnyObject?) {
        self.close()
        NSApplication.sharedApplication().stopModal()
    }
    
    override func validateUserInterfaceItem(anItem: NSValidatedUserInterfaceItem) -> Bool {
        let action = anItem.action()
        if (action == #selector(toggleToolbarShown(_:))) {
            return false
        } else {
            return super.validateUserInterfaceItem(anItem)
        }
    }
}