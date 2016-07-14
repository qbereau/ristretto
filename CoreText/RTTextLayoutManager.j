/*
 * RTTextLayoutManager.j - Ported from FrappKit's FPTextLayoutManager
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@import "RTTextBitmapCache.j"

function RTTextGetNumberOfCharactersInLine(line)
{
    var words = [line valueForKey:@"words"],
        numberOfCharactersInLine = 0;
    for (var k = 0; k < [words count]; k++)
        numberOfCharactersInLine += [[words objectAtIndex:k] length] + 1;
    return numberOfCharactersInLine;
}

function RTTextCreateParagraph()
{
    var paragraph = [CPMutableDictionary dictionary];
    [paragraph setValue:Math.uuid() forKey:@"uuid"];
    [paragraph setValue:[CPMutableArray array] forKey:@"intersectionRects"];
    return paragraph;
}

function RTTextCreateLine()
{
    var newLine = [CPMutableDictionary dictionary];
    [newLine setValue:Math.uuid() forKey:@"uuid"];
    [newLine setValue:CPMakeSize(0,0) forKey:@"size"];
    [newLine setValue:[CPMutableArray array] forKey:@"words"];
    [newLine setValue:[CPNumber numberWithInt:0] forKey:@"numberOfCharacters"];
    return newLine;
}

function RTTextNumberOfCharactersInLine(line)
{
    return [[line valueForKey:@"numberOfCharacters"] intValue];
}

function RTTextNumberOfCharactersInParagraph(paragraph)
{
    var lines = [paragraph valueForKey:@"lines"],
        numberOfCharactersInParagraph = 0;
    for (var l = 0; l < [lines count]; l++)
        numberOfCharactersInParagraph += RTTextNumberOfCharactersInLine([lines objectAtIndex:l]);
    return numberOfCharactersInParagraph;
}

@implementation CPObject (RTTextLayoutManagerDelegate) {}

- (void)layoutManager:(CPTextLayoutManager)aTextLayoutManager didRecalculateLayoutInFrame:(CPRect)aFrame {}

@end

@implementation RTTextLayoutManager : CPObject
{
    CPMutableArray      clippedAreas;
    CPMutableArray      paragraphs              @accessors;
    RTTextStorage       textStorage             @accessors;
    RTText              textView                @accessors;
    BOOL                shouldWrapText          @accessors;
    BOOL                initiatedLayout         @accessors;
    int                 defaultWordSpacing      @accessors;
    int                 lineHeightMultiplier    @accessors;
    int                 defaultLineWidth;
}

- (id)initWithTextView:(RTText)aTextView
{
    if (self = [super init])
    {
        initiatedLayout = NO;
        shouldWrapText = YES;
        textView = aTextView;

        textStorage = [textView textStorage];
        paragraphs = [[CPMutableArray alloc] init];
        clippedAreas = [[CPMutableArray alloc] init];
    }
    return self;
}

- (void)textLocationAtPoint:(CPPoint)point
{
    var textLocation = 0,
        currentPoint = CPMakePoint(0,-2);

    for (var i = 0; i < [paragraphs count]; i++)
    {
        currentPoint.x = 0;
        var paragraph = [paragraphs objectAtIndex:i],
            paragraphSize = [paragraph valueForKey:@"size"],
            paragraphRect = CPMakeRect(currentPoint.x,currentPoint.y,paragraphSize.width,paragraphSize.height);

        if (CGRectContainsPoint(paragraphRect,point))
        {
            var lines = [[paragraphs objectAtIndex:i] valueForKey:@"lines"];

            for (var j = 0; j < [lines count]; j++)
            {
                currentPoint.x = 0;
                var line = [lines objectAtIndex:j],
                    lineSize = [line valueForKey:@"size"],
                    lineRect = CPMakeRect(0,currentPoint.y,[textView bounds].size.width,lineSize.height);

                if (CGRectContainsPoint(lineRect,point))
                {
                    var words = [line valueForKey:@"words"];

                    for (var w = 0; w < [words count]; w++)
                    {
                        var word = [words objectAtIndex:w],
                            wordSpacing = [RTTextBitmapCache sizeOfCharacter:@" " withFont:[textView font]].width,
                            wordSize = [RTTextBitmapCache sizeOfWord:word withFont:[textView font]],
                            wordRect = CPMakeRect(currentPoint.x,currentPoint.y,wordSize.width,wordSize.height);
                        if (CGRectContainsPoint(wordRect,point))
                        {
                            for (var c = 0; c < [word length]; c++)
                            {
                                var character = [word characterAtIndex:c],
                                    characterSize = [RTTextBitmapCache sizeOfCharacter:character withFont:[textView font]];
                                if (currentPoint.x + characterSize.width / 2 >= point.x)
                                    return textLocation - 1;
                                currentPoint.x += characterSize.width;
                                textLocation++;
                            }
                            return textLocation;
                        }
                        textLocation += [word length] + 1;
                        currentPoint.x += wordSize.width + wordSpacing;
                    }
                    return textLocation - 1;
                } else {
                    textLocation += RTTextNumberOfCharactersInLine(line);
                    currentPoint.y += lineSize.height;
                }
            }
            return textLocation;
        } else {
            textLocation += RTTextNumberOfCharactersInParagraph(paragraph);
            currentPoint.y += paragraphSize.height;
        }
    }
}

- (void)updateSpacing
{
    var characterSize = [RTTextBitmapCache sizeOfCharacter:@" " withFont:[textView font]];
    defaultWordSpacing = characterSize.width;
    lineHeightMultiplier = 1.2;
    defaultLineWidth = lineHeightMultiplier * characterSize.height;
}

- (void)pointAtTextLocation:(int)characterIndex
{
    var point = CPMakePoint(0,0),
        currentCharacterIndex = 0;

    for (var i = 0; i < [paragraphs count]; i++)
    {
        var paragraph = [paragraphs objectAtIndex:i],
            numberOfCharactersInParagraph = RTTextNumberOfCharactersInParagraph(paragraph) + 1,
            paragraphRange = CPMakeRange(currentCharacterIndex,numberOfCharactersInParagraph);

        if (CPLocationInRange(characterIndex,paragraphRange))
        {
            var lines = [paragraph valueForKey:@"lines"];

            for (var j = 0; j < [lines count]; j++)
            {
                var line = [lines objectAtIndex:j],
                    words = [line valueForKey:@"words"],
                    numberOfCharactersInLine = RTTextNumberOfCharactersInLine(line),
                    lineRange = CPMakeRange(currentCharacterIndex,numberOfCharactersInLine);

                if (currentCharacterIndex == characterIndex)
                {
                    return point;
                }

                if (CPLocationInRange(characterIndex,lineRange))
                {
                    var characterIndexInLine = characterIndex - currentCharacterIndex,
                        currentIndexInLine = 0;

                    for (var l = 0; l < [words count]; l++)
                    {
                        var word = [words objectAtIndex:l],
                            charactersInWord = [word length];

                        if ((charactersInWord + currentIndexInLine) >= characterIndexInLine)
                        {
                            var characterIndexInWord = characterIndexInLine - currentIndexInLine,
                                subStringLength = [RTTextBitmapCache sizeOfWord:[word substringWithRange:CPMakeRange(0,characterIndexInWord)] withFont:[textView font]].width;
                            point.x += subStringLength;

                            return point;
                        }

                        var wordSpacing = [RTTextBitmapCache sizeOfCharacter:@" " withFont:[textView font]].width;
                        point.x += [RTTextBitmapCache sizeOfWord:word withFont:[textView font]].width + wordSpacing;
                        currentIndexInLine += charactersInWord;
                        currentIndexInLine++;
                    }
                }

                point.y += [line valueForKey:@"size"].height;
                currentCharacterIndex += numberOfCharactersInLine;
            }
        } else
        {
            point.y += [paragraph valueForKey:@"size"].height;
            currentCharacterIndex += numberOfCharactersInParagraph;
        }
    }

    return CGPointMakeZero();
}

- (CPRange)rangeOfWordAtPoint:(CPPoint)localPoint
{
    var textLocation = [self textLocationAtPoint:localPoint],
        textRange = CPMakeRange(textLocation,1);

    var clickedText = [[textView string] substringWithRange:textRange];
    if ([clickedText isEqual:@" "])
        return textRange;

    var selFirstWord = NO;
    while (![clickedText hasPrefix:@" "]&&![clickedText hasPrefix:@"\n"])
    {
        textRange.location--;
        textRange.length++;

        if (textRange.location < 0)
        {
            selFirstWord = YES;
            textRange.location++;
            textRange.length--;
            clickedText = [@" " stringByAppendingString:clickedText];
        }
        else
            clickedText = [[textView string] substringWithRange:textRange];
    }
    while (![clickedText hasSuffix:@" "]&&![clickedText hasSuffix:@"\n"])
    {
        textRange.length++;
        if (CPMaxRange(textRange) > [[textView string] length])
            clickedText = [clickedText stringByAppendingString:@" "]
        else
            clickedText = [[textView string] substringWithRange:textRange];
    }
    if ([clickedText hasSuffix:@". "] || [clickedText hasSuffix:@", "] || [clickedText hasSuffix:@"\n"])
        textRange.length--;

    if (!selFirstWord)
        textRange.location++;
    textRange.length -= (!selFirstWord)?2:1;

    return textRange;
}

- (CPRange)rangeOfParagraphAtPoint:(CPPoint)localPoint
{
    var paragraphOrigin = CPMakePoint(0,0),
        currentCharacterIndex = 0;

    for (var i = 0; i < [paragraphs count]; i++)
    {
        var paragraph = [paragraphs objectAtIndex:i],
            paragraphSize = [paragraph valueForKey:@"size"],
            paragraphRect = CPMakeRect(paragraphOrigin.x,paragraphOrigin.y,paragraphSize.width,paragraphSize.height),
            numberOfCharactersInParagraph = RTTextNumberOfCharactersInParagraph(paragraph)+1,
            paragraphRange = CPMakeRange(currentCharacterIndex,numberOfCharactersInParagraph);

        if (CGRectContainsPoint(paragraphRect,localPoint))
            return CPMakeRange(paragraphRange.location,paragraphRange.length - 2);

        paragraphOrigin.y += paragraphSize.height;
        currentCharacterIndex += numberOfCharactersInParagraph;
    }
    return CPMakeRange(0,0);
}

// Layout

- (void)_initiateLayout
{
    [paragraphs removeAllObjects];
    initiatedLayout = YES;

    var textViewBounds = [textView bounds],
        globalMaxLineWidth = CGRectGetWidth(textViewBounds),
        breakContentsInText = [textStorage breakContents];

    for (var i = 0;i < [breakContentsInText count]; i++)
    {
        var words = [breakContentsInText objectAtIndex:i];

        if ([words count] > 0)
        {
            var paragraph = RTTextCreateParagraph();
            [paragraph setValue:CPMakeSize(CGRectGetWidth([textView bounds]),0) forKey:@"size"];
            [paragraph setValue:words forKey:@"words"];
            [paragraph setValue:[CPNumber numberWithInt:i] forKey:@"breakIndex"];
            [self _layoutParagraph:paragraph];
            [paragraphs addObject:paragraph];
        }
    }
}

- (void)resetAllParagraphs
{
    for (var i = 0; i < [paragraphs count]; i++)
    {
        var paragraph = [paragraphs objectAtIndex:i];
        [self _resetWordsInParagraph:paragraph];
    }
}

- (void)_resetWordsInParagraph:(CPDictionary)paragraph
{
    var breakContentsInText = [textStorage breakContents],
        breakIndex = [[paragraph valueForKey:@"breakIndex"] intValue];
    [paragraph setValue:[breakContentsInText objectAtIndex:breakIndex] forKey:@"words"];

    RTTextBitmapCacheRemoveParagraph(paragraph);
    [paragraph setValue:Math.uuid() forKey:@"uuid"];

    var ctx = [[textView element] graphicsContext];
    CGContextClearRect(ctx, CGRectMake(0, 0, [textView frameSize].width, [textView frameSize].height));
}

- (void)_layoutParagraph:(CPDictionary)paragraph
{
    var existingLineArray = [paragraph valueForKey:@"lines"];
    if (existingLineArray == nil)
        existingLineArray = [CPArray array];

    var lineArray = [[CPMutableArray alloc] init],
        currentLine = nil,
        paragraphHeight = 0,
        wordIndex = 0,
        lineWidth = 0,
        globalMaxLineWidth = CGRectGetWidth([textView frame]),
        lineY = 0,
        words = [paragraph valueForKey:@"words"];

    while (wordIndex < [words count])
    {
        var word = [words objectAtIndex:wordIndex],
            wordSize = [RTTextBitmapCache sizeOfWord:word withFont:[textView font]],
            maxLineWidth = [textView multiLine] ? globalMaxLineWidth : 99999,
            lineSize = CPMakeSize(maxLineWidth,parseInt(wordSize.height * lineHeightMultiplier)),
            lineRect = CPMakeRect(0,lineY,CGRectGetWidth([textView bounds]),lineSize.height);

        if (currentLine == nil)
            currentLine = RTTextCreateLine();

        if (shouldWrapText)
        {
            var intersectionRectangles = [paragraph valueForKey:@"intersectionRects"],
                clippedIntersectionWidth = 0;

            for (var r = 0;r < [intersectionRectangles count]; r++)
            {
                var intersectionRect = [intersectionRectangles objectAtIndex:r],
                    rectOriginX = intersectionRect.origin.x,
                    lineIntersectionRect = CGRectIntersection(lineRect,intersectionRect),
                    lineClippedWidth = CGRectGetWidth([textView bounds]) - lineIntersectionRect.origin.x;

                if (lineIntersectionRect.size.width > 0 && lineClippedWidth > clippedIntersectionWidth)
                    clippedIntersectionWidth = lineClippedWidth;
            }

            maxLineWidth -= clippedIntersectionWidth;
        }

        var newLineWidth = lineWidth + wordSize.width + defaultWordSpacing;
        if (newLineWidth < maxLineWidth)
        {
            var lineLeftMargin = 0;
            [[currentLine valueForKey:@"words"] addObject:word];
            lineWidth = newLineWidth;
            lineSize.width = lineWidth;
            var prevHeight = [currentLine valueForKey:@"size"] ? [currentLine valueForKey:@"size"].height : 0;
            if (prevHeight > lineSize.height)
                lineSize.height = prevHeight;
            [currentLine setValue:lineSize forKey:@"size"];
            wordIndex++;
            continue;
        }
        else
        {
            if (![currentLine valueForKey:@"words"] || [[currentLine valueForKey:@"words"] count] == 0)
            {
                // At this point we have a word longer than a line
                // so we'll split the word into sub-words
                var isProcessingWord = YES,
                    charIdx = 0;
                while (isProcessingWord)
                {
                    var wSize = 0,
                        iLetters = 0;

                    while (wSize < maxLineWidth)
                    {
                        var w = [RTTextBitmapCache sizeOfCharacter:[word characterAtIndex:charIdx] withFont:[textView font]].width;
                        if (wSize + w > maxLineWidth || charIdx >= [word length])
                            break;

                        wSize += w;
                        ++charIdx;
                        ++iLetters;
                    }

                    [[currentLine valueForKey:@"words"] addObject:[word substringWithRange:CPMakeRange(charIdx - iLetters, iLetters)]];
                    [currentLine setValue:CGSizeMake(wSize, lineSize.height) forKey:@"size"];

                    if (charIdx < [word length] - 1)
                    {
                        [currentLine setValue:[CPNumber numberWithInt:iLetters] forKey:@"numberOfCharacters"];
                        [lineArray addObject:currentLine];
                        currentLine = RTTextCreateLine();
                        paragraphHeight += lineSize.height;
                    }
                    else
                    {
                        [currentLine setValue:[CPNumber numberWithInt:iLetters] forKey:@"numberOfCharacters"];
                        isProcessingWord = NO;
                    }
                }

                ++wordIndex;
                continue;
            }
        }

        lineWidth = 0;
        lineY += lineSize.height;

        var numberOfCharactersInLine = RTTextGetNumberOfCharactersInLine(currentLine);

        [currentLine setValue:[CPNumber numberWithInt:numberOfCharactersInLine] forKey:@"numberOfCharacters"];
        [lineArray addObject:currentLine];

        currentLine = nil;
        paragraphHeight += lineSize.height;
    }

    lineY += lineSize.height;
    [lineArray addObject:currentLine];
    paragraphHeight += lineSize.height * 2;

    lineWidth = 0;

    var numberOfCharactersInLine = RTTextGetNumberOfCharactersInLine(currentLine);
    [currentLine setValue:numberOfCharactersInLine forKey:@"numberOfCharacters"];

    var newParagraphSize = CPMakeSize(globalMaxLineWidth,paragraphHeight);
    [paragraph setValue:newParagraphSize forKey:@"size"];

    RTTextBitmapCacheRemoveLines([paragraph valueForKey:@"lines"]);

    var emptyLine = RTTextCreateLine();
    emptyLine.size = CPMakeSize(0, wordSize.height);
    [lineArray addObject:emptyLine];

    [paragraph setValue:lineArray forKey:@"lines"];
}

- (void)recalculateLayout
{
    [self recalculateLayoutInFrame:[textView bounds]];
}

- (void)recalculateLayoutInFrame:(CPRect)aFrame
{
    if (!initiatedLayout)
        [self _initiateLayout];
    else
    {
        if ([paragraphs count] > 0)
        {
            var yOffset = 0.0,
                paragraphsAffectedByClip = [[CPMutableArray alloc] init],
                paragraphOrigin = CPMakePoint(0,0);

            for (var i = 0; i < [paragraphs count]; i++)
            {
                var paragraph = [paragraphs objectAtIndex:i],
                    paragraphSize = [paragraph valueForKey:@"size"],
                    paragraphRect = CPMakeRect(paragraphOrigin.x,paragraphOrigin.y,paragraphSize.width,paragraphSize.height);

                if (CGRectIntersectsRect(paragraphRect, aFrame))
                {
                    /*
                    for (var a=0;a<[clippedAreas count];a++)
                    {
                        // Check against clipped areas
                        var clippedBounds = [self clippedBoundsAtIndex:a];
                        var intersectionRect = CGRectIntersection(paragraphRect,clippedBounds);
                        intersectionRect.origin.y -= paragraphOrigin.y;
                        if (intersectionRect.size.width > 0.0)
                        {
                            [[paragraph valueForKey:@"intersectionRects"] addObject:intersectionRect];

                            if (![paragraphsAffectedByClip containsObject:paragraph])
                                [paragraphsAffectedByClip addObject:paragraph];
                        }
                    }
                    */

                    // Let's just redraw the entire paragraph for now
                    // We could optimize further by using the code above with the
                    // interesectionRect...
                    [paragraphsAffectedByClip addObject:paragraph];
                }

                paragraphOrigin.y += paragraphSize.height;
            }

            var globalMaxLineWidth = CGRectGetWidth([textView frame]);

            for (var i = 0; i < [paragraphs count]; i++)
            {
                var paragraph = [paragraphs objectAtIndex:i],
                    paragraphIsAffected = [paragraphsAffectedByClip containsObject:paragraph];

                if (paragraphIsAffected || [[paragraph valueForKey:@"wrapping"] intValue] > 0)
                {
                    RTTextBitmapCacheRemoveParagraph(paragraph);
                    [paragraph setValue:Math.uuid() forKey:@"uuid"];
                    [paragraph setValue:[CPNumber numberWithInt:paragraphIsAffected?1:0] forKey:@"wrapping"];
                    [self _layoutParagraph:paragraph];
                    if (paragraphIsAffected)
                        [[paragraph valueForKey:@"intersectionRects"] removeAllObjects];
                }
            }
        }
    }

    [textView layoutManager:self didRecalculateLayoutInFrame:aFrame];
}

