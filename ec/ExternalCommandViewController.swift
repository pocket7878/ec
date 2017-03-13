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

class ExternalCommandViewController: NSViewController, ECTextViewSelectionDelegate, NSTextViewDelegate, WorkingFolderDataSource, NSWindowDelegate{
    
    var parentWindowController: NSWindowController!
    @IBOutlet var commandOutputView: ExternalCommandTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commandOutputView.selectionDelegate = self
    }
    
    func showErrorOutput(_ workingDir: String, command: String, error: String, statusCode: Int) {
        commandOutputView.showErrorOutput(workingDir, command: command, error: error, statusCode: statusCode)
    }
    
    func executeCommand(_ workingDir: String, command: String) {
        commandOutputView.executeCommand(workingDir, command: command)
    }
    
    //MARK: Utils
    func runECCmd(_ cmd: ECCmd) throws {
        switch(cmd) {
        case ECCmd.edit(let cmdLine):
            var fileFolderPath: String? = self.commandOutputView.workingFolder()
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
            var fileFolderPath: String? = self.commandOutputView.workingFolder()
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
        return commandOutputView.workingFolder()
    }
    
    //NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        cleaning()
    }
    
    func cleaning() {
        self.commandOutputView.clearning()

    }
}
