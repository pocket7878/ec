//
//  CmdParser.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/06/30.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import SwiftParsec

//MARK: Edit Command
/*
 * Parsing pattern like
 */
let patternLikeParser: GenericParser<String, (), PatternLike> = (StringParser.character("/") *> (StringParser.noneOf("/").many.stringValue) <* (StringParser.character("/") <?> "Unclosed Pattern Slash")) >>- { patternStr in
    return GenericParser(result: PatternLike(pat: patternStr))
}


/*
 * Text line parser
 */
let textLineParser: GenericParser<String, (), String> = (StringParser.noneOf("\n").many.stringValue <* StringParser.endOfLine) >>- { lineStr in
    return GenericParser(result: lineStr)
}

let dotLineParser: GenericParser<String, (), Bool> = (StringParser.character(".") *>
    StringParser.endOfLine *>
    GenericParser(result: true)).attempt <|>
    (StringParser.character(".") *> StringParser.eof *> GenericParser(result: true))

let textLinesParser: GenericParser<String, (), [String]> = textLineParser.manyTill(dotLineParser)

/*
 * Addr Parser
 */

let dotParser: GenericParser<String, (), Addr> = StringParser.character(".") >>- { _ in
    return GenericParser(result: Addr.Dot)
}

let bofParser: GenericParser<String, (), Addr> = StringParser.character("0") >>- { _ in
    return GenericParser(result: Addr.Bof)
}

let eofParser: GenericParser<String, (), Addr> = StringParser.character("$") >>- { _ in
    return GenericParser(result: Addr.Eof)
}

let lineNumberParser: GenericParser<String, (), Int> = StringParser.oneOf("123456789") >>- { head in
    StringParser.oneOf("0123456789").many.stringValue >>- {  body in
        let numStr = "\(head)\(body)"
        return GenericParser(result: Int(numStr)!)
    }
}

let forwardLineNumberAddrParser: GenericParser<String, (), Addr> = (StringParser.character("+") *> (lineNumberParser.attempt <|> GenericParser(result: 1))) >>- { lnum in
    return GenericParser(result: Addr.ForwardLineAddr(lnum))
}

let backwardLineNumberAddrParser: GenericParser<String, (), Addr> = (StringParser.character("-") *> (lineNumberParser.attempt <|> GenericParser(result: 1))) >>- { lnum in
    return GenericParser(result: Addr.BackwardLineAddr(lnum))
}

let lineAddrParser: GenericParser<String, (), Addr> = forwardLineNumberAddrParser.attempt <|> backwardLineNumberAddrParser.attempt <|> (lineNumberParser >>- { lnum in
    return GenericParser(result: Addr.LineAddr(lnum))
})

let forwardPatternAddrParser: GenericParser<String, (), Addr> = patternLikeParser >>- { pat in
    return GenericParser(result: Addr.ForwardPatternAddr(pat))
}

let backwardPatternAddrParser: GenericParser<String, (), Addr> = (StringParser.character("-") *> patternLikeParser) >>- { pat in
    return GenericParser(result: Addr.BackwardPatternAddr(pat))
}

let basicAddrParser: GenericParser<String, (), Addr> = dotParser.attempt <|> bofParser.attempt <|> eofParser.attempt <|> lineAddrParser.attempt <|> forwardPatternAddrParser.attempt <|> backwardPatternAddrParser.attempt

let leftAddrParser: GenericParser<String, (), Addr> = basicAddrParser.attempt <|> GenericParser(result: Addr.Bof)

let rightAddrParser: GenericParser<String, (), Addr> = basicAddrParser.attempt <|> GenericParser(result: Addr.Eof)

let composeAddrParser: GenericParser<String, (), Addr> = leftAddrParser >>- { leftAddr in
    (StringParser.character(",") *> rightAddrParser) >>- { rightAddr in
        return GenericParser(result: Addr.ComposeAddr(leftAddr, rightAddr))
    }
}

let addrParser: GenericParser<String, (), Addr> = composeAddrParser.attempt <|> basicAddrParser

/* 
 * Command Parser
 */

let patternStrOrMultilineParser: GenericParser<String, (), String> = ((patternLikeParser >>- { pat in
    return GenericParser(result: pat.pat)
    }) <|>
    ((StringParser.endOfLine *> textLinesParser) >>- { lines in
        let str = lines.joinWithSeparator("\n")
        return GenericParser(result: str)
        }))

let aCmdParser: GenericParser<String, (), Cmd> = StringParser.character("a") *> (patternStrOrMultilineParser >>- { str in
    return GenericParser(result: Cmd.ACmd(str))
})

let iCmdParser: GenericParser<String, (), Cmd> = StringParser.character("i") *> (patternStrOrMultilineParser >>- { str in
    return GenericParser(result: Cmd.ICmd(str))
    })

