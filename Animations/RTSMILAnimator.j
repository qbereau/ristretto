/*
 * RTSMILAnimator.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

var EASE_IN     = ".42 0 1 0",
    EASE_OUT    = "0 0 .58 1",
    EASE_IN_OUT = ".42 .0 .58 1";

@implementation RTSMILAnimator : RTAnimator
{
    CPArray         animatedObjects;
}

- (id)initWithDuration:(CPTimeInterval)aDuration
                 delay:(CPTimeInterval)aDelay
               options:(RTViewAnimationOption)aOptions
            animations:(block)anAnimationBlock
            completion:(block)aCompletionBlock
{
    self = [super _initWithDuration:aDuration
                              delay:aDelay
                            options:aOptions
                         animations:anAnimationBlock
                         completion:aCompletionBlock];

    return self;
}

- (void)startAnimation
{
    animatedObjects = [CPArray array];

    var timeOffset = -1;
    if (!_autoRepeat && !_autoReverse)
    {
        timeOffset = _duration;
    }
    else if (!_autoRepeat && _autoReverse)
    {
        timeOffset = _duration * 2;
    }

    if (timeOffset != -1)
    {
        [CPTimer scheduledTimerWithTimeInterval:timeOffset
                                         target:self
                                       selector:@selector(_animationDidEnd:)
                                       userInfo:nil
                                        repeats:NO];
    }

    _animationBlock(self);
}

- (void)_animationDidEnd:(CPTimer)aTimer
{
    for (var i = 0; i < [animatedObjects count]; ++i)
    {
        var dict    = [animatedObjects objectAtIndex:i],
            object  = [dict objectForKey:@"object"],
            params  = [dict objectForKey:@"params"],
            prop    = [params objectForKey:@"prop"],
            target  = [params objectForKey:@"target"];

        switch (prop)
        {
            case "frame":
                [object setFrame:target];
                break;
            case "frameOrigin":
                [object setFrameOrigin:target];
                break;
            case "frameSize":
                [object setFrameSize:target];
                break;
            case "frameSize":
                [object setFrameSize:target];
                break;
            case "frameSize":
                [object setFrameSize:target];
                break;
            case "alphaValue":
                [object setAlphaValue:target];
                break;
            case "backgroundColor":
                [object setBackgroundColor:target];
                break;
        }

        [RTSMILAnimator resetAnimationObject:object];
    }

    if (_completionBlock && typeof(_completionBlock) === "function")
    {
        _completionBlock(YES);
    }
}

- (CGRect)targetFrameForView:(RTView)aView superviewTargetFrame:(CGRect)aFrame
{
    var mask = [aView autoresizingMask];

    if (mask == RTViewNotSizable)
        return CGRectMakeCopy([aView frame]);

    var frame = aFrame,
        newFrame = CGRectMakeCopy(aView._frame),
        dX = (CGRectGetWidth(frame) - aView._superview._frame.size.width) /
            (((mask & RTViewMinXMargin) ? 1 : 0) + (mask & RTViewWidthSizable ? 1 : 0) + (mask & RTViewMaxXMargin ? 1 : 0)),
        dY = (CGRectGetHeight(frame) - aView._superview._frame.size.height) /
            ((mask & RTViewMinYMargin ? 1 : 0) + (mask & RTViewHeightSizable ? 1 : 0) + (mask & RTViewMaxYMargin ? 1 : 0));

    if (mask & RTViewMinXMargin)
        newFrame.origin.x += dX;
    if (mask & RTViewWidthSizable)
        newFrame.size.width += dX;

    if (mask & RTViewMinYMargin)
        newFrame.origin.y += dY;
    if (mask & RTViewHeightSizable)
        newFrame.size.height += dY;

    return newFrame;
}

- (void)animateObject:(id)anObject
         withProperty:(CPString)aProp
           toTarget:(id)aTarget
{
    var duration    = _duration + "s",
        repeatCount = "1",
        fill        = "freeze",
        calcMode    = (_animationCurve === RTViewAnimationOptionCurveLinear) ? "linear" : "spline",
        keySplines  = "",
        keyTimes    = "0;1";

    if (_autoReverse)
    {
        duration = _duration * 2 + "s";
        keyTimes = "0;.5;1";
    }

    if (_autoRepeat)
    {
        repeatCount = "indefinite";

        if (!_autoReverse)
        {
            fill = "remove";
        }
    }

    if (_animationCurve === RTViewAnimationOptionCurveEaseIn)
    {
        keySplines = EASE_IN;
        if (_autoReverse)
            keySplines += "; " + EASE_OUT;
    }
    else if (_animationCurve === RTViewAnimationOptionCurveEaseOut)
    {
        keySplines = EASE_OUT;
        if (_autoReverse)
            keySplines += "; " + EASE_IN;
    }
    else if (_animationCurve === RTViewAnimationOptionCurveEaseInOut)
    {
        keySplines = EASE_IN_OUT;
        if (_autoReverse)
            keySplines += "; " + EASE_IN_OUT;
    }


    var params = [CPDictionary dictionaryWithObjectsAndKeys:
        duration,       "duration",
        repeatCount,    "repeatCount",
        fill,           "fill",
        calcMode,       "calcMode",
        keySplines,     "keySplines",
        keyTimes,       "keyTimes",
        aProp,          "prop",
        aTarget,        "target"
        ];

    [animatedObjects addObject:[CPDictionary dictionaryWithObjectsAndKeys:anObject, @"object", params, @"params"]];

    [self _updatePropsWithView:anObject params:params];

    for (var idxSubObjects = 0; idxSubObjects < [[anObject subviews] count]; ++idxSubObjects)
    {
        var subview = [[anObject subviews] objectAtIndex:idxSubObjects],
            superviewTargetFrame = nil;

        if (aProp === "frameOrigin")
        {
            superviewTargetFrame   = CGRectMake(aTarget.x, aTarget.y, [subview frameSize].width, [subview frameSize].height);
        }
        else if (aProp === "frameSize")
        {
            superviewTargetFrame   = CGRectMake([subview frameOrigin].x, [subview frameOrigin].y, aTarget.width, aTarget.height);
        }
        else if (aProp === "frame")
        {
            superviewTargetFrame   = CGRectMakeCopy(aTarget);
        }
        else
        {
            superviewTargetFrame = CGRectMakeCopy([subview frame]);
        }

        var f = [self targetFrameForView:subview
                    superviewTargetFrame:superviewTargetFrame];

        [self animateObject:subview
               withProperty:"frame"
                   toTarget:f];
    }
}

+ (void)resetAnimationObject:(id)animObj
{
    var domObj  = [[animObj element] DOMObject],
        ctx     = [[animObj element] graphicsContext];

    if (domObj.currentAnimationAnimateTransformFrameOrigin)
    {
        domObj.removeChild(domObj.currentAnimationAnimateTransformFrameOrigin);
        domObj.currentAnimationAnimateTransformFrameOrigin = nil;

        var removeSubviewsAnim = function(parentView)
        {
            for (var idxSubObjects = 0; idxSubObjects < [[parentView subviews] count]; ++idxSubObjects)
            {
                var subview         = [[parentView subviews] objectAtIndex:idxSubObjects],
                    subviewDomObj   = [[parentView element] DOMObject];
                if (subviewDomObj.currentAnimationAnimateTransformFrameOrigin)
                {
                    subviewDomObj.removeChild(subviewDomObj.currentAnimationAnimateTransformFrameOrigin);
                    subviewDomObj.currentAnimationAnimateTransformFrameOrigin = nil;
                }

                removeSubviewsAnim(subview);
            }
        }

        removeSubviewsAnim(animObj);
    }

    if (domObj.currentAnimationAnimateFrameOriginX)
    {
        domObj.removeChild(domObj.currentAnimationAnimateFrameOriginX);
        domObj.currentAnimationAnimateFrameOriginX = nil;

        var removeSubviewsAnim = function(parentView)
        {
            for (var idxSubObjects = 0; idxSubObjects < [[parentView subviews] count]; ++idxSubObjects)
            {
                var subview         = [[parentView subviews] objectAtIndex:idxSubObjects],
                    subviewDomObj   = [[parentView element] DOMObject];
                if (subviewDomObj.currentAnimationAnimateFrameOriginX)
                {
                    subviewDomObj.removeChild(subviewDomObj.currentAnimationAnimateFrameOriginX);
                    subviewDomObj.currentAnimationAnimateFrameOriginX = nil;
                }

                removeSubviewsAnim(subview);
            }
        }

        removeSubviewsAnim(animObj);
    }

    if (domObj.currentAnimationAnimateFrameOriginY)
    {
        domObj.removeChild(domObj.currentAnimationAnimateFrameOriginY);
        domObj.currentAnimationAnimateFrameOriginY = nil;

        var removeSubviewsAnim = function(parentView)
        {
            for (var idxSubObjects = 0; idxSubObjects < [[parentView subviews] count]; ++idxSubObjects)
            {
                var subview         = [[parentView subviews] objectAtIndex:idxSubObjects],
                    subviewDomObj   = [[parentView element] DOMObject];
                if (subviewDomObj.currentAnimationAnimateFrameOriginY)
                {
                    subviewDomObj.removeChild(subviewDomObj.currentAnimationAnimateFrameOriginY);
                    subviewDomObj.currentAnimationAnimateFrameOriginY = nil;
                }

                removeSubviewsAnim(subview);
            }
        }

        removeSubviewsAnim(animObj);
    }

    if (ctx.currentAnimationAnimateFrameSizeWidth)
    {
        ctx.removeChild(ctx.currentAnimationAnimateFrameSizeWidth);
        ctx.currentAnimationAnimateFrameSizeWidth = nil;
        try
        {
            var cpr = document.getElementById("cpr_" + [animObj UID]);
            if (cpr && cpr.currentAnimationAnimateFrameSizeWidth)
            {
                cpr.removeChild(cpr.currentAnimationAnimateFrameSizeWidth);
                cpr.currentAnimationAnimateFrameSizeWidth = nil;
            }
        }
        catch (e)
        {

        }

        var removeSubviewsAnim = function(parentView)
        {
            for (var idxSubObjects = 0; idxSubObjects < [[parentView subviews] count]; ++idxSubObjects)
            {
                var subview         = [[parentView subviews] objectAtIndex:idxSubObjects],
                    subviewCTX      = [[parentView element] graphicsContext],
                    subviewDomObj   = [[parentView element] DOMObject];
                if (subviewCTX.currentAnimationAnimateFrameSizeWidth)
                {
                    subviewCTX.removeChild(subviewCTX.currentAnimationAnimateFrameSizeWidth);
                    subviewCTX.currentAnimationAnimateFrameSizeWidth = nil;

                    try
                    {
                        var cpr = document.getElementById("cpr_" + [subview UID]);
                        if (cpr && cpr.currentAnimationAnimateFrameSizeWidth)
                        {
                            cpr.removeChild(cpr.currentAnimationAnimateFrameSizeWidth);
                            cpr.currentAnimationAnimateFrameSizeWidth = nil;
                        }
                    }
                    catch (e)
                    {

                    }
                }

                if (subviewDomObj.currentAnimationAnimateTransformFrameOrigin)
                {
                    subviewDomObj.removeChild(subviewDomObj.currentAnimationAnimateTransformFrameOrigin);
                    subviewDomObj.currentAnimationAnimateTransformFrameOrigin = nil;
                }

                removeSubviewsAnim(subview);
            }
        }

        removeSubviewsAnim(animObj);
    }

    if (ctx.currentAnimationAnimateFrameSizeHeight)
    {
        ctx.removeChild(ctx.currentAnimationAnimateFrameSizeHeight);
        ctx.currentAnimationAnimateFrameSizeHeight = nil;
        try
        {
            var cpr = document.getElementById("cpr_" + [animObj UID]);
            if (cpr && cpr.currentAnimationAnimateFrameSizeHeight)
            {
                cpr.removeChild(cpr.currentAnimationAnimateFrameSizeHeight);
                cpr.currentAnimationAnimateFrameSizeHeight = nil;
            }
        }
        catch (e)
        {

        }

        var removeSubviewsAnim = function(parentView)
        {
            for (var idxSubObjects = 0; idxSubObjects < [[parentView subviews] count]; ++idxSubObjects)
            {
                var subview         = [[parentView subviews] objectAtIndex:idxSubObjects],
                    subviewCTX      = [[subview element] graphicsContext],
                    subviewDomObj   = [[subview element] DOMObject];
                if (subviewCTX.currentAnimationAnimateFrameSizeHeight)
                {
                    subviewCTX.removeChild(subviewCTX.currentAnimationAnimateFrameSizeHeight);
                    subviewCTX.currentAnimationAnimateFrameSizeHeight = nil;

                    try
                    {
                        var cpr = document.getElementById("cpr_" + [subview UID]);
                        if (cpr && cpr.currentAnimationAnimateFrameSizeHeight)
                        {
                            cpr.removeChild(cpr.currentAnimationAnimateFrameSizeHeight);
                            cpr.currentAnimationAnimateFrameSizeHeight = nil;
                        }
                    }
                    catch (e)
                    {

                    }
                }

                if (subviewDomObj.currentAnimationAnimateTransformFrameOrigin)
                {
                    subviewDomObj.removeChild(subviewDomObj.currentAnimationAnimateTransformFrameOrigin);
                    subviewDomObj.currentAnimationAnimateTransformFrameOrigin = nil;
                }

                removeSubviewsAnim(subview);
            }
        }

        removeSubviewsAnim(animObj);
    }

    if (domObj.currentAnimationAnimateFrameSizeViewBox)
    {
        domObj.removeChild(domObj.currentAnimationAnimateFrameSizeViewBox);
        domObj.currentAnimationAnimateFrameSizeViewBox = nil;

        var removeSubviewsAnim = function(parentView)
        {
            for (var idxSubObjects = 0; idxSubObjects < [[parentView subviews] count]; ++idxSubObjects)
            {
                var subview         = [[parentView subviews] objectAtIndex:idxSubObjects],
                    subviewDomObj   = [[parentView element] DOMObject];
                if (subviewDomObj.currentAnimationAnimateFrameSizeViewBox)
                {
                    subviewDomObj.removeChild(subviewDomObj.currentAnimationAnimateFrameSizeViewBox);
                    subviewDomObj.currentAnimationAnimateFrameSizeViewBox = nil;
                }

                removeSubviewsAnim(subview);
            }
        }

        removeSubviewsAnim(animObj);
    }

    if (ctx.currentAnimationAnimateBackgroundColor)
    {
        ctx.removeChild(ctx.currentAnimationAnimateBackgroundColor);
        ctx.currentAnimationAnimateBackgroundColor = nil;

        var removeSubviewsAnim = function(parentView)
        {
            for (var idxSubObjects = 0; idxSubObjects < [[parentView subviews] count]; ++idxSubObjects)
            {
                var subview     = [[parentView subviews] objectAtIndex:idxSubObjects],
                    subviewCTX  = [[parentView element] graphicsContext];
                if (subviewCTX.currentAnimationAnimateBackgroundColor)
                {
                    subviewCTX.removeChild(subviewCTX.currentAnimationAnimateBackgroundColor);
                    subviewCTX.currentAnimationAnimateBackgroundColor = nil;
                }

                removeSubviewsAnim(subview);
            }
        }

        removeSubviewsAnim(animObj);
    }

    if (domObj.currentAnimationAnimateAlphaValue)
    {
        domObj.removeChild(domObj.currentAnimationAnimateAlphaValue);
        domObj.currentAnimationAnimateAlphaValue = nil;

        var removeSubviewsAnim = function(parentView)
        {
            for (var idxSubObjects = 0; idxSubObjects < [[parentView subviews] count]; ++idxSubObjects)
            {
                var subview     = [[parentView subviews] objectAtIndex:idxSubObjects],
                    subviewCTX  = [[parentView element] graphicsContext];
                if (subviewCTX.currentAnimationAnimateAlphaValue)
                {
                    subviewCTX.removeChild(subviewCTX.currentAnimationAnimateAlphaValue);
                    subviewCTX.currentAnimationAnimateAlphaValue = nil;
                }

                removeSubviewsAnim(subview);
            }
        }

        removeSubviewsAnim(animObj);
    }
}

- (void)_updatePropsWithView:(RTView)aView params:(CPDictionary)aParams
{
    var duration    = [aParams objectForKey:@"duration"],
        repeatCount = [aParams objectForKey:@"repeatCount"],
        fill        = [aParams objectForKey:@"fill"],
        calcMode    = [aParams objectForKey:@"calcMode"],
        keySplines  = [aParams objectForKey:@"keySplines"],
        keyTimes    = [aParams objectForKey:@"keyTimes"],
        aProp       = [aParams objectForKey:@"prop"],
        aTarget     = [aParams objectForKey:@"target"],
        currentObject = aView;

    switch (aProp)
    {
        case "frame":
        case "frameOrigin":
        case "frameSize":

            if (aProp != "frameSize")
            {
                var domObj      = [[currentObject element] DOMObject],
                    ctx         = [[currentObject element] graphicsContext],
                    tg          = (aProp === "frameOrigin") ? aTarget.x + "," + aTarget.y : aTarget.origin.x + "," + aTarget.origin.y,
                    orig        = [currentObject frameOrigin].x+","+[currentObject frameOrigin].y,
                    values      = tg;

                if (_autoReverse)
                {
                    values = orig + ";" + tg;

                    if (_autoRepeat)
                    {
                        values = orig + ";" + tg + ";" + orig;
                    }
                }
                else
                {
                    values = orig + ";" + tg;
                }

                var anim = document.createElementNS(SVG_NS, "animateTransform");
                anim.setAttribute("id", "animateTransform_frameOrigin_"+[currentObject UID]);
                anim.setAttribute("attributeName", "transform");
                anim.setAttribute("attributeType", "XML");
                anim.setAttribute("type", "translate");
                anim.setAttribute("begin", "indefinite");
                anim.setAttribute("calcMode", calcMode);
                anim.setAttribute("keyTimes", keyTimes);
                anim.setAttribute("keySplines", keySplines);
                anim.setAttribute("values", values);
                anim.setAttribute("dur", duration);
                anim.setAttribute("fill", fill);
                anim.setAttribute("repeatCount", repeatCount);
                domObj.appendChild(anim);
                domObj.currentAnimationAnimateTransformFrameOrigin = anim;
                anim.beginElement();

                var vp      = document.getElementById("viewport_"+[currentObject UID]),
                    bgvp    = document.getElementById("bg_vp_"+[currentObject UID]);
                if (vp || bgvp)
                {
                    var tgX      = (aProp === "frameOrigin") ? aTarget.x : aTarget.origin.x,
                        tgY      = (aProp === "frameOrigin") ? aTarget.y : aTarget.origin.y,
                        origX    = [currentObject frameOrigin].x,
                        origY    = [currentObject frameOrigin].y,
                        valuesX  = tgX,
                        valuesY  = tgY;

                    if (_autoReverse)
                    {
                        valuesX = origX + ";" + tgX;
                        valuesY = origY + ";" + tgY;

                        if (_autoRepeat)
                        {
                            valuesX = origX + ";" + tgX + ";" + origX;
                            valuesY = origY + ";" + tgY + ";" + origY;
                        }
                    }
                    else
                    {
                        valuesX = origX + ";" + tgX;
                        valuesY = origY + ";" + tgY;
                    }

                    var animX = document.createElementNS(SVG_NS, "animate");
                    animX.setAttribute("id", "animate_frameOrigin_X_"+[currentObject UID]);
                    animX.setAttribute("attributeName", "x");
                    animX.setAttribute("attributeType", "XML");
                    animX.setAttribute("begin", "indefinite");
                    animX.setAttribute("calcMode", calcMode);
                    animX.setAttribute("keyTimes", keyTimes);
                    animX.setAttribute("keySplines", keySplines);
                    animX.setAttribute("values", valuesX);
                    animX.setAttribute("dur", duration);
                    animX.setAttribute("fill", fill);
                    animX.setAttribute("repeatCount", repeatCount);

                    ctx.appendChild(animX);
                    ctx.currentAnimationAnimateFrameOriginX = animX;
                    animX.beginElement();

                    if (bgvp)
                    {
                        var cloneAnimX = animX.cloneNode();
                        bgvp.appendChild(cloneAnimX);
                        bgvp.currentAnimationAnimateFrameOriginX = cloneAnimX;
                        cloneAnimX.beginElement();
                    }


                    var animY = document.createElementNS(SVG_NS, "animate");
                    animY.setAttribute("id", "animate_frameOrigin_Y_"+[currentObject UID]);
                    animY.setAttribute("attributeName", "y");
                    animY.setAttribute("attributeType", "XML");
                    animY.setAttribute("begin", "indefinite");
                    animY.setAttribute("calcMode", calcMode);
                    animY.setAttribute("keyTimes", keyTimes);
                    animY.setAttribute("keySplines", keySplines);
                    animY.setAttribute("values", valuesY);
                    animY.setAttribute("dur", duration);
                    animY.setAttribute("fill", fill);
                    animY.setAttribute("repeatCount", repeatCount);

                    ctx.appendChild(animY);
                    ctx.currentAnimationAnimateFrameOriginY = animY;
                    animY.beginElement();

                    if (bgvp)
                    {
                        var cloneAnimY = animY.cloneNode();
                        bgvp.appendChild(cloneAnimY);
                        bgvp.currentAnimationAnimateFrameOriginY = cloneAnimY;
                        cloneAnimY.beginElement();
                    }
                }
            }

            if (aProp != "frameOrigin")
            {
                var domObj   = [[currentObject element] DOMObject],
                    ctx      = [[currentObject element] graphicsContext],
                    tgW      = (aProp === "frameSize") ? aTarget.width : aTarget.size.width,
                    tgH      = (aProp === "frameSize") ? aTarget.height : aTarget.size.height,
                    origW    = [currentObject frameSize].width,
                    origH    = [currentObject frameSize].height,
                    valuesW  = tgW,
                    valuesH  = tgH,
                    valuesVB = "0 0 " + tgW + " " + tgH;

                if (_autoReverse)
                {
                    valuesW = origW + ";" + tgW;
                    valuesH = origH + ";" + tgH;
                    valuesVB = "0 0 " + origW + " " + origH + "; 0 0 " + tgW + " " + tgH;

                    if (_autoRepeat)
                    {
                        valuesW = origW + ";" + tgW + ";" + origW;
                        valuesH = origH + ";" + tgH + ";" + origH;
                        valuesVB = "0 0 " + origW + " " + origH + ";" + "0 0 " + tgW + " " + tgH + "; 0 0 " + origW + " " + origH;
                    }
                }
                else
                {
                    valuesW = origW + ";" + tgW;
                    valuesH = origH + ";" + tgH;
                    valuesVB = "0 0 " + origW + " " + origH + "; 0 0 " + tgW + " " + tgH;
                }

                var cpr     = document.getElementById("cpr_" + [currentObject UID]),
                    bgvp    = document.getElementById("bg_img_1_" + [currentObject UID]);

                var animW = document.createElementNS(SVG_NS, "animate");
                animW.setAttribute("id", "animate_frameSize_W_"+[currentObject UID]);
                animW.setAttribute("attributeName", "width");
                animW.setAttribute("attributeType", "XML");
                animW.setAttribute("begin", "indefinite");
                animW.setAttribute("calcMode", calcMode);
                animW.setAttribute("keyTimes", keyTimes);
                animW.setAttribute("keySplines", keySplines);
                animW.setAttribute("values", valuesW);
                animW.setAttribute("dur", duration);
                animW.setAttribute("fill", fill);
                animW.setAttribute("repeatCount", repeatCount);

                ctx.appendChild(animW);
                ctx.currentAnimationAnimateFrameSizeWidth = animW;
                animW.beginElement();

                if (cpr)
                {
                    var cloneAnimW = animW.cloneNode();
                    cpr.appendChild(cloneAnimW);
                    cpr.currentAnimationAnimateFrameSizeWidth = cloneAnimW;
                    cloneAnimW.beginElement();
                }

                if (bgvp)
                {
                    cloneAnimW = animW.cloneNode();
                    bgvp.appendChild(cloneAnimW);
                    bgvp.currentAnimationAnimateFrameSizeWidth = cloneAnimW;
                    cloneAnimW.beginElement();
                }

                var animH = document.createElementNS(SVG_NS, "animate");
                animH.setAttribute("id", "animate_frameSize_H_"+[currentObject UID]);
                animH.setAttribute("attributeName", "height");
                animH.setAttribute("attributeType", "XML");
                animH.setAttribute("begin", "indefinite");
                animH.setAttribute("calcMode", calcMode);
                animH.setAttribute("keyTimes", keyTimes);
                animH.setAttribute("keySplines", keySplines);
                animH.setAttribute("values", valuesH);
                animH.setAttribute("dur", duration);
                animH.setAttribute("fill", fill);
                animH.setAttribute("repeatCount", repeatCount);
                ctx.appendChild(animH);
                ctx.currentAnimationAnimateFrameSizeHeight = animH;
                animH.beginElement();

                if (cpr)
                {
                    var cloneAnimH = animH.cloneNode();
                    cpr.appendChild(cloneAnimH);
                    cpr.currentAnimationAnimateFrameSizeHeight = cloneAnimH;
                    cloneAnimH.beginElement();
                }

                if (bgvp)
                {
                    cloneAnimH = animH.cloneNode();
                    bg_vp.appendChild(cloneAnimH);
                    bg_vp.currentAnimationAnimateFrameSizeHeight = cloneAnimH;
                    cloneAnimH.beginElement();
                }

                var animVB = document.createElementNS(SVG_NS, "animate");
                animVB.setAttribute("id", "animate_frameSize_viewBox_"+[currentObject UID]);
                animVB.setAttribute("attributeName", "viewBox");
                animVB.setAttribute("attributeType", "XML");
                animVB.setAttribute("begin", "indefinite");
                animVB.setAttribute("calcMode", calcMode);
                animVB.setAttribute("keyTimes", keyTimes);
                animVB.setAttribute("keySplines", keySplines);
                animVB.setAttribute("values", valuesVB);
                animVB.setAttribute("dur", duration);
                animVB.setAttribute("fill", fill);
                animVB.setAttribute("repeatCount", repeatCount);
                domObj.appendChild(animVB);
                domObj.currentAnimationAnimateViewBox = animVB;
                animVB.beginElement();
            }

            var vp = document.getElementById("viewport_"+[currentObject UID]);
            if (vp)
            {
                var aspectRatio = "xMinYMin",
                    alignment   = "",
                    scaling     = "";

                if ([currentObject isKindOfClass:[RTImageView class]])
                {
                    alignment   = [currentObject imageAlignment];
                    scaling     = [currentObject imageScaling];
                }
                else if ([currentObject isKindOfClass:[RTVideoView class]])
                {
                    alignment   = [currentObject alignment];
                    scaling     = [currentObject scaling];
                }

                switch (alignment)
                {
                    case RTAlignCenter:
                        aspectRatio = "xMidYMid";
                        break;
                    case RTAlignTop:
                        aspectRatio = "xMidYMin";
                        break;
                    case RTAlignTopLeft:
                        aspectRatio = "xMinYMin";
                        break;
                    case RTAlignTopRight:
                        aspectRatio = "xMaxYMin";
                        break;
                    case RTAlignLeft:
                        aspectRatio = "xMinYMid";
                        break;
                    case RTAlignBottom:
                        aspectRatio = "xMidYMax";
                        break;
                    case RTAlignBottomLeft:
                        aspectRatio = "xMinYMax";
                        break;
                    case RTAlignBottomRight:
                        aspectRatio = "xMaxYMax";
                        break;
                    case RTAlignRight:
                        aspectRatio = "xMaxYMid";
                        break;
                }

                if (scaling === RTScaleNone)
                    aspectRatio = " slice";
                else if (scaling === RTScaleToFit)
                    aspectRatio = "none";

                ctx.setAttribute("preserveAspectRatio", aspectRatio);
            }

            break;
        case "alphaValue":
            var ctx     = [[currentObject element] DOMObject],
                tg      = aTarget,
                orig    = [currentObject alphaValue],
                values  = tg;

            if (_autoReverse)
            {
                values = orig + ";" + tg;

                if (_autoRepeat)
                {
                    values = orig + ";" + tg + ";" + orig;
                }
            }
            else
            {
                values = orig + ";" + tg;
            }

            var anim = document.createElementNS(SVG_NS, "animate");
            anim.setAttribute("id", "animate_alphaValue_"+[currentObject UID]);
            anim.setAttribute("attributeName", "opacity");
            anim.setAttribute("attributeType", "XML");
            anim.setAttribute("begin", "indefinite");
            anim.setAttribute("calcMode", calcMode);
            anim.setAttribute("keyTimes", keyTimes);
            anim.setAttribute("keySplines", keySplines);
            anim.setAttribute("values", values);
            anim.setAttribute("dur", duration);
            anim.setAttribute("fill", fill);
            anim.setAttribute("repeatCount", repeatCount);

            ctx.appendChild(anim);
            ctx.currentAnimationAnimateAlphaValue = anim;
            anim.beginElement();

            break;
        case "backgroundColor":
            var ctx     = [[currentObject element] graphicsContext],
                tg      = [aTarget cssString],
                orig    = [[currentObject backgroundColor] cssString],
                values  = tg;

            if (_autoReverse)
            {
                values = orig + ";" + tg;

                if (_autoRepeat)
                {
                    values = orig + ";" + tg + ";" + orig;
                }
            }
            else
            {
                values = orig + ";" + tg;
            }

            var anim = document.createElementNS(SVG_NS, "animateColor");
            anim.setAttribute("id", "animate_backgroundColor_"+[currentObject UID]);
            anim.setAttribute("begin", "indefinite");
            anim.setAttribute("calcMode", calcMode);
            anim.setAttribute("keyTimes", keyTimes);
            anim.setAttribute("keySplines", keySplines);
            anim.setAttribute("attributeName", "fill");
            anim.setAttribute("values", values);
            anim.setAttribute("dur", duration);
            anim.setAttribute("fill", fill);
            anim.setAttribute("repeatCount", repeatCount);
            ctx.appendChild(anim);
            ctx.currentAnimationAnimateBackgroundColor = anim;
            anim.beginElement();

            break;
    }
}

@end
