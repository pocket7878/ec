//
//  AppDelegate.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/28.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Cocoa
import Yaml

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var prefWC: NSWindowController?
    var commandWCs: Dictionary<String, NSWindowController> = [:]
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //Load Yaml If Exists
        let settingFilePath = Preference.preferenceFilePath
        if FileManager.default.fileExists(atPath: settingFilePath) {
            do {
                let yamlStr = try String(NSString(contentsOfFile: settingFilePath, encoding: String.Encoding.utf8.rawValue))
                let yaml = try Yaml.load(yamlStr)
                Preference.loadYaml(yaml)
            } catch {
                NSLog("\(error)")
            }
        } else {
            FileManager.default.createFile(atPath: settingFilePath, contents: nil, attributes: nil)
            do {
                let yamlStr = try String(NSString(contentsOfFile: settingFilePath, encoding: String.Encoding.utf8.rawValue))
                let yaml = try Yaml.load(yamlStr)
                Preference.loadYaml(yaml)
            } catch {
                NSLog("\(error)")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }

    @IBAction func openPreferenceWindow(_ sender: NSMenuItem) {
        ECDocumentController.shared().openDocument(
            withContentsOf: URL(fileURLWithPath: Preference.preferenceFilePath),
            display: false) { (newdoc, alreadyp, _) in
                if let newdoc = newdoc {
                    if !alreadyp {
                        newdoc.makeWindowControllers()
                    }
                    newdoc.showWindows()
                } else {
                    NSLog("Failed to open file")
                }
        }
    }
}

