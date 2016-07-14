/*
 * RTSVGRenderer.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@import "../Misc/RTScreen.j"

SVG_NS      = "http://www.w3.org/2000/svg";
XLINK       = "http://www.w3.org/1999/xlink";
XHTML       = "http://www.w3.org/1999/xhtml";
XML         = "http://www.w3.org/XML/1998/namespace";

@implementation RTSVGRenderer : RTRenderer
{
    SVG_ROOT            _SVGRoot;

    BOOL                _isTiny @accessors(readonly, getter=isTiny);

    CPArray             _cgCmds;

    CPString            _drawPath;
    DOMObject           _lastPath;
    CPColor             _fillColor;
    CPColor             _strokeColor;
    CPFont              _selectedFont;

    int                 _lineWidth;
    CPString            _lineCap;
    CPString            _lineJoin;
    int                 _miterLimit;
}

- (id)init
{
    if (self = [super _init])
    {
        _isSVG = YES;

        _drawPath = "";
        _cgCmds = [CPArray array];

        if (document.documentElement.nodeName === "HTML")
        {
            var b_size = [RTScreen browserSize];

            _SVGRoot = document.createElementNS(SVG_NS, 'svg');
            _SVGRoot.setAttribute('xmlns', SVG_NS);
            _SVGRoot.setAttribute('xmlns:xlink', XLINK);
            _SVGRoot.setAttribute('width', b_size.width);
            _SVGRoot.setAttribute('height', b_size.height);
            document.body.appendChild(_SVGRoot);
        }
        else
        {
            _SVGRoot = document.documentElement;
            _isTiny = YES;
        }

        _SVGRoot.setAttribute("viewport-fill", "#ffffff");
    }
    return self;
}

- (void)setSize:(CGSize)aSize
{
    if (_SVGRoot)
    {
        _SVGRoot.setAttribute('width', aSize.width);
        _SVGRoot.setAttribute('height', aSize.height);
    }
}

- (RTElement)createViewElement:(RTView)aView
{
    return [[RTSVGElement alloc] initWithView:aView];
}

- (RTElement)createImageElement:(RTView)aView
{
    return [[RTSVGImageElement alloc] initWithView:aView];
}

- (RTElement)createVideoElement:(RTView)aView
{
    return [[RTSVGVideoElement alloc] initWithView:aView];
}

- (RTElement)createTextElement:(RTView)aView
{
    return [[RTSVGTextElement alloc] initWithView:aView];
}

- (DOMObject)_parentView:(RTView)view
{
    return [view superview] ? [[[view superview] element] DOMObject] : _SVGRoot;
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

    text = document.createElementNS(SVG_NS,"text");

    text.setAttributeNS(XML, "xml:space", "preserve");
    text.setAttribute("x",100);
    text.setAttribute("y",100);
    text.setAttribute("fill","black");
    text.setAttribute('font-family', [aFont familyName]);
    text.setAttribute('font-size', [aFont size]);
    _SVGRoot.appendChild(text);

    if (_isTiny)
    {
        text.textContent = aString;
    }
    else
    {
        text.appendChild(document.createTextNode(aString));
        width = text.getComputedTextLength();
    }

    outSize = CGSizeMake(text.getBBox().width, text.getBBox().height);
    _SVGRoot.removeChild(text);


    return outSize;
}

- (BOOL)canCacheData
{
    return NO;
}

- (BOOL)supportsFilePrefix
{
    return NO;
}

- (BOOL)supportsSMILAnimations
{
    return YES;
    return _isTiny ? YES : NO;
}

// ************
// COREGRAPHICS
// ************

- (void)addRectToCommand:(CGRect)aRect withID:(int)anID forContext:(JSObject)aContext
{
    var o = {
        elementID:anID,
        rect:CGRectMakeCopy(aRect),
        context:aContext
        };
    [_cgCmds addObject:o];
}

- (void)CGContextBeginPath:(JSObject)aContext
{
    _drawPath = "";
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
                CPLog("[WARNING] TODO");
                break;
        }
    }
}

- (void)CGContextMoveToPointCanvas:(JSObject)aContext point:(CGPoint)aPoint
{
    _drawPath += "M" + aPoint.x + " " + aPoint.y + " ";
}

- (void)CGContextAddLineToPointCanvas:(JSObject)aContext point:(CGPoint)aPoint
{
    _drawPath += "L" + aPoint.x + " " + aPoint.y + " ";
}

- (void)CGContextAddQuadCurveToPointCanvas:(JSObject)aContext controlPoint:(CGPoint)aControlPoint point:(CGPoint)aPoint
{
    _drawPath += "Q" + aControlPoint.x + " " + aControlPoint.y + " " + aPoint.x + " " + aPoint.y + " ";
}

- (void)CGContextAddCurveToPointCanvas:(JSObject)aContext controlPoint1:(CGPoint)aControlPoint1 controlPoint2:(CGPoint)aControlPoint2 point:(CGPoint)aPoint
{
    _drawPath += "C" + aControlPoint1.x + " " + aControlPoint1.y + " " + aControlPoint2.x + " " + aControlPoint2.y + " " + aPoint.x + " " + aPoint.y + " ";
}

- (void)CGContextClosePathCanvas:(JSObject)aContext
{

}

- (void)CGContextAddArcCanvas:(JSObject)aContext point:(CGPoint)aPoint radius:(int)aRadius startAngle:(float)aStartAngle endAngle:(float)anEndAngle clockwise:(BOOL)aClockwise
{
    //aContext.arc(aPoint.x, aPoint.y, aRadius, aStartAngle, anEndAngle, aClockwise);
}

- (void)CGContextClosePath:(JSObject)aContext
{
    [self CGContextClosePathCanvas:aContext];
}

- (void)CGContextDrawLinearGradient:(JSObject)aContext gradient:(JSObject)aGradient startPoint:(CGPoint)aStartPoint endPoint:(CGpoint)anEndPoint options:(JSObject)options
{
    var colors = aGradient.colors,
        count = colors.length,
        uid = [CPString UUID];

    var parentRect = aContext.parentNode.getAttribute("viewBox").split(" ");
    parentRect = CGRectMake(parseInt(parentRect[0]),
                            parseInt(parentRect[1]),
                            parseInt(parentRect[2]),
                            parseInt(parentRect[3]));

    var defs = document.createElementNS(SVG_NS, "defs"),
        lg = document.createElementNS(SVG_NS, "linearGradient");
    lg.setAttribute("id", "linear_gradient_"+uid);

    lg.setAttribute("x1", (aStartPoint.x / parentRect.size.width) * 100 + "%");
    lg.setAttribute("y1", (aStartPoint.y / parentRect.size.height) * 100 + "%");
    lg.setAttribute("x2", (anEndPoint.x / parentRect.size.width) * 100 + "%");
    lg.setAttribute("y2", (anEndPoint.y / parentRect.size.height) * 100 + "%");

    for (var i = 0; i < count; ++i)
    {
        var stop = document.createElementNS(SVG_NS, "stop");
        stop.setAttribute("offset", ((i / (count - 1)) * 100) + "%");
        if (_isTiny)
            stop.setAttribute("style", "stop-color: " + [self toRGB:colors[i]]);
        else
            stop.setAttribute("style", "stop-color: " + [self toString:colors[i]]);
        lg.appendChild(stop);
    }

    defs.appendChild(lg);
    aContext.parentNode.insertBefore(defs, _lastPath);

    if (_lastPath)
        _lastPath.setAttribute("fill", "url(#linear_gradient_" + uid + ")");
}

- (void)CGContextDrawPath:(JSObject)aContext mode:(int)aMode
{
    _lastPath = document.createElementNS(SVG_NS, 'path');
    _lastPath.setAttribute('d', _drawPath);
    if (aMode == kCGPathFill || aMode == kCGPathFillStroke)
        _lastPath.setAttribute('fill', [_fillColor cssString]);
    if (aMode == kCGPathStroke || aMode == kCGPathFillStroke || aMode == kCGPathEOFillStroke)
        _lastPath.setAttribute('stroke', [_strokeColor cssString]);
    aContext.parentNode.appendChild(_lastPath);
}

- (void)CGContextSetFillColor:(JSObject)aContext color:(CPColor)aColor
{
    _fillColor = aColor;

    // Not supporting pattern image like the canvas version
    // although it's technically possible
}

- (void)CGContextSetStrokeColor:(JSObject)aContext color:(CPColor)aColor
{
    _strokeColor = aColor;
}

- (void)CGContextStrokeRect:(JSObject)aContext rect:(CPColor)aRect
{
    var el_id = Math.uuid(),
        el = document.createElementNS(SVG_NS, 'rect');
    el.setAttribute('id', el_id);
    el.setAttribute('x', CGRectGetMinX(aRect));
    el.setAttribute('y', CGRectGetMinY(aRect));
    el.setAttribute('width', CGRectGetWidth(aRect));
    el.setAttribute('height', CGRectGetHeight(aRect));
    el.setAttribute('stroke', [_strokeColor cssString]);
    el.setAttribute('fill', 'none');
    aContext.parentNode.appendChild(el);

    [self addRectToCommand:aRect withID:el_id forContext:aContext];
}

- (void)CGContextSelectFont:(JSObject)aContext font:(CPFont)aFont
{
    _selectedFont = aFont;
}

- (void)CGContextShowTextAtPoint:(JSObject)aContext text:(CPString)aText point:(CGPoint)aPoint
{
    var tSize = [aText sizeWithFont:_selectedFont],
        parentVB = aContext.parentNode.getAttribute("viewBox");
    if (!parentVB)
        return;

    var parentHeight = parentVB.split(" ")[3];
    if (aPoint.y + tSize.height > parentHeight)
        return;

    var el_id = Math.uuid(),
        el = document.createElementNS(SVG_NS, 'text');
    el.setAttribute('id', el_id);
    el.setAttribute('x', aPoint.x);
    el.setAttribute('y', aPoint.y);
    el.setAttribute('font-family', [_selectedFont familyName]);
    el.setAttribute('font-size', [_selectedFont size]);
    el.setAttribute('fill', [_fillColor cssString]);

    if (_isTiny)
        el.setAttribute('y', aPoint.y + tSize.height);
    else
       el.setAttribute('dominant-baseline', 'text-before-edge');

    var cid = aContext.getAttribute("id"),
        idx = cid.indexOf('_');
    if (idx != -1)
    {
        cid = [cid substringFromIndex:idx + 1];
        {
            el.setAttribute("clip-path", "url(#cp_"+cid+")");
            el.setAttribute("clip-rule", "nonzero");
        }
    }

    el.textContent = aText;
    aContext.parentNode.appendChild(el);

    var rect = CGRectMake(aPoint.x, aPoint.y, tSize.width, tSize.height);
    [self addRectToCommand:rect withID:el_id forContext:aContext];
}

- (void)CGContextFillRect:(JSObject)aContext rect:(CGRect)aRect
{
    var el_id = Math.uuid(),
        el = document.createElementNS(SVG_NS, 'rect');
    el.setAttribute('id', el_id);
    el.setAttribute('x', CGRectGetMinX(aRect));
    el.setAttribute('y', CGRectGetMinY(aRect));
    el.setAttribute('width', CGRectGetWidth(aRect));
    el.setAttribute('height', CGRectGetHeight(aRect));
    el.setAttribute('fill', [_fillColor cssString]);
    if (_isTiny)
        el.setAttribute('fill-opacity', [_fillColor alphaComponent]);
    aContext.parentNode.appendChild(el);

    [self addRectToCommand:aRect withID:el_id forContext:aContext];
}

- (void)CGContextClearRect:(JSObject)aContext rect:(CGRect)aRect
{
    for (var i = 0; i < [_cgCmds count]; ++i)
    {
        var o = [_cgCmds objectAtIndex:i];
        if (aContext.id == o.context.id && CGRectContainsRect(aRect, o.rect))
        {
            var el = document.getElementById(o.elementID);
            if (el)
                el.parentNode.removeChild(el);
        }
    }
}

- (void)CGContextGetImageData:(JSObject)aContext rect:(CGRect)aRect
{
    // No can do...
}

- (void)CGContextPutImageData:(JSObject)aContext image:(id)anImageData point:(CGPoint)aPoint
{
    // No can do...
}

- (CPString)toRGB:(CPColor)aColor
{
    return "rgb(" + ROUND(aColor.components[0] * 255) + ", " + ROUND(aColor.components[1] * 255) + ", " + ROUND(255 * aColor.components[2]) + ")";
}

- (CPString)toString:(CPColor)aColor
{
    return "rgba(" + ROUND(aColor.components[0] * 255) + ", " + ROUND(aColor.components[1] * 255) + ", " + ROUND(255 * aColor.components[2]) + ", " + aColor.components[3] + ")";
}

@end
