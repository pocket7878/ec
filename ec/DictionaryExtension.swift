//
//  DictionaryExtension.swift
//  ec
//
//  Created by 十亀眞怜 on 2017/02/01.
//  Copyright © 2017年 十亀眞怜. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func updateIfNotNull(key: Key, newVal: Value?) {
        if let newV = newVal {
            self[key] = newV
        }
    }
}
