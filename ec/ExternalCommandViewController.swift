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

class ExternalCommandViewController: NSViewController, ECTextViewSelectionDelegate, NSTextViewDelegate, WorkingFolderDataSource, NSWindowDelegate {
    
    @IBOutlet var commandOutputView: ECTextView!
    
    var cmdTask: NSTask!
    var outPipe: NSPipe!
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
        self.commandOutputView.textStorage?.setAttributedString(
            NSAttributedString(string: ""))
        self.workingDir = workingDir
        
        var output : [String] = []
        
        cmdTask = NSTask()
        var ax = ["-l", "-c", command]
        cmdTask.launchPath = Util.getShell()
        cmdTask.arguments = ax
        if let wdir = workingDir {
            cmdTask.currentDirectoryPath = wdir
        } else {
            cmdTask.currentDirectoryPath = "~/"
        }
        
        outPipe = NSPipe()
        cmdTask.standardOutput = outPipe
        cmdTask.standardError = outPipe
        
        cmdTask.launch()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(ExternalCommandViewController.notificationReadedData(_:)), name: NSFileHandleReadCompletionNotification, object: nil)
        outPipe.fileHandleForReading.readInBackgroundAndNotify()
    }
    
    func notificationReadedData(notification: NSNotification) {
        var output: NSData = notification.userInfo![NSFileHandleNotificationDataItem] as! NSData
        var outputStr: NSString = NSString(data: output, encoding: NSUTF8StringEncoding)!
        if cmdTask.running {
            outPipe.fileHandleForReading.readInBackgroundAndNotify()
        } else {
            NSNotificationCenter.defaultCenter().removeObserver(self,
                                                                name: NSFileHandleReadCompletionNotification, object: nil)
        }
        var outAttrStr = NSMutableAttributedString(string: String(outputStr))
        outAttrStr.addAttributes([NSForegroundColorAttributeName: NSColor.whiteColor()], range: NSMakeRange(0, output.length))
        self.commandOutputView.textStorage?.appendAttributedString(outAttrStr)
        self.commandOutputView.scrollToEndOfDocument(nil)
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
    
    //NSWindowDelegate
    func windowWillClose(notification: NSNotification) {
        cleaning()
    }
    
    func cleaning() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: NSFileHandleReadCompletionNotification, object: nil)
        if let cmdtask = self.cmdTask {
            cmdtask.terminate()
        }
    }
}