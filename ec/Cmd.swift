//
//  Cmd.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/30.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import SwiftParsec

struct PatternLike {
    let pat: String
}

indirect enum Addr {
    case lineAddr(Int)
    case forwardLineAddr(Int)
    case backwardLineAddr(Int)
    case forwardPatternAddr(PatternLike)
    case backwardPatternAddr(PatternLike)
    case composeAddr(Addr, Addr)
    case bof
    case dot
    case eof
}

struct FileAddr {
    let filepath: String
    let addr: Addr?
}

enum ExternalExecType {
    case pipe
    case input
    case output
    case none
}

indirect enum Cmd {
    case aCmd(String)
    case iCmd(String)
    case cCmd(String)
    case xCmd(PatternLike, CmdLine)
    case dCmd()
    case gCmd(PatternLike, CmdLine)
    case vCmd(PatternLike, CmdLine)
    case yCmd(PatternLike, CmdLine)
    case cmdGroup([CmdLine])
    case external(String, ExternalExecType)
}

struct CmdLine {
    let adders: [Addr]
    let cmd: Cmd?
}

enum ECCmd {
    case edit(CmdLine)
    case look(String)
    case lookback(String)
    case external(String, ExternalExecType)
}
