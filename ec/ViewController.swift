//
//  ViewController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/28.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextStorageDelegate, CmdPalettSelectionDelgate, NSTextViewDelegate, ECTextViewSelectionDelegate , NSWindowDelegate, WorkingFolderDataSource, SnapshotContentsDataSource {

    @IBOutlet var mainTextView: ECTextView!
    @IBOutlet var cmdTextView: ECTextView!
    @IBOutlet weak var cmdPalettView: CmdPalettView!
    
    var doc: ECDocument?
    
    let cmdPalett = CmdPalett()
    
    var editWC: NSWindowController?
    
    override func viewDidAppear() {
        super.viewDidAppear()
        NSLog("VIew Did apper: \(self.doc?.fileURL)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cmdPalettView.dataSource = cmdPalett
        cmdPalettView.delegate = cmdPalett
        cmdPalettView.selectionDelegate = self
        
        mainTextView.usesFindBar = true
        mainTextView.isIncrementalSearchingEnabled = true
        mainTextView.font = Preference.font()
        mainTextView.selectionDelegate = self
        mainTextView.isAutomaticTextReplacementEnabled = false
        mainTextView.isAutomaticLinkDetectionEnabled = false
        mainTextView.isAutomaticDataDetectionEnabled = false
        mainTextView.isAutomaticDashSubstitutionEnabled = false
        mainTextView.isAutomaticQuoteSubstitutionEnabled = false
        mainTextView.isAutomaticSpellingCorrectionEnabled = false
        mainTextView.workingFolderDataSource = self
        
        if let scrollView = mainTextView.enclosingScrollView {
            let rulerView = LineNumberRulerView(textView: mainTextView)
            scrollView.verticalRulerView = rulerView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.syncCmdPalett), name: NSNotification.Name(rawValue: "CmdPalettChangedNotification"), object: nil)
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    

    func syncCmdPalett() {
        cmdPalettView.reloadData()
    }

    //MARK: Sync with ECDcoument
    func loadDoc() {
        if let doc = self.doc {
            mainTextView.textStorage?.setAttributedString(doc.contentOfFile)
            mainTextView.font = Preference.font()
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
    
    //MARK: CmdPalettSelectionDelegate
    func onEditPalett(_ row: Int) {
        let cmd = cmdPalett.palett[row]
        let storyBoard = NSStoryboard(name: "CmdEditor", bundle: nil)
        let windowController = storyBoard.instantiateController(withIdentifier: "CmdEditorWC") as! NSWindowController
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
        NSApplication.shared().runModal(for: windowController.window!)
    }
    
    func onFindPalett(_ sender: Tagger, row: Int) {
        findString(cmdPalett.palett[row])
    }
    
    func onRunPalett(_ row: Int) {
        runCommand(cmdPalett.palett[row])
    }
    
    func onDeletePalett(_ row: Int) {
        cmdPalett.palett.remove(at: row)
        cmdPalettView.reloadData()
    }
    
    //MARK: Utils
    func selectedText() -> String? {
        let selectedNSRange = mainTextView.selectedRange()
        if selectedNSRange.location != NSNotFound {
            let selectedRange = mainTextView.string!.characters.index(mainTextView.string!.startIndex, offsetBy: selectedNSRange.location) ..< mainTextView.string!.characters.index(mainTextView.string!.startIndex, offsetBy: selectedNSRange.location + selectedNSRange.length)
            return mainTextView.string?.substring(with: selectedRange)
        } else {
            return nil
        }
    }
    
    func findString(_ str: String) {
        do {
            let regex = try NSRegularExpression(pattern: str, options: [
                NSRegularExpression.Options.ignoreMetacharacters
                ])
            var selectedRange = mainTextView.selectedRange()
            if selectedRange.location == NSNotFound {
                selectedRange = NSMakeRange(0, 0)
            }
            let selectionHead = selectedRange.location
            let selectionEnd = selectedRange.location + selectedRange.length
            let forwardRange = NSMakeRange(selectionEnd, mainTextView.string!.characters.count - selectionEnd)
            let backwardRange = NSMakeRange(0, selectionHead)
            if let firstMatchRange: NSRange = regex.firstMatch(in: mainTextView.string!, options: [], range: forwardRange)?.range {
                mainTextView.setSelectedRange(firstMatchRange)
                mainTextView.scrollToSelection()
                mainTextView.moveMouseCursorToSelectedRange()
            } else if let firstMatchRange: NSRange = regex.firstMatch(in: mainTextView.string!, options: [], range: backwardRange)?.range {
                mainTextView.setSelectedRange(firstMatchRange)
                mainTextView.scrollToSelection()
                mainTextView.moveMouseCursorToSelectedRange()
            }
        } catch {
            NSLog("\(error)")
        }
    }
    
    func runECCmd(_ cmd: ECCmd) throws {
        switch(cmd) {
        case ECCmd.edit(let cmdLine):
            var fileFolderPath: String? = nil
            if let fileUrl = doc?.fileURL, fileUrl.isFileURL {
                let fpath = fileUrl.path
                fileFolderPath = String(NSString(string: fpath).deletingLastPathComponent)
            }
            let currDot = mainTextView.selectedRange()
            try runCmdLine(
                TextEdit(
                    storage: mainTextView.textStorage!.string,
                    dot: (currDot.location, currDot.location + currDot.length)),
                textview: mainTextView,
                cmdLine: cmdLine, folderPath: fileFolderPath)
        case ECCmd.look(let str):
            findString(str)
        case .external(let str, let execType):
            var fileFolderPath: String? = nil
            if let fileUrl = doc?.fileURL, fileUrl.isFileURL {
                let fpath = fileUrl.path
                fileFolderPath = String(NSString(string: fpath).deletingLastPathComponent)
            }
            switch(execType) {
            case .pipe, .input, .output:
                try runECCmd(ECCmd.edit(CmdLine(adders: [], cmd: Cmd.external(str, execType))))
            case .none:
                Util.runExternalCommand(str, inputString: nil, fileFolderPath: fileFolderPath)
            }
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
    func onFileAddrSelection(_ fileAddr: FileAddr) {
        NSDocumentController.shared().openDocument(
            withContentsOf: URL(fileURLWithPath: fileAddr.filepath),
            display: false) { (newdoc, alreadyp, _) in
                if let newdoc = newdoc {
                    if let newfileUrl = newdoc.fileURL, newfileUrl.isFileURL,
                        let fileUrl = self.doc?.fileURL, fileUrl.isFileURL {
                        if newfileUrl.path == fileUrl.path {
                            //Same file. then just execute addr command
                            if let ecdoc = newdoc as? ECDocument,
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
    
    func onRightMouseSelection(_ str: String) {
        findString(str)
    }
    
    func onOtherMouseSelection(_ str: String) {
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
            fileFolderPath = String(NSString(string: fpath).deletingLastPathComponent)
        }
        return fileFolderPath
    }
}