let cCmdParser: GenericParser<String, (), Cmd> = StringParser.character("c") *> (patternStrOrMultilineParser >>- { str in
    return GenericParser(result: Cmd.CCmd(str))
    })

let dCmdParser: GenericParser<String, (), Cmd> = StringParser.character("d") *> GenericParser(result: Cmd.DCmd())

let xCmdParser: GenericParser<String, (), Cmd> = StringParser.character("x") *> (patternLikeParser >>- { pat in
    (StringParser.spaces *> cmdLineParser) >>- { cmd in
        return GenericParser(result: Cmd.XCmd(pat, cmd))
    }
})

let yCmdParser: GenericParser<String, (), Cmd> = StringParser.character("y") *> (patternLikeParser >>- { pat in
    (StringParser.spaces *> cmdLineParser) >>- { cmd in
        return GenericParser(result: Cmd.YCmd(pat, cmd))
    }
    })

let gCmdParser: GenericParser<String, (), Cmd> = StringParser.character("g") *> (patternLikeParser >>- { pat in
    (StringParser.spaces *>  cmdLineParser) >>- { cmd in
        return GenericParser(result: Cmd.GCmd(pat, cmd))
    }
    })

let vCmdParser: GenericParser<String, (), Cmd> = StringParser.character("v") *> (patternLikeParser >>- { pat in
    (StringParser.spaces *> cmdLineParser) >>- { cmd in
        return GenericParser(result: Cmd.VCmd(pat, cmd))
    }
    })

let pipeCmdParser: GenericParser<String, (), Cmd> = StringParser.character("|") *> (patternLikeParser >>- { pat in
    return GenericParser(result: Cmd.External(pat.pat, .Pipe))
    })

let inputCmdParser: GenericParser<String, (), Cmd> = StringParser.character("<") *> (patternLikeParser >>- { pat in
    return GenericParser(result: Cmd.External(pat.pat, .Input))
    })

let outputCmdParser: GenericParser<String, (), Cmd> = StringParser.character(">") *> (patternLikeParser >>- { pat in
    return GenericParser(result: Cmd.External(pat.pat, .Output))
    })

let groupCmdParser: GenericParser<String, (), Cmd> = cmdLineParser.separatedBy(StringParser.endOfLine).between(StringParser.character("{"), StringParser.character("}")) >>- { cmds in
    return GenericParser(result: Cmd.CmdGroup(cmds))
}

let cmdParser: GenericParser<String, (), Cmd> = aCmdParser <|> iCmdParser <|> cCmdParser <|> dCmdParser <|> xCmdParser <|> yCmdParser <|> gCmdParser <|> vCmdParser <|> pipeCmdParser <|> inputCmdParser <|> outputCmdParser <|> groupCmdParser

let addrsParser: GenericParser<String, (), [Addr]> = addrParser.many

let cmdLineParser: GenericParser<String, (), CmdLine> = (StringParser.spaces *> addrsParser) >>- { addrs in
    (cmdParser >>- { cmd in
        return GenericParser(result: CmdLine(adders: addrs, cmd: cmd))
        }) <|> GenericParser(result: CmdLine(adders: addrs, cmd: nil))
}

let editCommandParser: GenericParser<String, (), ECCmd> = StringParser.string("Edit") *> StringParser.spaces *> cmdLineParser >>- { cmdLine in
    return GenericParser(result: ECCmd.Edit(cmdLine))
}

//MARK: Find Command
let findCommandParser: GenericParser<String, (), ECCmd> = StringParser.string("Find") *> StringParser.spaces *> (StringParser.noneOf("\n").many.stringValue) >>- { str in
    return GenericParser(result: ECCmd.Look(str))
}

//MARK: External Command
let systemCommandParser: GenericParser<String, (), ECCmd> = (StringParser.noneOf("\n").many.stringValue >>- { str in
    return GenericParser(result: ECCmd.External(str, .None))
})

//Mark: Pipe Command
let pipeCommandParser: GenericParser<String, (), ECCmd> = StringParser.character("|") *> (patternLikeParser >>- { pat in
    return GenericParser(result: ECCmd.External(pat.pat, .Pipe))
    })

let inputCommandParser: GenericParser<String, (), ECCmd> = StringParser.character("<") *> (patternLikeParser >>- { pat in
    return GenericParser(result: ECCmd.External(pat.pat, .Input))
    })

let outputCommandParser: GenericParser<String, (), ECCmd> = StringParser.character(">") *> (patternLikeParser >>- { pat in
    return GenericParser(result: ECCmd.External(pat.pat, .Output))
    })

/*
 ***************************
 * EC Command
 ***************************
 */
let ecCmdParser: GenericParser<String, (), ECCmd> = editCommandParser.attempt <|>
    findCommandParser.attempt <|>
    pipeCommandParser.attempt <|>
    inputCommandParser.attempt <|>
    outputCommandParser.attempt <|>
    systemCommandParser.attempt