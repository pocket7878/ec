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
    case insert(Int, String, Dot)
    case delete(Int, Int, Dot)
    case replace(Int, Int, String, Dot)
    case append(Int, String, Dot)
    case moveDot(Dot)
    case noOp
    case group([Patch])
}

struct TextEdit {
    let storage: String
    var dot: Dot
}

func dotText(_ edit: TextEdit) -> String {
    return edit.storage.substring(
        with: edit.storage.characters.index(edit.storage.startIndex, offsetBy: edit.dot.0) ..< edit.storage.characters.index(edit.storage.startIndex, offsetBy: edit.dot.1)
    )
}

func strToEof(_ edit: TextEdit) -> String {
    return edit.storage.substring(from: edit.storage.characters.index(edit.storage.startIndex, offsetBy: edit.dot.1))
}

func strFromBof(_ edit: TextEdit) -> String {
    return edit.storage.substring(to: edit.storage.characters.index(edit.storage.startIndex, offsetBy: edit.dot.0))
}

func appendString(_ edit: TextEdit, str: String) -> Patch {
    return Patch.append(edit.dot.1, str, (edit.dot.1 + 1, edit.dot.1 + 1 + str.characters.count))
}

func insertString(_ edit: TextEdit, str: String) -> Patch {
    return Patch.insert(edit.dot.0, str, (edit.dot.0, edit.dot.0 + str.characters.count))
}

func replaceString(_ edit: TextEdit, str: String) -> Patch {
    return Patch.replace(edit.dot.0, edit.dot.1, str, (edit.dot.0, edit.dot.0 + str.characters.count))
}

func deleteString(_ edit: TextEdit) -> Patch {
    return Patch.delete(edit.dot.0, edit.dot.1, (edit.dot.0, edit.dot.0))
}

func selectBOF(_ edit: TextEdit) -> Patch {
    return Patch.moveDot((0, 0))
}

func selectEOF(_ edit: TextEdit) -> Patch {
    let eofpos = edit.storage.characters.count
    return Patch.moveDot((eofpos, eofpos))
}

func selectLine(_ edit: TextEdit, linum: Int) -> Patch {
    let ls = edit.storage.lines
    let lens = ls.map({ (l) -> Int in
        l.characters.count + 1
    })
    var p1 = 0
    for i in 0..<(linum - 1) {
        p1 += lens[i]
    }
    let p2 = p1 + lens[linum - 1]
    return Patch.moveDot((p1, p2))
}

func selectForwardLine(_ edit: TextEdit, linum: Int) throws -> Patch {
    if edit.dot.1 == 0 {
        return selectLine(edit, linum: linum)
    } else {
        let restStr = edit.storage.substring(from: edit.storage.characters.index(edit.storage.startIndex, offsetBy: edit.dot.1 - 1))
        var count = 0
        var lineLenAcc = 0
        var stopLineLen = 0
        restStr.enumerateLines(invoking: { (line, stop) in
            if (count < linum) {
                lineLenAcc += line.characters.count + 1
                count += 1
            } else {
                stop = true
                stopLineLen = line.characters.count + 1
            }
        })
        if (count < linum) {
            throw ECError.addrOutOfRange
        } else {
            return Patch.moveDot((edit.dot.1 + lineLenAcc - 1, edit.dot.1 + lineLenAcc + stopLineLen - 1))
        }
    }
}

