//
//  ECSubTextView.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/12/03.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa

class ECSubTextView: ECTextView, PreferenceHandler {
    override func insertText(_ string: Any, replacementRange: NSRange) {
        if let attrStr = string as? NSAttributedString {
            let mutAttrStr = NSMutableAttributedString(attributedString: attrStr)
            if let color = pref.value?.subFgColor {
                mutAttrStr.setAttributes(
                    [NSForegroundColorAttributeName: color],
                    range: NSMakeRange(0, mutAttrStr.length))
            }
            super.insertText(mutAttrStr, replacementRange: replacementRange)
        } else if let nsstr = string as? NSString {
            let mutAttrStr = NSMutableAttributedString(string: String(nsstr))
            if let color = pref.value?.subFgColor {
                mutAttrStr.setAttributes(
                    [NSForegroundColorAttributeName: color],
                    range: NSMakeRange(0, mutAttrStr.length))
            }
            super.insertText(mutAttrStr, replacementRange: replacementRange)
        } else if let str = string as? String {
            let mutAttrStr = NSMutableAttributedString(string: str)
            if let color = pref.value?.subFgColor {
                mutAttrStr.setAttributes(
                    [NSForegroundColorAttributeName: color],
                    range: NSMakeRange(0, mutAttrStr.length))
            }
            super.insertText(mutAttrStr, replacementRange: replacementRange)
        } else {
            super.insertText(string, replacementRange: replacementRange)
        }
    }
    
    func reloadPreference(pref: Preference) {
        self.pref.value = pref
        self.backgroundColor = pref.subBgColor
        self.textColor = pref.subFgColor
        self.insertionPointColor = pref.subFgColor
        self.font = pref.font
        if let storage = self.textStorage {
            storage.addAttributes([
                NSForegroundColorAttributeName: pref.subFgColor,
                NSFontAttributeName: pref.font
            ], range: NSMakeRange(0, storage.length))
        }
    }
}
