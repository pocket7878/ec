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
    let storage: String
    var dot: Dot
}

func dotText(edit: TextEdit) -> String {
    return edit.storage.substringWithRange(
        edit.storage.startIndex.advancedBy(edit.dot.0) ..< edit.storage.startIndex.advancedBy(edit.dot.1)
    )
}

func strToEof(edit: TextEdit) -> String {
    return edit.storage.substringFromIndex(edit.storage.startIndex.advancedBy(edit.dot.1))
}

func strFromBof(edit: TextEdit) -> String {
    return edit.storage.substringToIndex(edit.storage.startIndex.advancedBy(edit.dot.0))
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
    let eofpos = edit.storage.characters.count
    return Patch.MoveDot((eofpos, eofpos))
}

func selectLine(edit: TextEdit, linum: Int) -> Patch {
    let ls = String(edit.storage).lines
    let lens = ls.map({ (l) -> Int in
        l.characters.count + 1
    })
    var p1 = 0
    for i in 0..<(linum - 1) {
        p1 += lens[i]
    }
    let p2 = p1 + lens[linum - 1]
    return Patch.MoveDot((p1, p2))
}

func selectForwardLine(edit: TextEdit, linum: Int) throws -> Patch {
    if edit.dot.1 == 0 {
        return selectLine(edit, linum: linum)
    } else {
        let restStr = edit.storage.substringFromIndex(edit.storage.startIndex.advancedBy(edit.dot.1 - 1))
        var count = 0
        var lineLenAcc = 0
        var stopLineLen = 0
        restStr.enumerateLines({ (line, stop) in
            if (count < linum) {
                lineLenAcc += line.characters.count + 1
                count += 1
            } else {
                stop = true
                stopLineLen = line.characters.count + 1
            }
        })
        if (count < linum) {
            throw ECError.AddrOutOfRange
        } else {
            return Patch.MoveDot((edit.dot.1 + lineLenAcc - 1, edit.dot.1 + lineLenAcc + stopLineLen - 1))
        }
    }
}

func selectBackwardLine(edit: TextEdit, linum: Int) throws -> Patch {
    if (edit.dot.0 < edit.storage.characters.count) {
        let prevStr = edit.storage.substringToIndex(edit.storage.startIndex.advancedBy(edit.dot.0 + 1))
        let rlines = prevStr.lines.reverse()
        if (rlines.count > linum) {
            var lineLenAcc = 0
            var stopLineLen = 0
            for i in 0 ..< (linum + 1) {
                lineLenAcc += rlines[rlines.startIndex.advancedBy(i)].characters.count + 1
                stopLineLen = rlines[rlines.startIndex.advancedBy(i)].characters.count + 1
            }
            return Patch.MoveDot((edit.dot.0 - lineLenAcc + 2, edit.dot.0 - lineLenAcc + 2 + stopLineLen))
        } else {
            throw ECError.AddrOutOfRange
        }
    } else {
        let prevStr = edit.storage.substringToIndex(edit.storage.startIndex.advancedBy(edit.dot.0))
        let rlines = prevStr.lines.reverse()
        if (rlines.count > linum) {
            var lineLenAcc = 0
            var stopLineLen = 0
            for i in 0 ..< (linum + 1) {
                lineLenAcc += rlines[rlines.startIndex.advancedBy(i)].characters.count + 1
                stopLineLen = rlines[rlines.startIndex.advancedBy(i)].characters.count + 1
            }
            return Patch.MoveDot((edit.dot.0 - lineLenAcc + 1, edit.dot.0 - lineLenAcc + 1 + stopLineLen))
        } else {
            throw ECError.AddrOutOfRange
        }
    }
}

/*
 * Search func
 */

let regexOptions: NSRegularExpressionOptions = [
    NSRegularExpressionOptions.AnchorsMatchLines,
]

func searchForward(edit: TextEdit, pat: PatternLike) throws -> Patch? {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: regexOptions)
    let forwardRange = NSMakeRange(edit.dot.1, edit.storage.characters.count - edit.dot.1)
    let backwardRange = NSMakeRange(0, edit.dot.0)
    if let firstMatchRange: NSRange = regex.firstMatchInString(edit.storage, options: [], range: forwardRange)?.range {
        return Patch.MoveDot((firstMatchRange.location, firstMatchRange.location + firstMatchRange.length))
    } else if let firstMatchRange: NSRange = regex.firstMatchInString(String(edit.storage), options: [], range: backwardRange)?.range {
        return Patch.MoveDot((firstMatchRange.location, firstMatchRange.location + firstMatchRange.length))
    } else {
        return nil
    }
}