- (void)recalculateLayoutInRange:(CPRange)range
{
    var startPoint = [self pointAtTextLocation:range.location],
        endPoint = [self pointAtTextLocation:CPMaxRange(range)];

    var paragraphOrigin = CPMakePoint(0,0);

    for (var i = 0; i < [paragraphs count]; i++)
    {
        var paragraph = [paragraphs objectAtIndex:i],
            paragraphSize = [paragraph valueForKey:@"size"],
            paragraphRect = CPMakeRect(paragraphOrigin.x,paragraphOrigin.y,paragraphSize.width,paragraphSize.height);

        if (CGRectContainsPoint(paragraphRect,startPoint) || CGRectContainsPoint(paragraphRect,endPoint))
        {
            [self _resetWordsInParagraph:paragraph];
            [self recalculateLayoutInFrame:paragraphRect];
        }

        paragraphOrigin.y += paragraphSize.height;
    }
}

// Clipped Areas

- (void)removeAllClippedAreas
{
    [clippedAreas removeAllObjects];
}

- (void)addClippedArea:(CPRect)clippedRect
{
    var clippedValue = [CPValue valueWithJSObject:clippedRect];
    [clippedAreas addObject:clippedValue];
}

- (CPRect)clippedBoundsAtIndex:(int)index
{
    var clippedArea = CPRectCreateCopy([[clippedAreas objectAtIndex:index] JSObject]);
    clippedArea.origin.y -= [textView frame].origin.y;
    clippedArea.origin.x -= [textView frame].origin.x;
    return clippedArea;
}

@end
