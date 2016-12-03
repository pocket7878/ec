//
//  PreferenceEntry.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/12/03.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import Cocoa
import Yaml

struct PreferenceEntry<T> {
    let loader: (Yaml) -> T
}
