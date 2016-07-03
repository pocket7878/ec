//
//  ViewController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/28.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextStorageDelegate, CmdPalettSelectionDelgate {

    @IBOutlet var mainTextView: NSTextView!
    @IBOutlet var cmdTextView: NSTextView!
    @IBOutlet weak var cmdPalettView: CmdPalettView!
    
    var doc: ECDocument?
    
    let cmdPalett = CmdPalett()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cmdPalettView.setDataSource(cmdPalett)
        cmdPalettView.setDelegate(cmdPalett)
        cmdPalettView.selectionDelegate = self
    }

    override var representedObject: AnyObject? {
        didSet {
            
        // Update the view, if already loaded.
        }
    }
    
    func runCommand(cmd: String) {
        do {
            let res = try cmdLineParser.run(userState: (), sourceName: "cmdText", input: cmd)
            let currDot = mainTextView.selectedRange()
            let newEdit = try runCmdLine(TextEdit(storage:  mainTextView.textStorage!.string, dot: (currDot.location, currDot.location + currDot.length)), cmdLine: res.0)
            if mainTextView.shouldChangeTextInRange(NSMakeRange(0, mainTextView.textStorage!.string.characters.count), replacementString: newEdit.storage) {
                mainTextView.string = newEdit.storage
                mainTextView.setSelectedRange(NSMakeRange(newEdit.dot.0, newEdit.dot.1 - newEdit.dot.0))
                mainTextView.didChangeText()
            }
        } catch {
        }
    }

    @IBAction func runBtnTouched(sender: NSButton) {
        runCommand(cmdTextView.textStorage!.string)
    }

    @IBAction func addBtnTouched(sender: NSButton) {
        cmdPalett.addCmd(cmdTextView.string!)
        cmdPalettView.reloadData()
    }
    
    func loadDoc() {
        if let doc = self.doc {
            mainTextView.textStorage?.setAttributedString(doc.contentOfFile)
        }
    }
    
    func updateDoc() {
        if let doc = self.doc {
            doc.contentOfFile = mainTextView.attributedString()
        }
    }
    
    //MARK: CmdPalettSelectionDelegate
    func onRightClick(idx: Int) {
        runCommand(cmdPalett.palett[idx])
    }
    
    func onMiddleClick(idx: Int) {
        runCommand(cmdPalett.palett[idx])
    }
}

