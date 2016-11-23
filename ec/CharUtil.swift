
//
//  CharUtil.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/11/23.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation

func isChar(_ char: Character, inSet set: CharacterSet) -> Bool {
    if String(char).rangeOfCharacter(from: set, options: [], range: nil) != nil {
        return true
    }
    return false
}

func isAlnum(_ char: Character) -> Bool {
    let symbolCharacterSet = CharacterSet(
        charactersIn: "!\"#$%&'()*+,-./:;<=>?@[\\]^`{|}~")
    let whiteSpaceCharacterSet = CharacterSet.whitespacesAndNewlines
    if isChar(char, inSet: whiteSpaceCharacterSet) {
        return false
    } else if isChar(char, inSet: symbolCharacterSet) {
        return false
    }
    return true
}

func isAddrChar(_ char: Character) -> Bool {
    let characterSet = CharacterSet(charactersIn: "0123456789+-/$.#,;?")
    if isChar(char, inSet: characterSet)  {
        return true
    } else {
        return false
    }
}

func isRegexChar(_ char: Character) -> Bool {
    if (isAlnum(char)) {
        return true
    }
    if (isChar(char, inSet: CharacterSet(charactersIn: "^+-.*?#,;[]()$"))) {
        return true
    }
    return false
}

func isFileChar(_ char: Character) -> Bool {
    if (isAlnum(char)) {
        return true
    }
    if (isChar(char, inSet: CharacterSet(charactersIn: ".-+/:"))) {
        return true
    }
    return false
}
