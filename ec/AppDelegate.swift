//
//  AppDelegate.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/28.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var prefWC: NSWindowController?
    var commandWCs: Dictionary<String, NSWindowController> = [:]
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let systemFont = NSFont.systemFont(ofSize: NSFont.systemFontSize())
        let appDefaults: [String: Any] = [
            "fontName": systemFont.fontName,
            "fontSize": Int(systemFont.pointSize),
            "expandTab": false,
            "tabSpace": 4,
            "autoIndent": false
        ]
        UserDefaults.standard.register(defaults: appDefaults)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }

    @IBAction func openPreferenceWindow(_ sender: NSMenuItem) {
        let storyBoard = NSStoryboard(name: "Preference", bundle: nil)
        let windowController = storyBoard.instantiateController(withIdentifier: "PreferenceWC") as! NSWindowController
        prefWC = windowController
        windowController.showWindow(nil)
        windowController.becomeFirstResponder()
    }
}

