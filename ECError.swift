//
//  ECError.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/06.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation

enum ECError: Error {
    case patternNotFound(String)
    case addrOutOfRange
    case illigalState
    case systemCmdExecuteError(String)
    case openingBinaryFile
}
