//
//  NSDocumentExtension.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/31.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa

extension NSDocument {
    func sameFilePath(doc: NSDocument) -> Bool {
        if let myfileUrl = self.fileURL where myfileUrl.fileURL,
            let newfpath = myfileUrl.path,
            let fileUrl = doc.fileURL where fileUrl.fileURL,
            let fpath = fileUrl.path {
            return true
        } else {
            return false
        }
    }
}