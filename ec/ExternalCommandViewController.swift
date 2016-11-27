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
    
    var parentWindowController: NSWindowController!
    var cmdTask: Process!
    var outPipe: Pipe!
    var workingDir: String!
    var command: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commandOutputView.usesFindBar = true
        commandOutputView.isIncrementalSearchingEnabled = true
        commandOutputView.font = Preference.font()
        commandOutputView.delegate = self
        commandOutputView.selectionDelegate = self
        commandOutputView.isAutomaticTextReplacementEnabled = false
        commandOutputView.isAutomaticLinkDetectionEnabled = false
        commandOutputView.isAutomaticDataDetectionEnabled = false
        commandOutputView.isAutomaticDashSubstitutionEnabled = false
        commandOutputView.isAutomaticQuoteSubstitutionEnabled = false
        commandOutputView.isAutomaticSpellingCorrectionEnabled = false
        commandOutputView.workingFolderDataSource = self
        
    }
    
    func executeCommand(_ workingDir: String, command: String) {
        //Clear whole text and run command
        self.commandOutputView.textStorage?.setAttributedString(
            NSAttributedString(string: ""))
        self.workingDir = workingDir
        
        var output : [String] = []
        
        cmdTask = Process()
        let ax = ["-l", "-c", command]
        cmdTask.launchPath = Util.getShell()
        cmdTask.arguments = ax
        cmdTask.currentDirectoryPath = workingDir

        self.workingDir = cmdTask.currentDirectoryPath
        self.command = command
        
        outPipe = Pipe()
        cmdTask.standardOutput = outPipe
        cmdTask.standardError = outPipe
        
        cmdTask.launch()
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(ExternalCommandViewController.notificationReadedData(_:)), name: FileHandle.readCompletionNotification, object: nil)
        outPipe.fileHandleForReading.readInBackgroundAndNotify()
    }
    
    func notificationReadedData(_ notification: Notification) {
        var output: Data = notification.userInfo![NSFileHandleNotificationDataItem] as! Data
        let outputStr: NSString = NSString(data: output, encoding: String.Encoding.utf8.rawValue)!
        let outAttrStr = NSMutableAttributedString(string: String(outputStr))
        outAttrStr.addAttributes([NSForegroundColorAttributeName: NSColor.white], range: NSMakeRange(0, output.count))
        self.commandOutputView.textStorage?.append(outAttrStr)
        if cmdTask.isRunning {
            outPipe.fileHandleForReading.readInBackgroundAndNotify()
        } else {
            let exitMsg = "\n[COMMAND OUTPUT FINISH EXIT STATUS: \(cmdTask.terminationStatus)]"
            let exitMessage = NSMutableAttributedString(string: exitMsg)
            exitMessage.addAttributes([NSForegroundColorAttributeName: NSColor.white], range: NSMakeRange(0, exitMsg.characters.count))
            self.commandOutputView.textStorage?.append(exitMessage)
            NotificationCenter.default.removeObserver(self,
                                                                name: FileHandle.readCompletionNotification, object: nil)
        }
        self.commandOutputView.scrollToEndOfDocument(nil)
    }

    //MARK: Utils
    func selectedText() -> String? {
        let selectedNSRange = commandOutputView.selectedRange()
        if selectedNSRange.location != NSNotFound {
            let selectedRange = commandOutputView.string!.characters.index(commandOutputView.string!.startIndex, offsetBy: selectedNSRange.location) ..< commandOutputView.string!.characters.index(commandOutputView.string!.startIndex, offsetBy: selectedNSRange.location + selectedNSRange.length)
            return commandOutputView.string?.substring(with: selectedRange)
        } else {
            return nil
        }
    }
    
    func findBackwardString(_ str: String) {
        do {
            let regex = try NSRegularExpression(pattern: str, options: [
                NSRegularExpression.Options.ignoreMetacharacters
                ])
            var selectedRange = commandOutputView.selectedRange()
            if selectedRange.location == NSNotFound {
                selectedRange = NSMakeRange(0, 0)
            }
            let selectionHead = selectedRange.location
            let selectionEnd = selectedRange.location + selectedRange.length
            let forwardRange = NSMakeRange(selectionEnd, commandOutputView.string!.characters.count - selectionEnd)
            let backwardRange = NSMakeRange(0, selectionHead)
            if let lastBackwardMatch = regex.matches(in: commandOutputView.string!, options: [], range: backwardRange).last {
                commandOutputView.setSelectedRange(lastBackwardMatch.range)
                commandOutputView.scrollToSelection()
                commandOutputView.moveMouseCursorToSelectedRange()
            } else if let lastForwardMatch = regex.matches(in: commandOutputView.string!, options: [], range: forwardRange).last {
                commandOutputView.setSelectedRange(lastForwardMatch.range)
                commandOutputView.scrollToSelection()
                commandOutputView.moveMouseCursorToSelectedRange()
            }
        } catch {
            NSLog("\(error)")
        }
    }
    
    func findString(_ str: String) {
        do {
            let regex = try NSRegularExpression(pattern: str, options: [
                NSRegularExpression.Options.ignoreMetacharacters
                ])
            var selectedRange = commandOutputView.selectedRange()
            if selectedRange.location == NSNotFound {
                selectedRange = NSMakeRange(0, 0)
            }
            let selectionHead = selectedRange.location
            let selectionEnd = selectedRange.location + selectedRange.length
            let forwardRange = NSMakeRange(selectionEnd, commandOutputView.string!.characters.count - selectionEnd)
            let backwardRange = NSMakeRange(0, selectionHead)
            if let firstMatchRange: NSRange = regex.firstMatch(in: commandOutputView.string!, options: [], range: forwardRange)?.range {
                commandOutputView.setSelectedRange(firstMatchRange)
                commandOutputView.scrollToSelection()
                commandOutputView.moveMouseCursorToSelectedRange()
            } else if let firstMatchRange: NSRange = regex.firstMatch(in: commandOutputView.string!, options: [], range: backwardRange)?.range {
                commandOutputView.setSelectedRange(firstMatchRange)
                commandOutputView.scrollToSelection()
                commandOutputView.moveMouseCursorToSelectedRange()
            }
        } catch {
            NSLog("\(error)")
        }
    }
    
    func runECCmd(_ cmd: ECCmd) throws {
        switch(cmd) {
        case ECCmd.edit(let cmdLine):
            var fileFolderPath: String? = self.workingDir
            let currDot = commandOutputView.selectedRange()
            try runCmdLine(
                TextEdit(
                    storage: commandOutputView.textStorage!.string,
                    dot: (currDot.location, currDot.location + currDot.length)),
                textview: commandOutputView,
                cmdLine: cmdLine, folderPath: fileFolderPath)
        case ECCmd.look(let str):
            findString(str)
        case ECCmd.lookback(let str):
            findBackwardString(str)
        case .external(let str, let execType):
            var fileFolderPath: String? = self.workingDir
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
    func onFileAddrSelection(_ fileAddr: FileAddr, by: NSEvent) {
        NSDocumentController.shared().openDocument(
            withContentsOf: URL(fileURLWithPath: fileAddr.filepath),
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
    
    func onRightMouseSelection(_ str: String, by: NSEvent) {
        findString(str)
    }
    
    func onOtherMouseSelection(_ str: String, by: NSEvent) {
        runCommand(str)
    }
    
    //MARK: WorkingFolderDataSource
    func workingFolder() -> String? {
        return self.workingDir
    }
    
    //NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        cleaning()
    }
    
    func cleaning() {
        NotificationCenter.default.removeObserver(self,
                                                            name: FileHandle.readCompletionNotification, object: nil)
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate {
            appDelegate.commandWCs["\(self.workingDir) \(self.command)+Errors"] = nil
        }
        if let cmdtask = self.cmdTask {
            cmdtask.terminate()
        }
    }
}