func selectBackwardLine(_ edit: TextEdit, linum: Int) throws -> Patch {
    if (edit.dot.0 < edit.storage.characters.count) {
        let prevStr = edit.storage.substring(to: edit.storage.characters.index(edit.storage.startIndex, offsetBy: edit.dot.0 + 1))
        let rlines = prevStr.lines.reversed()
        if (rlines.count > linum) {
            var lineLenAcc = 0
            var stopLineLen = 0
            for i in 0 ..< (linum + 1) {
                lineLenAcc += rlines[rlines.index(rlines.startIndex, offsetBy: i)].characters.count + 1
                stopLineLen = rlines[rlines.index(rlines.startIndex, offsetBy: i)].characters.count + 1
            }
            return Patch.moveDot((edit.dot.0 - lineLenAcc + 2, edit.dot.0 - lineLenAcc + 2 + stopLineLen))
        } else {
            throw ECError.addrOutOfRange
        }
    } else {
        let prevStr = edit.storage.substring(to: edit.storage.characters.index(edit.storage.startIndex, offsetBy: edit.dot.0))
        let rlines = prevStr.lines.reversed()
        if (rlines.count > linum) {
            var lineLenAcc = 0
            var stopLineLen = 0
            for i in 0 ..< (linum + 1) {
                lineLenAcc += rlines[rlines.index(rlines.startIndex, offsetBy: i)].characters.count + 1
                stopLineLen = rlines[rlines.index(rlines.startIndex, offsetBy: i)].characters.count + 1
            }
            return Patch.moveDot((edit.dot.0 - lineLenAcc + 1, edit.dot.0 - lineLenAcc + 1 + stopLineLen))
        } else {
            throw ECError.addrOutOfRange
        }
    }
}

/*
 * Search func
 */

let regexOptions: NSRegularExpression.Options = [
    NSRegularExpression.Options.anchorsMatchLines,
]

func searchForward(_ edit: TextEdit, pat: PatternLike) throws -> Patch? {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: regexOptions)
    let forwardRange = NSMakeRange(edit.dot.1, edit.storage.characters.count - edit.dot.1)
    let backwardRange = NSMakeRange(0, edit.dot.0)
    if let firstMatchRange: NSRange = regex.firstMatch(in: edit.storage, options: [], range: forwardRange)?.range {
        return Patch.moveDot((firstMatchRange.location, firstMatchRange.location + firstMatchRange.length))
    } else if let firstMatchRange: NSRange = regex.firstMatch(in: edit.storage, options: [], range: backwardRange)?.range {
        return Patch.moveDot((firstMatchRange.location, firstMatchRange.location + firstMatchRange.length))
    } else {
        return nil
    }
}

func searchBackward(_ edit: TextEdit, pat: PatternLike) throws -> Patch? {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: regexOptions)
    let forwardRange = NSMakeRange(edit.dot.1, edit.storage.characters.count - edit.dot.1)
    let backwardRange = NSMakeRange(0, edit.dot.0)
    let backwardMatchies = regex.matches(in: edit.storage, options: [], range: backwardRange)
    if backwardMatchies.count > 0 {
        if let lastMatch = backwardMatchies.last {
            return Patch.moveDot((lastMatch.range.location, lastMatch.range.location + lastMatch.range.length))
        } else {
            throw ECError.illigalState
        }
    } else {
        let forwardMatchies = regex.matches(in: edit.storage, options: [], range: forwardRange)
        if forwardMatchies.count > 0 {
            if let lastMatch = forwardMatchies.last {
                return Patch.moveDot((lastMatch.range.location, lastMatch.range.location + lastMatch.range.length))
            } else {
                throw ECError.illigalState
            }
        }
    }
    return nil
}

func findAllMatchies(_ edit: TextEdit, pat: PatternLike) throws -> [Dot] {
    let pat = pat.pat
    let regex = try NSRegularExpression(pattern: pat, options: regexOptions)
    return regex.matches(
        in: edit.storage,
        options: [],
        range: NSMakeRange(edit.dot.0, edit.dot.1 - edit.dot.0)).map { (res) -> Dot in
            (res.range.location, res.range.location + res.range.length)
    }
}

func findAllUnmatch(_ edit: TextEdit, pat: PatternLike) throws -> [Dot] {
    let dx = try findAllMatchies(edit, pat: pat)
    var rx = [(edit.dot.0, edit.dot.0)]
    rx.append(contentsOf: dx)
    rx.append((edit.dot.1, edit.dot.1))
    var px: [(Dot, Dot)] = []
    for i in 0..<(rx.count - 1) {
        px.append((rx[i], rx[i + 1]))
    }
    return px.map { (p) -> Dot in
        (p.0.1, p.1.0)
    }
}


/*
 * Shift functions
 */
func shiftDot(_ offset: Int, dot: Dot) -> Dot {
    return (offset + dot.0, offset + dot.1)
}