func searchBackward(edit: TextEdit, pat: PatternLike) throws -> Patch? {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: regexOptions)
    let forwardRange = NSMakeRange(edit.dot.1, edit.storage.characters.count - edit.dot.1)
    let backwardRange = NSMakeRange(0, edit.dot.0)
    let backwardMatchies = regex.matchesInString(String(edit.storage), options: [], range: backwardRange)
    if backwardMatchies.count > 0 {
        if let lastMatch = backwardMatchies.last {
            return Patch.MoveDot((lastMatch.range.location, lastMatch.range.location + lastMatch.range.length))
        } else {
            throw ECError.IlligalState
        }
    } else {
        let forwardMatchies = regex.matchesInString(String(edit.storage), options: [], range: forwardRange)
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
    let regex = try NSRegularExpression(pattern: pat, options: regexOptions)
    return regex.matchesInString(
        String(edit.storage),
        options: [],
        range: NSMakeRange(edit.dot.0, edit.dot.1 - edit.dot.0)).map { (res) -> Dot in
            (res.range.location, res.range.location + res.range.length)
    }
}

func findAllUnmatch(edit: TextEdit, pat: PatternLike) throws -> [Dot] {
    let dx = try findAllMatchies(edit, pat: pat)
    var rx = [(edit.dot.0, edit.dot.0)]
    rx.appendContentsOf(dx)
    rx.append((edit.dot.1, edit.dot.1))
    var px: [(Dot, Dot)] = []
    for i in 0..<(rx.count - 1) {
        px.append((rx[i], rx[i + 1]))
    }
    return px.map { (let p) -> Dot in
        (p.0.1, p.1.0)
    }
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
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.insertContentsOf(ns.characters, at: cloneStorage.startIndex.advancedBy(p))
        return TextEdit(storage: cloneStorage, dot: nd)
    case .Delete(let p1, let p2, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.replaceRange(
            cloneStorage.startIndex.advancedBy(p1) ..< cloneStorage.startIndex.advancedBy(p2 - p1),
            with: "")
        return TextEdit(storage: cloneStorage, dot: nd)
    case .Replace(let p1, let p2, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.replaceRange(
            cloneStorage.startIndex.advancedBy(p1) ..< cloneStorage.startIndex.advancedBy(p2 - p1),
            with: ns)
        return TextEdit(storage: cloneStorage, dot: nd)
    case .Append(let p, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.insertContentsOf(ns.characters, at: cloneStorage.startIndex.advancedBy(p))
        return TextEdit(storage: cloneStorage, dot: nd)
    case .MoveDot(let nd):
        let cloneStorage = edit.storage.copy() as! String
        return TextEdit(storage: cloneStorage, dot: nd)
    default:
        break
    }
    return edit
}

func applyOffsetPatch(edit: TextEdit, offset: Int, patch: Patch) -> (TextEdit, Int) {
    switch(patch) {
    case .Insert(let p, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.insertContentsOf(ns.characters, at: cloneStorage.startIndex.advancedBy(p))
        let newE = TextEdit(storage: cloneStorage, dot: nd)
        return (newE, offset + ns.characters.count)
    case .Delete(let p1, let p2, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.replaceRange(
            cloneStorage.startIndex.advancedBy(p1) ..< cloneStorage.startIndex.advancedBy(p2),
            with: "")
        return (TextEdit(storage: cloneStorage, dot: nd), offset - (p2 - p1))
    case .Replace(let p1, let p2, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.replaceRange(
            cloneStorage.startIndex.advancedBy(p1) ..< cloneStorage.startIndex.advancedBy(p2),
            with: ns)
        return (TextEdit(storage: cloneStorage, dot: nd), offset - ((p2 - p1) - ns.characters.count))
    case .Append(let p, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.insertContentsOf(ns.characters, at: cloneStorage.startIndex.advancedBy(p))
        return (TextEdit(storage: cloneStorage, dot: nd), offset + ns.characters.count)
    case .MoveDot(let nd):
        let cloneStorage = edit.storage.copy() as! String
        return (TextEdit(storage: cloneStorage, dot: nd) , offset)
    case .NoOp:
        let cloneStorage = edit.storage.copy() as! String
        return (TextEdit(storage: cloneStorage, dot: shiftDot(offset, dot: edit.dot)), offset)
    case .Group(let ps):
        return ps.reduce((edit, offset), combine: { (let st, p) -> (TextEdit, Int) in
            applyOffsetPatch(st.0, offset: st.1, patch: p)
        })
    }
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
    case .ForwardPatternAddr(let pat):
        if let res = try searchForward(edit, pat: pat) {
            return res
        } else {
            return Patch.NoOp
        }
    case .BackwardPatternAddr(let pat):
        if let res = try searchBackward(edit, pat: pat) {
            return res
        } else {
            return Patch.NoOp
        }
    case .ForwardLineAddr(let linum):
        return try selectForwardLine(edit, linum: linum)
    case .BackwardLineAddr(let linum):
        return try selectBackwardLine(edit, linum: linum)
    }
}

func applyAddr(edit: TextEdit, addr: Addr) throws -> TextEdit {
    let patch = try evalAddr(edit, addr: addr)
    if case Patch.MoveDot(let np1, let np2) = patch {
        return TextEdit(storage: edit.storage, dot: (np1, np2))
    } else if case Patch.NoOp = patch {
        return edit
    }
    throw ECError.IlligalState
}





func evalCmd(edit: TextEdit, cmd: Cmd, folderPath: String?) throws -> [Patch] {
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
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            let matchies = regex.matchesInString(dtxt, options: [], range: NSMakeRange(0, dtxt.characters.count))
            if (matchies.count > 0) {
                return try evalCmdLine(edit, cmdLine: cmd, folderPath: folderPath)
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
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            let matchies = regex.matchesInString(dtxt, options: [], range: NSMakeRange(0, dtxt.characters.count))
            if (matchies.count == 0) {
                return try evalCmdLine(edit, cmdLine: cmd, folderPath: folderPath)
            } else {
                return [Patch.NoOp]
            }
        } catch {
            throw ECError.IlligalState
        }
    case .XCmd(let pat, let cli):
        let dx = try findAllMatchies(edit, pat: pat)
        return try dx.flatMap({ (let d) -> [Patch] in
            try evalCmdLine(
                TextEdit(storage: edit.storage.copy() as! String, dot: d),
                cmdLine: cli,
                folderPath: folderPath)
        })
    case .YCmd(let pat, let cli):
        let dx = try findAllUnmatch(edit, pat: pat)
        return try dx.flatMap({ (let d) -> [Patch] in
            try evalCmdLine(
                TextEdit(storage: edit.storage.copy() as! String, dot: d),
                cmdLine: cli,
                folderPath: folderPath
            )
        })
    case .CmdGroup(let clx):
        return try clx.flatMap({ (cl) -> [Patch] in
            try evalCmdLine(edit, cmdLine: cl, folderPath: folderPath)
        })
    case .External(let cmd, let execType):
        switch(execType) {
        case .Pipe:
            let dstr = dotText(edit)
            let cx: [String] = cmd.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            if cx.count > 0 {
                let c: String = cx[0]
                var args: [String] = []
                for i in 1..<cx.count {
                    args.append(cx[i])
                }
                let res = Util.runCommand(c, inputStr: dstr, wdir: folderPath, args: args)
                if res.exitCode == 0 {
                    let str = res.0.joinWithSeparator("\n")
                    return [Patch.Replace(edit.dot.0, edit.dot.1, str, (edit.dot.0, edit.dot.0 + str.characters.count))]
                } else {
                    throw ECError.SystemCmdExecuteError(res.error.joinWithSeparator("\n"))
                }
            } else {
                return [Patch.NoOp]
            }
        case .Input:
            let cx: [String] = cmd.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            if cx.count > 0 {
                let c: String = cx[0]
                var args: [String] = []
                for i in 1..<cx.count {
                    args.append(cx[i])
                }
                let res = Util.runCommand(c, inputStr: nil, wdir: folderPath, args: args)
                if res.exitCode == 0 {
                    let str = res.0.joinWithSeparator("\n")
                    return [Patch.Replace(edit.dot.0, edit.dot.1, str, (edit.dot.0, edit.dot.0 + str.characters.count))]
                } else {
                    throw ECError.SystemCmdExecuteError(res.error.joinWithSeparator("\n"))
                }
            } else {
                return [Patch.NoOp]
            }
        case .Output:
            let dotStr = dotText(edit)
            Util.runExternalCommand(cmd, inputString: dotStr, fileFolderPath: folderPath)
            return [Patch.NoOp]
        default:
            throw ECError.IlligalState
        }
    }
    throw ECError.IlligalState
}

func evalCmdLine(edit: TextEdit, cmdLine: CmdLine, folderPath: String?) throws -> [Patch] {
    let newEdit = try cmdLine.adders.reduce(edit, combine: { (e, a) -> TextEdit in
        try applyAddr(e, addr: a)
    })
    if let cmd = cmdLine.cmd {
        return try evalCmd(newEdit, cmd: cmd, folderPath: folderPath)
    } else {
        return [Patch.MoveDot(newEdit.dot)]
    }
}

func applyPatchesToTextView(textview: NSTextView, dot: Dot, patches: [Patch], topLevel: Bool) throws -> (Int, Dot) {
    if (topLevel) {
        textview.undoManager?.beginUndoGrouping()
    }
    let res = try patches.reduce((0, dot)) { (let st, patch) -> (Int, Dot) in
        let offset = st.0
        let dot = st.1
        let shiftedPatch = shiftPatch(offset, patch: patch)
        switch(shiftedPatch) {
        case .Insert(let p, let ns, let nd):
            if (textview.shouldChangeTextInRange(NSMakeRange(p, 0), replacementString: ns)) {
                textview.insertText(ns, replacementRange: NSMakeRange(p, 0))
                textview.didChangeText()
            }
            return (offset + ns.characters.count, nd)
        case .Delete(let p1, let p2, let nd):
            if (textview.shouldChangeTextInRange(NSMakeRange(p1, p2 - p1), replacementString: "")) {
                textview.replaceCharactersInRange(NSMakeRange(p1, p2 - p1), withString: "")
                textview.didChangeText()
            }
            return (offset - (p2 - p1), nd)
        case .Replace(let p1, let p2, let ns, let nd):
            if (textview.shouldChangeTextInRange(NSMakeRange(p1, p2 - p1), replacementString: ns)) {
                textview.replaceCharactersInRange(NSMakeRange(p1, p2 - p1), withString: ns)
                textview.didChangeText()
            }
            return (offset - ((p2 - p1) - ns.characters.count), nd)
        case .Append(let p, let ns, let nd):
            if (textview.shouldChangeTextInRange(NSMakeRange(p, 0), replacementString: ns)) {
                textview.insertText(ns, replacementRange: NSMakeRange(p, 0))
                textview.didChangeText()
            }
            return (offset + ns.characters.count, nd)
        case .MoveDot(let nd):
            return (offset, nd)
        case .NoOp:
            return (offset, shiftDot(offset, dot: dot))
        case .Group(let ps):
            return try applyPatchesToTextView(textview, dot: dot, patches: ps, topLevel: false)
        }
    }
    let newDot = res.1
    textview.setSelectedRange(NSMakeRange(newDot.0, newDot.1 - newDot.0))
    textview.scrollRangeToVisible(NSMakeRange(newDot.0, newDot.1 - newDot.0))
    if (topLevel) {
        textview.undoManager?.endUndoGrouping()
    }
    return res
}

func runCmdLine(edit: TextEdit, textview: NSTextView, cmdLine: CmdLine, folderPath: String?) throws {
    NSLog("\(cmdLine)")
    if cmdLine.cmd != nil {
        let px = try evalCmdLine(edit, cmdLine: cmdLine, folderPath: folderPath)
        try applyPatchesToTextView(textview, dot: edit.dot, patches: px, topLevel: true)
    } else {
        let newEdit = try cmdLine.adders.reduce(edit, combine: { (e, a) ->  TextEdit in
            try applyAddr(e, addr: a)
        })
        let newRange = NSMakeRange(newEdit.dot.0, newEdit.dot.1 - newEdit.dot.0)
        textview.setSelectedRange(newRange)
        textview.scrollRangeToVisible(newRange)
    }
}