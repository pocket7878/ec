//
//  Preference.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/05.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class Preference {
    class func font() -> NSFont {
        if let fontName = UserDefaults.standard.string(forKey: "fontName") {
            let fontSize = CGFloat(UserDefaults.standard.integer(forKey: "fontSize"))
            let f = NSFont(name: fontName, size: fontSize)
            return f ?? NSFont.systemFont(ofSize: fontSize)
        } else {
            return NSFont.systemFont(ofSize: NSFont.systemFontSize())
        }
    }
    
    class func expandTab() -> Bool {
        return UserDefaults.standard.bool(forKey: "expandTab")
    }
    
    class func tabWidth() -> Int {
        return UserDefaults.standard.integer(forKey: "tabSpace")
    }
    
    class func autoIndent() -> Bool {
        return UserDefaults.standard.bool(forKey: "autoIndent")
    }
}
