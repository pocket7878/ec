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
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        let systemFont = NSFont.systemFontOfSize(NSFont.systemFontSize())
        let appDefaults: [String: AnyObject] = [
            "fontName": systemFont.fontName,
            "fontSize": Int(systemFont.pointSize),
            "expandTab": false,
            "tabSpace": 4,
            "autoIndent": false,
        ]
        NSUserDefaults.standardUserDefaults().registerDefaults(appDefaults)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func applicationShouldOpenUntitledFile(sender: NSApplication) -> Bool {
        return false
    }

    @IBAction func openPreferenceWindow(sender: NSMenuItem) {
        let storyBoard = NSStoryboard(name: "Preference", bundle: nil)
        let windowController = storyBoard.instantiateControllerWithIdentifier("PreferenceWC") as! NSWindowController
        prefWC = windowController
        windowController.showWindow(nil)
    }
}

