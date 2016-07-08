//
//  TextView.swift
//  Review
//
//  Created by Matthias Hochgatterer on 03/04/15.
//  Copyright (c) 2015 Matthias Hochgatterer. All rights reserved.
//

import AppKit

class CodeTextView: NSTextView {
    weak var rulerView: NSRulerView?
    
    var text: String {
        get {
            if let str = self.string {
                return str
            }
            return ""
        }
    }
    
    override func updateRuler() {
        super.updateRuler()
        rulerView?.needsDisplay = true
    }
}
