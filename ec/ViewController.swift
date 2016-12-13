//
//  ViewController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/28.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Cocoa
import SnapKit

class ViewController: NSViewController, NSTextStorageDelegate, NSTextViewDelegate, ECTextViewSelectionDelegate , NSWindowDelegate, WorkingFolderDataSource, SnapshotContentsDataSource {

    @IBOutlet var mainTextView: ECTextView!
    @IBOutlet var cmdTextView: ECTextView!
    
    var doc: ECDocument?
    
    var editWC: NSWindowController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainTextView.usesFindBar = true
        mainTextView.isIncrementalSearchingEnabled = true
        mainTextView.font = Preference.font
        mainTextView.selectionDelegate = self
        mainTextView.isAutomaticTextReplacementEnabled = false
        mainTextView.isAutomaticLinkDetectionEnabled = false
        mainTextView.isAutomaticDataDetectionEnabled = false
        mainTextView.isAutomaticDashSubstitutionEnabled = false
        mainTextView.isAutomaticQuoteSubstitutionEnabled = false
        mainTextView.isAutomaticSpellingCorrectionEnabled = false
        mainTextView.workingFolderDataSource = self
        mainTextView.backgroundColor = Preference.mainBgColor
        mainTextView.textColor = Preference.mainFgColor
        mainTextView.insertionPointColor = Preference.mainFgColor
        
        cmdTextView.usesFindBar = true
        cmdTextView.isIncrementalSearchingEnabled = true
        cmdTextView.font = Preference.font
        cmdTextView.selectionDelegate = self
        cmdTextView.isAutomaticTextReplacementEnabled = false
        cmdTextView.isAutomaticLinkDetectionEnabled = false
        cmdTextView.isAutomaticDataDetectionEnabled = false
        cmdTextView.isAutomaticDashSubstitutionEnabled = false
        cmdTextView.isAutomaticQuoteSubstitutionEnabled = false
        cmdTextView.isAutomaticSpellingCorrectionEnabled = false
        cmdTextView.workingFolderDataSource = self
        cmdTextView.translatesAutoresizingMaskIntoConstraints = true
        cmdTextView.backgroundColor = Preference.subBgColor
        cmdTextView.textColor = Preference.subFgColor
        cmdTextView.insertionPointColor = Preference.subFgColor
        
        if let scrollView = mainTextView.enclosingScrollView {
            let rulerView = LineNumberRulerView(textView: mainTextView)
            scrollView.verticalRulerView = rulerView
            scrollView.hasVerticalRuler = true
            scrollView.hasHorizontalRuler = false
            scrollView.rulersVisible = true
        }
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    //MARK: Sync with ECDcoument
    func loadDoc() {
        if let doc = self.doc {
            mainTextView.textStorage?.setAttributedString(doc.contentOfFile)
            mainTextView.font = Preference.font
            doc.snapshotContentDataSource = self
        }
    }
    
    func updateDoc() {
        if let doc = self.doc {
            doc.contentOfFile = mainTextView.attributedString()
            self.mainTextView.breakUndoCoalescing()
        }
    }
    
    func snapshotContent() -> NSAttributedString {
        return NSAttributedString(string: self.mainTextView.string!)
    }
    
    func runECCmd(_ cmd: ECCmd) throws {
        switch(cmd) {
        case ECCmd.edit(let cmdLine):
            let fileFolderPath = self.workingFolder()
            let currDot = mainTextView.selectedRange()
            try runCmdLine(
                TextEdit(
                    storage: mainTextView.textStorage!.string,
                    dot: (currDot.location, currDot.location + currDot.length)),
                textview: mainTextView,
                cmdLine: cmdLine, folderPath: fileFolderPath)
        case ECCmd.look(let str):
            mainTextView.findString(str)
        case ECCmd.lookback(let str):
            mainTextView.findBackwardString(str)
        case .external(let str, let execType):
            let fileFolderPath = self.workingFolder()
            switch(execType) {
            case .pipe, .input, .output:
                try runECCmd(ECCmd.edit(CmdLine(adders: [], cmd: Cmd.external(str, execType))))
            case .none:
                Util.runExternalCommand(str, inputString: nil, fileFolderPath: fileFolderPath)
            }
        case .win():
            OperationQueue().addOperation({ () -> Void in
                let fileFolderPath = self.workingFolder()
                Util.startWin(workingFolder: fileFolderPath)
            })
        }
    }

    func runCommand(_ cmd: String) {
        do {
            let res = try ecCmdParser.run(userState: (), sourceName: "cmdText", input: cmd)
            try runECCmd(res)
        } catch {
            if let nserror = error as? NSError {
                let alert = NSAlert(error: nserror)
                alert.runModal()
            } else {
                let alert = NSAlert()
                alert.messageText = "\(error)"
                alert.runModal()
            }
        }
    }
    
    //MARK: ECTextViewSelectionDelegate
    func onFileAddrSelection(_ fileAddr: FileAddr, by: NSEvent) {
        NSDocumentController.shared().openDocument(
            withContentsOf: URL(fileURLWithPath: fileAddr.filepath),
            display: false) { (newdoc, alreadyp, _) in
                if let newdoc = newdoc {
                    if let newfileUrl = newdoc.fileURL, newfileUrl.isFileURL,
                        let fileUrl = self.doc?.fileURL, fileUrl.isFileURL {
                        if newfileUrl.path == fileUrl.path {
                            //Same file. then just execute addr command
                            if let _ = newdoc as? ECDocument,
                                let addr = fileAddr.addr {
                                do {
                                    try self.runECCmd(ECCmd.edit(CmdLine(adders: [addr], cmd: nil)))
                                } catch {
                                    NSLog("Failed to run addr")
                                }
                            }
                        } else {
                            if let ecdoc = newdoc as? ECDocument {
                                ecdoc.jumpAddr = fileAddr.addr
                            }
                            if !alreadyp {
                                newdoc.makeWindowControllers()
                            }
                            newdoc.showWindows()
                        }
                    }
                } else {
                    NSLog("Failed to open file")
                }
        }
    }
    
    func onRightMouseSelection(_ str: String, by event: NSEvent) {
        if (event.modifierFlags.contains(NSEventModifierFlags.shift)) {
            mainTextView.findBackwardString(str)
        } else {
            mainTextView.findString(str)
        }
    }
    
    func onOtherMouseSelection(_ str: String, by event: NSEvent) {
        runCommand(str)
    }
    
    //MARK: NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared().stopModal()
    }
    
    //MARK: WorkingFolderDataSource
    func workingFolder() -> String? {
        var fileFolderPath: String? = nil
        if let fileUrl = doc?.fileURL, fileUrl.isFileURL {
            let fpath = fileUrl.path
            if !(doc?.isDirectoryDocument)! {
                fileFolderPath = String(NSString(string: fpath).deletingLastPathComponent)
            } else {
                fileFolderPath = fpath
            }
        }
        return fileFolderPath
    }
}

