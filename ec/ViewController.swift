//
//  ViewController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/28.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextStorageDelegate, CmdPalettSelectionDelgate, NSTextViewDelegate, ECTextViewSelectionDelegate , NSWindowDelegate, WorkingFolderDataSource {

    @IBOutlet var mainTextView: ECTextView!
    @IBOutlet var cmdTextView: NSTextView!
    @IBOutlet weak var cmdPalettView: CmdPalettView!
    @IBOutlet weak var newLineTypeLabel: NSTextField!
    
    var doc: ECDocument?
    
    let cmdPalett = CmdPalett()
    
    var editWC: NSWindowController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cmdPalettView.setDataSource(cmdPalett)
        cmdPalettView.setDelegate(cmdPalett)
        cmdPalettView.selectionDelegate = self
        
        mainTextView.usesFindBar = true
        mainTextView.incrementalSearchingEnabled = true
        mainTextView.font = Preference.font()
        mainTextView.delegate = self
        mainTextView.selectionDelegate = self
        mainTextView.automaticTextReplacementEnabled = false
        mainTextView.automaticLinkDetectionEnabled = false
        mainTextView.automaticDataDetectionEnabled = false
        mainTextView.automaticDashSubstitutionEnabled = false
        mainTextView.automaticQuoteSubstitutionEnabled = false
        mainTextView.automaticSpellingCorrectionEnabled = false
        mainTextView.workingFolderDataSource = self
        
        if let scrollView = mainTextView.enclosingScrollView {
            let rulerView = LineNumberRulerView(textView: mainTextView)
            scrollView.verticalRulerView = rulerView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.syncCmdPalett), name: "CmdPalettChangedNotification", object: nil)
    }

    override var representedObject: AnyObject? {
        didSet {
        }
    }
    

    func syncCmdPalett() {
        cmdPalettView.reloadData()
    }

    @IBAction func runBtnTouched(sender: NSButton) {
        runCommand(cmdTextView.textStorage!.string)
    }

    @IBAction func addBtnTouched(sender: NSButton) {
        cmdPalett.addCmd(cmdTextView.string!)
    }
    
    @IBAction func lookBtnTouched(sender: AnyObject) {
        findString(cmdTextView.string!)
    }
    
    //MARK: Sync with ECDcoument
    func loadDoc() {
        if let doc = self.doc {
            mainTextView.textStorage?.setAttributedString(doc.contentOfFile)
            mainTextView.font = Preference.font()
            self.newLineTypeLabel.stringValue = "\(doc.newLineType)"
        }
    }
    
    func updateDoc() {
        if let doc = self.doc {
            doc.contentOfFile = mainTextView.attributedString()
        }
    }
    
    //MARK: CmdPalettSelectionDelegate
    func onEditPalett(row: Int) {
        let cmd = cmdPalett.palett[row]
        let storyBoard = NSStoryboard(name: "CmdEditor", bundle: nil)
        let windowController = storyBoard.instantiateControllerWithIdentifier("CmdEditorWC") as! NSWindowController
        editWC = windowController
        if let win = windowController.window {
            if let ceWin = win as? CmdEditorWindow {
                ceWin.delegate = self
                if
                    let cvc = ceWin.contentViewController,
                    let ceVC = cvc as? CmdEditorViewController {
                    ceVC.editorTextView.textStorage?.setAttributedString(NSAttributedString(string: cmd))
                    ceWin.row = row
                    ceWin.palett = self.cmdPalett
                    ceVC.delegate = ceWin
                }
            }
        }
        NSApplication.sharedApplication().runModalForWindow(windowController.window!)
    }
    
    func onFindPalett(sender: Tagger, row: Int) {
        findString(cmdPalett.palett[row])
    }
    
    func onRunPalett(row: Int) {
        runCommand(cmdPalett.palett[row])
    }
    
    func onDeletePalett(row: Int) {
        cmdPalett.palett.removeAtIndex(row)
        cmdPalettView.reloadData()
    }
    
    //MARK: Utils
    func selectedText() -> String? {
        let selectedNSRange = mainTextView.selectedRange()
        if selectedNSRange.location != NSNotFound {
            let selectedRange = mainTextView.string!.startIndex.advancedBy(selectedNSRange.location) ..< mainTextView.string!.startIndex.advancedBy(selectedNSRange.location + selectedNSRange.length)
            return mainTextView.string?.substringWithRange(selectedRange)
        } else {
            return nil
        }
    }
    
    func findString(str: String) {
        do {
            let regex = try NSRegularExpression(pattern: str, options: [
                NSRegularExpressionOptions.IgnoreMetacharacters
                ])
            var selectedRange = mainTextView.selectedRange()
            if selectedRange.location == NSNotFound {
                selectedRange = NSMakeRange(0, 0)
            }
            let selectionHead = selectedRange.location
            let selectionEnd = selectedRange.location + selectedRange.length
            let forwardRange = NSMakeRange(selectionEnd, mainTextView.string!.characters.count - selectionEnd)
            let backwardRange = NSMakeRange(0, selectionHead)
            if let firstMatchRange: NSRange = regex.firstMatchInString(mainTextView.string!, options: [], range: forwardRange)?.range {
                mainTextView.setSelectedRange(firstMatchRange)
                mainTextView.scrollToSelection()
                mainTextView.moveMouseCursorToSelectedRange()
            } else if let firstMatchRange: NSRange = regex.firstMatchInString(mainTextView.string!, options: [], range: backwardRange)?.range {
                mainTextView.setSelectedRange(firstMatchRange)
                mainTextView.scrollToSelection()
                mainTextView.moveMouseCursorToSelectedRange()
            }
        } catch {
            NSLog("\(error)")
        }
    }
    
    func runECCmd(cmd: ECCmd) throws {
        switch(cmd) {
        case ECCmd.Edit(let cmdLine):
            var fileFolderPath: String? = nil
            if let fileUrl = doc?.fileURL where fileUrl.fileURL,
                let fpath = fileUrl.path {
                fileFolderPath = String(NSString(string: fpath).stringByDeletingLastPathComponent)
            }
            let currDot = mainTextView.selectedRange()
            try runCmdLine(
                TextEdit(
                    storage: mainTextView.textStorage!.string,
                    dot: (currDot.location, currDot.location + currDot.length)),
                textview: mainTextView,
                cmdLine: cmdLine, folderPath: fileFolderPath)
        case ECCmd.Look(let str):
            findString(str)
        case .External(let str, let execType):
            var fileFolderPath: String? = nil
            if let fileUrl = doc?.fileURL where fileUrl.fileURL,
                let fpath = fileUrl.path {
                fileFolderPath = String(NSString(string: fpath).stringByDeletingLastPathComponent)
            }
            switch(execType) {
            case .Pipe, .Input, .Output:
                try runECCmd(ECCmd.Edit(CmdLine(adders: [], cmd: Cmd.External(str, execType))))
            case .None:
                Util.runExternalCommand(str, inputString: nil, fileFolderPath: fileFolderPath)
            }
        }
    }

    func runCommand(cmd: String) {
        do {
            let res = try ecCmdParser.run(userState: (), sourceName: "cmdText", input: cmd)
            try runECCmd(res.0)
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
    func onFileAddrSelection(fileAddr: FileAddr) {
        NSDocumentController.sharedDocumentController().openDocumentWithContentsOfURL(
            NSURL.fileURLWithPath(fileAddr.filepath),
            display: false) { (newdoc, alreadyp, _) in
                if let newdoc = newdoc {
                    if let newfileUrl = newdoc.fileURL where newfileUrl.fileURL,
                        let newfpath = newfileUrl.path,
                        let fileUrl = self.doc?.fileURL where fileUrl.fileURL,
                        let fpath = fileUrl.path {
                        if newfpath == fpath {
                            //Same file. then just execute addr command
                            if let ecdoc = newdoc as? ECDocument,
                                let addr = fileAddr.addr {
                                do {
                                    try self.runECCmd(ECCmd.Edit(CmdLine(adders: [addr], cmd: nil)))
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
    
    func onRightMouseSelection(str: String) {
        findString(str)
    }
    
    func onOtherMouseSelection(str: String) {
        runCommand(str)
    }
    
    //MARK: NSWindowDelegate
    func windowWillClose(notification: NSNotification) {
        NSApplication.sharedApplication().stopModal()
    }
    
    //MARK: WorkingFolderDataSource
    func workingFolder() -> String? {
        var fileFolderPath: String? = nil
        if let fileUrl = doc?.fileURL where fileUrl.fileURL,
            let fpath = fileUrl.path {
            fileFolderPath = String(NSString(string: fpath).stringByDeletingLastPathComponent)
        }
        return fileFolderPath
    }
}

