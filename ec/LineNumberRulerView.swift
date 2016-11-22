//
//  LineNumberRulerView.swift
//  Review
//
//  Created by Matthias Hochgatterer on 03/04/15.
//  Copyright (c) 2015 Matthias Hochgatterer. All rights reserved.
//

import AppKit

let NSRangeZero = NSMakeRange(0, 0)

func NumberOfDigits(_ number: Int) -> Int {
    let result = log10(Double(number)) + 1
    return Int(result)
}

func NumberAt(_ place: Int, number: Int) -> Int {
    let fplace = Double(place)
    let fnumber = Double(number)
    var result = fnumber.truncatingRemainder(dividingBy: pow(10.0, fplace + 1))
    result = result / pow(10, fplace)
    return Int(result)
}

extension Array {
    init(defaultValue: Element, count: Int) {
        self.init()
        
        for i in 0..<count {
            self.append(defaultValue)
        }
    }
}

// Shameless copy from https://github.com/coteditor/CotEditor
class LineNumberRulerView: NSRulerView {
    let MinNumberOfDigits = 3
    let DefaultRulerThickness = CGFloat(40)
    
    override var requiredThickness: CGFloat {
        get {
            return max(DefaultRulerThickness, self.ruleThickness)
        }
    }
    
    fileprivate weak var textView: CodeTextView? {
        get {
            return self.clientView as? CodeTextView
        }
    }
    
    var font: NSFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize()) {
        didSet {
            invalidateLineNumber()
        }
    }
    
    init(textView: CodeTextView) {
        super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerOrientation.verticalRuler)
        textView.rulerView = self
        self.clientView = textView
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.ruleThickness = DefaultRulerThickness
    }
    
    // Draws the line numbers
    override func drawHashMarksAndLabels(in rect: NSRect) {
        let textView = self.textView!
        let text = textView.string!
        let string = text as NSString
        let width = self.ruleThickness
        let layoutManager = textView.layoutManager!
        let padding = CGFloat(5.0)
        let textColor = NSColor.gray
        
        // Use smallest font size
        let fontSize = font.pointSize
        let ctFont = font as CTFont
        let cgFont = CTFontCopyGraphicsFont(ctFont, nil)
        if let context = NSGraphicsContext.current()?.cgContext {
            context.saveGState()
            // Font
            context.setFont(cgFont)
            context.setFontSize(fontSize)
            context.setFillColor(textColor.cgColor)
            
            // Glyphs
            var dash: unichar = NSString(string: "-").character(at: 0)
            var wrappedMarkGlyph = CGGlyph(kCGGlyphMax)
            CTFontGetGlyphsForCharacters(ctFont, &dash, &wrappedMarkGlyph, 1)
            
            // [CGGlyph][10]
            var digitGlyphs = Array(defaultValue: CGGlyph(kCGGlyphMax), count: 10)
            var numbers: [unichar] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map {
                let str = NSString(format: "%d", $0)
                return str.character(at: 0)
            }
            
            CTFontGetGlyphsForCharacters(ctFont, &numbers, &digitGlyphs, 10)
            var advance = CGSize.zero
            CTFontGetAdvancesForGlyphs(
                ctFont,
                .horizontal,
                &digitGlyphs[8], &advance, 1)
            let charWidth = advance.width
            
            let relativePoint = self.convert(NSZeroPoint, from: textView)
            let inset = textView.textContainerOrigin
            let ascent = CTFontGetAscent(ctFont)
            var transform = CGAffineTransform.identity
            transform = transform.scaledBy(x: 1.0, y: -1.0) // flip
            transform = transform.translatedBy(x: -padding, y: -relativePoint.y - inset.y - ascent)
            context.textMatrix = transform
            
            let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)
            
            guard visibleGlyphRange.location != NSNotFound else { return }
            
            // Counter
            let characterCount = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
            var glyphCount = visibleGlyphRange.location
            var lineIndex = 0
            var lineNum = lineIndex + 1
            var lastLineNum = 0
            
            // Support other newline characters
            let substr = text.substring(to: text.characters.index(text.startIndex, offsetBy: characterCount))
            lineNum += substr.lineCount
            
            var glyphIndex: Int = glyphCount
            while (glyphIndex < NSMaxRange(visibleGlyphRange)) {
                let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
                let lineRange = string.lineRange(for: NSMakeRange(charIndex, 0))
                let lineCharacterRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
                glyphIndex = NSMaxRange(lineCharacterRange)
                                
                while (glyphCount < glyphIndex) { // handle wrapper lines
                    var effectiveRange = NSRangeZero
                    let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphCount, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                    let y = -NSMinY(lineRect)
                    if lastLineNum == lineNum { // draw wrapped mark
                        var position = CGPoint(x: width - charWidth, y: y)
                        context.showGlyphs([wrappedMarkGlyph], at: [position])
                    } else { // new line
                        let digit = NumberOfDigits(lineNum)
                        
                        var glyphs = Array(
                            defaultValue: CGGlyph(kCGGlyphMax),
                            count: digit)
                        var positions = Array(
                            defaultValue: CGPoint.zero,
                            count: digit)
                        for i in 0..<digit {
                            let glyph = digitGlyphs[NumberAt(i, number: lineNum)]
                            glyphs[i] = glyph
                            let point = CGPoint(x: width - CGFloat(i + 1) * charWidth, y: y)
                            positions[i] = point
                        }
                        context.showGlyphs(glyphs, at: positions)
                    }
                    lastLineNum = lineNum
                    glyphCount = NSMaxRange(effectiveRange)
                }
                
                lineNum += 1
                lineIndex += 1
            }
            
            if layoutManager.extraLineFragmentTextContainer != nil {
                let lineRect = layoutManager.extraLineFragmentRect
                let y = -NSMinY(lineRect)
                
                let digit = NumberOfDigits(lineNum)
                
                var glyphs = Array(
                    defaultValue: CGGlyph(kCGGlyphMax),
                    count: digit)
                var positions = Array(
                    defaultValue: CGPoint.zero,
                    count: digit)
                for i in 0..<digit {
                    let glyph = digitGlyphs[NumberAt(i, number: lineNum)]
                    glyphs[i] = glyph
                    let point = CGPoint(x: width - CGFloat(i + 1) * charWidth, y: y)
                    positions[i] = point
                }
                context.showGlyphs(glyphs, at: positions)
            }
            context.restoreGState()
            
            // adjust ruler thickness
            let length = max(NumberOfDigits(lineNum), MinNumberOfDigits)
            let requiredWidth = max(CGFloat(length) * charWidth + 2.0 * padding, ruleThickness)
            self.ruleThickness = requiredWidth
        }
    }
    
    // Invalidates view to redraw line numbers
    func invalidateLineNumber() {
        self.needsDisplay = true
    }
}