func shiftPatch(_ offset: Int, patch: Patch) -> Patch {
    switch(patch) {
    case .insert(let p, let ns, let nd):
        return .insert(offset + p, ns, shiftDot(offset, dot: nd))
    case .delete(let p1, let p2, let nd):
        return .delete(offset + p1, offset + p2, shiftDot(offset, dot: nd))
    case .replace(let p1, let p2, let ns, let nd):
        return .replace(offset + p1, offset + p2, ns, shiftDot(offset, dot: nd))
    case .append(let p, let ns, let nd):
        return .append(offset + p, ns, shiftDot(offset, dot: nd))
    case .moveDot(let nd):
        return .moveDot(shiftDot(offset, dot: nd))
    default:
        return patch
    }
}

/*
 * Apply functions
 */
func applyPatch(_ edit: TextEdit, patch: Patch) -> TextEdit {
    switch(patch) {
    case .insert(let p, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.insert(contentsOf: ns.characters, at: cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p))
        return TextEdit(storage: cloneStorage, dot: nd)
    case .delete(let p1, let p2, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.replaceSubrange(
            cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p1) ..< cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p2 - p1),
            with: "")
        return TextEdit(storage: cloneStorage, dot: nd)
    case .replace(let p1, let p2, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.replaceSubrange(
            cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p1) ..< cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p2 - p1),
            with: ns)
        return TextEdit(storage: cloneStorage, dot: nd)
    case .append(let p, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.insert(contentsOf: ns.characters, at: cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p))
        return TextEdit(storage: cloneStorage, dot: nd)
    case .moveDot(let nd):
        let cloneStorage = edit.storage.copy() as! String
        return TextEdit(storage: cloneStorage, dot: nd)
    default:
        break
    }
    return edit
}

func applyOffsetPatch(_ edit: TextEdit, offset: Int, patch: Patch) -> (TextEdit, Int) {
    switch(patch) {
    case .insert(let p, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.insert(contentsOf: ns.characters, at: cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p))
        let newE = TextEdit(storage: cloneStorage, dot: nd)
        return (newE, offset + ns.characters.count)
    case .delete(let p1, let p2, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.replaceSubrange(
            cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p1) ..< cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p2),
            with: "")
        return (TextEdit(storage: cloneStorage, dot: nd), offset - (p2 - p1))
    case .replace(let p1, let p2, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.replaceSubrange(
            cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p1) ..< cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p2),
            with: ns)
        return (TextEdit(storage: cloneStorage, dot: nd), offset - ((p2 - p1) - ns.characters.count))
    case .append(let p, let ns, let nd):
        var cloneStorage = edit.storage.copy() as! String
        cloneStorage.insert(contentsOf: ns.characters, at: cloneStorage.characters.index(cloneStorage.startIndex, offsetBy: p))
        return (TextEdit(storage: cloneStorage, dot: nd), offset + ns.characters.count)
    case .moveDot(let nd):
        let cloneStorage = edit.storage.copy() as! String
        return (TextEdit(storage: cloneStorage, dot: nd) , offset)
    case .noOp:
        let cloneStorage = edit.storage.copy() as! String
        return (TextEdit(storage: cloneStorage, dot: shiftDot(offset, dot: edit.dot)), offset)
    case .group(let ps):
        return ps.reduce((edit, offset), { (st, p) -> (TextEdit, Int) in
            applyOffsetPatch(st.0, offset: st.1, patch: p)
        })
    }
}



func evalAddr(_ edit: TextEdit, addr: Addr) throws -> Patch {
    switch(addr) {
    case .dot:
        return Patch.moveDot(edit.dot)
    case .lineAddr(let linum):
        return selectLine(edit, linum: linum)
    case .bof:
        return selectBOF(edit)
    case .eof:
        return selectEOF(edit)
    case .composeAddr(let l, let r):
        let p1 = try evalAddr(edit, addr: l)
        let p2 = try evalAddr(edit, addr: r)
        if case Patch.moveDot(let f, _) = p1 {
            if case Patch.moveDot(_, let t) = p2 {
                return Patch.moveDot(f, t)
            } else {
                throw ECError.illigalState
            }
        } else {
            throw ECError.illigalState
        }
    case .forwardPatternAddr(let pat):
        if let res = try searchForward(edit, pat: pat) {
            return res
        } else {
            return Patch.noOp
        }
    case .backwardPatternAddr(let pat):
        if let res = try searchBackward(edit, pat: pat) {
            return res
        } else {
            return Patch.noOp
        }
    case .forwardLineAddr(let linum):
        return try selectForwardLine(edit, linum: linum)
    case .backwardLineAddr(let linum):
        return try selectBackwardLine(edit, linum: linum)
    }
}

