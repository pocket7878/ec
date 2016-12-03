//
//  PreferenceViewController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/04.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class PreferenceViewController: NSViewController {
    
    @IBOutlet weak var fontNameLabel: NSTextField!
    @IBOutlet weak var tabWidthField: NSTextField!
    @IBOutlet weak var tabWidthStepper: NSStepper!
    @IBOutlet weak var expandCheckBtn: NSButton!
    @IBOutlet weak var autoIndentCheckBox: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        let font = Preference.font
        fontNameLabel.stringValue = "\(Int(font.pointSize))pt \(font.fontName)"
        tabWidthField.integerValue = Preference.tabWidth
        tabWidthStepper.integerValue = Preference.tabWidth
        if Preference.expandTab {
            expandCheckBtn.state = NSOnState
        } else {
            expandCheckBtn.state = NSOffState
        }
        tabWidthStepper.isEnabled = Preference.expandTab
        tabWidthField.isEnabled = Preference.expandTab
        if Preference.autoIndent {
            autoIndentCheckBox.state = NSOnState
        } else {
            autoIndentCheckBox.state = NSOffState
        }
    }
    
    @IBAction func changeFontBtnTouched(_ sender: NSButton) {
        self.view.window?.makeFirstResponder(self)
        NSFontManager.shared().orderFrontFontPanel(self)
    }
    
    override func changeFont(_ sender: Any?) {
        if let fmanager = sender as? NSFontManager {
            let newFont = fmanager.convert(Preference.font)
            fontNameLabel.stringValue = "\(Int(newFont.pointSize))pt \(newFont.fontName)"
            UserDefaults.standard.set(newFont.fontName, forKey: "fontName")
            UserDefaults.standard.set(Int(newFont.pointSize), forKey: "fontSize")
        }
    }
    
    @IBAction func tabWidthChanged(_ sender: NSStepper) {
        let width = sender.integerValue
        tabWidthField.stringValue = "\(width)"
        UserDefaults.standard.set(width, forKey: "tabSpace")
    }
    
    @IBAction func tabWidthEdited(_ sender: NSTextField) {
        let width = sender.integerValue
        tabWidthStepper.integerValue = width
        UserDefaults.standard.set(width, forKey: "tabSpace")
    }
    
    @IBAction func expandTabCheckBoxChanged(_ sender: NSButton) {
        if (sender.state == NSOnState) {
            UserDefaults.standard.set(true, forKey: "expandTab")
            tabWidthStepper.isEnabled = true
            tabWidthField.isEnabled = true
        } else if (sender.state == NSOffState) {
            UserDefaults.standard.set(false, forKey: "expandTab")
            tabWidthField.isEnabled = false
            tabWidthStepper.isEnabled = false
        }
    }
    
    //MARK: AutoIndent
    @IBAction func autoIndentCheckBoxChanged(_ sender: NSButton) {
        if (sender.state == NSOnState) {
            UserDefaults.standard.set(true, forKey: "autoIndent")
        } else if (sender.state == NSOffState) {
            UserDefaults.standard.set(false, forKey: "autoIndent")
        }
    }
}
