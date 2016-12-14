//
//  Util.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/15.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa

class Util {
    
    class func getShell() -> String {
        let env = ProcessInfo.processInfo.environment
        if let value = env["SHELL"] {
            return value
        } else {
            return "/bin/sh"
        }
    }
    
    class func appInstalled(_ appName: String) -> Bool {
        let res = Util.runCommand("osascript", inputStr: "id of app \"\(appName)\"", wdir: nil, args: [])
        if res.exitCode == 0 {
            return true
        } else {
            return false
        }
    }
    
    class func runCommandWithoutSeparateOutAndError(_ cmd : String, inputStr: String?, wdir: String?, args : [String]) -> (output: [String], exitCode: Int32) {
        
        var output : [String] = []
        
        let task = Process()
        var ax = ["-l", "-c", ([cmd] + args).joined(separator: " ")]
        task.launchPath = Util.getShell()
        task.arguments = ax
        if let wdir = wdir {
            task.currentDirectoryPath = wdir
        } else {
            task.currentDirectoryPath = "~/"
        }
        
        if let instr = inputStr,
            let inData = instr.data(using: String.Encoding.utf8) {
            let inpipe = Pipe()
            task.standardInput = inpipe
            let handle = inpipe.fileHandleForWriting
            handle.write(inData)
            handle.closeFile()
        }
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = outpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = NSString(data: outdata, encoding: String.Encoding.utf8.rawValue) {
            string = string.trimmingCharacters(in: CharacterSet.newlines) as NSString
            output = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, status)
    }
    
    class func runCommand(_ cmd : String, inputStr: String?, wdir: String?, args : [String]) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = Process()
        var ax = ["-l", "-c", ([cmd] + args).joined(separator: " ")]
        task.launchPath = Util.getShell()
        task.arguments = ax
        if let wdir = wdir {
            task.currentDirectoryPath = wdir
        } else {
            task.currentDirectoryPath = "~/"
        }
        
        if let instr = inputStr,
            let inData = instr.data(using: String.Encoding.utf8) {
            let inpipe = Pipe()
            task.standardInput = inpipe
            let handle = inpipe.fileHandleForWriting
            handle.write(inData)
            handle.closeFile()
        }
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = NSString(data: outdata, encoding: String.Encoding.utf8.rawValue) {
            string = string.trimmingCharacters(in: CharacterSet.newlines) as NSString
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = NSString(data: errdata, encoding: String.Encoding.utf8.rawValue) {
            string = string.trimmingCharacters(in: CharacterSet.newlines) as NSString
            error = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, error, status)
    }
    
    fileprivate class func runShellIniTerm(fileFolderPath: String?) {
        var cmdString = ""
        if let wdir = fileFolderPath {
            cmdString = "cd \(wdir)"
        }
        var script = "tell application \"iTerm\"\n"
        script += "\tactivate\n"
        script += "\tset newWindow to (create window with default profile)\n"
        script += "\ttell newWindow\n"
        script += "\t\ttell current session\n"
        script += "\t\t\twrite text \"\(cmdString)\"\n"
        script += "\t\tend tell\n"
        script += "\tend tell\n"
        script += "end tell"
        Util.runCommand("osascript", inputStr: script, wdir: fileFolderPath, args: [])
    }
    
    fileprivate class func runShellInTerminal(fileFolderPath: String?) {
        Util.runCommand("osascript", inputStr: "tell application \"Terminal\" to activate", wdir: fileFolderPath, args: [])
        var cmdString = ""
        if let wdir = fileFolderPath {
            cmdString = "cd \(wdir)"
        }
        Util.runCommand(
            "osascript",
            inputStr: "tell application \"Terminal\" to do script(\"\(cmdString)\")",
            wdir: fileFolderPath,
            args: [])
    }
    
    class func showExternalCommandError(_ command: String, error: String, statusCode: Int, fileFolderPath: String?) {
        var wdir = ""
        if let fileFolderPath = fileFolderPath {
            wdir = fileFolderPath
        } else {
            wdir = "~/"
        }
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate {
            if let windowController = appDelegate.commandWCs["\(wdir) \(command)+Errors"] {
                if let vc = windowController.contentViewController as? ExternalCommandViewController {
                    vc.parentWindowController = windowController
                    vc.showErrorOutput(wdir, command: command, error: error, statusCode: statusCode)
                    if let win = windowController.window {
                        var winTitle = ""
                        if let wdir = fileFolderPath {
                            winTitle = "\(wdir) \(command)+Errors"
                        } else {
                            winTitle = "\(command)+Errors"
                        }
                        win.title = winTitle
                        win.delegate = vc
                    }
                }
                windowController.showWindow(nil)
                windowController.becomeFirstResponder()
            } else {
                let storyBoard = NSStoryboard(name: "ExternalCommandView", bundle: nil)
                let windowController = storyBoard.instantiateController(withIdentifier: "ExternalCommandWC") as! NSWindowController
                appDelegate.commandWCs["\(wdir) \(command)+Errors"] = windowController
                if let vc = windowController.contentViewController as? ExternalCommandViewController {
                    vc.parentWindowController = windowController
                    vc.showErrorOutput(wdir, command: command, error: error, statusCode: statusCode)
                    if let win = windowController.window {
                        var winTitle = ""
                        if let wdir = fileFolderPath {
                            winTitle = "\(wdir) \(command)+Errors"
                        } else {
                            winTitle = "\(command)+Errors"
                        }
                        win.title = winTitle
                        win.delegate = vc
                    }
                }
                windowController.showWindow(nil)
                windowController.becomeFirstResponder()
            }
        }
    }

    class func runExternalCommand(_ command: String, inputString: String?, fileFolderPath: String?) {
        var wdir = ""
        if let fileFolderPath = fileFolderPath {
            wdir = fileFolderPath
        } else {
            wdir = NSHomeDirectory()
        }
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate {
            if let windowController = appDelegate.commandWCs["\(wdir) \(command)+Errors"] {
                if let vc = windowController.contentViewController as? ExternalCommandViewController {
                    vc.parentWindowController = windowController
                    vc.executeCommand(wdir, command: command)
                    if let win = windowController.window {
                        var winTitle = ""
                        if let wdir = fileFolderPath {
                            winTitle = "\(wdir) \(command)+Errors"
                        } else {
                            winTitle = "\(command)+Errors"
                        }
                        win.title = winTitle
                        win.delegate = vc
                    }
                }
                windowController.showWindow(nil)
                windowController.becomeFirstResponder()
            } else {
                let storyBoard = NSStoryboard(name: "ExternalCommandView", bundle: nil)
                let windowController = storyBoard.instantiateController(withIdentifier: "ExternalCommandWC") as! NSWindowController
                appDelegate.commandWCs["\(wdir) \(command)+Errors"] = windowController
                if let vc = windowController.contentViewController as? ExternalCommandViewController {
                    vc.parentWindowController = windowController
                    vc.executeCommand(wdir, command: command)
                    if let win = windowController.window {
                        var winTitle = ""
                        if let wdir = fileFolderPath {
                            winTitle = "\(wdir) \(command)+Errors"
                        } else {
                            winTitle = "\(command)+Errors"
                        }
                        win.title = winTitle
                        win.delegate = vc
                    }
                }
                windowController.showWindow(nil)
                windowController.becomeFirstResponder()
            }
        }
    }
    
    class func startWin(workingFolder: String?) {
        if appInstalled("iTerm") {
            runShellIniTerm(fileFolderPath: workingFolder)
        } else {
            runShellInTerminal(fileFolderPath: workingFolder)
        }
    }
}