func applyAddr(_ edit: TextEdit, addr: Addr) throws -> TextEdit {
    let patch = try evalAddr(edit, addr: addr)
    if case Patch.moveDot(let np1, let np2) = patch {
        return TextEdit(storage: edit.storage, dot: (np1, np2))
    } else if case Patch.noOp = patch {
        return edit
    }
    throw ECError.illigalState
}


func evalCmd(_ edit: TextEdit, cmd: Cmd, folderPath: String?) throws -> [Patch] {
    switch(cmd) {
    case .aCmd(let str):
        return [Patch.append(edit.dot.1, str, (edit.dot.1, edit.dot.1 + str.characters.count))]
    case .iCmd(let str):
        return [Patch.insert(edit.dot.0, str, (edit.dot.0, edit.dot.0 + str.characters.count))]
    case .cCmd(let str):
        return [Patch.replace(edit.dot.0, edit.dot.1, str, (edit.dot.0, edit.dot.0 + str.characters.count))]
    case .dCmd():
        return [Patch.replace(edit.dot.0, edit.dot.1, "", (edit.dot.0, edit.dot.0))]
    case .gCmd(let pat, let cmd):
        let dtxt = dotText(edit)
        do {
            let pattern = pat.pat
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            let matchies = regex.matches(in: dtxt, options: [], range: NSMakeRange(0, dtxt.characters.count))
            if (matchies.count > 0) {
                return try evalCmdLine(edit, cmdLine: cmd, folderPath: folderPath)
            } else {
                return [Patch.noOp]
            }
        } catch {
            throw ECError.illigalState
        }
    case .vCmd(let pat, let cmd):
        let dtxt = dotText(edit)
        do {
            let pattern = pat.pat
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            let matchies = regex.matches(in: dtxt, options: [], range: NSMakeRange(0, dtxt.characters.count))
            if (matchies.count == 0) {
                return try evalCmdLine(edit, cmdLine: cmd, folderPath: folderPath)
            } else {
                return [Patch.noOp]
            }
        } catch {
            throw ECError.illigalState
        }
    case .xCmd(let pat, let cli):
        let dx = try findAllMatchies(edit, pat: pat)
        return try dx.flatMap({ (d) -> [Patch] in
            try evalCmdLine(
                TextEdit(storage: edit.storage.copy() as! String, dot: d),
                cmdLine: cli,
                folderPath: folderPath)
        })
    case .yCmd(let pat, let cli):
        let dx = try findAllUnmatch(edit, pat: pat)
        return try dx.flatMap({ (d) -> [Patch] in
            try evalCmdLine(
                TextEdit(storage: edit.storage.copy() as! String, dot: d),
                cmdLine: cli,
                folderPath: folderPath
            )
        })
    case .cmdGroup(let clx):
        return try clx.flatMap({ (cl) -> [Patch] in
            try evalCmdLine(edit, cmdLine: cl, folderPath: folderPath)
        })
    case .external(let cmd, let execType):
        switch(execType) {
        case .pipe:
            let dstr = dotText(edit)
            let cx: [String] = cmd.components(separatedBy: CharacterSet.whitespaces)
            if cx.count > 0 {
                let c: String = cx[0]
                var args: [String] = []
                for i in 1..<cx.count {
                    args.append(cx[i])
                }
                let res = Util.runCommand(c, inputStr: dstr, wdir: folderPath, args: args)
                if res.exitCode == 0 {
                    let str = res.0.joined(separator: "\n")
                    return [Patch.replace(edit.dot.0, edit.dot.1, str, (edit.dot.0, edit.dot.0 + str.characters.count))]
                } else {
                    throw ECError.systemCmdExecuteError(res.error.joined(separator: "\n"))
                }
            } else {
                return [Patch.noOp]
            }
        case .input:
            let cx: [String] = cmd.components(separatedBy: CharacterSet.whitespaces)
            if cx.count > 0 {
                let c: String = cx[0]
                var args: [String] = []
                for i in 1..<cx.count {
                    args.append(cx[i])
                }
                let res = Util.runCommand(c, inputStr: nil, wdir: folderPath, args: args)
                if res.exitCode == 0 {
                    let str = res.0.joined(separator: "\n")
                    return [Patch.replace(edit.dot.0, edit.dot.1, str, (edit.dot.0, edit.dot.0 + str.characters.count))]
                } else {
                    throw ECError.systemCmdExecuteError(res.error.joined(separator: "\n"))
                }
            } else {
                return [Patch.noOp]
            }
        case .output:
            let dotStr = dotText(edit)
            Util.runExternalCommand(cmd, inputString: dotStr, fileFolderPath: folderPath)
            return [Patch.noOp]
        default:
            throw ECError.illigalState
        }
    }
    throw ECError.illigalState
}

