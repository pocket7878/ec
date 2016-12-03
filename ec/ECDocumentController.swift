//
//  ECDocumentController.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/12/02.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import AppKit

class ECDocumentController: NSDocumentController {
    override init() {
        super.init()
        NSLog("ECDocumentController init")
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?, completionHandler: @escaping (Int) -> Void) {

        openPanel.showsHiddenFiles = true
        openPanel.canChooseDirectories = true
        super.beginOpenPanel(openPanel, forTypes: inTypes) { [weak self] (result: Int) in
            completionHandler(result)
        }
    }
}
