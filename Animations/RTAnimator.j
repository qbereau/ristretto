/*
 * RTAnimator.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@import <Foundation/CPObject.j>

@implementation RTAnimator : CPObject
{
    id                              _delegate;

    BOOL                            _autoRepeat;
    BOOL                            _autoReverse;

    RTView                          _view;

    CPTimeInterval                  _duration;
    CPTimeInterval                  _delay;
    RTViewAnimationOption           _options;
    JSFunction                      _animationBlock;
    JSFunction                      _completionBlock;
    RTViewAnimationOptionCurve      _animationCurve;

    CPTimeInterval                  _start;
    int                             _direction;
}

+ (id)animatorWithDuration:(CPTimeInterval)aDuration
                     delay:(CPTimeInterval)aDelay
                   options:(RTViewAnimationOption)aOptions
                animations:(block)anAnimationBlock
                completion:(block)aCompletionBlock
{
    return [[RTAnimator alloc] initWithDuration:aDuration
                                          delay:aDelay
                                        options:aOptions
                                     animations:anAnimationBlock
                                     completion:aCompletionBlock];
}

- (id)initWithDuration:(CPTimeInterval)aDuration
                 delay:(CPTimeInterval)aDelay
               options:(RTViewAnimationOption)aOptions
            animations:(block)anAnimationBlock
            completion:(block)aCompletionBlock
{
    if ([[RTRenderer sharedRenderer] supportsSMILAnimations])
    {
        return [[RTSMILAnimator alloc] initWithDuration:aDuration
                                                  delay:aDelay
                                                options:aOptions
                                             animations:anAnimationBlock
                                             completion:aCompletionBlock];
    }
    else if ([RTCSSAnimator canUseAnimator])
    {
        return [[RTCSSAnimator alloc] initWithDuration:aDuration
                                                delay:aDelay
                                              options:aOptions
                                           animations:anAnimationBlock
                                           completion:aCompletionBlock];
    }
    else
    {
        [[RTJSAnimator sharedAnimator] createAnimatedGroupWithDuration:aDuration
                                                                 delay:aDelay
                                                               options:aOptions
                                                            animations:anAnimationBlock
                                                            completion:aCompletionBlock];
        return [RTJSAnimator sharedAnimator];
    }
}

- (id)_initWithDuration:(CPTimeInterval)aDuration
                  delay:(CPTimeInterval)aDelay
                options:(RTViewAnimationOption)aOptions
             animations:(block)anAnimationBlock
             completion:(block)aCompletionBlock
{
    if (self = [super init])
    {
        _duration           = aDuration;
        _delay              = aDelay;
        _options            = aOptions;
        _animationBlock     = anAnimationBlock;
        _completionBlock    = aCompletionBlock;

        _autoRepeat     = aOptions & RTViewAnimationOptionRepeat;
        _autoReverse    = aOptions & RTViewAnimationOptionAutoreverse;

        _animationCurve =   (aOptions & RTViewAnimationOptionCurveEaseIn)    ||
                            (aOptions & RTViewAnimationOptionCurveEaseOut)   ||
                            (aOptions & RTViewAnimationOptionCurveEaseInOut) ||
                            RTViewAnimationOptionCurveLinear;

    }
    return self;
}

+ (void)resetAnimationObject:(id)animObject
{
    if ([[RTRenderer sharedRenderer] supportsSMILAnimations])
    {
        [RTSMILAnimator resetAnimationObject:animObject];
    }
    else if ([RTCSSAnimator canUseAnimator])
    {
        [RTCSSAnimator resetAnimationObject:animObject];
    }
    else
    {
        [[RTJSAnimator sharedAnimator] resetAnimationObject:animObject];
    }
}

- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (void)startAnimation
{

}

// Used by CSS & SMIL Animator
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

@end
