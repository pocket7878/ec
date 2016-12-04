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
    func reloadPreference()
}

class Preference {
    
    static let preferenceFilePath = NSHomeDirectory().appendingPathComponent(".ec.yaml")
    
    //PreferenceEntries
    static private let mainBgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let mainBgColorHex = yaml["mainBgColor"].string,
                let color = NSColor.from(hex: mainBgColorHex) {
                return color
            } else {
                return NSColor.from(hex: "#FFFEEB")!
            }
    })
    static private let mainFgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let mainFgColorHex = yaml["mainFgColor"].string,
                let color = NSColor.from(hex: mainFgColorHex) {
                return color
            } else {
                return NSColor.black
            }
    })
    static private let subBgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let subBgColorHex = yaml["subBgColor"].string,
                let color = NSColor.from(hex: subBgColorHex) {
                return color
            } else {
                return NSColor.from(hex: "#E4FEFF")!
            }
    })
    static private let subFgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let subFgColorHex = yaml["subFgColor"].string,
                let color = NSColor.from(hex: subFgColorHex) {
                return color
            } else {
                return NSColor.black
            }
    })
    static private let leftSelectBgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let subBgColorHex = yaml["leftSelectBgColor"].string,
                let color = NSColor.from(hex: subBgColorHex) {
                return color
            } else {
                return NSColor(red: 0.933, green: 0.921, blue: 0.570, alpha: 1.0)
            }
    })
    static private let leftSelectFgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let subFgColorHex = yaml["leftSelectFgColor"].string,
                let color = NSColor.from(hex: subFgColorHex) {
                return color
            } else {
                return NSColor.black
            }
    })
    static private let rightSelectBgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let subBgColorHex = yaml["rightSelectBgColor"].string,
                let color = NSColor.from(hex: subBgColorHex) {
                return color
            } else {
                return NSColor(red: 0.003, green: 0.356, blue: 0.0, alpha: 1.0)
            }
    })
    static private let rightSelectFgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let subFgColorHex = yaml["rightSelectFgColor"].string,
                let color = NSColor.from(hex: subFgColorHex) {
                return color
            } else {
                return NSColor.white
            }
    })
    static private let otherSelectBgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let subBgColorHex = yaml["otherSelectBgColor"].string,
                let color = NSColor.from(hex: subBgColorHex) {
                return color
            } else {
                return NSColor(red: 0.627, green: 0.0, blue: 0.0, alpha: 1.0)
            }
    })
    static private let otherSelectFgEntry: PreferenceEntry<NSColor> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSColor in
            if let subFgColorHex = yaml["otherSelectFgColor"].string,
                let color = NSColor.from(hex: subFgColorHex) {
                return color
            } else {
                return NSColor.white
            }
    })
    static private let fontEntry: PreferenceEntry<NSFont> = PreferenceEntry(
        loader: { (yaml: Yaml) -> NSFont in
            let fontName = yaml["fontName"].string
            let fontSize = yaml["fontSize"].double
            if let fname = fontName,
                let fsize = fontSize {
                return NSFont(name: fname, size: CGFloat(fsize))!
            } else if let fname = fontName {
                return NSFont(name: fname, size: NSFont.systemFontSize())!
            } else if let fsize = fontSize {
                return NSFont.systemFont(ofSize: CGFloat(fsize))
            } else {
                return NSFont.systemFont(ofSize: NSFont.systemFontSize())
            }
    })
    static private let tabWidthEntry: PreferenceEntry<Int> = PreferenceEntry(
        loader: { (yaml: Yaml) -> Int in
            return yaml["tabWidth"].int ?? 4
    })
    static private let expandTabEntry: PreferenceEntry<Bool> = PreferenceEntry(
        loader: { (yaml: Yaml) -> Bool in
            return yaml["expandTab"].bool ?? false
    })
    static private let autoIndentEntry: PreferenceEntry<Bool> = PreferenceEntry(
        loader: { (yaml: Yaml) -> Bool in
            return yaml["autoIndent"].bool ?? false
    })
    
    //Preferences
    static var mainBgColor: NSColor!
    static var mainFgColor: NSColor!
    static var subBgColor: NSColor!
    static var subFgColor: NSColor!
    static var leftBgColor: NSColor!
    static var leftFgColor: NSColor!
    static var rightBgColor: NSColor!
    static var rightFgColor: NSColor!
    static var otherBgColor: NSColor!
    static var otherFgColor: NSColor!
    static var font: NSFont!
    static var tabWidth: Int = 4
    static var expandTab: Bool = false
    static var autoIndent: Bool = false
    
    
    class func loadYaml(_ yaml: Yaml) {
        mainBgColor = mainBgEntry.loader(yaml)
        mainFgColor = mainFgEntry.loader(yaml)
        subBgColor = subBgEntry.loader(yaml)
        subFgColor = subFgEntry.loader(yaml)
        font = fontEntry.loader(yaml)
        tabWidth = tabWidthEntry.loader(yaml)
        expandTab = expandTabEntry.loader(yaml)
        autoIndent = autoIndentEntry.loader(yaml)
        leftBgColor = leftSelectBgEntry.loader(yaml)
        leftFgColor = leftSelectFgEntry.loader(yaml)
        rightBgColor = rightSelectBgEntry.loader(yaml)
        rightFgColor = rightSelectFgEntry.loader(yaml)
        otherBgColor = otherSelectBgEntry.loader(yaml)
        otherFgColor = otherSelectFgEntry.loader(yaml)
    }
}
