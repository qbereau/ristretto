/*
 * RTRenderer.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@import "../CoreGraphics/CGAffineTransform.j"
@import "../Cappuccino/CPCompatibility.j"
@import "../CoreGraphics/CGGeometry.j"
@import "../CoreGraphics/CGPath.j"

// Global Vars
kCGLineCapButt              = 0;
kCGLineCapRound             = 1;
kCGLineCapSquare            = 2;

kCGLineJoinMiter            = 0;
kCGLineJoinRound            = 1;
kCGLineJoinBevel            = 2;

kCGPathFill                 = 0;
kCGPathEOFill               = 1;
kCGPathStroke               = 2;
kCGPathFillStroke           = 3;
kCGPathEOFillStroke         = 4;

/*!
    @group CGBlendMode
*/

kCGBlendModeNormal          = 0;
kCGBlendModeMultiply        = 1;
kCGBlendModeScreen          = 2;
kCGBlendModeOverlay         = 3;
kCGBlendModeDarken          = 4;
kCGBlendModeLighten         = 5;
kCGBlendModeColorDodge      = 6;
kCGBlendModeColorBurn       = 7;
kCGBlendModeSoftLight       = 8;
kCGBlendModeHardLight       = 9;
kCGBlendModeDifference      = 10;
kCGBlendModeExclusion       = 11;
kCGBlendModeHue             = 12;
kCGBlendModeSaturation      = 13;
kCGBlendModeColor           = 14;
kCGBlendModeLuminosity      = 15;
kCGBlendModeClear           = 16;
kCGBlendModeCopy            = 17;
kCGBlendModeSourceIn        = 18;
kCGBlendModeSourceOut       = 19;
kCGBlendModeSourceAtop      = 20;
kCGBlendModeDestinationOver = 21;
kCGBlendModeDestinationIn   = 22;
kCGBlendModeDestinationOut  = 23;
kCGBlendModeDestinationAtop = 24;
kCGBlendModeXOR             = 25;
kCGBlendModePlusDarker      = 26;
kCGBlendModePlusLighter     = 27;



RTRend = nil;

@implementation RTRenderer : CPObject
{
    BOOL            _isSVG          @accessors(readonly,getter=isSVG);

    CPArray         _displayObjects;
    CPDictionary    _displayObjectsByUID;

    CPArray         _layoutObjects;
    CPDictionary    _layoutObjectsByUID;
}

// ****
// INIT
// ****

+ (RTRenderer)sharedRenderer
{
    if (!RTRend)
    {
        // Check if browser is canvas-enabled
        if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
        {
            if (window && window.parent && window.parent.sf && window.parent.sf.core && window.parent.sf.service)
            {
                sf = window.parent.sf;
                RTRend = [[RTRenderer alloc] initWithSamsungSmartTVRenderer];
            }
            else
            {
                RTRend = [[RTRenderer alloc] initWithCanvasRenderer];
            }
        }
        else
        {
            RTRend = [[RTRenderer alloc] initWithSVGRenderer];
        }
    }

    return RTRend;
}

- (id)init
{
    [CPException raise:CPUnsupportedMethodException reason:"Can't init abstract class. Use concrete class"];
    return nil;
}

- (id)_init
{
    if (self = [super init])
    {
        _displayObjects         = [CPArray array];
        _displayObjectsByUID    = [CPDictionary dictionary];

        _layoutObjects          = [CPArray array];
        _layoutObjectsByUID     = [CPDictionary dictionary];
    }

    return self;
}

- (id)initWithCanvasRenderer
{
    RTRend = [RTCanvasRenderer new];
    return RTRend;
}

- (id)initWithSamsungSmartTVRenderer
{
    RTRend = [RTSamsungSmartTVRenderer new];
    return RTRend;
}

- (id)initWithSVGRenderer
{
    RTRend = [RTSVGRenderer new];
    return RTRend;
}

// **********
// OPERATIONS
// **********
- (void)addDisplayObject:(JSObject)anObject
{
    var UID = [anObject UID];

    if ([_displayObjectsByUID objectForKey:UID])
        return;

    [_displayObjects addObject:anObject];
    [_displayObjectsByUID setValue:[_displayObjects count] forKey:UID];

    [self run];
}

- (void)addLayoutObject:(JSObject)anObject
{
    var UID = [anObject UID];

    if ([_layoutObjectsByUID objectForKey:UID])
        return;

    [_layoutObjects addObject:anObject];
    [_layoutObjectsByUID setValue:[_layoutObjects count] forKey:UID];

    [self run];
}

