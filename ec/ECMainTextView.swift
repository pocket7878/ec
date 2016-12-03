//
//  ECMainTextView.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/12/03.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa

class ECMainTextView: ECTextView, PreferenceHandler {
    
    override func insertText(_ string: Any, replacementRange: NSRange) {
        let color = Preference.mainFgColor
        if let attrStr = string as? NSAttributedString {
            let mutAttrStr = NSMutableAttributedString(attributedString: attrStr)
            mutAttrStr.setAttributes(
                [NSForegroundColorAttributeName: color],
                range: NSMakeRange(0, mutAttrStr.length))
            super.insertText(mutAttrStr, replacementRange: replacementRange)
        } else if let nsstr = string as? NSString {
            let mutAttrStr = NSMutableAttributedString(string: String(nsstr))
            mutAttrStr.setAttributes(
                [NSForegroundColorAttributeName: color],
                range: NSMakeRange(0, mutAttrStr.length))
            super.insertText(mutAttrStr, replacementRange: replacementRange)
        } else if let str = string as? String {
            let mutAttrStr = NSMutableAttributedString(string: str)
            mutAttrStr.setAttributes(
                [NSForegroundColorAttributeName: color],
                range: NSMakeRange(0, mutAttrStr.length))
            super.insertText(mutAttrStr, replacementRange: replacementRange)
        } else {
            super.insertText(string, replacementRange: replacementRange)
        }
    }
    
    func reloadPreference() {
        self.backgroundColor = Preference.mainBgColor
        self.textColor = Preference.mainFgColor
        self.insertionPointColor = Preference.mainFgColor
        self.font = Preference.font
        if let storage = self.textStorage {
            storage.addAttributes([NSForegroundColorAttributeName: Preference.mainFgColor], range: NSMakeRange(0, storage.length))
        }
    }
}
