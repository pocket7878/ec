//
//  StringExtension.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/01.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation

extension String {
    var lines: [String] {
        var lines = [String]()
        self.enumerateLines { (line, stop) in
            lines.append(line)
        }
        return lines
    }
}