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
let escapedPatternCharStr: GenericParser<String, (), String> = (StringParser.string("\\/").attempt <|> (StringParser.noneOf("/") >>- { char in
    return GenericParser(result: "\(char)")
    }))

let escapedPatternCharStrList: GenericParser<String, (), [String]> = escapedPatternCharStr.many

let escapedPatternStr: GenericParser<String, (), String> = escapedPatternCharStrList >>- { strList in
    let joinedStr: String = strList.joined(separator: "")
    return GenericParser(result: joinedStr)
}

let patternLikeParser: GenericParser<String, (), PatternLike> = StringParser.character("/") *> escapedPatternStr <* (StringParser.character("/") <?> "Unclosed Pattern Slash") >>- { patternStr in
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
    return GenericParser(result: Addr.dot)
}

let bofParser: GenericParser<String, (), Addr> = StringParser.character("0") >>- { _ in
    return GenericParser(result: Addr.bof)
}

let eofParser: GenericParser<String, (), Addr> = StringParser.character("$") >>- { _ in
    return GenericParser(result: Addr.eof)
}

let lineNumberParser: GenericParser<String, (), Int> = StringParser.oneOf("123456789") >>- { head in
    StringParser.oneOf("0123456789").many.stringValue >>- {  body in
        let numStr = "\(head)\(body)"
        return GenericParser(result: Int(numStr)!)
    }
}

let forwardLineNumberAddrParser: GenericParser<String, (), Addr> = (StringParser.character("+") *> (lineNumberParser.attempt <|> GenericParser(result: 1))) >>- { lnum in
    return GenericParser(result: Addr.forwardLineAddr(lnum))
}

let backwardLineNumberAddrParser: GenericParser<String, (), Addr> = (StringParser.character("-") *> (lineNumberParser.attempt <|> GenericParser(result: 1))) >>- { lnum in
    return GenericParser(result: Addr.backwardLineAddr(lnum))
}

let lineAddrParser: GenericParser<String, (), Addr> = forwardLineNumberAddrParser.attempt <|> backwardLineNumberAddrParser.attempt <|> (lineNumberParser >>- { lnum in
    return GenericParser(result: Addr.lineAddr(lnum))
})

let forwardPatternAddrParser: GenericParser<String, (), Addr> = patternLikeParser >>- { pat in
    return GenericParser(result: Addr.forwardPatternAddr(pat))
}

let backwardPatternAddrParser: GenericParser<String, (), Addr> = (StringParser.character("-") *> patternLikeParser) >>- { pat in
    return GenericParser(result: Addr.backwardPatternAddr(pat))
}

let basicAddrParser: GenericParser<String, (), Addr> = dotParser.attempt <|> bofParser.attempt <|> eofParser.attempt <|> forwardPatternAddrParser.attempt <|> backwardPatternAddrParser.attempt <|> lineAddrParser

let leftAddrParser: GenericParser<String, (), Addr> = basicAddrParser.attempt <|> GenericParser(result: Addr.bof)

let rightAddrParser: GenericParser<String, (), Addr> = basicAddrParser.attempt <|> GenericParser(result: Addr.eof)

let composeAddrParser: GenericParser<String, (), Addr> = leftAddrParser >>- { leftAddr in
    (StringParser.character(",") *> rightAddrParser) >>- { rightAddr in
        return GenericParser(result: Addr.composeAddr(leftAddr, rightAddr))
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
        let str = lines.joined(separator: "\n")
        return GenericParser(result: str)
        }))

let aCmdParser: GenericParser<String, (), Cmd> = StringParser.character("a") *> (patternStrOrMultilineParser >>- { str in
    return GenericParser(result: Cmd.aCmd(str))
})

let iCmdParser: GenericParser<String, (), Cmd> = StringParser.character("i") *> (patternStrOrMultilineParser >>- { str in
    return GenericParser(result: Cmd.iCmd(str))
    })

let cCmdParser: GenericParser<String, (), Cmd> = StringParser.character("c") *> (patternStrOrMultilineParser >>- { str in
    return GenericParser(result: Cmd.cCmd(str))
    })

let dCmdParser: GenericParser<String, (), Cmd> = StringParser.character("d") *> GenericParser(result: Cmd.dCmd())

let xCmdParser: GenericParser<String, (), Cmd> = StringParser.character("x") *> (patternLikeParser >>- { pat in
    (StringParser.spaces *> cmdLineParser) >>- { cmd in
        return GenericParser(result: Cmd.xCmd(pat, cmd))
    }
})

