//
//  LineNumberRulerView.swift
//  Review
//
//  Created by Matthias Hochgatterer on 03/04/15.
//  Copyright (c) 2015 Matthias Hochgatterer. All rights reserved.
//

import AppKit

let NSRangeZero = NSMakeRange(0, 0)

func NumberOfDigits(number: Int) -> Int {
    let result = log10(Double(number)) + 1
    return Int(result)
}

func NumberAt(place: Int, number: Int) -> Int {
    let fplace = Double(place)
    let fnumber = Double(number)
    var result = fnumber % pow(10.0, fplace + 1)
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
    
    private weak var textView: CodeTextView? {
        get {
            return self.clientView as? CodeTextView
        }
    }
    
    var font: NSFont = NSFont.systemFontOfSize(NSFont.smallSystemFontSize()) {
        didSet {
            invalidateLineNumber()
        }
    }
    
    init(textView: CodeTextView) {
        super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerOrientation.VerticalRuler)
        textView.rulerView = self
        self.clientView = textView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.ruleThickness = DefaultRulerThickness
    }
    
    // Draws the line numbers
    override func drawHashMarksAndLabelsInRect(rect: NSRect) {
        let textView = self.textView!
        let text = textView.string!
        let string = text as NSString
        let width = self.ruleThickness
        let layoutManager = textView.layoutManager!
        let padding = CGFloat(5.0)
        let textColor = NSColor.grayColor()
        
        // Use smallest font size
        let fontSize = font.pointSize
        let ctFont = font as CTFontRef
        let cgFont = CTFontCopyGraphicsFont(ctFont, nil)
        if let context = NSGraphicsContext.currentContext()?.CGContext {
            CGContextSaveGState(context)
            // Font
            CGContextSetFont(context, cgFont)
            CGContextSetFontSize(context, fontSize)
            CGContextSetFillColorWithColor(context, textColor.CGColor)
            
            // Glyphs
            var dash: unichar = "-".characterAtIndex(0)
            var wrappedMarkGlyph = CGGlyph(kCGGlyphMax)
            CTFontGetGlyphsForCharacters(ctFont, &dash, &wrappedMarkGlyph, 1)
            
            // [CGGlyph][10]
            var digitGlyphs = Array(defaultValue: CGGlyph(kCGGlyphMax), count: 10)
            var numbers: [unichar] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map {
                let str = NSString(format: "%d", $0)
                return str.characterAtIndex(0)
            }
            
            CTFontGetGlyphsForCharacters(ctFont, &numbers, &digitGlyphs, 10)
            var advance = CGSizeZero
            CTFontGetAdvancesForGlyphs(
                ctFont,
                .Horizontal,
                &digitGlyphs[8], &advance, 1)
            let charWidth = advance.width
            
            let relativePoint = self.convertPoint(NSZeroPoint, fromView: textView)
            let inset = textView.textContainerOrigin
            let ascent = CTFontGetAscent(ctFont)
            var transform = CGAffineTransformIdentity
            transform = CGAffineTransformScale(transform, 1.0, -1.0) // flip
            transform = CGAffineTransformTranslate(transform, -padding, -relativePoint.y - inset.y - ascent)
            CGContextSetTextMatrix(context, transform)
            
            let visibleGlyphRange = layoutManager.glyphRangeForBoundingRect(textView.visibleRect, inTextContainer: textView.textContainer!)
            
            guard visibleGlyphRange.location != NSNotFound else { return }
            
            // Counter
            let characterCount = layoutManager.characterIndexForGlyphAtIndex(visibleGlyphRange.location)
            var glyphCount = visibleGlyphRange.location
            var lineIndex = 0
            var lineNum = lineIndex + 1
            var lastLineNum = 0
            
            // Support other newline characters
            let substr = text.substringToIndex(text.startIndex.advancedBy(characterCount))
            lineNum += substr.lineCount
            
            var glyphIndex: Int
            for glyphIndex = glyphCount; glyphIndex < NSMaxRange(visibleGlyphRange); lineIndex++ {
                let charIndex = layoutManager.characterIndexForGlyphAtIndex(glyphIndex)
                let lineRange = string.lineRangeForRange(NSMakeRange(charIndex, 0))
                let lineCharacterRange = layoutManager.glyphRangeForCharacterRange(lineRange, actualCharacterRange: nil)
                glyphIndex = NSMaxRange(lineCharacterRange)
                                
                while (glyphCount < glyphIndex) { // handle wrapper lines
                    var effectiveRange = NSRangeZero
                    let lineRect = layoutManager.lineFragmentRectForGlyphAtIndex(glyphCount, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                    let y = -NSMinY(lineRect)
                    if lastLineNum == lineNum { // draw wrapped mark
                        var position = CGPointMake(width - charWidth, y)
                        CGContextShowGlyphsAtPositions(context, &wrappedMarkGlyph, &position, 1)
                    } else { // new line
                        let digit = NumberOfDigits(lineNum)
                        
                        var glyphs = Array(
                            defaultValue: CGGlyph(kCGGlyphMax),
                            count: digit)
                        var positions = Array(
                            defaultValue: CGPointZero,
                            count: digit)
                        for i in 0..<digit {
                            let glyph = digitGlyphs[NumberAt(i, number: lineNum)]
                            glyphs[i] = glyph
                            let point = CGPointMake(width - CGFloat(i + 1) * charWidth, y)
                            positions[i] = point
                        }
                        CGContextShowGlyphsAtPositions(context, &glyphs, &positions, digit)
                    }
                    lastLineNum = lineNum
                    glyphCount = NSMaxRange(effectiveRange)
                }
                
                lineNum++
            }
            
            if layoutManager.extraLineFragmentTextContainer != nil {
                let lineRect = layoutManager.extraLineFragmentRect
                let y = -NSMinY(lineRect)
                
                let digit = NumberOfDigits(lineNum)
                
                var glyphs = Array(
                    defaultValue: CGGlyph(kCGGlyphMax),
                    count: digit)
                var positions = Array(
                    defaultValue: CGPointZero,
                    count: digit)
                for i in 0..<digit {
                    let glyph = digitGlyphs[NumberAt(i, number: lineNum)]
                    glyphs[i] = glyph
                    let point = CGPointMake(width - CGFloat(i + 1) * charWidth, y)
                    positions[i] = point
                }
                CGContextShowGlyphsAtPositions(context, &glyphs, &positions, digit)
            }
            CGContextRestoreGState(context)
            
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
