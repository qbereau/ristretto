/*
 * RTCSSAnimator.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

// Note This class animates views using CSS3 animations.
// It's not complete though. There are a couple of problems that need to be taken care of
// 1. If we animate frameSize/frameOrigin, we need to animate 3- and 9-part images also (normally it's redrawn through scripts on setFrame:..)
// 2. Videos need to keep their appropriate aspect ratio
// 3. Background colors should be animated through scripts because we draw the color inside the canvas

var browserPrefix = nil;
/*
if (CPBrowserIs(CPChromeBrowser) || CPBrowserIs(CPSafariBrowser))
{
    browserPrefix = "-webkit-";
}
// Should work normally but it currently doesn't...
else if (CPBrowserIs(CPFirefoxBrowser))
{
    browserPrefix = "-moz-";
}
*/

@implementation RTCSSAnimator : RTAnimator
{
    CPArray         _animatedPropObj;
}

+ (BOOL)canUseAnimator
{
    return browserPrefix !== nil;
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
    var timeOffset = -1;

    _animatedPropObj    = [CPArray array];

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
    var objectsEnumerator = [_animatedPropObj objectEnumerator],
        animObj = nil;

    while (animObj = [objectsEnumerator nextObject])
    {
        var obj     = [animObj objectForKey:@"view"],
            prop    = [animObj objectForKey:@"prop"],
            target  = [animObj objectForKey:@"target"],
            rootEl  = [[obj element] DOMObject];

        switch (prop)
        {
            case "frame":
                [obj setFrame:target];
                break;
            case "frameOrigin":
                [obj setFrameOrigin:target];
                break;
            case "frameSize":
                [obj setFrameSize:target];
                break;
            case "alphaValue":
                [obj setAlphaValue:target];
                break;
            case "backgroundColor":
                [obj setBackgroundColor:target];
                break;
        }

    }

    if (_completionBlock && typeof(_completionBlock) === "function")
    {
        _completionBlock(YES);
    }
}

+ (void)resetAnimationObject:(id)animObj
{
    [[animObj element] DOMObject].style.removeProperty(browserPrefix + "animation-name");
    [[animObj element] DOMObject].style.removeProperty(browserPrefix + "animation-duration");
    [[animObj element] DOMObject].style.removeProperty(browserPrefix + "animation-direction");
    [[animObj element] DOMObject].style.removeProperty(browserPrefix + "animation-iteration-count");
    [[animObj element] DOMObject].style.removeProperty(browserPrefix + "animation-timing-function");
}