let yCmdParser: GenericParser<String, (), Cmd> = StringParser.character("y") *> (patternLikeParser >>- { pat in
    (StringParser.spaces *> cmdLineParser) >>- { cmd in
        return GenericParser(result: Cmd.yCmd(pat, cmd))
    }
    })

let gCmdParser: GenericParser<String, (), Cmd> = StringParser.character("g") *> (patternLikeParser >>- { pat in
    (StringParser.spaces *>  cmdLineParser) >>- { cmd in
        return GenericParser(result: Cmd.gCmd(pat, cmd))
    }
    })

let vCmdParser: GenericParser<String, (), Cmd> = StringParser.character("v") *> (patternLikeParser >>- { pat in
    (StringParser.spaces *> cmdLineParser) >>- { cmd in
        return GenericParser(result: Cmd.vCmd(pat, cmd))
    }
    })

let pipeCmdParser: GenericParser<String, (), Cmd> = StringParser.character("|") *> (patternLikeParser >>- { pat in
    return GenericParser(result: Cmd.external(pat.pat, .pipe))
    })

let inputCmdParser: GenericParser<String, (), Cmd> = StringParser.character("<") *> (patternLikeParser >>- { pat in
    return GenericParser(result: Cmd.external(pat.pat, .input))
    })

let outputCmdParser: GenericParser<String, (), Cmd> = StringParser.character(">") *> (patternLikeParser >>- { pat in
    return GenericParser(result: Cmd.external(pat.pat, .output))
    })

let groupCmdParser: GenericParser<String, (), Cmd> = cmdLineParser.separatedBy(StringParser.endOfLine).between(StringParser.character("{"), StringParser.character("}")) >>- { cmds in
    return GenericParser(result: Cmd.cmdGroup(cmds))
}

let cmdParser: GenericParser<String, (), Cmd> = aCmdParser <|> iCmdParser <|> cCmdParser <|> dCmdParser <|> xCmdParser <|> yCmdParser <|> gCmdParser <|> vCmdParser <|> pipeCmdParser <|> inputCmdParser <|> outputCmdParser <|> groupCmdParser

let addrsParser: GenericParser<String, (), [Addr]> = addrParser.many

let cmdLineParser: GenericParser<String, (), CmdLine> = (StringParser.spaces *> addrsParser) >>- { addrs in
    (cmdParser >>- { cmd in
        return GenericParser(result: CmdLine(adders: addrs, cmd: cmd))
        }) <|> GenericParser(result: CmdLine(adders: addrs, cmd: nil))
}

let editCommandParser: GenericParser<String, (), ECCmd> = StringParser.string("Edit") *> StringParser.spaces *> cmdLineParser >>- { cmdLine in
    return GenericParser(result: ECCmd.edit(cmdLine))
}

//MARK: Look Command
let lookCommandParser: GenericParser<String, (), ECCmd> = StringParser.string("Look") *> StringParser.spaces *> (StringParser.noneOf("\n").many.stringValue) >>- { str in
    return GenericParser(result: ECCmd.look(str))
}

let lookBackCommandParser: GenericParser<String, (), ECCmd> = StringParser.string("LookBack") *> StringParser.spaces *> (StringParser.noneOf("\n").many.stringValue) >>- { str in
    return GenericParser(result: ECCmd.lookback(str))
}

//MARK: External Command
let systemCommandParser: GenericParser<String, (), ECCmd> = (StringParser.noneOf("\n").many.stringValue >>- { str in
    return GenericParser(result: ECCmd.external(str, .none))
})

//Mark: Pipe Command
let pipeCommandParser: GenericParser<String, (), ECCmd> = StringParser.character("|") *> (patternLikeParser >>- { pat in
    return GenericParser(result: ECCmd.external(pat.pat, .pipe))
    })

let inputCommandParser: GenericParser<String, (), ECCmd> = StringParser.character("<") *> (patternLikeParser >>- { pat in
    return GenericParser(result: ECCmd.external(pat.pat, .input))
    })

let outputCommandParser: GenericParser<String, (), ECCmd> = StringParser.character(">") *> (patternLikeParser >>- { pat in
    return GenericParser(result: ECCmd.external(pat.pat, .output))
    })

/*
 ***************************
 * EC Command
 ***************************
 */
let ecCmdParser: GenericParser<String, (), ECCmd> = editCommandParser.attempt <|>
    lookBackCommandParser.attempt <|>
    lookCommandParser.attempt <|>
    pipeCommandParser.attempt <|>
    inputCommandParser.attempt <|>
    outputCommandParser.attempt <|>
    systemCommandParser.attempt
