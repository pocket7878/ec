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
    
    class func runExternalCommand(command: String, inputString: String?, fileFolderPath: String?) {
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
}