//
//  ECDocument.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/30.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

class ECDocument: NSDocument {
    
    var contentOfFile: NSAttributedString = NSAttributedString(string: "")
    
    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    override func makeWindowControllers() {
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyBoard.instantiateControllerWithIdentifier("WC") as! NSWindowController
        (windowController.contentViewController as? ViewController)?.doc = self
        (windowController.contentViewController as? ViewController)?.loadDoc()
        self.addWindowController(windowController)
    }
    
    override func dataOfType(typeName: String) throws -> NSData {
        for win in self.windowControllers {
            if let vc = win.contentViewController as? ViewController {
                vc.updateDoc()
            }
        }

        if let d = self.contentOfFile.string.dataUsingEncoding(NSUTF8StringEncoding) {
            return d
        }
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        self.contentOfFile = try NSAttributedString(URL: url, options: [:], documentAttributes: nil)
    }
    /*
    override func readFromData(data: NSData, ofType typeName: String) throws {
        do {
            let fileContents = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
            self.contentOfFile = fileContents
        } catch {
            throw error
        }
    }
 */
}