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
import RxSwift

protocol SnapshotContentsDataSource: class {
    func snapshotContent() -> NSAttributedString
}

class ECDocument: NSDocument {
    
    var newLineType: NewLineType = NewLineType.lf
    var contentOfFile: NSAttributedString = NSAttributedString(string: "")
    var jumpAddr: Addr?
    weak var snapshotContentDataSource: SnapshotContentsDataSource?
    
    var isDirectoryDocument: Bool = false
    let disposeBag = DisposeBag()
    
    override class func autosavesInPlace() -> Bool {
        return false
    }
    
    override func makeWindowControllers() {
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyBoard.instantiateController(withIdentifier: "WC") as! NSWindowController
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
                    try vc.runECCmd(ECCmd.edit(CmdLine(adders: [jumpAddr], cmd: nil)))
                    self.jumpAddr = nil
                } catch {
                    NSLog("Failed to execute addr command")
                }
            }
        }
    }
    
    override func data(ofType typeName: String) throws -> Data {
        for win in self.windowControllers {
            if let vc = win.contentViewController as? ViewController {
                vc.updateDoc()
            }
        }
        
        self.unblockUserInteraction()
        
        var str = self.contentOfFile.string
        str = str.stringByReplaceNewLineCharacterWith(self.newLineType)

        if let d = str.data(using: String.Encoding.utf8) {
            return d
        }
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    override func read(from url: URL, ofType typeName: String) throws {
        switch(typeName) {
        case "public.folder":
            self.isDirectoryDocument = true
            do{
                let fileManager = FileManager.default
                var childrens: [String] = []
                for entry in try fileManager.contentsOfDirectory(atPath: url.path) {
                    let entryFullPath = url.path.appendingPathComponent(entry)
                    var isDir : ObjCBool = false
                    fileManager.fileExists(atPath: entryFullPath, isDirectory: &isDir)
                    if isDir.boolValue {
                        childrens.append("\(entry)/")
                    } else {
                        childrens.append("\(entry)")
                    }
                }
                self.hasUndoManager = false
                self.newLineType = .lf
                self.contentOfFile = NSAttributedString(string: childrens.joined(separator: "\n"))
            } catch {
                NSLog("\(error)")
                throw ECError.openingBinaryFile
            }
        default:
            do {
                let attrStr = try NSAttributedString(
                    url: url,
                    options: [NSDocumentTypeDocumentOption:NSPlainTextDocumentType],
                    documentAttributes: nil)
                let newLineType = attrStr.string.detectNewLineType()
                if newLineType != .none {
                    self.newLineType = newLineType
                }
                self.contentOfFile = attrStr
            } catch {
                NSLog("\(error)")
                throw ECError.openingBinaryFile
            }
        }
    }
    
    override func write(to url: URL, ofType typeName: String, for saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws {
        if self.isDirectoryDocument {
            throw ECError.illigalState
        } else {
            try super.write(to: url, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
        }
    }
    
    override func printOperation(withSettings printSettings: [String : Any]) throws -> NSPrintOperation {
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