- (void)animateObject:(id)anObject
         withProperty:(CPString)aProp
           toTarget:(id)aTarget
{

    var duration    = _duration + "s",
        direction   = "normal",
        repeatCount = "1";

    if (_autoReverse)
    {
        direction   = "alternate";
    }

    if (_autoRepeat)
    {
        repeatCount = "infinite";
    }


    var params = [CPDictionary dictionaryWithObjectsAndKeys:
        duration,       "duration",
        repeatCount,    "repeatCount",
        direction,      "direction",
        aProp,          "prop",
        aTarget,        "target"
        ];

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

- (void)_updatePropsWithView:(RTView)aView params:(CPDictionary)aParams
{
    var duration        = parseInt([aParams objectForKey:@"duration"]),
        repeatCount     = [aParams objectForKey:@"repeatCount"],
        direction       = [aParams objectForKey:@"direction"],
        aProp           = [aParams objectForKey:@"prop"],
        aTarget         = [aParams objectForKey:@"target"],
        currentObject   = aView,
        animCurve       = "linear";

    var dict = [CPDictionary dictionaryWithDictionary:aParams];
    [dict setObject:currentObject forKey:@"view"];
    [_animatedPropObj addObject:dict];

    var addKeyframeRule = function(rule) {
        if (document.styleSheets && document.styleSheets.length)
        {
            // Insert the style into the first attached stylesheet
            document.styleSheets[0].insertRule(rule, 0);
        }
        else
        {
            // No attached stylesheets so append to the DOM
            var style = document.createElement('style');
            style.innerHTML = rule;
            document.head.appendChild(style);
        }
    }

    switch (_animationCurve)
    {
        case RTViewAnimationOptionCurveLinear:
            animCurve = "linear";
            break;
        case RTViewAnimationOptionCurveEaseIn:
            animCurve = "ease-in";
            break;
        case RTViewAnimationOptionCurveEaseOut:
            animCurve = "ease-out";
            break;
        case RTViewAnimationOptionCurveEaseInOut:
            animCurve = "ease-in-out";
            break;
    }

    var stDur        = duration + "s",
        stDir        = direction,
        stIteration  = repeatCount,
        stTiming     = animCurve;

    switch (aProp)
    {
        case "frame":
        case "frameOrigin":
        case "frameSize":

            if (aProp != "frameSize")
            {
                var rootEl  = [[currentObject element] DOMObject],
                    ctx     = [[currentObject element] graphicsContext].canvas,
                    tg      = (aProp === "frameOrigin") ? CGPointMake(aTarget.x, aTarget.y) : CGPointMake(aTarget.origin.x, aTarget.origin.y),
                    orig    = CGPointMake([currentObject frameOrigin].x, [currentObject frameOrigin].y),
                    kfName  = "kf_orig_" + [currentObject UID];

                var keyframes = '@' + browserPrefix + 'keyframes ' + kfName + ' { '+
                    '0% { left:' + orig.x + 'px; top:' + orig.y + 'px; }' +
                    '100% { left:' + tg.x + 'px; top:' + tg.y + 'px; } ' +
                    '}';

                addKeyframeRule(keyframes);

                var stAnimName   = kfName;

                if (rootEl && rootEl.style && rootEl.style[browserPrefix + "animation-name"] && rootEl.style[browserPrefix + "animation-name"].length > 0)
                {
                    stAnimName  = rootEl.style[browserPrefix + "animation-name"] + " " + kfName;
                    stDur       = rootEl.style[browserPrefix + "animation-duration"] + " " + stDur;
                    stDir       = rootEl.style[browserPrefix + "animation-direction"] + " " + stDir;
                    stIteration = rootEl.style[browserPrefix + "animation-iteration-count"] + " " + stIteration;
                    stTiming    = rootEl.style[browserPrefix + "animation-timing-function"] + " " + stTiming;
                }

                rootEl.style[browserPrefix + "animation-name"]            = stAnimName;
                rootEl.style[browserPrefix + "animation-duration"]        = stDur;
                rootEl.style[browserPrefix + "animation-direction"]       = stDir;
                rootEl.style[browserPrefix + "animation-iteration-count"]  = stIteration;
                rootEl.style[browserPrefix + "animation-timing-function"]  = stTiming;

                ctx.style[browserPrefix + "animation-name"]           = stAnimName;
                ctx.style[browserPrefix + "animation-duration"]       = stDur;
                ctx.style[browserPrefix + "animation-direction"]      = stDir;
                ctx.style[browserPrefix + "animation-iteration-count"] = stIteration;
                ctx.style[browserPrefix + "animation-timing-function"] = stTiming;

                var vidEl = document.getElementById("video_"+[currentObject UID]);
                if (vidEl)
                {
                    vidEl.style[browserPrefix + "animation-name"]             = stAnimName;
                    vidEl.style[browserPrefix + "animation-duration"]         = stDur;
                    vidEl.style[browserPrefix + "animation-direction"]        = stDir;
                    vidEl.style[browserPrefix + "animation-iteration-count"]   = stIteration;
                    vidEl.style[browserPrefix + "animation-timing-function"]   = stTiming;
                }

            }

            if (aProp != "frameOrigin")
            {
                var rootEl  = [[currentObject element] DOMObject],
                    ctx     = [[currentObject element] graphicsContext].canvas,
                    tg      = (aProp === "frameSize") ? CGSizeMake(aTarget.width, aTarget.height) : CGSizeMake(aTarget.size.width, aTarget.size.height),
                    orig    = CGSizeMake([currentObject frameSize].width, [currentObject frameSize].height),
                    kfName  = "kf_size_" + [currentObject UID];

                var keyframes = '@' + browserPrefix + 'keyframes ' + kfName + ' { '+
                    '0% { width:' + orig.width + 'px; height:' + orig.height + 'px; } ' +
                    '100% { width:' + tg.width + 'px; height:' + tg.height + 'px; } ' +
                    '}';

                addKeyframeRule(keyframes);

                rootEl.style[browserPrefix + "animation-name"]            = (rootEl && rootEl.style && rootEl.style[browserPrefix + "animation-name"] && rootEl.style[browserPrefix + "animation-name"].length > 0) ? [CPString stringWithFormat:@"%@, %@", rootEl.style[browserPrefix + "animation-name"], kfName] : kfName;
                rootEl.style[browserPrefix + "animation-duration"]        = duration;
                rootEl.style[browserPrefix + "animation-direction"]       = direction;
                rootEl.style[browserPrefix + "animation-iteration-count"]  = repeatCount;
                rootEl.style[browserPrefix + "animation-timing-function"]  = animCurve;

                ctx.style[browserPrefix + "animation-name"]           = (ctx && ctx.style && ctx.style[browserPrefix + "animation-name"] && ctx.style[browserPrefix + "animation-name"].length > 0) ? [CPString stringWithFormat:@"%@, %@", ctx.style[browserPrefix + "animation-name"], kfName] : kfName;
                ctx.style[browserPrefix + "animation-duration"]       = duration;
                ctx.style[browserPrefix + "animation-direction"]      = direction;
                ctx.style[browserPrefix + "animation-iteration-count"] = repeatCount;
                ctx.style[browserPrefix + "animation-timing-function"] = animCurve;

                var vidEl = document.getElementById("video_"+[currentObject UID]);
                if (vidEl)
                {
                    vidEl.style[browserPrefix + "animation-name"]             = (vidEl && vidEl.style && vidEl.style[browserPrefix + "animation-name"] && vidEl.style[browserPrefix + "animation-name"].length > 0) ? [CPString stringWithFormat:@"%@, %@", vidEl.style[browserPrefix + "animation-name"], kfName] : kfName;
                    vidEl.style[browserPrefix + "animation-duration"]         = duration;
                    vidEl.style[browserPrefix + "animation-direction"]        = direction;
                    vidEl.style[browserPrefix + "animation-iteration-count"]   = repeatCount;
                    vidEl.style[browserPrefix + "animation-timing-function"]   = animCurve;
                }
            }

            break;
        case "alphaValue":
            var rootEl  = [[currentObject element] DOMObject],
                tg      = aTarget,
                orig    = [currentObject alphaValue],
                kfName  = "kf_alpha_" + [currentObject UID];


            var keyframes = '@' + browserPrefix + 'keyframes ' + kfName + ' { '+
                '0% { opacity:' + orig + '; }' +
                '100% { opacity:' + tg + '; } ' +
                '}';

            addKeyframeRule(keyframes);

            var stAnimName   = kfName;

            if (rootEl && rootEl.style && rootEl.style[browserPrefix + "animation-name"] && rootEl.style[browserPrefix + "animation-name"].length > 0)
            {
                stAnimName  = rootEl.style[browserPrefix + "animation-name"] + " " + kfName;
                stDur       = rootEl.style[browserPrefix + "animation-duration"] + " " + stDur;
                stDir       = rootEl.style[browserPrefix + "animation-direction"] + " " + stDir;
                stIteration = rootEl.style[browserPrefix + "animation-iteration-count"] + " " + stIteration;
                stTiming    = rootEl.style[browserPrefix + "animation-timing-function"] + " " + stTiming;
            }

            rootEl.style[browserPrefix + "animation-name"]           = stAnimName;
            rootEl.style[browserPrefix + "animation-duration"]       = stDur;
            rootEl.style[browserPrefix + "animation-direction"]      = stDir;
            rootEl.style[browserPrefix + "animation-iteration-count"] = stIteration;
            rootEl.style[browserPrefix + "animation-timing-function"] = stTiming;

            break;
        case "backgroundColor":
            // Would need to animate through scripts...
            break;
    }
}

@end
