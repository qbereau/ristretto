/*
 * RTCanvasRenderer.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

// Canvas CGContext
var CANVAS_LINECAP_TABLE    = [ "butt", "round", "square" ],
    CANVAS_LINEJOIN_TABLE   = [ "miter", "round", "bevel" ],
    CANVAS_COMPOSITE_TABLE  = [ "source-over", "source-over", "source-over", "source-over", "darker",
                                "lighter", "source-over", "source-over", "source-over", "source-over",
                                "source-over", "source-over", "source-over", "source-over", "source-over",
                                "source-over", "source-over",
                                "copy", "source-in", "source-out", "source-atop",
                                "destination-over", "destination-in", "destination-out", "destination-atop",
                                "xor", "source-over", "source-over" ];

@implementation RTCanvasRenderer : RTRenderer
{

}

- (id)init
{
    if (self = [super _init])
    {
        _isSVG = NO;
    }
    return self;
}

- (RTElement)createViewElement:(RTView)aView
{
    return [[RTCanvasElement alloc] initWithView:aView];
}

- (RTElement)createImageElement:(RTView)aView
{
    return [[RTCanvasImageElement alloc] initWithView:aView];
}

- (RTElement)createVideoElement:(RTView)aView
{
    return [[RTCanvasVideoElement alloc] initWithView:aView];
}

- (RTElement)createTextElement:(RTView)aView
{
    return [[RTCanvasTextElement alloc] initWithView:aView];
}

- (DOMObject)_parentView:(RTView)view
{
    return [view superview] ? [[[view superview] element] DOMObject] : document.body;
}

- (void)appendView:(RTView)view
{
    var parentView = [self _parentView:view];
    parentView.appendChild([[view element] DOMObject]);

    [[view element] update];
}

- (void)insertView:(RTView)view before:(RTView)bView
{
    var parentView = [self _parentView:bView];
    parentView.insertBefore([[view element] DOMObject], [[bView element] DOMObject]);

    [[view element] update];
}

- (void)removeView:(RTView)view
{
    var parentView = [self _parentView:view];
    parentView.removeChild([[view element] DOMObject]);
    [[view element] release];
}

- (CGSize)sizeOfString:(CPString)aString withFont:(CPFont)aFont forWidth:(int)aWidth
{
    if (!aFont)
        return CGSizeMakeZero();

    var div = document.createElement("div"),
        text = document.createElement("span");
    text.setAttribute("style", "font: " + [aFont cssString]);
    text.textContent = "Hg";
    div.appendChild(text);

    var block = document.createElement("div");
    block.setAttribute("style", "display: inline-block; width: 1px; height: 0px;");
    div.appendChild(block);

    document.body.appendChild(div);
    var result = {};

    try {

        block.setAttribute("style", "display: inline-block; width: 1px; height: 0px; vertical-align: baseline;");
        result.ascent = block.offsetTop - text.offsetTop;

        block.setAttribute("style", "display: inline-block; width: 1px; height: 0px; vertical-align: bottom;");
        result.height = block.offsetTop - text.offsetTop;

        result.descent = result.height - result.ascent;

        var canvas = document.createElement("canvas"),
            context = canvas.getContext("2d");
        context.font = [aFont cssString];
        context.textAlign = "left";
        context.baseline = "top";
        result.width = context.measureText(aString).width;

    } finally {

        document.body.removeChild(div);
    }

    return CGSizeMake(result.width, result.height);
}

- (BOOL)canCacheData
{
    return YES;
}

- (BOOL)supportsFilePrefix
{
    return YES;
}

// ************
// COREGRAPHICS
// ************
- (CPString)toString:(CPColor)aColor
{
    return "rgba(" + ROUND(aColor.components[0] * 255) + ", " + ROUND(aColor.components[1] * 255) + ", " + ROUND(255 * aColor.components[2]) + ", " + aColor.components[3] + ")";
}

- (void)CGContextBeginPath:(JSObject)aContext
{
    aContext.beginPath();
}

- (void)CGContextAddPath:(JSObject)aContext path:(Path)aPath
{
    if (!aContext || CGPathIsEmpty(aPath))
        return;

    var elements = aPath.elements,

        i = 0,
        count = aPath.count;

    for (; i < count; ++i)
    {
        var element = elements[i],
            type = element.type;

        switch (type)
        {
            case kCGPathElementMoveToPoint:
                [self CGContextMoveToPointCanvas:aContext point:CGPointMake(element.x, element.y)];
                break;
            case kCGPathElementAddLineToPoint:
                [self CGContextAddLineToPointCanvas:aContext point:CGPointMake(element.x, element.y)];
                break;
            case kCGPathElementAddQuadCurveToPoint:
                [self CGContextAddQuadCurveToPointCanvas:aContext controlPoint:CGPointMake(element.cpx, element.cpy) point:CGPointMake(element.x, element.y)];
                break;
            case kCGPathElementAddCurveToPoint:
                [self CGContextAddCurveToPointCanvas:aContext controlPoint1:CGPointMake(element.cp1x, element.cp1y) controlPoint2:CGPointMake(element.cp2x, element.cp2y) point:CGPointMake(element.x, element.y)];
                break;
            case kCGPathElementCloseSubpath:
                [self CGContextClosePathCanvas:aContext];
                break;
            case kCGPathElementAddArc:
                [self CGContextAddArcCanvas:aContext point:CGPointMake(element.x, element.y) radius:element.radius startAngle:element.startAngle endAngle:element.endAngle clockwise:element.clockwise];
                break;
            case kCGPathElementAddArcTo:
                console.log("[WARNING] TODO");
                break;
        }
    }
}

- (void)CGContextMoveToPointCanvas:(JSObject)aContext point:(CGPoint)aPoint
{
    aContext.moveTo(aPoint.x, aPoint.y);
}

- (void)CGContextAddLineToPointCanvas:(JSObject)aContext point:(CGPoint)aPoint
{
    aContext.lineTo(aPoint.x, aPoint.y);
}

- (void)CGContextAddQuadCurveToPointCanvas:(JSObject)aContext controlPoint:(CGPoint)aControlPoint point:(CGPoint)aPoint
{
    aContext.quadraticCurveTo(aControlPoint.x, aControlPoint.y, aPoint.x, aPoint.y);
}

- (void)CGContextAddCurveToPointCanvas:(JSObject)aContext controlPoint1:(CGPoint)aControlPoint1 controlPoint2:(CGPoint)aControlPoint2 point:(CGPoint)aPoint
{
    aContext.bezierCurveTo(aControlPoint1.x, aControlPoint1.y, aControlPoint2.x, aControlPoint2.y, aPoint.x, aPoint.y);
}

- (void)CGContextClosePathCanvas:(JSObject)aContext
{
    aContext.closePath();
}

- (void)CGContextAddArcCanvas:(JSObject)aContext point:(CGPoint)aPoint radius:(int)aRadius startAngle:(float)aStartAngle endAngle:(float)anEndAngle clockwise:(BOOL)aClockwise
{
    aContext.arc(aPoint.x, aPoint.y, aRadius, aStartAngle, anEndAngle, aClockwise);
}

- (void)CGContextClosePath:(JSObject)aContext
{
    [self CGContextClosePathCanvas:aContext];
}

- (void)CGContextDrawLinearGradient:(JSObject)aContext gradient:(JSObject)aGradient startPoint:(CGPoint)aStartPoint endPoint:(CGpoint)anEndPoint options:(JSObject)options
{
    var colors = aGradient.colors,
        count = colors.length,

        linearGradient = aContext.createLinearGradient(aStartPoint.x, aStartPoint.y, anEndPoint.x, anEndPoint.y);

    while (count--)
        linearGradient.addColorStop(aGradient.locations[count], [self toString:colors[count]]);

    aContext.fillStyle = linearGradient;
    aContext.fill();
}

- (void)CGContextDrawPath:(JSObject)aContext mode:(int)aMode
{
    if (aMode == kCGPathFill || aMode == kCGPathFillStroke)
        aContext.fill();
    else if (aMode == kCGPathEOFill || aMode == kCGPathEOFillStroke)
        alert("not implemented!!!");

    if (aMode == kCGPathStroke || aMode == kCGPathFillStroke || aMode == kCGPathEOFillStroke)
        aContext.stroke();
}

- (void)CGContextSetFillColor:(JSObject)aContext color:(CPColor)aColor
{
    if ([aColor patternImage])
    {
        var patternImg = [aColor patternImage],
            size = [patternImg size],
            img;

        if (size)
            img = new Image(size.width, size.height);
        else
            img = new Image();

        img.src = [patternImg filename];

        var pattern = aContext.createPattern(img, "repeat");

        aContext.fillStyle = pattern;
    }
    else
    {
        aContext.fillStyle = "rgb(" + ROUND([aColor redComponent] * 255) + ", " + ROUND([aColor greenComponent] * 255) + ", " + ROUND([aColor blueComponent] * 255) + ")";
        aContext.globalAlpha = [aColor alphaComponent];
    }
}

- (void)CGContextSetStrokeColor:(JSObject)aContext color:(CPColor)aColor
{
    aContext.strokeStyle = [aColor cssString];
}

- (void)CGContextStrokeRect:(JSObject)aContext rect:(CPColor)aRect
{
    aContext.strokeRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
}

- (void)CGContextSelectFont:(JSObject)aContext font:(CPFont)aFont
{
    aContext.font = [aFont cssString];
}

- (void)CGContextShowTextAtPoint:(JSObject)aContext text:(CPString)aText point:(CGPoint)aPoint
{
    aContext.textBaseline = "top";
    aContext.fillText(aText, aPoint.x, aPoint.y);
}

- (void)CGContextFillRect:(JSObject)aContext rect:(CGRect)aRect
{
    aContext.fillRect(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
}

- (void)CGContextClearRect:(JSObject)aContext rect:(CGRect)aRect
{
    aContext.clearRect(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
}

- (void)CGContextGetImageData:(JSObject)aContext rect:(CGRect)aRect
{
    aContext.getImageData(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
}

- (void)CGContextPutImageData:(JSObject)aContext image:(id)anImageData point:(CGPoint)aPoint
{
    aContext.putImageData(anImageData, aPoint.x, aPoint.y);
}

- (void)CGContextTranslateCTM:(JSObject)aContext tx:(float)tx ty:(float)ty
{
    aContext.translate(tx, ty);
}

- (void)CGContextRotateCTM:(JSObject)aContext angle:(float)angle
{
    aContext.rotate(angle);
}

- (void)CGContextScaleCTM:(JSObject)aContext sx:(float)sx sy:(float)sy
{
    aContext.scale(sx, sy);
}

@end
