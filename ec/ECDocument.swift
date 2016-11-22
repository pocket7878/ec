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

protocol SnapshotContentsDataSource: class {
    func snapshotContent() -> NSAttributedString
}

class ECDocument: NSDocument {
    
    var newLineType: NewLineType = NewLineType.LF
    var contentOfFile: NSAttributedString = NSAttributedString(string: "")
    var jumpAddr: Addr?
    weak var snapshotContentDataSource: SnapshotContentsDataSource?
    
    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    override func makeWindowControllers() {
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyBoard.instantiateControllerWithIdentifier("WC") as! NSWindowController
        (windowController.contentViewController as? ViewController)?.doc = self
        (windowController.contentViewController as? ViewController)?.loadDoc()
        self.addWindowController(windowController)
    }
    
    override func showWindows() {
        super.showWindows()
        for win in self.windowControllers {
            if let jumpAddr = self.jumpAddr,
                let vc = win.contentViewController as? ViewController {
                do {
                    try vc.runECCmd(ECCmd.Edit(CmdLine(adders: [jumpAddr], cmd: nil)))
                    self.jumpAddr = nil
                } catch {
                    NSLog("Failed to execute addr command")
                }
            }
        }
    }
    
    override func dataOfType(typeName: String) throws -> NSData {
        for win in self.windowControllers {
            if let vc = win.contentViewController as? ViewController {
                vc.updateDoc()
            }
        }
        
        self.unblockUserInteraction()
        
        var str = self.contentOfFile.string
        str = str.stringByReplaceNewLineCharacterWith(self.newLineType)

        if let d = str.dataUsingEncoding(NSUTF8StringEncoding) {
            return d
        }
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        do {
            let attrStr = try NSAttributedString(
                URL: url,
                options: [NSDocumentTypeDocumentOption:NSPlainTextDocumentType],
                documentAttributes: nil)
            let newLineType = attrStr.string.detectNewLineType()
            if newLineType != .None {
                self.newLineType = newLineType
            }
            self.contentOfFile = attrStr
        } catch {
            throw ECError.OpeningBinaryFile
        }
    }
    
    override func printOperationWithSettings(printSettings: [String : AnyObject]) throws -> NSPrintOperation {
        var content = self.contentOfFile
        if let snapshotContentDataSource = self.snapshotContentDataSource {
            content = snapshotContentDataSource.snapshotContent()
        }
        let paperSize = self.printInfo.paperSize
        let textView = NSTextView(frame: NSMakeRect(
            0, 0,
            paperSize.width - self.printInfo.leftMargin - self.printInfo.rightMargin,
            paperSize.height - self.printInfo.topMargin - self.printInfo.bottomMargin))
        textView.textStorage?.setAttributedString(content)
        return NSPrintOperation(view: textView, printInfo: self.printInfo)
    }
}