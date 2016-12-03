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
import Yaml

class Preference {
    
    class func loadYaml(_ yaml: Yaml) {
        if let mainBgColorHex = yaml["mainBgColor"].string,
            let mainBgColor = NSColor.from(hex: mainBgColorHex) {
            Preference.mainBgColor = mainBgColor
        }
        if let mainFgColorHex = yaml["mainFgColor"].string,
            let mainFgColor = NSColor.from(hex: mainFgColorHex) {
            Preference.mainFgColor = mainFgColor
        }

        if let subBgColorHex = yaml["subBgColor"].string,
            let subBgColor = NSColor.from(hex: subBgColorHex) {
            Preference.subBgColor = subBgColor
        }
        if let subFgColorHex = yaml["subFgColor"].string,
            let subFgColor = NSColor.from(hex: subFgColorHex) {
            Preference.subFgColor = subFgColor
        }
    }
    
    class var font: NSFont {
        set(newFont) {
            UserDefaults.standard.set(newFont.fontName, forKey: "fontName")
            UserDefaults.standard.set(Int(newFont.pointSize), forKey: "fontSize")
        }
        get {
            if let fontName = UserDefaults.standard.string(forKey: "fontName") {
                let fontSize = CGFloat(UserDefaults.standard.integer(forKey: "fontSize"))
                let f = NSFont(name: fontName, size: fontSize)
                return f ?? NSFont.systemFont(ofSize: fontSize)
            } else {
                return NSFont.systemFont(ofSize: NSFont.systemFontSize())
            }
        }
    }
    
    class var expandTab: Bool {
        set(newExpandTab) {
            UserDefaults.standard.set(newExpandTab, forKey: "expandTab")
        }
        get {
            return UserDefaults.standard.bool(forKey: "expandTab")
        }
    }
    
    class var tabWidth: Int {
        set(newTabWidth) {
            UserDefaults.standard.set(newTabWidth, forKey: "tabSpace")
        }
        get {
            return UserDefaults.standard.integer(forKey: "tabSpace")
        }
    }
    
    class var autoIndent: Bool {
        set(newAutoIndent) {
            UserDefaults.standard.set(newAutoIndent, forKey: "autoIndent")
        }
        get {
            return UserDefaults.standard.bool(forKey: "autoIndent")
        }
    }
    
    class var mainBgColor: NSColor {
        set(newColor) {
            let hex = newColor.toHex()
            UserDefaults.standard.set(hex, forKey: "mainBgColor")
        }
        get {
            if let colorStr = UserDefaults.standard.string(forKey: "mainBgColor"),
                let color = NSColor.from(hex: colorStr) {
                return color
            } else {
                return NSColor.from(hex: "#FFFEEB")!
            }
        }
    }
    
    class var mainFgColor: NSColor {
        set(newColor) {
            let hex = newColor.toHex()
            UserDefaults.standard.set(hex, forKey: "mainFgColor")
        }
        get {
            if let colorStr = UserDefaults.standard.string(forKey: "mainFgColor"),
                let color = NSColor.from(hex: colorStr) {
                return color
            } else {
                return NSColor.black
            }
        }
    }
    
    class var subBgColor: NSColor {
        set(newColor) {
            let hex = newColor.toHex()
            UserDefaults.standard.set(hex, forKey: "subBgColor")
        }
        get {
            if let colorStr = UserDefaults.standard.string(forKey: "subBgColor"),
                let color = NSColor.from(hex: colorStr) {
                return color
            } else {
                return NSColor.from(hex: "#E4FEFF")!
            }
        }
    }
    
    class var subFgColor: NSColor {
        set(newColor) {
            let hex = newColor.toHex()
            UserDefaults.standard.set(hex, forKey: "subFgColor")
        }
        get {
            if let colorStr = UserDefaults.standard.string(forKey: "subFgColor"),
                let color = NSColor.from(hex: colorStr) {
                return color
            } else {
                return NSColor.black
            }
        }
    }
}
