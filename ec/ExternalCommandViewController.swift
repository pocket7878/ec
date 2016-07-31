//
//  ExternalCommandViewController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/30.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class ExternalCommandViewController: NSViewController, ECTextViewSelectionDelegate, NSTextViewDelegate, WorkingFolderDataSource {
    
    @IBOutlet var commandOutputView: ECTextView!
    
    var workingDir: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commandOutputView.usesFindBar = true
        commandOutputView.incrementalSearchingEnabled = true
        commandOutputView.font = Preference.font()
        commandOutputView.delegate = self
        commandOutputView.selectionDelegate = self
        commandOutputView.automaticTextReplacementEnabled = false
        commandOutputView.automaticLinkDetectionEnabled = false
        commandOutputView.automaticDataDetectionEnabled = false
        commandOutputView.automaticDashSubstitutionEnabled = false
        commandOutputView.automaticQuoteSubstitutionEnabled = false
        commandOutputView.automaticSpellingCorrectionEnabled = false
        commandOutputView.workingFolderDataSource = self
    }
    
    func executeCommand(workingDir: String?, command: String) {
        //Clear whole text and run command
        self.commandOutputView.textStorage?.setAttributedString(NSAttributedString(string: ""))
        self.workingDir = workingDir
        let res = Util.runCommandWithoutSeparateOutAndError(command, inputStr: nil, wdir: workingDir, args: [])
        self.commandOutputView.textStorage?.setAttributedString(NSAttributedString(string: res.output.joinWithSeparator("\n")))
    }

    //MARK: Utils
    func selectedText() -> String? {
        let selectedNSRange = commandOutputView.selectedRange()
        if selectedNSRange.location != NSNotFound {
            let selectedRange = commandOutputView.string!.startIndex.advancedBy(selectedNSRange.location) ..< commandOutputView.string!.startIndex.advancedBy(selectedNSRange.location + selectedNSRange.length)
            return commandOutputView.string?.substringWithRange(selectedRange)
        } else {
            return nil
        }
    }
    
    func findString(str: String) {
        do {
            let regex = try NSRegularExpression(pattern: str, options: [
                NSRegularExpressionOptions.IgnoreMetacharacters
                ])
            var selectedRange = commandOutputView.selectedRange()
            if selectedRange.location == NSNotFound {
                selectedRange = NSMakeRange(0, 0)
            }
            let selectionHead = selectedRange.location
            let selectionEnd = selectedRange.location + selectedRange.length
            let forwardRange = NSMakeRange(selectionEnd, commandOutputView.string!.characters.count - selectionEnd)
            let backwardRange = NSMakeRange(0, selectionHead)
            if let firstMatchRange: NSRange = regex.firstMatchInString(commandOutputView.string!, options: [], range: forwardRange)?.range {
                commandOutputView.setSelectedRange(firstMatchRange)
                commandOutputView.scrollToSelection()
                commandOutputView.moveMouseCursorToSelectedRange()
            } else if let firstMatchRange: NSRange = regex.firstMatchInString(commandOutputView.string!, options: [], range: backwardRange)?.range {
                commandOutputView.setSelectedRange(firstMatchRange)
                commandOutputView.scrollToSelection()
                commandOutputView.moveMouseCursorToSelectedRange()
            }
        } catch {
            NSLog("\(error)")
        }
    }
    
    func runECCmd(cmd: ECCmd) throws {
        switch(cmd) {
        case ECCmd.Edit(let cmdLine):
            var fileFolderPath: String? = self.workingDir
            let currDot = commandOutputView.selectedRange()
            try runCmdLine(
                TextEdit(
                    storage: commandOutputView.textStorage!.string,
                    dot: (currDot.location, currDot.location + currDot.length)),
                textview: commandOutputView,
                cmdLine: cmdLine, folderPath: fileFolderPath)
        case ECCmd.Look(let str):
            findString(str)
        case .External(let str, let execType):
            var fileFolderPath: String? = self.workingDir
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
                    if let ecdoc = newdoc as? ECDocument {
                        ecdoc.jumpAddr = fileAddr.addr
                    }
                    if !alreadyp {
                        newdoc.makeWindowControllers()
                    }
                    newdoc.showWindows()
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
    
    //MARK: WorkingFolderDataSource
    func workingFolder() -> String? {
        return self.workingDir
    }
}