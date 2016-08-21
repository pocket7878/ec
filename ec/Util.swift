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
        let env = NSProcessInfo.processInfo().environment
        if let value = env["SHELL"] {
            return value
        } else {
            return "/bin/sh"
        }
    }
    
    class func appInstalled(appName: String) -> Bool {
        let res = Util.runCommand("osascript", inputStr: "id of app \"\(appName)\"", wdir: nil, args: [])
        if res.exitCode == 0 {
            return true
        } else {
            return false
        }
    }
    
    class func runCommandWithoutSeparateOutAndError(cmd : String, inputStr: String?, wdir: String?, args : [String]) -> (output: [String], exitCode: Int32) {
        
        var output : [String] = []
        
        let task = NSTask()
        var ax = ["-l", "-c", cmd]
        ax.appendContentsOf(args)
        task.launchPath = Util.getShell()
        task.arguments = ax
        if let wdir = wdir {
            task.currentDirectoryPath = wdir
        } else {
            task.currentDirectoryPath = "~/"
        }
        
        if let instr = inputStr,
            inData = instr.dataUsingEncoding(NSUTF8StringEncoding) {
            let inpipe = NSPipe()
            task.standardInput = inpipe
            let handle = inpipe.fileHandleForWriting
            handle.writeData(inData)
            handle.closeFile()
        }
        
        let outpipe = NSPipe()
        task.standardOutput = outpipe
        task.standardError = outpipe
        
        task.launch()
        
        
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = NSString(data: outdata, encoding: NSUTF8StringEncoding) {
            string = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            output = string.componentsSeparatedByString("\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, status)
    }
    
    class func runCommand(cmd : String, inputStr: String?, wdir: String?, args : [String]) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = NSTask()
        var ax = ["-l", "-c", cmd]
        ax.appendContentsOf(args)
        task.launchPath = Util.getShell()
        task.arguments = ax
        if let wdir = wdir {
            task.currentDirectoryPath = wdir
        } else {
            task.currentDirectoryPath = "~/"
        }
        
        if let instr = inputStr,
            inData = instr.dataUsingEncoding(NSUTF8StringEncoding) {
            let inpipe = NSPipe()
            task.standardInput = inpipe
            let handle = inpipe.fileHandleForWriting
            handle.writeData(inData)
            handle.closeFile()
        }
        
        let outpipe = NSPipe()
        task.standardOutput = outpipe
        let errpipe = NSPipe()
        task.standardError = errpipe
        
        task.launch()
        
        
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = NSString(data: outdata, encoding: NSUTF8StringEncoding) {
            string = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            output = string.componentsSeparatedByString("\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = NSString(data: errdata, encoding: NSUTF8StringEncoding) {
            string = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            error = string.componentsSeparatedByString("\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, error, status)
    }
    
    private class func runExternalCommandIniTerm(command: String, inputString: String?, fileFolderPath: String?) {
        var inputFileName: String? = nil
        if let inputStr = inputString {
            //Create Temporary file and write inputStr to it
            let tempDir = NSTemporaryDirectory()
            let randomFileName = "\(tempDir)/\(NSDate().timeIntervalSince1970)-temp"
            inputFileName = randomFileName
            do {
                try inputStr.writeToFile(randomFileName, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                NSLog("\(error)")
            }
        }
        var cmdString = ""
        if let wdir = fileFolderPath {
            cmdString = "cd \(wdir) && "
        }
        cmdString = "\(cmdString) \(command)"
        if let inFile = inputFileName {
            cmdString = "\(cmdString) < \(inFile)"
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
    
    private class func runExternalCommandInTerminal(command: String, inputString: String?, fileFolderPath: String?) {
        Util.runCommand("osascript", inputStr: "tell application \"Terminal\" to activate", wdir: fileFolderPath, args: [])
        var inputFileName: String? = nil
        if let inputStr = inputString {
            //Create Temporary file and write inputStr to it
            let tempDir = NSTemporaryDirectory()
            let randomFileName = "\(tempDir)/\(NSDate().timeIntervalSince1970)-temp"
            inputFileName = randomFileName
            do {
                try inputStr.writeToFile(randomFileName, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                NSLog("\(error)")
            }
        }
        var cmdString = ""
        if let wdir = fileFolderPath {
            cmdString = "cd \(wdir) && "
        }
        cmdString = "\(cmdString) \(command)"
        if let inFile = inputFileName {
            cmdString = "\(cmdString) < \(inFile)"
        }
        Util.runCommand("osascript", inputStr: "tell application \"Terminal\" to do script(\"\(cmdString)\")", wdir: fileFolderPath, args: [])
    }

    class func runExternalCommand(command: String, inputString: String?, fileFolderPath: String?) {
        var wdir = ""
        if let fileFolderPath = fileFolderPath {
            wdir = fileFolderPath
        } else {
            wdir = "~/"
        }
        if let appDelegate = NSApplication.sharedApplication().delegate as? AppDelegate {
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
                let windowController = storyBoard.instantiateControllerWithIdentifier("ExternalCommandWC") as! NSWindowController
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
}