func evalCmdLine(_ edit: TextEdit, cmdLine: CmdLine, folderPath: String?) throws -> [Patch] {
    let newEdit = try cmdLine.adders.reduce(edit, { (e, a) -> TextEdit in
        try applyAddr(e, addr: a)
    })
    if let cmd = cmdLine.cmd {
        return try evalCmd(newEdit, cmd: cmd, folderPath: folderPath)
    } else {
        return [Patch.moveDot(newEdit.dot)]
    }
}

func applyPatchesToTextView(_ textview: NSTextView, dot: Dot, patches: [Patch], topLevel: Bool) throws -> (Int, Dot) {
    if (topLevel) {
        textview.undoManager?.beginUndoGrouping()
    }
    let res = try patches.reduce((0, dot)) { (st, patch) -> (Int, Dot) in
        let offset = st.0
        let dot = st.1
        let shiftedPatch = shiftPatch(offset, patch: patch)
        switch(shiftedPatch) {
        case .insert(let p, let ns, let nd):
            if (textview.shouldChangeText(in: NSMakeRange(p, 0), replacementString: ns)) {
                textview.insertText(ns, replacementRange: NSMakeRange(p, 0))
                textview.didChangeText()
            }
            return (offset + ns.characters.count, nd)
        case .delete(let p1, let p2, let nd):
            if (textview.shouldChangeText(in: NSMakeRange(p1, p2 - p1), replacementString: "")) {
                textview.replaceCharacters(in: NSMakeRange(p1, p2 - p1), with: "")
                textview.didChangeText()
            }
            return (offset - (p2 - p1), nd)
        case .replace(let p1, let p2, let ns, let nd):
            if (textview.shouldChangeText(in: NSMakeRange(p1, p2 - p1), replacementString: ns)) {
                textview.replaceCharacters(in: NSMakeRange(p1, p2 - p1), with: ns)
                textview.didChangeText()
            }
            return (offset - ((p2 - p1) - ns.characters.count), nd)
        case .append(let p, let ns, let nd):
            if (textview.shouldChangeText(in: NSMakeRange(p, 0), replacementString: ns)) {
                textview.insertText(ns, replacementRange: NSMakeRange(p, 0))
                textview.didChangeText()
            }
            return (offset + ns.characters.count, nd)
        case .moveDot(let nd):
            return (offset, nd)
        case .noOp:
            return (offset, shiftDot(offset, dot: dot))
        case .group(let ps):
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

func runCmdLine(_ edit: TextEdit, textview: NSTextView, cmdLine: CmdLine, folderPath: String?) throws {
    NSLog("\(cmdLine)")
    if cmdLine.cmd != nil {
        let px = try evalCmdLine(edit, cmdLine: cmdLine, folderPath: folderPath)
        try applyPatchesToTextView(textview, dot: edit.dot, patches: px, topLevel: true)
    } else {
        let newEdit = try cmdLine.adders.reduce(edit, { (e, a) ->  TextEdit in
            try applyAddr(e, addr: a)
        })
        let newRange = NSMakeRange(newEdit.dot.0, newEdit.dot.1 - newEdit.dot.0)
        textview.setSelectedRange(newRange)
        textview.scrollRangeToVisible(newRange)
    }
}
