//
//  Util.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/15.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation

class Util {
    class func getShell() -> String {
        let env = NSProcessInfo.processInfo().environment
        if let value = env["SHELL"] {
            return value
        } else {
            return "/bin/sh"
        }
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
    
    class func runExternalCommand(command: String, fileFolderPath: String?) {
        Util.runCommand("osascript", inputStr: "tell application \"Terminal\" to activate", wdir: fileFolderPath, args: [])
        if let wdir = fileFolderPath {
            Util.runCommand("osascript", inputStr: "tell application \"Terminal\" to do script (\"cd \(wdir) && \(command)\")", wdir: fileFolderPath, args: [])
        } else {
            Util.runCommand("osascript", inputStr: "tell application \"Terminal\" to do script (\"\(command)\")", wdir: fileFolderPath, args: [])
        }
    }
}