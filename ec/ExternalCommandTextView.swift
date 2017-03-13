//
//  ExternalCommandTextView.swift
//  ec
//
//  Created by 十亀眞怜 on 2017/03/12.
//  Copyright © 2017年 十亀眞怜. All rights reserved.
//

import Foundation
import PseudoTeletypewriter
import VT100Parser

class ExternalCommandTextView: ECTextView, NSTextViewDelegate, WorkingFolderDataSource {
    
    var pty: PseudoTeletypewriter!
    var workingDir: String!
    var command: String!
    
    var commandOutputTail: Int = 0
    var currentOutputFg: NSColor = Preference.mainFgColor
    var currentOutputBg: NSColor = Preference.mainBgColor
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.usesFindBar = true
        self.isIncrementalSearchingEnabled = true
        self.font = Preference.font
        self.delegate = self
        self.isAutomaticTextReplacementEnabled = false
        self.isAutomaticLinkDetectionEnabled = false
        self.isAutomaticDataDetectionEnabled = false
        self.isAutomaticDashSubstitutionEnabled = false
        self.isAutomaticQuoteSubstitutionEnabled = false
        self.isAutomaticSpellingCorrectionEnabled = false
        self.workingFolderDataSource = self
        self.backgroundColor = Preference.mainBgColor
        self.insertionPointColor = Preference.mainFgColor
        self.textColor = Preference.mainFgColor
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
        self.textStorage?.append(genOutputAttributeString(error))
        let exitMsg = "\n\(command): exit \(statusCode)"
        self.textStorage?.append(genOutputAttributeString(exitMsg))
        self.scrollToEndOfDocument(nil)
    }
    
    func executeCommand(_ workingDir: String, command: String) {
        let shell = Util.getShell()
        let env = ProcessInfo.processInfo.environment
        var envs: [String] = []
        env.forEach { (key, val) in
            envs += ["\(key)=\(val)"]
        }
        envs += ["TERM=vt100"]
        envs += ["LANG=\(Util.getLang())"]
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
                                               selector: #selector(ExternalCommandTextView.notificationReadedData(_:)),
                                               name: FileHandle.readCompletionNotification, object: nil)
        pty.masterFileHandle.readInBackgroundAndNotify()
    }
    
    func notificationReadedData(_ notification: Notification) {
        let output: Data = notification.userInfo![NSFileHandleNotificationDataItem] as! Data
        let vt100cmds = parseVT100(bytes: Array<UInt8>(output))
        self.textStorage?.beginEditing()
        for cmd in vt100cmds {
            //Handle each commands
            switch(cmd) {
            case .backspace:
                if let textTail = self.textStorage?.length {
                    self.textStorage?.replaceCharacters(in: NSMakeRange(textTail - 1, 1), with: "")
                }
            case .bytes(let bs):
                if let outputStr = String(data: Data(bs), encoding: .utf8) {
                    self.textStorage?.append(genOutputAttributeString(outputStr))
                }
            case .carriageReturn:
                self.textStorage?.append(genOutputAttributeString("\r"))
            case .lineFeed:
                self.textStorage?.append(genOutputAttributeString("\n"))
            case .horizontalTab:
                self.textStorage?.append(genOutputAttributeString("\t"))
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
        self.textStorage?.endEditing()
        if !pty.isChildProcessFinished() {
            pty.masterFileHandle.readInBackgroundAndNotify()
        } else {
            let exitMsg = "\n[COMMAND OUTPUT FINISH EXIT STATUS: \(pty.childProcessExitStatus())]"
            let exitMessage = NSMutableAttributedString(string: exitMsg)
            exitMessage.addAttributes([NSForegroundColorAttributeName: Preference.mainFgColor], range: NSMakeRange(0, exitMsg.characters.count))
            self.textStorage?.append(exitMessage)
            NotificationCenter.default.removeObserver(self,
                                                      name: FileHandle.readCompletionNotification, object: nil)
        }
        self.commandOutputTail = self.textStorage?.length ?? 0
        self.scrollToEndOfDocument(nil)
    }
    
    override func doCommand(by selector: Selector) {
        debugPrint(selector)
        super.doCommand(by: selector)
    }
    
    override func deleteBackward(_ sender: Any?) {
        if let textTail = self.textStorage?.length,
            !self.hasMarkedText(), self.selectedRange().location == textTail,
            let bsStr = String(repeating: "\u{8}", count: 1).data(using: .utf8) {
            pty.masterFileHandle.write(bsStr)
        } else {
            super.deleteBackward(sender)
            self.commandOutputTail =  self.textStorage?.length ?? 0
        }
    }
    
    override func insertText(_ string: Any, replacementRange: NSRange) {
        let r = replacementRange.location != NSNotFound ? replacementRange : (self.hasMarkedText() ? self.markedRange() : self.selectedRange())
        if let string = string as? String {
            if let strData = string.data(using: .utf8, allowLossyConversion: true),
                r.location == commandOutputTail {
                debugPrint(Array<UInt8>(strData))
                //Added to tail
                pty.masterFileHandle.write(strData)
            } else if let bsStr = String(repeating: "\u{8}", count: r.length).data(using: .utf8),
                string.isEmpty,
                replacementRange.location != NSNotFound,
                (replacementRange.location + replacementRange.length) == commandOutputTail {
                pty.masterFileHandle.write(bsStr)
            } else {
                super.insertText(string, replacementRange: replacementRange)
            }
        }
    }
    
    func clearning() {
        NotificationCenter.default.removeObserver(self,
                                                  name: FileHandle.readCompletionNotification, object: nil)
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate {
            appDelegate.commandWCs["\(self.workingDir) \(self.command)+Errors"] = nil
        }
        pty.killChild(sig: SIGTERM)
    }
    
    //MARK: WorkingFolderDataSource
    func workingFolder() -> String? {
        return self.workingDir
    }
}
