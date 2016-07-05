//
//  Preference.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/05.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKitScripting

class Preference {
    class func font() -> NSFont {
        if let fontName = NSUserDefaults.standardUserDefaults().stringForKey("fontName") {
            let fontSize = CGFloat(NSUserDefaults.standardUserDefaults().integerForKey("fontSize"))
            let f = NSFont(name: fontName, size: fontSize)
            return f ?? NSFont.systemFontOfSize(fontSize)
        } else {
            return NSFont.systemFontOfSize(NSFont.systemFontSize())
        }
    }
    
    class func expandTab() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("expandTab")
    }
    
    class func tabWidth() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey("tabSpace")
    }
}