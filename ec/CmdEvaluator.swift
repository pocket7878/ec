//
//  CmdEvaluator.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/01.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

typealias Dot = (Int, Int)

indirect enum Patch {
    case Insert(Int, String, Dot)
    case Delete(Int, Int, Dot)
    case Replace(Int, Int, String, Dot)
    case Append(Int, String, Dot)
    case MoveDot(Dot)
    case NoOp
    case Group([Patch])
}

struct TextEdit {
    let storage: NSTextStorage
    var dot: Dot
}

func dotText(edit: TextEdit) -> String {
    return edit.storage.string.substringWithRange(edit.storage.string.startIndex.advancedBy(edit.dot.0)..<edit.storage.string.startIndex.advancedBy(edit.dot.1))
}

func strToEof(edit: TextEdit) -> String {
    return edit.storage.string.substringFromIndex(edit.storage.string.startIndex.advancedBy(edit.dot.1))
}

func strFromBof(edit: TextEdit) -> String {
    return edit.storage.string.substringToIndex(edit.storage.string.startIndex.advancedBy(edit.dot.0))
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
    return Patch.MoveDot((0, 0))
}

func selectEOF(edit: TextEdit) -> Patch {
    let eofpos = edit.storage.string.characters.count
    return Patch.MoveDot((eofpos, eofpos))
}

func selectLine(edit: TextEdit, linum: Int) -> Patch {
    let ls = edit.storage.string.lines
    let lens = ls.map({ (l) -> Int in
        l.characters.count
    })
    var p1 = 0
    for i in 0..<linum {
        p1 += lens[i]
    }
    let p2 = p1 + lens[linum - 1]
    return Patch.MoveDot((p1, p2))
}

/*
 * Search func
 */
func searchForward(edit: TextEdit, pat: PatternLike) throws -> Patch? {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: [])
    let forwardRange = NSMakeRange(edit.dot.1, edit.storage.string.characters.count)
    let backwardRange = NSMakeRange(0, edit.dot.0)
    if let firstMatchRange: NSRange = regex.firstMatchInString(edit.storage.string, options: [], range: forwardRange)?.range {
        return Patch.MoveDot((firstMatchRange.location, firstMatchRange.location + firstMatchRange.length))
    } else if let firstMatchRange: NSRange = regex.firstMatchInString(edit.storage.string, options: [], range: backwardRange)?.range {
        return Patch.MoveDot((firstMatchRange.location, firstMatchRange.location + firstMatchRange.length))
    } else {
        return nil
    }
}

func searchBackward(edit: TextEdit, pat: PatternLike) throws -> Patch? {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: [])
    let forwardRange = NSMakeRange(edit.dot.1, edit.storage.string.characters.count)
    let backwardRange = NSMakeRange(0, edit.dot.0)
    let backwardMatchies = regex.matchesInString(edit.storage.string, options: [], range: backwardRange)
    if backwardMatchies.count > 0 {
        if let lastMatch = backwardMatchies.last {
            return Patch.MoveDot((lastMatch.range.location, lastMatch.range.location + lastMatch.range.length))
        } else {
            throw ECError.IlligalState
        }
    } else {
        let forwardMatchies = regex.matchesInString(edit.storage.string, options: [], range: forwardRange)
        if forwardMatchies.count > 0 {
            if let lastMatch = forwardMatchies.last {
                return Patch.MoveDot((lastMatch.range.location, lastMatch.range.location + lastMatch.range.length))
            } else {
                throw ECError.IlligalState
            }
        }
    }
    return nil
}

func findAllMatchies(edit: TextEdit, pat: PatternLike) throws -> [Dot] {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: [])
    return regex.matchesInString(edit.storage.string, options: [], range: NSMakeRange(0, edit.storage.string.characters.count)).map { (res) -> Dot in
        (res.range.location, res.range.location + res.range.length)
    }
}

func findAllMatchiesWithOffset(edit: TextEdit, pat: PatternLike, offset: Int) throws -> [Dot] {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: [])
    return regex.matchesInString(edit.storage.string, options: [], range: NSMakeRange(0, edit.storage.string.characters.count)).map { (res) -> Dot in
        let d = (res.range.location, res.range.location + res.range.length)
        shiftDot(offset, dot: d)
    }
}

