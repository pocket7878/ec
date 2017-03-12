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
import PseudoTeletypewriter
import VT100Parser

class ExternalCommandViewController: NSViewController, ECTextViewSelectionDelegate, NSTextViewDelegate, WorkingFolderDataSource, NSWindowDelegate {
    
    var parentWindowController: NSWindowController!
    @IBOutlet var commandOutputView: ECTextView!
    var pty: PseudoTeletypewriter!
    var workingDir: String!
    var command: String!
    
    var currentOutputFg: NSColor = Preference.mainFgColor
    var currentOutputBg: NSColor = Preference.mainBgColor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commandOutputView.usesFindBar = true
        commandOutputView.isIncrementalSearchingEnabled = true
        commandOutputView.font = Preference.font
        commandOutputView.delegate = self
        commandOutputView.selectionDelegate = self
        commandOutputView.isAutomaticTextReplacementEnabled = false
        commandOutputView.isAutomaticLinkDetectionEnabled = false
        commandOutputView.isAutomaticDataDetectionEnabled = false
        commandOutputView.isAutomaticDashSubstitutionEnabled = false
        commandOutputView.isAutomaticQuoteSubstitutionEnabled = false
        commandOutputView.isAutomaticSpellingCorrectionEnabled = false
        commandOutputView.workingFolderDataSource = self
        commandOutputView.backgroundColor = Preference.mainBgColor
        commandOutputView.insertionPointColor = Preference.mainFgColor
        commandOutputView.textColor = Preference.mainFgColor
    }
    
    func genOutputAttributeString(_ str: String) -> NSAttributedString {
        let outAttrStr = NSMutableAttributedString(string: str)
        outAttrStr.setAttributes([
            NSForegroundColorAttributeName: currentOutputFg,
            NSBackgroundColorAttributeName: currentOutputBg,
            NSFontAttributeName: Preference.font
        ], range: NSMakeRange(0, str.characters.count))
        return outAttrStr
    }
    
    func showErrorOutput(_ workingDir: String, command: String, error: String, statusCode: Int) {
        self.commandOutputView.textStorage?.append(genOutputAttributeString(error))
        let exitMsg = "\n\(command): exit \(statusCode)"
        self.commandOutputView.textStorage?.append(genOutputAttributeString(exitMsg))
        self.commandOutputView.scrollToEndOfDocument(nil)
    }
    
    func executeCommand(_ workingDir: String, command: String) {
        let shell = Util.getShell()
        let env = ProcessInfo.processInfo.environment
        var envs: [String] = []
        env.forEach { (key, val) in
            envs += ["\(key)=\(val)"]
        }
        envs += ["TERM=vt100"]
        var envpath = shell
        for (ek, ev) in env {
            if (ek == "PATH") {
                envpath = ev
            }
        }
        pty = PseudoTeletypewriter(path: shell, arguments: [shell, "-l", "-c", "cd \(workingDir) && \(command)"], environment: envs)!
        self.workingDir = workingDir
        self.command = command
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ExternalCommandViewController.notificationReadedData(_:)),
                                               name: FileHandle.readCompletionNotification, object: nil)
        pty.masterFileHandle.readInBackgroundAndNotify()
    }
    
    func notificationReadedData(_ notification: Notification) {
        let output: Data = notification.userInfo![NSFileHandleNotificationDataItem] as! Data
        let vt100cmds = parseVT100(bytes: Array<UInt8>(output))
        self.commandOutputView.textStorage?.beginEditing()
        for cmd in vt100cmds {
            //Handle each commands
            switch(cmd) {
            case .backspace:
                if let textTail = self.commandOutputView.textStorage?.length {
                    self.commandOutputView.textStorage?.replaceCharacters(in: NSMakeRange(textTail - 1, 1), with: "")
                }
            case .bytes(let bs):
                let outputStr = String(NSString(data: Data(bs), encoding: String.Encoding.utf8.rawValue)!)
                self.commandOutputView.textStorage?.append(genOutputAttributeString(outputStr))
            case .carriageReturn:
                self.commandOutputView.textStorage?.append(genOutputAttributeString("\r"))
            case .lineFeed:
                self.commandOutputView.textStorage?.append(genOutputAttributeString("\n"))
            case .horizontalTab:
                self.commandOutputView.textStorage?.append(genOutputAttributeString("\t"))
            case .bell:
                NSBeep()
            //Background Colors
            case .setBgBlack:
                currentOutputBg = NSColor.black
            case .setBgRed:
                currentOutputBg = NSColor.red
            case .setBgGreen:
                currentOutputBg = NSColor.green
            case .setBgYellow:
                currentOutputBg = NSColor.yellow
            case .setBgBlue:
                currentOutputBg = NSColor.blue
            case .setBgMagenta:
                currentOutputBg = NSColor.magenta
            case .setBgCyan:
                currentOutputBg = NSColor.cyan
            case .setBgWhite:
                currentOutputBg = NSColor.white
            case .setBgDefault:
                currentOutputBg = Preference.mainBgColor
            //Foreground Colors
            case .setFgBlack:
                currentOutputFg = NSColor.black
            case .setFgRed:
                currentOutputFg = NSColor.red
            case .setFgGreen:
                currentOutputFg = NSColor.green
            case .setFgYellow:
                currentOutputFg = NSColor.yellow
            case .setFgBlue:
                currentOutputFg = NSColor.blue
            case .setFgMagenta:
                currentOutputFg = NSColor.magenta
            case .setFgCyan:
                currentOutputFg = NSColor.cyan
            case .setFgWhite:
                currentOutputFg = NSColor.white
            case .setFgDefault:
                currentOutputFg = Preference.mainFgColor
            default:
                break
            }
        }
        self.commandOutputView.textStorage?.endEditing()
        if !pty.isChildProcessFinished() {
            pty.masterFileHandle.readInBackgroundAndNotify()
        } else {
            let exitMsg = "\n[COMMAND OUTPUT FINISH EXIT STATUS: \(pty.childProcessExitStatus())]"
            let exitMessage = NSMutableAttributedString(string: exitMsg)
            exitMessage.addAttributes([NSForegroundColorAttributeName: Preference.mainFgColor], range: NSMakeRange(0, exitMsg.characters.count))
            self.commandOutputView.textStorage?.append(exitMessage)
            NotificationCenter.default.removeObserver(self,
                                                      name: FileHandle.readCompletionNotification, object: nil)
        }
        self.commandOutputView.scrollToEndOfDocument(nil)
    }

    //MARK: Utils
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
            commandOutputView.findString(str)
        case ECCmd.lookback(let str):
            commandOutputView.findBackwardString(str)
        case .external(let str, let execType):
            var fileFolderPath: String? = self.workingDir
            switch(execType) {
            case .pipe, .input, .output:
                try runECCmd(ECCmd.edit(CmdLine(adders: [], cmd: Cmd.external(str, execType))))
            case .none:
                Util.runExternalCommand(str, inputString: nil, fileFolderPath: fileFolderPath)
            }
        case .win():
            Util.startWin(workingFolder: self.workingFolder())
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
        commandOutputView.findString(str)
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
        pty.killChild(sig: SIGTERM)
    }
    
    //NSTextViewDelegate
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let replacementString = replacementString else {
            return true
        }
        let textTail = textView.textStorage?.length
        if let strData = replacementString.data(using: .utf8),
            affectedCharRange.location == textTail {
            //Added to tail
            pty.masterFileHandle.write(strData)
            return false
        } else if let bsStr = String(repeating: "\u{8}", count: affectedCharRange.length).data(using: .utf8),
            replacementString.isEmpty,
            affectedCharRange.location != NSNotFound,
            (affectedCharRange.location + affectedCharRange.length) == textTail {
            pty.masterFileHandle.write(bsStr)
            return false
        }
        return true
    }
}
