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

protocol PreferenceHandler {
    func reloadPreference(pref: Preference)
}

struct FileTypePref {
    let path: String
    let pathSetting: Yaml
}

class Preference {
    
    static let preferenceFilePath = NSHomeDirectory().appendingPathComponent(".ec.yaml")
    
    //Preferences
    var mainBgColor: NSColor!
    var mainFgColor: NSColor!
    var subBgColor:  NSColor!
    var subFgColor:  NSColor!
    var leftBgColor: NSColor!
    var leftFgColor: NSColor!
    var rightBgColor: NSColor!
    var rightFgColor: NSColor!
    var otherBgColor: NSColor!
    var otherFgColor: NSColor!
    var font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize())
    var tabWidth: Int = 4
    var expandTab: Bool = false
    var autoIndent: Bool = false
    var fileTypes: [FileTypePref] = []
    
    enum ColorKey: String {
        case mainBg = "mainBgColor"
        case mainFg = "mainFgColor"
        case subBg = "subBgColor"
        case subFg = "subFgColor"
        case leftBg = "leftSelectBgColor"
        case leftFg = "leftSelectFgColor"
        case rightBg = "rightSelectBgColor"
        case rightFg = "rightSelectFgColor"
        case otherBg = "otherBgColor"
        case otherFg = "otherFgColor"
    }
    
    enum FontKey: String {
        case fontSize = "fontSize"
        case fontName = "fontName"
    }
    
    enum FormatKey: String {
        case expandTab = "expandTab"
        case autoIndent = "autoIndent"
        case tabWidth = "tabWidth"
    }
    
    private class func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafePointer(to: &i) {
                $0.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
            }
            if next.hashValue != i { return nil }
            i += 1
            return next
        }
    }
    
    private class func loadYamlToDic(_ yaml: Yaml) -> [String: Any] {
        var dic: [String: Any] = [:]
        
        func readIntFromYaml(_ key: String) {
            dic[key] = yaml[Yaml.string(key)].int
        }
        
        func readStringFromYaml(_ key: String) {
            dic[key] = yaml[Yaml.string(key)].string
        }
        
        func readBoolFromYaml(_ key: String) {
            dic[key] = yaml[Yaml.string(key)].bool
        }
        
        for colorKey in iterateEnum(Preference.ColorKey) {
            dic[colorKey.rawValue] = yaml[Yaml.string(colorKey.rawValue)].string
        }
        dic[FontKey.fontName.rawValue] = yaml[Yaml.string(FontKey.fontName.rawValue)].string
        dic[FontKey.fontSize.rawValue] = yaml[Yaml.string(FontKey.fontSize.rawValue)].int
        dic[FormatKey.autoIndent.rawValue] = yaml[Yaml.string(FormatKey.autoIndent.rawValue)].bool
        dic[FormatKey.expandTab.rawValue] = yaml[Yaml.string(FormatKey.expandTab.rawValue)].bool
        dic[FormatKey.tabWidth.rawValue] = yaml[Yaml.string(FormatKey.tabWidth.rawValue)].int

        return dic
    }
    
    private class func dicToPreference(dic: [String: Any]) -> Preference {
        var pref = Preference()
        
        func loadColor(_ dic: [String: Any], key: String, _ defaultColor: NSColor) -> NSColor {
            if let colorHex = dic[key] as? String,
                let color = NSColor.from(hex: colorHex) {
                return color
            } else {
                return defaultColor
            }
        }
        
        func loadFont(_ dic: [String: Any], nameKey: String, sizeKey: String) -> NSFont {
            let fontName = dic[nameKey] as? String
            let fontSize = dic[sizeKey] as? Int
            if let fname = fontName,
                let fsize = fontSize,
                let font = NSFont(name: fname, size: CGFloat(fsize)) {
                return font
            } else if let fname = fontName,
                let font = NSFont(name: fname, size: NSFont.systemFontSize()) {
                return font
            } else if let fsize = fontSize {
                return NSFont.systemFont(ofSize: CGFloat(fsize))
            } else {
                return NSFont.systemFont(ofSize: NSFont.systemFontSize())
            }
        }
        
        func loadBool(_ dic: [String: Any], key: String, _ defaultBool: Bool) -> Bool {
            return dic[key] as? Bool ?? defaultBool
        }
        
        func loadInt(_ dic: [String: Any], key: String, _ defaultInt: Int) -> Int {
            return dic[key] as? Int ?? defaultInt
        }
        
        pref.mainBgColor = loadColor(dic, key: ColorKey.mainBg.rawValue, NSColor.from(hex: "#FFFEEB")!)
        pref.mainFgColor = loadColor(dic, key: ColorKey.mainFg.rawValue, NSColor.from(hex: "#000000")!)
        pref.subBgColor = loadColor(dic, key: ColorKey.subBg.rawValue, NSColor.from(hex: "#E4FEFF")!)
        pref.subFgColor = loadColor(dic, key: ColorKey.subFg.rawValue, NSColor.from(hex: "#000000")!)
        pref.leftBgColor = loadColor(dic, key: ColorKey.leftBg.rawValue, NSColor.from(hex: "#EEEB91")!)
        pref.leftFgColor = loadColor(dic, key: ColorKey.leftFg.rawValue, NSColor.from(hex: "#000000")!)
        pref.rightBgColor = loadColor(dic, key: ColorKey.rightBg.rawValue, NSColor.from(hex: "#015B00")!)
        pref.rightFgColor = loadColor(dic, key: ColorKey.rightFg.rawValue, NSColor.from(hex: "#FFFFFF")!)
        pref.otherBgColor = loadColor(dic, key: ColorKey.otherBg.rawValue, NSColor.from(hex: "#A00000")!)
        pref.otherFgColor = loadColor(dic, key: ColorKey.otherFg.rawValue, NSColor.from(hex: "#FFFFFF")!)
        pref.font = loadFont(dic, nameKey: FontKey.fontName.rawValue, sizeKey: FontKey.fontSize.rawValue)
        pref.tabWidth = loadInt(dic, key: FormatKey.tabWidth.rawValue, 4)
        pref.autoIndent = loadBool(dic, key: FormatKey.autoIndent.rawValue, false)
        pref.expandTab = loadBool(dic, key: FormatKey.expandTab.rawValue, false)
        
        return pref
    }
    
    class func loadDefaultYaml(_ yaml: Yaml) -> Preference {
        return dicToPreference(dic: loadYamlToDic(yaml))
    }
    
    class func loadYaml(_ yaml: Yaml, for filePath: String) -> Preference {
        var dic: [String: Any] = loadYamlToDic(yaml)
        if let fileTypeYamls = yaml[Yaml.string("fileTypes")].array {
            for fileTypeYaml in fileTypeYamls {
                NSLog("Path pattern \(fileTypeYaml[Yaml.string("path")].string))")
                if let pathPattern = fileTypeYaml[Yaml.string("path")].string, filePath.pregMatche(pattern: pathPattern) {
                    for colorKey in iterateEnum(Preference.ColorKey.self) {
                        dic.updateIfNotNull(key: colorKey.rawValue, newVal: fileTypeYaml[Yaml.string(colorKey.rawValue)].string)
                    }
                    dic.updateIfNotNull(key: FontKey.fontName.rawValue, newVal: fileTypeYaml[Yaml.string(FontKey.fontName.rawValue)].string)
                    dic.updateIfNotNull(key: FontKey.fontSize.rawValue, newVal: fileTypeYaml[Yaml.string(FontKey.fontSize.rawValue)].int)
                    dic.updateIfNotNull(key: FormatKey.autoIndent.rawValue, newVal:  fileTypeYaml[Yaml.string(FormatKey.autoIndent.rawValue)].bool)
                    dic.updateIfNotNull(key: FormatKey.expandTab.rawValue, newVal: fileTypeYaml[Yaml.string(FormatKey.expandTab.rawValue)].bool)
                    dic.updateIfNotNull(key: FormatKey.tabWidth.rawValue, newVal: fileTypeYaml[Yaml.string(FormatKey.tabWidth.rawValue)].int)
                    break
                }
            }
        }
        return dicToPreference(dic: dic)
    }
}
