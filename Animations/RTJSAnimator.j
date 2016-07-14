/*
 * RTJSAnimator.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

requestAnimationFrame = window.requestAnimationFrame        ||
                        window.mozRequestAnimationFrame     ||
                        window.webkitRequestAnimationFrame  ||
                        window.msRequestAnimationFrame;

RTJSAnim = nil;

@implementation RTJSAnimatedGroup : CPObject
{
    id                              _delegate @accessors(property=delegate);
    Function                        _animationBlock;
    Function                        _completionBlock;
    RTViewAnimationOptionCurve      _animationCurve;
    BOOL                            _firstAnimOccured;
    float                           _progress;
    BOOL                            _autoRepeat;
    BOOL                            _autoReverse;
    CPTimeInterval                  _duration;
    CPTimeInterval                  _delay;
    RTViewAnimationOption           _options;
    CPTimeInterval                  _start;
    int                             _direction;
    JSObject                        _easer;
    RTView                          _view;
    CPArray                         _animatedObjects @accessors(getter=animatedObjects);
}

- (id)initWithDuration:(CPTimeInterval)aDuration
                 delay:(CPTimeInterval)aDelay
               options:(RTViewAnimationOption)aOptions
            animations:(block)anAnimationBlock
            completion:(block)aCompletionBlock
{
    self = [super init];
    if (self)
    {
        _animationBlock     = anAnimationBlock;
        _completionBlock    = aCompletionBlock;
        _options            = aOptions;
        _duration           = aDuration;
        _delay              = aDelay;

        _autoRepeat         = aOptions & RTViewAnimationOptionRepeat;
        _autoReverse        = aOptions & RTViewAnimationOptionAutoreverse;

        _animationCurve     =   (aOptions & RTViewAnimationOptionCurveEaseIn)    ||
                                (aOptions & RTViewAnimationOptionCurveEaseOut)   ||
                                (aOptions & RTViewAnimationOptionCurveEaseInOut) ||
                                RTViewAnimationOptionCurveLinear;

        var type = "linear",
            side = "none";

        if (_animationCurve != RTViewAnimationOptionCurveLinear)
        {
            type = "quadratic";
            side = "in";
            if (_animationCurve == RTViewAnimationOptionCurveEaseInOut)
                side = "both";
            else if (_animationCurve == RTViewAnimationOptionCurveEaseOut)
                side = "out";
        }

        _easer = new Easing.Easer({type: type,side: side});

        _start              = Date.now();
        _direction          = RTAnimationDirectionStraight;
        _firstAnimOccured   = NO;
        _animatedObjects    = [CPArray array];
    }
    return self;
}

- (void)processAnimation:(CPTimeInterval)timestamp
{
    var progress = (timestamp - _start) / 1000;
    if (progress <= _duration)
    {
        _progress = _easer.ease(progress, 0.0, 1, _duration);
        _animationBlock(self);
        _firstAnimOccured = YES;
    }
    else
    {
        if (
              _autoRepeat ||
              (!_autoRepeat && _autoReverse && _direction == RTAnimationDirectionStraight)
            )
        {
            if (_autoReverse)
            {
                _direction *= RTAnimationDirectionReverse;

                // Inverted mode so we also revert the easing
                if (_easer.type === 'quadratic')
                {
                    if (_easer.side === 'in')
                        _easer.reset({type:'quadratic', side:'out'});
                    else if (_easer.side === 'out')
                        _easer.reset({type:'quadratic', side:'in'});
                }
            }
            else
                _direction = RTAnimationDirectionStraight;

            _start = Date.now();
        }
        else
        {
            var objectsEnumerator = [_animatedObjects objectEnumerator],
                animObj = nil;

            while (animObj = [objectsEnumerator nextObject])
            {
                [self resetAnimationObject:animObj];
            }

            if ([_delegate respondsToSelector:@selector(removeGroup:)])
                [_delegate removeGroup:self];

            if (_completionBlock && typeof(_completionBlock) === "function")
            {
                _completionBlock(YES);
            }
        }
    }
}

- (void)animateObject:(id)anObject
         withProperty:(CPString)aProp
           toTarget:(id)aTarget
{
    if (!anObject)
        return;

    if (!_firstAnimOccured)
    {
        anObject.currentAnimationShouldAnimate = YES;
        [_animatedObjects addObject:anObject];
    }

    if (!anObject.currentAnimationShouldAnimate)
        return;

    switch (aProp)
    {
        case "frame":
            if (!anObject.currentAnimationTempFrame)
                anObject.currentAnimationTempFrame = CPRectCreateCopy([anObject frame]);

            if (!anObject.currentAnimationTargetFrame)
                anObject.currentAnimationTargetFrame = CPRectCreateCopy(aTarget);

            var val = [anObject frame];

            if (_direction == RTAnimationDirectionStraight)
            {
                val.origin.x    = anObject.currentAnimationTempFrame.origin.x       + (aTarget.origin.x     - anObject.currentAnimationTempFrame.origin.x)      * _progress;
                val.origin.y    = anObject.currentAnimationTempFrame.origin.y       + (aTarget.origin.y     - anObject.currentAnimationTempFrame.origin.y)      * _progress;
                val.size.width  = anObject.currentAnimationTempFrame.size.width     + (aTarget.size.width   - anObject.currentAnimationTempFrame.size.width)    * _progress;
                val.size.height = anObject.currentAnimationTempFrame.size.height    + (aTarget.size.height  - anObject.currentAnimationTempFrame.size.height)   * _progress;
            }
            else
            {
                val.origin.x    = aTarget.origin.x      + (anObject.currentAnimationTempFrame.origin.x      - aTarget.origin.x)     * _progress;
                val.origin.y    = aTarget.origin.y      + (anObject.currentAnimationTempFrame.origin.y      - aTarget.origin.y)     * _progress;
                val.size.width  = aTarget.size.width    + (anObject.currentAnimationTempFrame.size.width    - aTarget.size.width)   * _progress;
                val.size.height = aTarget.size.height   + (anObject.currentAnimationTempFrame.size.height   - aTarget.size.height)  * _progress;
            }

            [anObject setFrame:val];

            break;
        case "frameOrigin":
            if (!anObject.currentAnimationTempOrigin)
                anObject.currentAnimationTempOrigin = CPPointCreateCopy([anObject frameOrigin]);

            if (!anObject.currentAnimationTargetOrigin)
                anObject.currentAnimationTargetOrigin = CPPointCreateCopy(aTarget);

            var val = [anObject frameOrigin];

            if (_direction == RTAnimationDirectionStraight)
            {
                val.x = anObject.currentAnimationTempOrigin.x + (aTarget.x - anObject.currentAnimationTempOrigin.x) * _progress;
                val.y = anObject.currentAnimationTempOrigin.y + (aTarget.y - anObject.currentAnimationTempOrigin.y) * _progress;
            }
            else
            {
                val.x = aTarget.x + (anObject.currentAnimationTempOrigin.x - aTarget.x) * _progress;
                val.y = aTarget.y + (anObject.currentAnimationTempOrigin.y - aTarget.y) * _progress;
            }

            [anObject setFrameOrigin:val];

            break;
        case "frameSize":
            if (!anObject.currentAnimationTempSize)
                anObject.currentAnimationTempSize = CPSizeCreateCopy([anObject frameSize]);

            if (!anObject.currentAnimationTargetSize)
                anObject.currentAnimationTargetSize = CPSizeCreateCopy(aTarget);

            var val = [anObject frameSize];

            if (_direction == RTAnimationDirectionStraight)
            {
                val.width = anObject.currentAnimationTempSize.width + (aTarget.width - anObject.currentAnimationTempSize.width) * _progress;
                val.height = anObject.currentAnimationTempSize.height + (aTarget.height - anObject.currentAnimationTempSize.height) * _progress;
            }
            else
            {
                val.width = aTarget.width + (anObject.currentAnimationTempSize.width - aTarget.width) * _progress;
                val.height = aTarget.height + (anObject.currentAnimationTempSize.height - aTarget.height) * _progress;
            }

            [anObject setFrameSize:val];

            break;
        case "alphaValue":
            if (!anObject.currentAnimationTempAlpha)
                anObject.currentAnimationTempAlpha = [anObject alphaValue];

            if (!anObject.currentAnimationTargetAlpha)
                anObject.currentAnimationTargetAlpha = aTarget;

            var val = [anObject alphaValue];

            if (_direction == RTAnimationDirectionStraight)
            {
                val = anObject.currentAnimationTempAlpha + (aTarget - anObject.currentAnimationTempAlpha) * _progress;
            }
            else
            {
                val = aTarget + (anObject.currentAnimationTempAlpha - aTarget) * _progress;
            }

            [anObject setAlphaValue:val];
            break;
        case "backgroundColor":
            if (!anObject.currentAnimationTempColor)
                anObject.currentAnimationTempColor = [anObject backgroundColor];

            if (!anObject.currentAnimationTargetBackgroundColor)
                anObject.currentAnimationTargetBackgroundColor = aTarget;

            var val = [anObject backgroundColor];

            if (_direction == RTAnimationDirectionStraight)
            {
                var red     = [anObject.currentAnimationTempColor redComponent]     + ([aTarget redComponent]   - [anObject.currentAnimationTempColor redComponent])    * _progress,
                    green   = [anObject.currentAnimationTempColor greenComponent]   + ([aTarget greenComponent] - [anObject.currentAnimationTempColor greenComponent])  * _progress,
                    blue    = [anObject.currentAnimationTempColor blueComponent]    + ([aTarget blueComponent]  - [anObject.currentAnimationTempColor blueComponent])   * _progress,
                    alpha   = [anObject.currentAnimationTempColor alphaComponent]   + ([aTarget alphaComponent] - [anObject.currentAnimationTempColor alphaComponent])  * _progress;
                val         = [CPColor colorWithRed:red green:green blue:blue alpha:alpha];
            }
            else
            {
                var red     = [aTarget redComponent]    + ([anObject.currentAnimationTempColor redComponent]    - [aTarget redComponent])   * _progress,
                    green   = [aTarget greenComponent]  + ([anObject.currentAnimationTempColor greenComponent]  - [aTarget greenComponent]) * _progress,
                    blue    = [aTarget blueComponent]   + ([anObject.currentAnimationTempColor blueComponent]   - [aTarget blueComponent])  * _progress,
                    alpha   = [aTarget alphaComponent]  + ([anObject.currentAnimationTempColor alphaComponent]  - [aTarget alphaComponent]) * _progress;
                val         = [CPColor colorWithRed:red green:green blue:blue alpha:alpha];
            }

            [anObject setBackgroundColor:val];

            break;
    }
}

- (void)resetAnimationObject:(id)animObj
{
    for (var i = 0; i < [_animatedObjects count]; ++i)
    {
        var obj = [_animatedObjects objectAtIndex:i];
        if (obj === animObj)
        {
            obj.currentAnimationShouldAnimate   = NO;
            obj.currentAnimationTempFrame       = nil;
            obj.currentAnimationTempOrigin      = nil;
            obj.currentAnimationTempSize        = nil;
            obj.currentAnimationTempAlpha       = nil;
            obj.currentAnimationTempColor       = nil;

            if (obj.currentAnimationTargetFrame)
            {
                [obj setFrame:obj.currentAnimationTargetFrame];
                obj.currentAnimationTargetFrame = nil;
            }

            if (obj.currentAnimationTargetOrigin)
            {
                [obj setFrameOrigin:obj.currentAnimationTargetOrigin];
                obj.currentAnimationTargetOrigin = nil;
            }

            if (obj.currentAnimationTargetSize)
            {
                [obj setFrameSize:obj.currentAnimationTargetSize];
                obj.currentAnimationTargetSize = nil;
            }

            if (obj.currentAnimationTargetAlpha)
            {
                [obj setAlphaValue:obj.currentAnimationTargetAlpha];
                obj.currentAnimationTargetAlpha = nil;
            }

            if (obj.currentAnimationTargetBackgroundColor)
            {
                [obj setBackgroundColor:obj.currentAnimationTargetBackgroundColor];
                obj.currentAnimationTargetBackgroundColor = nil;
            }
        }
    }
}

@end

@implementation RTJSAnimator : RTAnimator
{
    Function        _refresh;
    CPArray         _animators;
    int             _animationTimerID;
}

+ (RTJSAnimator)sharedAnimator
{
    if (!RTJSAnim)
    {
        RTJSAnim = [[RTJSAnimator alloc] init];
    }

    return RTJSAnim;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _animators = [CPArray array];
    }
    return self;
}

- (void)createAnimatedGroupWithDuration:(CPTimeInterval)aDuration
                                  delay:(CPTimeInterval)aDelay
                                options:(RTViewAnimationOption)aOptions
                             animations:(block)anAnimationBlock
                             completion:(block)aCompletionBlock
{
    var animObj = [[RTJSAnimatedGroup alloc] initWithDuration:aDuration
                                                        delay:aDelay
                                                      options:aOptions
                                                   animations:anAnimationBlock
                                                   completion:aCompletionBlock];
    [animObj setDelegate:self];
    [_animators addObject:animObj];
}

- (void)startAnimation
{
    setTimeout(
        function()
        {
            if (!requestAnimationFrame)
            {
                if (!_animationTimerID)
                {
                    _animationTimerID = objj_setInterval(
                        function()
                        {
                            for (var i = 0; i < [_animators count]; ++i)
                            {
                                var obj = [_animators objectAtIndex:i];
                                [obj processAnimation:Date.now()];
                            }
                        },
                        40);
                }
            }
            else
            {
                if (!_refresh)
                {
                    var running = YES,
                        lastFrame = new Date().getTime();
                    _refresh = function(timestamp)
                    {
                        //if (running !== false)
                        {
                            requestAnimationFrame(_refresh);
                            var deltaT = timestamp - lastFrame;
                            if (deltaT < 160)
                            {
                                running = YES;
                                for (var i = 0; i < [_animators count]; ++i)
                                {
                                    var obj = [_animators objectAtIndex:i];
                                    [obj processAnimation:timestamp];
                                }
                            }
                            lastFrame = timestamp;
                        }
                    }
                    _refresh();
                }
            }
        }, 0);
}

- (void)removeGroup:(RTJSAnimatedGroup)aGroup
{
    [_animators removeObject:aGroup];
}

- (void)resetAnimationObject:(id)animObj
{
    for (var i = 0; i < [_animators count]; ++i)
    {
        var obj = [_animators objectAtIndex:i];
        [obj resetAnimationObject:animObj];

        if (![obj animatedObjects] || [[obj animatedObjects] count] == 0)
        {
            [_animators removeObjectAtIndex:i];
        }
    }

    if ([_animators count] == 0)
    {
        if (_animationTimerID)
        {
            clearInterval(_animationTimerID);
        }
    }
}

@end



//
// Copyright (c) 2008 Paul Duncan (paul@pablotron.org)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

/**
 * Easer: namespace for Easier class and methods.
 * @namespace
 */
