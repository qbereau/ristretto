/*
 * RTTextBitmapCache.j - Ported from FrappKit's FPTextBitmapCache
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

var characterCache = nil,
    characterSizeCache = nil,
    wordCache = nil,
    wordSizeCache = nil,
    lineCache = nil,
    paragraphCache = nil;

function RTTextBitmapCacheRemoveLines(lineArray)
{
    for (var i = 0; i < [lineArray count]; i++)
    {
        RTTextBitmapCacheRemoveLine([lineArray objectAtIndex:i]);
    }
}

function RTTextBitmapCacheRemoveLine(line)
{
    if (lineCache && line)
    {
        RTTextBitmapCacheRemoveWords([line valueForKey:@"words"]);
        lineCache[[line valueForKey:@"uuid"]] = nil;
    }
}

function RTTextBitmapCacheRemoveWords(wordArray)
{
    for (var i = 0; i < [wordArray count]; i++)
    {
        RTTextBitmapCacheRemoveWord([wordArray objectAtIndex:i]);
    }
}

function RTTextBitmapCacheRemoveWord(word)
{
    if (wordCache && word)
        wordCache[word] = nil;
}

function RTTextBitmapCacheRemoveParagraph(paragraph)
{
    if (paragraphCache && paragraph)
    {
        RTTextBitmapCacheRemoveLines([paragraph valueForKey:@"lines"]);
        paragraphCache[[paragraph valueForKey:@"uuid"]] = nil;
    }
}

@implementation RTTextBitmapCache : CPObject {}

+ (CPSize)drawCharacter:(CPString)character inView:(RTView)aView withFont:(CPFont)font atPoint:(CPPoint)origin
{
    CPLog("[WARNING] Should be tested...");
    if (characterCache == nil)
    {
        CPLog(@"created characterCache");
        characterCache = new Array();
    }

    var keyString = character + [font cssString],
        cachedImageData = characterCache[keyString],
        ctx = [[CPGraphicsContext currentContext] graphicsPort];

    if (cachedImageData != nil)
    {
        CGContextClearRect(ctx, CGRectMake(origin.x, origin.y, cachedImageData.width, cachedImageData.height));
        CGContextPutImageData(ctx, cachedImageData, CGPointMake(origin.x, origin.y));
        return [characterSizeCache objectForKey:keyString];
    }

    var characterSize = [self sizeOfCharacter:character withFont:font];
    CGContextClearRect(ctx, CGRectMake(origin.x, origin.y, characterSize.width, characterSize.height));

    var ctx = [[aView element] graphicsContext];
    CGContextSelectFont(ctx, font);
    CGContextShowTextAtPoint(ctx, character, origin);

    var imageData = CGContextGetImageData(ctx, CGRectMake(origin.x,origin.y,characterSize.width,characterSize.height));
    [characterCache setObject:imageData forKey:keyString];
    characterCache[keyString] = imageData;

    return characterSize;
}

+ (CPSize)sizeOfCharacter:(CPString)character withFont:(CPFont)font
{
    if (characterSizeCache == nil)
        characterSizeCache = [[CPMutableDictionary alloc] init];

    var keyString = character + [font cssString],
        cachedImageSize = [characterSizeCache objectForKey:keyString];

    if (cachedImageSize != nil)
        return cachedImageSize;

    cachedImageSize = [character sizeWithFont:font];
    [characterSizeCache setObject:cachedImageSize forKey:keyString];

    return cachedImageSize;
}

// Word Caching

+ (CPSize)drawWord:(CPString)word inView:(RTView)aView withFont:(CPFont)font atPoint:(CPPoint)origin
{
    [self drawWord:word inView:aView withFont:font atPoint:origin usingCache:YES];
}

+ (CPSize)drawWord:(CPString)word inView:(RTView)aView withFont:(CPFont)font atPoint:(CPPoint)origin usingCache:(BOOL)useCache
{
    if (wordCache == nil)
        wordCache = new Array();

    var keyString = word + [font cssString],
        cachedImageData = wordCache[keyString],
        ctx = [[aView element] graphicsContext],
        canCache = [[RTRenderer sharedRenderer] canCacheData];

    if (canCache && useCache && cachedImageData != nil)
    {
        CGContextClearRect(ctx, CGRectMake(origin.x, origin.y, cachedImageData.width, cachedImageData.height));
        CGContextPutImageData(ctx, cachedImageData, CGPointMake(origin.x, origin.y));
        return [wordSizeCache objectForKey:keyString];
    }

    var wordSize = [self sizeOfWord:word withFont:font];

    CGContextClearRect(ctx, CGRectMake(origin.x, origin.y, wordSize.width, wordSize.height));
    CGContextSelectFont(ctx, font);
    CGContextShowTextAtPoint(ctx, word, origin);

    if (canCache && useCache && wordSize.width > 0 && wordSize.height > 0)
    {
        var imageData = CGContextGetImageData(ctx, CGRectMake(origin.x, origin.y, wordSize.width, wordSize.height));
        wordCache[keyString] = imageData;
    }

    return wordSize;
}

+ (CPSize)sizeOfWord:(CPString)word withFont:(CPFont)font
{
    if (wordSizeCache == nil)
        wordSizeCache = [[CPMutableDictionary alloc] init];

    var keyString = word + [font cssString],
        cachedImageSize = [wordSizeCache objectForKey:keyString];
    if (cachedImageSize != nil)
        return cachedImageSize;

    var wordSize = CPMakeSize(0,0);
    for (var i = 0; i < [word length]; i++)
    {
        var character = [word substringWithRange:CPMakeRange(i,1)],
            characterSize = [self sizeOfCharacter:character withFont:font];
        if (characterSize.height > wordSize.height)
            wordSize.height = characterSize.height;
        wordSize.width += characterSize.width;
    }

    [wordSizeCache setObject:wordSize forKey:keyString];
    return wordSize;
}

+ (CPSize)drawLine:(id)line inView:(RTView)aView withFont:(CPFont)font atPoint:(CPPoint)origin
{
    [self drawLine:line inView:aView withFont:font atPoint:origin usingCache:YES];
}

+ (CPSize)drawLine:(id)line inView:(RTView)aView withFont:(CPFont)font atPoint:(CPPoint)origin usingCache:(BOOL)useCache
{
    var lineSize = [line valueForKey:@"size"];

    if (lineCache == nil)
        lineCache = new Array();

    var keyString = [line valueForKey:@"uuid"] + [font cssString],
        cachedImageData = lineCache[keyString],
        ctx = [[aView element] graphicsContext],
        canCache = [[RTRenderer sharedRenderer] canCacheData];

    CGContextClearRect(ctx, CGRectMake(origin.x, origin.y, lineSize.width, lineSize.height));
    if (canCache && useCache && cachedImageData)
    {
        CGContextPutImageData(ctx, cachedImageData, CGPointMake(origin.x, origin.y));
        return lineSize;
    }

    var wordPoint = CPPointCreateCopy(origin),
        wordSpacing = [self sizeOfCharacter:@" " withFont:font].width,
        lineWords = [line valueForKey:@"words"];

    for (var wordIndex = 0; wordIndex < [lineWords count]; wordIndex++)
    {
        var word = [lineWords objectAtIndex:wordIndex],
            wordSize = [RTTextBitmapCache drawWord:word inView:aView withFont:font atPoint:wordPoint usingCache:useCache];
        wordPoint.x += wordSize.width + wordSpacing;
    }

    if (canCache && useCache && lineSize.width > 0 && lineSize.height > 0)
    {
        var imageData = CGContextGetImageData(ctx, CGRectMake(origin.x, origin.y, lineSize.width, lineSize.height));
        lineCache[keyString] = imageData;
    }

    return lineSize;
}

+ (CPSize)drawParagraph:(id)paragraph inView:(RTView)aView withFont:(CPFont)font atPoint:(CPPoint)origin
{
    [self drawParagraph:paragraph inView:aView withFont:font atPoint:origin usingCache:YES];
}

+ (CPSize)drawParagraph:(id)paragraph inView:(RTView)aView withFont:(CPFont)font atPoint:(CPPoint)origin usingCache:(BOOL)useCache
{
    var paragraphRect = CPMakeRect(0,0,0,0);
    paragraphRect.origin = origin;
    paragraphRect.size = [paragraph valueForKey:@"size"];

    if (paragraphCache == nil)
        paragraphCache = new Array();

    var keyString = [paragraph valueForKey:@"uuid"] + [font cssString],
        cachedImageData = paragraphCache[keyString],
        ctx = [[aView element] graphicsContext],
        canCache = [[RTRenderer sharedRenderer] canCacheData];

    CGContextClearRect(ctx, CGRectMake(paragraphRect.origin.x,paragraphRect.origin.y,paragraphRect.size.width, paragraphRect.size.height));
    if (canCache && useCache && cachedImageData != nil)
    {
        CGContextPutImageData(ctx, cachedImageData, CGPointMake(paragraphRect.origin.x, paragraphRect.origin.y));
        return paragraphRect.size;
    }

    var lines = [paragraph valueForKey:@"lines"],
        linePoint = CPPointCreateCopy(paragraphRect.origin);

    for (var l = 0; l < [lines count]; l++)
    {
        var line = [lines objectAtIndex:l];
        linePoint.y += [self drawLine:line inView:aView withFont:font atPoint:linePoint usingCache:useCache].height;
    }

    if (canCache && useCache && paragraphRect.size.width > 0 && paragraphRect.size.height > 0)
    {
        var imageData = CGContextGetImageData(ctx, CGRectMake(paragraphRect.origin.x, paragraphRect.origin.y, paragraphRect.size.width, paragraphRect.size.height));
        paragraphCache[keyString] = imageData;
    }

    return paragraphRect.size;
}

@end
