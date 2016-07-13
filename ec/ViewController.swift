//
//  ViewController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/28.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextStorageDelegate, CmdPalettSelectionDelgate, NSTextViewDelegate, ECTextViewSelectionDelegate {

    @IBOutlet var mainTextView: ECTextView!
    @IBOutlet var cmdTextView: NSTextView!
    @IBOutlet weak var cmdPalettView: CmdPalettView!
    
    var doc: ECDocument?
    
    let cmdPalett = CmdPalett()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cmdPalettView.setDataSource(cmdPalett)
        cmdPalettView.setDelegate(cmdPalett)
        cmdPalettView.selectionDelegate = self
        
        mainTextView.usesFindBar = true
        mainTextView.incrementalSearchingEnabled = true
        mainTextView.font = Preference.font()
        mainTextView.automaticQuoteSubstitutionEnabled = false
        mainTextView.delegate = self
        mainTextView.selectionDelegate = self
        
        if let scrollView = mainTextView.enclosingScrollView {
            var rulerView = LineNumberRulerView(textView: mainTextView)
            scrollView.verticalRulerView = rulerView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }
        
    }

    override var representedObject: AnyObject? {
        didSet {
            
        // Update the view, if already loaded.
        }
    }
    
    func runCommand(cmd: String) {
        do {
            var fileFolderPath: String? = nil
            if let fileUrl = doc?.fileURL where fileUrl.fileURL,
                let fpath = fileUrl.path {
                fileFolderPath = String(NSString(string: fpath).stringByDeletingLastPathComponent)
            }
            let res = try cmdLineParser.run(userState: (), sourceName: "cmdText", input: cmd)
            let currDot = mainTextView.selectedRange()
            try runCmdLine(
                TextEdit(
                    storage: mainTextView.textStorage!.string,
                    dot: (currDot.location, currDot.location + currDot.length)),
                    textview: mainTextView,
                    cmdLine: res.0, folderPath: fileFolderPath)
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

    @IBAction func runBtnTouched(sender: NSButton) {
        runCommand(cmdTextView.textStorage!.string)
    }

    @IBAction func addBtnTouched(sender: NSButton) {
        cmdPalett.addCmd(cmdTextView.string!)
        cmdPalettView.reloadData()
    }
    
    @IBAction func lookBtnTouched(sender: AnyObject) {
        findString(cmdTextView.string!)
    }
    
    func loadDoc() {
        if let doc = self.doc {
            mainTextView.textStorage?.setAttributedString(doc.contentOfFile)
            mainTextView.font = Preference.font()
        }
    }
    
    func updateDoc() {
        if let doc = self.doc {
            doc.contentOfFile = mainTextView.attributedString()
        }
    }
    
    //MARK: CmdPalettSelectionDelegate
    func find(sender: Tagger, row: Int) {
        findString(cmdPalett.palett[row])
    }
    
    func run(row: Int) {
        runCommand(cmdPalett.palett[row])
    }
    
    func delete(row: Int) {
        cmdPalett.palett.removeAtIndex(row)
        cmdPalettView.reloadData()
    }
    
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
        runCommand("/\(str)/")
        let selectedRange = mainTextView.selectedRange()
        if selectedRange.location != NSNotFound {
            mainTextView.scrollRangeToVisible(selectedRange)
            let rect = mainTextView.firstRectForCharacterRange(selectedRange, actualRange: nil)
            let pt = NSMakePoint(rect.origin.x, rect.origin.y)
            let y = pt.y;
            let screenY = CGDisplayBounds(CGMainDisplayID()).size.height - y
            CGWarpMouseCursorPosition(CGPointMake(pt.x + rect.width / 2, screenY - rect.height / 2))
        }
    }
    
    func runString(str: String) {
        runCommand(str)
    }

    
    //ECTextViewSelectionDelegate
    func onRightMouseSelection(str: String) {
        findString(str)
    }
    
    func onOtherMouseSelection(str: String) {
        runString(str)
    }
}

