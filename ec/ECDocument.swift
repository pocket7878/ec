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
import Yaml

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
    var pref: Variable<Preference?> = Variable(nil)
    
    var fileData: Data? = nil
    
    override init() {
        super.init()
        do {
            let yamlStr = try String(NSString(contentsOfFile: Preference.preferenceFilePath, encoding: String.Encoding.utf8.rawValue))
            let yaml = try Yaml.load(yamlStr)
            self.pref.value = Preference.loadDefaultYaml(yaml)
        } catch {
            NSLog("\(error)")
        }
    }
    
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
    
    override var fileURL: URL? {
        didSet {
            guard self.fileURL != oldValue else { return }
            
            DispatchQueue.main.async { [weak self] in
                do {
                    let yamlStr = try String(NSString(contentsOfFile: Preference.preferenceFilePath, encoding: String.Encoding.utf8.rawValue))
                    let yaml = try Yaml.load(yamlStr)
                    if let url = self?.fileURL {
                        self?.pref.value = Preference.loadYaml(yaml, for: url.path)
                    } else {
                        self?.pref.value = Preference.loadDefaultYaml(yaml)
                    }
                } catch {
                    NSLog("\(error)")
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
    
    private func buildContentOfFileread(from url: URL, ofType typeName: String) throws -> NSAttributedString {
        switch(typeName) {
        case "public.folder":
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
                let mutStr = NSMutableAttributedString(string: childrens.joined(separator: "\n"),
                                                       attributes: [:])
                if let pre = pref.value {
                    mutStr.addAttributes([
                        NSForegroundColorAttributeName: pre.mainFgColor,
                        NSFontAttributeName: pre.font
                        ], range: NSMakeRange(0, mutStr.length))
                }
                return mutStr
            } catch {
                NSLog("\(error)")
                throw ECError.openingBinaryFile
            }
        default:
            do {
                let attrStr = try NSMutableAttributedString(
                    url: url,
                    options: [NSDocumentTypeDocumentOption:NSPlainTextDocumentType],
                    documentAttributes: nil)
                if let pre = pref.value {
                    attrStr.addAttributes([
                        NSForegroundColorAttributeName: pre.mainFgColor,
                        NSFontAttributeName: pre.font
                        ], range: NSMakeRange(0, attrStr.length))
                }
                return attrStr
            } catch {
                NSLog("\(error)")
                throw ECError.openingBinaryFile
            }
        }
    }
    
    
    override func read(from url: URL, ofType typeName: String) throws {
        self.fileType = typeName
        switch(typeName) {
        case "public.folder":
            self.isDirectoryDocument = true
            do {
                let yamlStr = try String(NSString(contentsOfFile: Preference.preferenceFilePath,
                                                  encoding: String.Encoding.utf8.rawValue))
                let yaml = try Yaml.load(yamlStr)
                self.pref.value = Preference.loadYaml(yaml, for: url.path)
            } catch {
                NSLog("\(error)")
            }
            do{
                let dirContent = try buildContentOfFileread(from: url, ofType: typeName)
                self.hasUndoManager = false
                self.newLineType = .lf
                self.contentOfFile = dirContent
            } catch {
                NSLog("\(error)")
                throw ECError.openingBinaryFile
            }
        default:
            do {
                let yamlStr = try String(NSString(contentsOfFile: Preference.preferenceFilePath, encoding: String.Encoding.utf8.rawValue))
                let yaml = try Yaml.load(yamlStr)
                self.pref.value = Preference.loadYaml(yaml, for: url.path)
            } catch {
                NSLog("\(error)")
            }
            do {
                self.fileData = try Data(contentsOf: url)
                let fileContent = try buildContentOfFileread(from: url, ofType: typeName)
                let newLineType = fileContent.string.detectNewLineType()
                if newLineType != .none {
                    self.newLineType = newLineType
                }
                self.contentOfFile = fileContent
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
            if saveOperation != .autosaveElsewhereOperation {
                //Refresh Data
                if let data = try? Data(contentsOf: url) {
                    self.fileData = data
                }
            }
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
    
    // MARK: Protocols
    
    /// file has been modified by an external process
    override func presentedItemDidChange() {
        if let fileURL = fileURL {
            var changed = false
            var modifiedAt: Date?
            let coordinator = NSFileCoordinator(filePresenter: self)
            coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: nil) { [weak self] (newURL) in
                modifiedAt = (try? FileManager.default.attributesOfItem(atPath: newURL.path))?[.modificationDate] as? Date
                if modifiedAt != self?.fileModificationDate {
                    let newData = try? Data(contentsOf: newURL)
                    if newData != self?.fileData {
                        changed = true
                    } else {
                        return
                    }
                } else {
                    //Self edit
                    return
                }
            }
            
            //Just update timestamp
            if !changed {
                if let modifiedAt = modifiedAt,
                    let fileModificationDate = self.fileModificationDate,
                    modifiedAt > fileModificationDate {
                    self.fileModificationDate = modifiedAt
                }
                return
            }
            
            if let fileType = self.fileType {
                do {
                    DispatchQueue.main.async { [weak self] in
                        if let me = self {
                            do {
                                //If file is not dirty, then just reload content
                                if changed && !me.isDocumentEdited {
                                    try me.revert(toContentsOf: fileURL, ofType: fileType)
                                    for winC in me.windowControllers {
                                        (winC.contentViewController as? ViewController)?.loadDoc()
                                    }
                                } else {
                                    //Otherwise display notification
                                    me.askRefreshOrKeep()
                                }
                            } catch {
                                me.presentError(error)
                            }
                        }
                    }
                } catch {
                    
                }
            }
        }
    }
    
    private func askRefreshOrKeep() {
        let alert = NSAlert()
        alert.messageText = "The file changed on disk"
        alert.informativeText = "Reread from disk?"
        alert.addButton(withTitle: "y")
        alert.addButton(withTitle: "n")
        
        alert.beginSheetModal(for: self.windowForSheet!) { [weak self] (returnCode: NSModalResponse) in
            if let me = self {
                if returnCode == NSAlertFirstButtonReturn,
                    let fileType = me.fileType,
                    let fileURL = me.fileURL {
                    do {
                        try me.revert(toContentsOf: fileURL, ofType: fileType)
                        for winC in me.windowControllers {
                            (winC.contentViewController as? ViewController)?.loadDoc()
                        }
                    } catch {
                        me.presentError(error)
                    }
                }
            }
        }
    }
}