func findAllUnmatchWithOffset(edit: TextEdit, pat: PatternLike, offset: Int) throws -> [Dot] {
    
}


/*
 * Shift functions
 */
func shiftDot(offset: Int, dot: Dot) -> Dot {
    return (offset + dot.0, offset + dot.1)
}

func shiftPatch(offset: Int, patch: Patch) -> Patch {
    switch(patch) {
    case .Insert(let p, let ns, let nd):
        return .Insert(offset + p, ns, shiftDot(offset, dot: nd))
    case .Delete(let p1, let p2, let nd):
        return .Delete(offset + p1, offset + p2, shiftDot(offset, dot: nd))
    case .Replace(let p1, let p2, let ns, let nd):
        return .Replace(offset + p1, offset + p2, ns, shiftDot(offset, dot: nd))
    case .Append(let p, let ns, let nd):
        return .Append(offset + p, ns, shiftDot(offset, dot: nd))
    case .MoveDot(let nd):
        return .MoveDot(shiftDot(offset, dot: nd))
    default:
        return patch
    }
}

/*
 * Apply functions
 */
func applyPatch(edit: TextEdit, patch: Patch) -> TextEdit {
    switch(patch) {
    case .Insert(let p, let ns, let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        cloneStorage.insertAttributedString(NSAttributedString(string: ns), atIndex: Int(p))
        return TextEdit(storage: cloneStorage, dot: nd)
    case .Delete(let p1, let p2, let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        cloneStorage.replaceCharactersInRange(NSMakeRange(Int(p1), Int(p2 - p1)), withString: "")
        return TextEdit(storage: cloneStorage, dot: nd)
    case .Replace(let p1, let p2, let ns, let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        cloneStorage.replaceCharactersInRange(NSMakeRange(Int(p1), Int(p2 - p1)), withString: ns)
        return TextEdit(storage: cloneStorage, dot: nd)
    case .Append(let p, let ns, let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        cloneStorage.insertAttributedString(NSAttributedString(string: ns), atIndex: Int(p))
        return TextEdit(storage: cloneStorage, dot: nd)
    case .MoveDot(let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        return TextEdit(storage: cloneStorage, dot: nd)
    default:
        break
    }
    return edit
}

func applyOffsetPatch(edit: TextEdit, offset: Int, patch: Patch) -> (TextEdit, Int) {
    switch(patch) {
    case .Insert(let p, let ns, let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        cloneStorage.insertAttributedString(NSAttributedString(string: ns), atIndex: p)
        let newE = TextEdit(storage: cloneStorage, dot: shiftDot(offset, dot: nd))
        return (newE, offset + ns.characters.count)
    case .Delete(let p1, let p2, let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        cloneStorage.replaceCharactersInRange(NSMakeRange(Int(p1), Int(p2 - p1)), withString: "")
        return (TextEdit(storage: cloneStorage, dot: shiftDot(offset, dot: nd)), offset - (p2 - p1))
    case .Replace(let p1, let p2, let ns, let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        cloneStorage.replaceCharactersInRange(NSMakeRange(Int(p1), Int(p2 - p1)), withString: ns)
        return (TextEdit(storage: cloneStorage, dot: shiftDot(offset, dot: nd)), offset - ((p2 - p1) - ns.characters.count))
    case .Append(let p, let ns, let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        cloneStorage.insertAttributedString(NSAttributedString(string: ns), atIndex: Int(p))
        return (TextEdit(storage: cloneStorage, dot: shiftDot(offset, dot: nd)), offset + ns.characters.count)
    case .MoveDot(let nd):
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        return (TextEdit(storage: cloneStorage, dot: shiftDot(offset, dot: nd)) , offset)
    case .NoOp:
        let cloneStorage = edit.storage.copy() as! NSTextStorage
        return (TextEdit(storage: cloneStorage, dot: shiftDot(offset, dot: edit.dot)), offset)
    case .Group(let ps):
        return ps.reduce((edit, offset), combine: { (let st, p) -> (TextEdit, Int) in
            applyOffsetPatch(st.0, offset: st.1, patch: p)
        })
    }
    return (edit, offset)
}

enum ECError: ErrorType {
    case PatternNotFound(String)
    case IlligalState
}

func evalAddr(edit: TextEdit, addr: Addr) throws -> Patch {
    switch(addr) {
    case .Dot:
        return Patch.MoveDot(edit.dot)
    case .LineAddr(let linum):
        return selectLine(edit, linum: linum)
    case .Bof:
        return selectBOF(edit)
    case .Eof:
        return selectEOF(edit)
    case .ComposeAddr(let l, let r):
        let p1 = try evalAddr(edit, addr: l)
        let p2 = try evalAddr(edit, addr: r)
        if case Patch.MoveDot(let f, _) = p1 {
            if case Patch.MoveDot(_, let t) = p2 {
                return Patch.MoveDot(f, t)
            } else {
                throw ECError.IlligalState
            }
        } else {
            throw ECError.IlligalState
        }
    default:
        //TODO: Implement Forward Backward Pattern and Linenum
        return Patch.NoOp
    }
}

func applyAddr(edit: TextEdit, addr: Addr) throws -> TextEdit {
    let patch = try evalAddr(edit, addr: addr)
    if case Patch.MoveDot(let np1, let np2) = patch {
        return TextEdit(storage: edit.storage, dot: (np1, np2))
    }
    throw ECError.IlligalState
}

func evalCmd(edit: TextEdit, cmd: Cmd) throws -> [Patch] {
    switch(cmd) {
    case .ACmd(let str):
        return [Patch.Append(edit.dot.1, str, (edit.dot.1, edit.dot.1 + str.characters.count))]
    case .ICmd(let str):
        return [Patch.Insert(edit.dot.0, str, (edit.dot.0, edit.dot.0 + str.characters.count))]
    case .CCmd(let str):
        return [Patch.Replace(edit.dot.0, edit.dot.1, str, (edit.dot.0, edit.dot.0 + str.characters.count))]
    case .DCmd():
        return [Patch.Replace(edit.dot.0, edit.dot.1, "", (edit.dot.0, edit.dot.0))]
    case .GCmd(let pat, let cmd):
        let dtxt = dotText(edit)
        do {
            let pattern = pat.pat
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matchies = regex.matchesInString(dtxt, options: [], range: NSMakeRange(0, dtxt.characters.count))
            if (matchies.count > 0) {
                try evalCmdLine(edit, cmdLine: cmd)
            } else {
                return [Patch.NoOp]
            }
        } catch {
            throw ECError.IlligalState
        }
    case .VCmd(let pat, let cmd):
        let dtxt = dotText(edit)
        do {
            let pattern = pat.pat
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matchies = regex.matchesInString(dtxt, options: [], range: NSMakeRange(0, dtxt.characters.count))
            if (matchies.count == 0) {
                try evalCmdLine(edit, cmdLine: cmd)
            } else {
                return [Patch.NoOp]
            }
        } catch {
            throw ECError.IlligalState
        }
    case .CmdGroup(let clx):
        return try clx.flatMap({ (cl) -> [Patch] in
            try evalCmdLine(edit, cmdLine: cl)
        })
    default:
        return [Patch.NoOp]
    }
    throw ECError.IlligalState
}

func evalCmdLine(edit: TextEdit, cmdLine: CmdLine) throws -> [Patch] {
    for addr in cmdLine.adders {
        try applyAddr(edit, addr: addr)
    }
    if let cmd = cmdLine.cmd {
        return try evalCmd(edit, cmd: cmd)
    } else {
        return [Patch.NoOp]
    }
}

func runCmdLine(edit: TextEdit, cmdLine: CmdLine) throws -> TextEdit {
    if cmdLine.cmd != nil {
        let px = try evalCmdLine(edit, cmdLine: cmdLine)
        let res = px.reduce((edit, 0), combine: { (let st, p) -> (TextEdit, Int) in
            applyOffsetPatch(st.0, offset: st.1, patch: p)
        })
        return res.0
    } else {
        let newEdit = try cmdLine.adders.reduce(edit, combine: { (e, a) ->  TextEdit in
            try applyAddr(e, addr: a)
        })
        return newEdit
    }
}