//
//  CmdEvaluator.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/01.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import AppKit

typealias Dot = (UInt, UInt)

indirect enum Patch {
    case Insert(UInt, String, Dot)
    case Delete(UInt, UInt, Dot)
    case Replace(UInt, UInt, String, Dot)
    case Append(UInt, String, Dot)
    case MoveDot(Dot)
    case NoOp
    case Group([Patch])
}

struct TextEdit {
    let storage: NSTextStorage,
    let dot: Dot
}

func appendString(edit: TextEdit, str: String) -> Patch {
    return Patch.Append(edit.dot.1, str, (edit.dot.1 + 1, edit.dot.1 + 1 + str.characters.count))
}

func insertString(edit: TextEdit, str: String) -> Patch {
    return Patch.Insert(edit.dot.0, str, (edit.dot.0, edit.dot.0 + str.characters.count))
}

func replaceString(edit: TextEdit, str: String) -> Patch {
    return Patch.Replace(edit.dot.0, edit.dot.1, str, (edit.dot.0, edit.dot.0 + str.characters.count))
}

func deleteString(edit: TextEdit) -> Patch {
    return Patch.Delete(edit.dot.0, edit.dot.1, (edit.dot.0, edit.dot.0))
}

func selectBOF(edit: TextEdit) -> Patch {
    return Patch.MoveDot(0, 0)
}

func selectEOF(edit: TextEdit) -> Patch {
    let eofpos = edit.storage.string.characters.count
    return Patch.MoveDot(eofpos, eofpos)
}

func selectLine(edit: TextEdit, linum: UInt) -> Patch {
    let ls = edit.storage.string.lines
    let lens = ls.map({ (l) -> UInt in
        l.characters.count
    })
    var p1 = 0
    for i in 0..<i {
        p1 += lens[i]
    }
    let p2 = p1 + (lens[linum - 1])
    return Patch.MoveDot(p1, p2)
}

