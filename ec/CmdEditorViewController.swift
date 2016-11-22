//
//  CmdEditorViewController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/14.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

protocol CmdEditDelegate: class {
    func onCmdEditCancel()
    func onCmdEditSave(_ newCmd: String)
}

class CmdEditorViewController: NSViewController {
    
    weak var delegate: CmdEditDelegate?
    
    @IBOutlet var editorTextView: NSTextView!
    
    @IBAction func cancelBtnTouched(_ sender: Any) {
        self.delegate?.onCmdEditCancel()
    }
    
    @IBAction func saveBtnTouched(_ sender: Any) {
        self.delegate?.onCmdEditSave(editorTextView.string!)
    }
}