- (void)run
{
    while ([_layoutObjects count] || [_displayObjects count])
    {
        var index = 0;

        for (; index < [_layoutObjects count]; ++index)
        {
            var object = [_layoutObjects objectAtIndex:index];

            [_layoutObjectsByUID removeObjectForKey:[object UID]];
            [object layoutIfNeeded];
        }

        _layoutObjects = [CPArray array];
        _layoutObjectsByUID = [CPDictionary dictionary];

        index = 0;

        for (; index < [_displayObjects count]; ++index)
        {
            if ([_layoutObjects count])
                break;

            var object = [_displayObjects objectAtIndex:index];

            [_displayObjectsByUID removeObjectForKey:[object UID]];
            [object displayIfNeeded];
        }

        if (index === [_displayObjects count])
        {
            _displayObjects = [CPArray array];
            _displayObjectsByUID = [CPDictionary dictionary];
        }
        else
            [_displayObjects removeObjectsInRange:CPMakeRange(0, index)];
    }
}

- (void)setSize:(CGSize)aSize
{

}

- (RTElement)createViewElement:(RTView)aView
{

}

- (RTElement)createImageElement:(RTView)aView
{

}

- (RTElement)createVideoElement:(RTView)aView
{

}

- (RTElement)createTextElement:(RTView)aView
{

}

- (void)appendView:(RTView)view
{

}

- (void)insertView:(RTView)view before:(RTView)bView
{

}

- (void)removeView:(RTView)view
{

}

- (CGSize)sizeOfString:(CPString)aString withFont:(CPFont)aFont forWidth:(int)aWidth
{
    return nil;
}

- (BOOL)canCacheData
{
    return YES;
}

- (BOOL)supportsFilePrefix
{
    return NO;
}

- (BOOL)supportsSMILAnimations
{
    return NO;
}

@end

// ************
// COREGRAPHICS
// ************
function to_string(aColor)
{
    [RTRend toString:aColor];
}

function CGContextBeginPath(aContext)
{
    [RTRend CGContextBeginPath:aContext];
}

function CGContextDrawLinearGradient(aContext, aGradient, aStartPoint, anEndPoint, options)
{
    [RTRend CGContextDrawLinearGradient:aContext gradient:aGradient startPoint:aStartPoint endPoint:anEndPoint options:options];
}

function CGContextAddPath(aContext, aPath)
{
    [RTRend CGContextAddPath:aContext path:aPath];
}

function CGContextClosePath(aContext)
{
    [RTRend CGContextClosePath:aContext];
}

function CGContextFillPath(aContext)
{
    [RTRend CGContextDrawPath:aContext mode:kCGPathFill];
    CGContextClosePath(aContext);
}

function CGContextFillRoundedRectangleInRect(aContext, aRect, aRadius, ne, se, sw, nw)
{
    CGContextBeginPath(aContext);
    CGContextAddPath(aContext, CGPathWithRoundedRectangleInRect(aRect, aRadius, aRadius, ne, se, sw, nw));
    CGContextClosePath(aContext);
    CGContextFillPath(aContext);
}

function CGContextSetFillColor(aContext, aColor)
{
    [RTRend CGContextSetFillColor:aContext color:aColor];
}

function CGContextSetStrokeColor(aContext, aColor)
{
    [RTRend CGContextSetStrokeColor:aContext color:aColor];
}

function CGContextStrokeRect(aContext, aRect)
{
    [RTRend CGContextStrokeRect:aContext rect:aRect];
}

function CGContextSelectFont(aContext, aFont)
{
    [RTRend CGContextSelectFont:aContext font:aFont];
}

function CGContextShowTextAtPoint(aContext, text, aPoint)
{
    [RTRend CGContextShowTextAtPoint:aContext text:text point:aPoint];
}

function CGContextFillRect(aContext, aRect)
{
    [RTRend CGContextFillRect:aContext rect:aRect];
}

function CGContextClearRect(aContext, aRect)
{
    [RTRend CGContextClearRect:aContext rect:aRect];
}

function CGContextGetImageData(aContext, aRect)
{
    [RTRend CGContextGetImageData:aContext rect:aRect];
}

function CGContextPutImageData(aContext, anImage, aPoint)
{
    [RTRend CGContextPutImageData:aContext image:anImage point:aPoint];
}

function CGContextTranslateCTM(aContext, tx, ty)
{
    [RTRend CGContextTranslateCTM:aContext tx:tx ty:ty];
}

function CGContextRotateCTM(aContext, angle)
{
    [RTRend CGContextRotateCTM:aContext angle:angle];
}

function CGContextScaleCTM(aContext, sx, sy)
{
    [RTRend CGContextScaleCTM:aContext sx:sx sy:sy];
}
