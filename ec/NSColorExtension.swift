//
//  NSColorExtension.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/12/03.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {
    class func from(hex: String) -> NSColor? {
        let colorStr = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: colorStr)
        var color: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        } else {
            NSLog("Error: Failed to scan NSColor from hex string: \(hex)")
            return nil
        }
    }
    
    func toHex() -> String {
        let r = Int(self.redComponent * 0xFF)
        let g = Int(self.greenComponent * 0xFF)
        let b = Int(self.blueComponent * 0xFF)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
