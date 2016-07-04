//
//  ECTextFinderClient.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/04.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

class ECTextFinderClient: NSObject, NSTextFinderClient {
    
    let textView: NSTextView
    
    init(textView: NSTextView) {
        self.textView = textView
        super.init()
    }
    
    var string: String {
        return textView.string ?? ""
    }
}