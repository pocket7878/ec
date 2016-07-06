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
        let font = Preference.font()
        fontNameLabel.stringValue = "\(Int(font.pointSize))pt \(font.fontName)"
        tabWidthField.integerValue = Preference.tabWidth()
        tabWidthStepper.integerValue = Preference.tabWidth()
        if Preference.expandTab() {
            expandCheckBtn.state = NSOnState
        } else {
            expandCheckBtn.state = NSOffState
        }
        tabWidthStepper.enabled = Preference.expandTab()
        tabWidthField.enabled = Preference.expandTab()
        if Preference.autoIndent() {
            autoIndentCheckBox.state = NSOnState
        } else {
            autoIndentCheckBox.state = NSOffState
        }
    }
    
    @IBAction func changeFontBtnTouched(sender: AnyObject) {
        let fontPanel = NSFontManager.sharedFontManager().fontPanel(true)
        fontPanel?.makeKeyAndOrderFront(self)
    }
    
    override func changeFont(sender: AnyObject?) {
        if let fmanager = sender as? NSFontManager {
            let newFont = fmanager.convertFont(Preference.font())
            fontNameLabel.stringValue = "\(Int(newFont.pointSize))pt \(newFont.fontName)"
            NSUserDefaults.standardUserDefaults().setObject(newFont.fontName, forKey: "fontName")
            NSUserDefaults.standardUserDefaults().setInteger(Int(newFont.pointSize), forKey: "fontSize")
        }
    }
    
    @IBAction func tabWidthChanged(sender: NSStepper) {
        let width = sender.integerValue
        tabWidthField.stringValue = "\(width)"
        NSUserDefaults.standardUserDefaults().setInteger(width, forKey: "tabSpace")
    }
    
    @IBAction func tabWidthEdited(sender: NSTextField) {
        let width = sender.integerValue
        tabWidthStepper.integerValue = width
        NSUserDefaults.standardUserDefaults().setInteger(width, forKey: "tabSpace")
    }
    
    @IBAction func expandTabCheckBoxChanged(sender: NSButton) {
        if (sender.state == NSOnState) {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "expandTab")
            tabWidthStepper.enabled = true
            tabWidthField.enabled = true
        } else if (sender.state == NSOffState) {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "expandTab")
            tabWidthField.enabled = false
            tabWidthStepper.enabled = false
        }
    }
    
    //MARK: AutoIndent
    @IBAction func autoIndentCheckBoxChanged(sender: NSButton) {
        if (sender.state == NSOnState) {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "autoIndent")
        } else if (sender.state == NSOffState) {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "autoIndent")
        }
    }
}