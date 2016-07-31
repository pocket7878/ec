//
//  ECDocument.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/30.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

class ECDocument: NSDocument {
    
    var newLineType: NewLineType = NewLineType.LF
    var contentOfFile: NSAttributedString = NSAttributedString(string: "")
    var jumpAddr: Addr?
    
    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    override func makeWindowControllers() {
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyBoard.instantiateControllerWithIdentifier("WC") as! NSWindowController
        (windowController.contentViewController as? ViewController)?.doc = self
        (windowController.contentViewController as? ViewController)?.loadDoc()
        self.addWindowController(windowController)
        if let jumpAddr = self.jumpAddr,
            let vc = windowController.contentViewController as? ViewController {
            do {
                try vc.runECCmd(ECCmd.Edit(CmdLine(adders: [jumpAddr], cmd: nil)))
                self.jumpAddr = nil
            } catch {
                NSLog("Failed to execute addr command")
            }
        }
    }
    
    override func dataOfType(typeName: String) throws -> NSData {
        for win in self.windowControllers {
            if let vc = win.contentViewController as? ViewController {
                vc.updateDoc()
            }
        }
        
        var str = self.contentOfFile.string
        str = str.stringByReplaceNewLineCharacterWith(self.newLineType)

        if let d = str.dataUsingEncoding(NSUTF8StringEncoding) {
            return d
        }
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        do {
            let attrStr = try NSAttributedString(URL: url, options: [:], documentAttributes: nil)
            let newLineType = attrStr.string.detectNewLineType()
            if newLineType != .None {
                self.newLineType = newLineType
            }
            self.contentOfFile = attrStr
        } catch {
            throw ECError.OpeningBinaryFile
        }
    }
}