Easing = (function () {
  // return namespace
  var E = {};

  // import math functions to speed up ease callbacks
  var abs     = Math.abs,
      asin    = Math.asin,
      cos     = Math.cos,
      pow     = Math.pow,
      sin     = Math.sin,
      sqrt    = Math.sqrt,
      PI      = Math.PI,
      HALF_PI = Math.PI / 2;

  E = {
    /**
     * Version of Easing library.
     * @static
     */
    VERSION: '0.1.0',

    /**
     * Default options for Easer.
     * @static
     */
    DEFAULTS: {
      type: 'linear',
      side: 'none'
    },

    /**
     * Hash of valid types and sides.
     * @static
     */
    VALID: {
      type: {
        linear:     true,
        bounce:     true,
        circular:   true,
        cubic:      true,
        elastic:    true,
        exp:        true,
        quadratic:  true,
        quartic:    true,
        quintic:    true,
        sine:       true
      },

      side: {
        none: true,
        'in': true,
        out:  true,
        both: true
      }
    }
  };

  /**
   * Easing.Easer: Easing class.
   * @class Easing.Easer.
   * @constructor
   *
   * @param {Hash}  o   Hash of options.  Valid keys are "type" and "side".
   *
   * Example:
   *
   *   // create a new quadratic easer
   *   e = new Easing.Easer({
   *     type: 'quadratic',
   *     side: 'both'
   *   });
   *
   */
  E.Easer = function(o) {
    var key;

    // set defaults
    for (key in E.DEFAULTS)
      this[key] = E.DEFAULTS[key];

    this.reset(o);
  };

  /**
   * Reset an Easer with new values.
   *
   * @param {Hash}  o   Hash of options.  Valid keys are "type" and "side".
   *
   * Example:
   *
   *   // reset easer to quintic easing
   *   e = e.reset({
   *     type: 'quintic',
   *     side: 'end'
   *   });
   *
   */
  E.Easer.prototype.reset = function(o) {
    var key, name, type, side, err;
    for (key in o)
      this[key] = o[key];

    // get/check type
    type = (this.side != 'none') ? this.type : 'linear';
    if (!E.VALID.type[type])
      throw new Error("unknown type: " + this.type);

    // get/check side
    side = (type != 'linear') ? this.side : 'none';
    if (!E.VALID.side[side])
      throw new Error("unknown side: " + this.side);

    // build callback name
    name = ['ease', side].join('_');
    this.fn = E[type] && E[type][name];

    // make sure callback exists
    if (!this.fn) {
      err = "type = " + this.type + ", side = " + this.side;
      throw new Error("unknown ease: " + err);
    }
  };

  /**
   * Get the ease for a particular time offset.
   *
   * @param {Number}    time_now     Current time offset (in the range of 0-time_dur).
   * @param {Number}    begin_val    Beginning value.
   * @param {Number}    change_val   End offset value.
   * @param {Number}    time_dur     Duration of time.
   *
   * @returns Eased value.
   * @type Number
   *
   * Example:
   *
   *   // calculate ease at 50 time units for transition from 10 to 300
   *   var x = e.ease(50, 10, 290, 100);
   *
   */
  E.Easer.prototype.ease = function(time_now, begin_val, change_val, time_dur) {
    return this.fn.apply(this, arguments);
  };

  /**
   * linear easing
   * @namespace
   */
  E.linear = {};

  E.linear.ease_none = function(t, b, c, d) {
    return c * t / d + b;
  };

  /**
   * back easing
   * @namespace
   */
  E.back = {};

  var BACK_DEFAULT_S = 1.70158;

  E.back.ease_in = function(t, b, c, d, s) {
    if (s == undefined) s = BACK_DEFAULT_S;
    return c*(t/=d)*t*((s+1)*t - s) + b;
  };

  E.back.ease_out = function(t, b, c, d, s) {
    if (s == undefined) s = BACK_DEFAULT_S;
    return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;
  };

  E.back.ease_both = function(t, b, c, d, s) {
    if (s == undefined) s = BACK_DEFAULT_S;
    if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
    return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
  };

  /**
   * bounce easing
   * @namespace
   */
  E.bounce = {};

  var bounce_ratios = [
    1 / 2.75,
    2 / 2.75,
    2.5 / 2.75
  ];

  var bounce_factors = [
    null,
    1.5 / 2.75,
    2.25 / 2.75,
    2.625 / 2.75
  ];

  E.bounce.ease_out = function(t, b, c, d) {
    if ((t/=d) < (bounce_ratios[0])) {
      return c*(7.5625*t*t) + b;
    } else if (t < (bounce_ratios[1])) {
      return c*(7.5625*(t-=(bounce_factors[1]))*t + .75) + b;
    } else if (t < (bounce_ratios[2])) {
      return c*(7.5625*(t-=(bounce_factors[2]))*t + .9375) + b;
    } else {
      return c*(7.5625*(t-=(bounce_factors[3]))*t + .984375) + b;
    }
  };

  E.bounce.ease_in = function(t, b, c, d) {
    return c - E.bounce.ease_out(d-t, 0, c, d) + b;
  };

  E.bounce.ease_both = function(t, b, c, d) {
    if (t < d/2) return E.bounce.ease_in(t*2, 0, c, d) * .5 + b;
    else return E.bounce.ease_out(t*2-d, 0, c, d) * .5 + c*.5 + b;
  };

  /**
   * circular easing
   * @namespace
   */
  E.circular = {};

  E.circular.ease_in = function(t, b, c, d) {
    return -c * (sqrt(1 - (t/=d)*t) - 1) + b;
  };

  E.circular.ease_out = function(t, b, c, d) {
    return c * sqrt(1 - (t=t/d-1)*t) + b;
  };

  E.circular.ease_both = function(t, b, c, d) {
    if ((t/=d/2) < 1) return -c/2 * (sqrt(1 - t*t) - 1) + b;
    return c/2 * (sqrt(1 - (t-=2)*t) + 1) + b;
  };

  /**
   * cubic easing
   * @namespace
   */
  E.cubic = {};

  E.cubic.ease_in = function(t, b, c, d) {
    return c*(t/=d)*t*t + b;
  };

  E.cubic.ease_out = function(t, b, c, d) {
    return c*((t=t/d-1)*t*t + 1) + b;
  };

  E.cubic.ease_both = function(t, b, c, d) {
    if ((t/=d/2) < 1) return c/2*t*t*t + b;
    return c/2*((t-=2)*t*t + 2) + b;
  };

  /**
   * elastic easing
   * @namespace
   */
  E.elastic = {};

  E.elastic.ease_in = function(t, b, c, d, a, p) {
    if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
    if (!a || a < abs(c)) { a=c; var s=p/4; }
    else var s = p/(2*PI) * asin(c/a);
    return -(a*pow(2,10*(t-=1)) * sin( (t*d-s)*(2*PI)/p )) + b;
  };

  E.elastic.ease_out = function(t, b, c, d, a, p) {
    if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
    if (!a || a < abs(c)) { a=c; var s=p/4; }
    else var s = p/(2*PI) * asin(c/a);
    return (a*pow(2,-10*t) * sin( (t*d-s)*(2*PI)/p ) + c + b);
  };

  E.elastic.ease_both = function(t, b, c, d, a, p) {
    if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
    if (!a || a < abs(c)) { a=c; var s=p/4; }
    else var s = p/(2*PI) * asin (c/a);
    if (t < 1) return -.5*(a*pow(2,10*(t-=1)) * sin( (t*d-s)*(2*PI)/p )) + b;
    return a*pow(2,-10*(t-=1)) * sin( (t*d-s)*(2*PI)/p )*.5 + c + b;
  };

  /**
   * exponential easing
   * @namespace
   */
  E.exp = {};

  E.exp.ease_in = function(t, b, c, d) {
    return (t==0) ? b : c * pow(2, 10 * (t/d - 1)) + b;
  };

  E.exp.ease_out = function(t, b, c, d) {
    return (t==d) ? b+c : c * (-pow(2, -10 * t/d) + 1) + b;
  };

  E.exp.ease_both = function(t, b, c, d) {
    if (t==0) return b;
    if (t==d) return b+c;
    if ((t/=d/2) < 1) return c/2 * pow(2, 10 * (t - 1)) + b;
    return c/2 * (-pow(2, -10 * --t) + 2) + b;
  };

  /**
   * quadratic easing
   */
  E.quadratic = {};

  E.quadratic.ease_in = function(t, b, c, d) {
    return c*(t/=d)*t + b;
  };

  E.quadratic.ease_out = function(t, b, c, d) {
    return -c *(t/=d)*(t-2) + b;
  };

  E.quadratic.ease_both = function(t, b, c, d) {
    if ((t/=d/2) < 1) return c/2*t*t + b;
    return -c/2 * ((--t)*(t-2) - 1) + b;
  };

  /**
   * quartic easing
   * @namespace
   */
  E.quartic = {};

  E.quartic.ease_in = function(t, b, c, d) {
    return c*(t/=d)*t*t*t + b;
  };

  E.quartic.ease_out = function(t, b, c, d) {
    return -c * ((t=t/d-1)*t*t*t - 1) + b;
  };

  E.quartic.ease_both = function(t, b, c, d) {
    if ((t/=d/2) < 1) return c/2*t*t*t*t + b;
    return -c/2 * ((t-=2)*t*t*t - 2) + b;
  };

  /**
   * quintic easing
   * @namespace
   */
  E.quintic = {};

  E.quintic.ease_in = function(t, b, c, d) {
    return c*(t/=d)*t*t*t*t + b;
  };

  E.quintic.ease_out = function(t, b, c, d) {
    return c*((t=t/d-1)*t*t*t*t + 1) + b;
  };

  E.quintic.ease_both = function(t, b, c, d) {
    if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
    return c/2*((t-=2)*t*t*t*t + 2) + b;
  };

  /**
   * sinusoidal easing
   * @namespace
   */
  E.sine = {};

  E.sine.ease_in = function(t, b, c, d) {
    return -c * cos(t/d * (HALF_PI)) + c + b;
  };

  E.sine.ease_out = function(t, b, c, d) {
    return c * sin(t/d * (HALF_PI)) + b;
  };

  E.sine.ease_both = function(t, b, c, d) {
    return -c/2 * (cos(PI*t/d) - 1) + b;
  };

  // return scope
  return E;
})();
