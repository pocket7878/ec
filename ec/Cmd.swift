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
    case LineAddr(UInt)
    case ForwardLineAddr(UInt)
    case BackwardLineAddr(UInt)
    case ForwardPatternAddr(PatternLike)
    case BackwardPatternAddr(PatternLike)
    case ComposeAddr(Addr, Addr)
    case Bof
    case Dot
    case Eof
}

indirect enum Cmd {
    case ACmd(String)
    case ICmd(String)
    case CCmd(String)
    case XCmd(PatternLike, Cmd)
    case DCmd()
    case GCmd(PatternLike, Cmd)
    case VCmd(PatternLike, Cmd)
    case YCmd(PatternLike, Cmd)
    case CmdGroup([CmdLine])
    case PipeCmd(String)
    case RedirectCmd(String)
}

struct CmdLine {
    let adders: [Addr]
    let cmd: Cmd?
}