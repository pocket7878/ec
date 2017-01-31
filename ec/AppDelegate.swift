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
    var psn: ProcessSerialNumber = ProcessSerialNumber(
        highLongOfPSN: UInt32(0),
        lowLongOfPSN: UInt32(kCurrentProcess))
    var eventTap: CFMachPort?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {        
        //Load Yaml If Exists
        let settingFilePath = Preference.preferenceFilePath
        if !FileManager.default.fileExists(atPath: settingFilePath) {
            FileManager.default.createFile(atPath: settingFilePath, contents: nil, attributes: nil)
        }
        
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.rightMouseUp.rawValue)
            | (1 << CGEventType.otherMouseDown.rawValue)
            | (1 << CGEventType.otherMouseUp.rawValue)
        
        let observer = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? in
                if let observer = refcon {
                    let mySelf = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
                    return mySelf.eventCallback(proxy: proxy, type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
        },
            userInfo: observer
            ) else {
                print("failed to create event tap")
                exit(1)
        }
        
        let runloopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runloopSource, CFRunLoopMode.commonModes)
    }

    
    func eventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        
        let frontMostApp: NSRunningApplication? = NSWorkspace.shared().runningApplications.filter { (app) -> Bool in
            app.isActive
        }.first
        
        if let frontMostApp = frontMostApp {
            if (frontMostApp.processIdentifier == ProcessInfo.processInfo.processIdentifier) {
                NSLog("Event Callback")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MouseEvent"),
                                                object: nil,
                                                userInfo: [
                                                    "event": event,
                                                    "event_type": type])
            }
        }
        return Unmanaged.passUnretained(event)
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        NSLog("Resign Active")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ResignActive"), object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        NSWorkspace.shared().notificationCenter.removeObserver(self);
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

