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
    case LineAddr(Int)
    case ForwardLineAddr(Int)
    case BackwardLineAddr(Int)
    case ForwardPatternAddr(PatternLike)
    case BackwardPatternAddr(PatternLike)
    case ComposeAddr(Addr, Addr)
    case Bof
    case Dot
    case Eof
}

enum ExternalExecType {
    case Pipe
    case Input
    case Output
    case None
}

indirect enum Cmd {
    case ACmd(String)
    case ICmd(String)
    case CCmd(String)
    case XCmd(PatternLike, CmdLine)
    case DCmd()
    case GCmd(PatternLike, CmdLine)
    case VCmd(PatternLike, CmdLine)
    case YCmd(PatternLike, CmdLine)
    case CmdGroup([CmdLine])
    case External(String, ExternalExecType)
}

struct CmdLine {
    let adders: [Addr]
    let cmd: Cmd?
}

enum ECCmd {
    case Edit(CmdLine)
    case Look(String)
    case External(String, ExternalExecType)
}