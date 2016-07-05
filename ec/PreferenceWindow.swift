//
//  PreferenceWindow.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/04.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class PreferenceWindow: NSWindow {
    override func cancelOperation(sender: AnyObject?) {
        self.close()
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