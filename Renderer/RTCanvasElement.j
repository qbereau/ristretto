/*
 * RTCanvasElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

// To hack around FF bug which trhows load image while it's not
// usable for canvas drawing... Stupid bug!
var LOAD_IMAGE_DELAY = CPBrowserIs(CPFirefoxBrowser) ? 500 : 0;

@implementation RTCanvasElement : RTElement
{
    DOMObject       _canvas;

    Image           _imgBg;

    Image           _imgLeftSliceHori;
    Image           _imgMiddleSliceHori;
    Image           _imgRightSliceHori;

    Image           _imgTopSliceVert;
    Image           _imgMiddleSliceVert;
    Image           _imgBottomSliceVert;

    Image           _imgTopLeft;
    Image           _imgTopMiddle;
    Image           _imgTopRight;
    Image           _imgMiddleLeft;
    Image           _imgMiddleMiddle;
    Image           _imgMiddleRight;
    Image           _imgBottomLeft;
    Image           _imgBottomMiddle;
    Image           _imgBottomRight;
}

- (id)initWithView:(RTView)aView
{
    if (self = [super _initWithView:aView])
    {
        _domObject                  = document.createElement('div');
        _domObject.style.overflow   = "hidden";
        _domObject.style.position   = "absolute";
        _domObject.visibility       = "visible";
        _domObject.zIndex           = 0;

        _canvas = document.createElement('canvas');
        _domObject.appendChild(_canvas);
    }
    return self;
}

- (DOMObject)graphicsContext
{
    return _canvas.getContext("2d");
}

- (void)moveTo:(CGPoint)aPoint
{
    _domObject.style.left   = aPoint.x + "px";
    _domObject.style.top    = aPoint.y + "px";

    // Had to do this otherwise animation movements doesn't work on Webkit
    // This has absolutely not any sense!!!!!!!!!
    if (CPFeatureIsCompatible(CPWebKitBrowserEngine))
        _domObject.style.webkitTransform = "translate(0px, 0px)";
}

- (void)moveLocallyTo:(CGPoint)aPoint
{
    _localPos = CGPointMakeCopy(aPoint);
    [self renderRect:nil];
}

- (void)resizeTo:(CGSize)aSize
{
    _domObject.style.width  = aSize.width + "px";
    _domObject.style.height = aSize.height + "px";

    _canvas.width           = aSize.width;
    _canvas.height          = aSize.height;

    [self renderRect:nil];
}

- (void)resizeLocallyTo:(CGSize)aSize
{
    _localSize = CGSizeMakeCopy(aSize);
    [self renderRect:nil];
}

- (void)rotateLocallyTo:(float)anAngle
{
    _angleRotation = anAngle;
    [self renderRect:nil];
}

- (void)hide:(BOOL)isHidden
{
    _domObject.style.display = isHidden ? "none" : "block";
}

- (void)clip:(BOOL)shouldClip
{
    _domObject.style.overflow = shouldClip ? "hidden" : "visible";
}

- (void)setOpacity:(float)aOpacity
{
    _domObject.style.opacity = aOpacity;

    [CPTimer scheduledTimerWithTimeInterval:0.01
                                     target:self
                                   selector:@selector(update)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)update
{
    [self moveTo:[_view frameOrigin]];
    [self resizeTo:[_view frameSize]];
    [self renderRect:nil];
}

- (void)renderRect:(CGRect)aRect
{
    var alpha   = [_view alphaValue],
        x       = aRect ? aRect.origin.x : 0,
        y       = aRect ? aRect.origin.y : 0,
        w       = aRect ? aRect.size.width : [_view frameSize].width,
        h       = aRect ? aRect.size.height : [_view frameSize].height,
        patternImage            = [[_view backgroundColor] patternImage],
        colorExists             = [_view backgroundColor] && ([[_view backgroundColor] patternImage] || [[_view backgroundColor] alphaComponent] > 0.0),
        colorHasAlpha           = colorExists && [[_view backgroundColor] alphaComponent] < 1.0,
        supportsRGBA            = CPFeatureIsCompatible(CPCSSRGBAFeature),
        colorNeedsDOMElement    = colorHasAlpha && !supportsRGBA;

    if ([patternImage isThreePartImage])
    {
        bgType = [patternImage isVertical] ? BackgroundVerticalThreePartImage : BackgroundHorizontalThreePartImage;
    }
    else if ([patternImage isNinePartImage])
    {
        bgType = BackgroundNinePartImage;
    }
    else if (patternImage)
    {
        bgType = BackgroundImage;
    }
    else
    {
        bgType = colorNeedsDOMElement ? BackgroundTransparentColor : BackgroundTrivialColor;
    }

    var ctx = _canvas.getContext("2d");
    ctx.clearRect(x, y, w, h);

    if (bgType == BackgroundTransparentColor || bgType == BackgroundTrivialColor)
    {
        var bgColor = [_view backgroundColor];
        if (!bgColor)
            return;

        var red     = ROUND([bgColor redComponent] * 255.0),
            green   = ROUND([bgColor greenComponent] * 255.0),
            blue    = ROUND([bgColor blueComponent] * 255.0);

        ctx.fillStyle = [CPString stringWithFormat:@"rgba(%d, %d, %d, %d)", red, green, blue, [bgColor alphaComponent]];
        ctx.fillRect(x, y, w, h);
    }
    else if (bgType == BackgroundImage)
    {
        if (!_imgBg || _imgBg.src != [patternImage filename])
        {
            _imgBg = new Image();
            _imgBg.onload = function()
            {
                setTimeout(
                    function()
                    {
                        var pattern = ctx.createPattern(_imgBg, "repeat");
                        ctx.fillStyle = pattern;
                        ctx.fillRect(0, 0, [_view frameSize].width, [_view frameSize].height);
                    }, LOAD_IMAGE_DELAY);
            };
            _imgBg.src = [patternImage filename];
        }
        else
        {
            setTimeout(
                function()
                {
                    var pattern = ctx.createPattern(_imgBg, "repeat");
                    ctx.fillStyle = pattern;
                    ctx.fillRect(0, 0, [_view frameSize].width, [_view frameSize].height);
                }, LOAD_IMAGE_DELAY);
        }
    }
    else if (bgType == BackgroundHorizontalThreePartImage)
    {
        var leftSliceHori   = [patternImage imageSlices][0],
            middleSliceHori = [patternImage imageSlices][1],
            rightSliceHori  = [patternImage imageSlices][2];

        if (!_imgLeftSliceHori || _imgLeftSliceHori.src != [leftSliceHori filename])
        {
            _imgLeftSliceHori = new Image();
            _imgLeftSliceHori.onload = function() {
                if (![[[_view backgroundColor] patternImage] isVertical])
                {
                    ctx.drawImage(_imgLeftSliceHori, 0, 0);
                }
            };
            _imgLeftSliceHori.src = [leftSliceHori filename];
        }
        else
        {
            ctx.drawImage(_imgLeftSliceHori, 0, 0);
        }

        if (!_imgMiddleSliceHori || _imgMiddleSliceHori.src != [middleSliceHori filename])
        {
            _imgMiddleSliceHori = new Image();
            _imgMiddleSliceHori.onload = function() {
                if (![[[_view backgroundColor] patternImage] isVertical])
                {
                    setTimeout(
                        function()
                        {
                            var pattern = ctx.createPattern(_imgMiddleSliceHori, "repeat");
                            ctx.fillStyle = pattern;
                            ctx.fillRect([leftSliceHori size].width, 0, [_view frameSize].width - [rightSliceHori size].width - [leftSliceHori size].width, [middleSliceHori size].height);
                        }, LOAD_IMAGE_DELAY);
                }
            };
            _imgMiddleSliceHori.src = [middleSliceHori filename];
        }
        else
        {
            setTimeout(
                function()
                {
                    var pattern = ctx.createPattern(_imgMiddleSliceHori, "repeat");
                    ctx.fillStyle = pattern;
                    ctx.fillRect([leftSliceHori size].width, 0, [_view frameSize].width - [rightSliceHori size].width - [leftSliceHori size].width, [middleSliceHori size].height);
                }, LOAD_IMAGE_DELAY);
        }

        if (!_imgRightSliceHori || _imgRightSliceHori.src != [rightSliceHori filename])
        {
            _imgRightSliceHori = new Image();
            _imgRightSliceHori.onload = function() {
                if (![[[_view backgroundColor] patternImage] isVertical])
                    ctx.drawImage(_imgRightSliceHori, [_view frameSize].width - [rightSliceHori size].width, 0);
            };
            _imgRightSliceHori.src = [rightSliceHori filename];
        }
        else
        {
            ctx.drawImage(_imgRightSliceHori, [_view frameSize].width - [rightSliceHori size].width, 0);
        }
    }
    else if (bgType == BackgroundVerticalThreePartImage)
    {
        var topSliceVert    = [patternImage imageSlices][0],
            middleSliceVert = [patternImage imageSlices][1],
            bottomSliceVert = [patternImage imageSlices][2];

        if (!_imgTopSliceVert || _imgTopSliceVert.src != [topSliceVert filename])
        {
            _imgTopSliceVert = new Image();
            _imgTopSliceVert.onload = function() {
                if ([[[_view backgroundColor] patternImage] isVertical])
                    ctx.drawImage(_imgTopSliceVert, 0, 0);
            };
            _imgTopSliceVert.src = [topSliceVert filename];
        }
        else
        {
            ctx.drawImage(_imgTopSliceVert, 0, 0);
        }


        if (!_imgMiddleSliceVert || _imgMiddleSliceVert.src != [middleSliceVert filename])
        {
            _imgMiddleSliceVert = new Image();
            _imgMiddleSliceVert.onload = function()
            {
                if ([[[_view backgroundColor] patternImage] isVertical])
                {
                    setTimeout(
                        function()
                        {
                            var pattern = ctx.createPattern(_imgMiddleSliceVert, "repeat");
                            ctx.fillStyle = pattern;
                            ctx.fillRect(0, [topSliceVert size].height, [middleSliceVert size].width, [_view frameSize].height - [bottomSliceVert size].height - [topSliceVert size].height);
                        }, LOAD_IMAGE_DELAY);
                }
            };
            _imgMiddleSliceVert.src = [middleSliceVert filename];
        }
        else
        {
            setTimeout(
                function()
                {
                    var pattern = ctx.createPattern(_imgMiddleSliceVert, "repeat");
                    ctx.fillStyle = pattern;
                    ctx.fillRect(0, [topSliceVert size].height, [middleSliceVert size].width, [_view frameSize].height - [bottomSliceVert size].height - [topSliceVert size].height);
                }, LOAD_IMAGE_DELAY);
        }


        if (!_imgBottomSliceVert || _imgBottomSliceVert.src != [bottomSliceVert filename])
        {
            _imgBottomSliceVert = new Image();
            _imgBottomSliceVert.onload = function() {
                if ([[[_view backgroundColor] patternImage] isVertical])
                    ctx.drawImage(_imgBottomSliceVert, 0, [_view frameSize].height - [bottomSliceVert size].height);
            };
            _imgBottomSliceVert.src = [bottomSliceVert filename];
        }
        else
        {
            ctx.drawImage(_imgBottomSliceVert, 0, [_view frameSize].height - [bottomSliceVert size].height);
        }
    }
    else if (bgType == BackgroundNinePartImage)
    {
        var topLeft         = [patternImage imageSlices][0],
            topMiddle       = [patternImage imageSlices][1],
            topRight        = [patternImage imageSlices][2],
            middleLeft      = [patternImage imageSlices][3],
            middleMiddle    = [patternImage imageSlices][4],
            middleRight     = [patternImage imageSlices][5],
            bottomLeft      = [patternImage imageSlices][6],
            bottomMiddle    = [patternImage imageSlices][7],
            bottomRight     = [patternImage imageSlices][8];

        // TOP
        if (!_imgTopLeft || _imgTopLeft.src != [topLeft filename])
        {
            _imgTopLeft = new Image();
            _imgTopLeft.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                    ctx.drawImage(_imgTopLeft, 0, 0);
            };
            _imgTopLeft.src = [topLeft filename];
        }
        else
        {
            ctx.drawImage(_imgTopLeft, 0, 0);
        }


        if (!_imgTopMiddle || _imgTopMiddle.src != [topMiddle filename])
        {
            _imgTopMiddle = new Image();
            _imgTopMiddle.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                    ctx.drawImage(_imgTopMiddle, [topLeft size].width, 0, [_view frameSize].width - [topLeft size].width - [topRight size].width, [topMiddle size].height);
            };
            _imgTopMiddle.src = [topMiddle filename];
        }
        else
        {
            ctx.drawImage(_imgTopMiddle, [topLeft size].width, 0, [_view frameSize].width - [topLeft size].width - [topRight size].width, [topMiddle size].height);
        }


        if (!_imgTopRight || _imgTopRight.src != [topRight filename])
        {
            _imgTopRight = new Image();
            _imgTopRight.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                    ctx.drawImage(_imgTopRight, [_view frameSize].width - [topRight size].width, 0);
            };
            _imgTopRight.src = [topRight filename];
        }
        else
        {
            ctx.drawImage(_imgTopRight, [_view frameSize].width - [topRight size].width, 0);
        }


        // MIDDLE
        if (!_imgMiddleLeft || _imgMiddleLeft.src != [middleLeft filename])
        {
            _imgMiddleLeft = new Image();
            _imgMiddleLeft.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                    ctx.drawImage(_imgMiddleLeft, 0, [topLeft size].height, [middleLeft size].width, [_view frameSize].height - [topLeft size].height - [bottomLeft size].height);
            };
            _imgMiddleLeft.src = [middleLeft filename];
        }
        else
        {
            ctx.drawImage(_imgMiddleLeft, 0, [topLeft size].height, [middleLeft size].width, [_view frameSize].height - [topLeft size].height - [bottomLeft size].height);
        }


        if (!_imgMiddleMiddle || _imgMiddleMiddle.src != [middleMiddle filename])
        {
            _imgMiddleMiddle = new Image();
            _imgMiddleMiddle.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                {
                    setTimeout(
                        function()
                        {
                            var pattern = ctx.createPattern(_imgMiddleMiddle, "repeat");
                            ctx.fillStyle = pattern;
                            ctx.fillRect([middleLeft size].width, [topMiddle size].height, [_view frameSize].width - [middleLeft size].width - [middleRight size].width, [_view frameSize].height - [topMiddle size].height - [bottomMiddle size].height);
                        }, LOAD_IMAGE_DELAY);
                }
            };
            _imgMiddleMiddle.src = [middleMiddle filename];
        }
        else
        {
            setTimeout(
                function()
                {
                    var pattern = ctx.createPattern(_imgMiddleMiddle, "repeat");
                    ctx.fillStyle = pattern;
                    ctx.fillRect([middleLeft size].width, [topMiddle size].height, [_view frameSize].width - [middleLeft size].width - [middleRight size].width, [_view frameSize].height - [topMiddle size].height - [bottomMiddle size].height);
                }, LOAD_IMAGE_DELAY);
        }


        if (!_imgMiddleRight || _imgMiddleRight.src != [middleRight filename])
        {
            _imgMiddleRight = new Image();
            _imgMiddleRight.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                    ctx.drawImage(_imgMiddleRight, [_view frameSize].width - [middleRight size].width, [topRight size].height, [middleRight size].width, [_view frameSize].height - [topRight size].height - [bottomRight size].height);
            };
            _imgMiddleRight.src = [middleRight filename];
        }
        else
        {
            ctx.drawImage(_imgMiddleRight, [_view frameSize].width - [middleRight size].width, [topRight size].height, [middleRight size].width, [_view frameSize].height - [topRight size].height - [bottomRight size].height);
        }


        // BOTTOM
        if (!_imgBottomLeft || _imgBottomLeft.src != [bottomLeft filename])
        {
            _imgBottomLeft = new Image();
            _imgBottomLeft.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                    ctx.drawImage(_imgBottomLeft, 0, [_view frameSize].height - [bottomLeft size].height);
            };
            _imgBottomLeft.src = [bottomLeft filename];
        }
        else
        {
            ctx.drawImage(_imgBottomLeft, 0, [_view frameSize].height - [bottomLeft size].height);
        }


        if (!_imgBottomMiddle || _imgBottomMiddle.src != [bottomMiddle filename])
        {
            _imgBottomMiddle = new Image();
            _imgBottomMiddle.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                    ctx.drawImage(_imgBottomMiddle, [bottomLeft size].width, [_view frameSize].height - [bottomMiddle size].height, [_view frameSize].width - [bottomLeft size].width - [bottomRight size].width, [bottomMiddle size].height);
            };
            _imgBottomMiddle.src = [bottomMiddle filename];
        }
        else
        {
            ctx.drawImage(_imgBottomMiddle, [bottomLeft size].width, [_view frameSize].height - [bottomMiddle size].height, [_view frameSize].width - [bottomLeft size].width - [bottomRight size].width, [bottomMiddle size].height);
        }


        if (!_imgBottomRight || _imgBottomRight.src != [bottomRight filename])
        {
            _imgBottomRight = new Image();
            _imgBottomRight.onload = function() {
                if ([[[_view backgroundColor] patternImage] isNinePartImage])
                    ctx.drawImage(_imgBottomRight, [_view frameSize].width - [bottomRight size].width, [_view frameSize].height - [bottomRight size].height);
            };
            _imgBottomRight.src = [bottomRight filename];
        }
        else
        {
            ctx.drawImage(_imgBottomRight, [_view frameSize].width - [bottomRight size].width, [_view frameSize].height - [bottomRight size].height);
        }
    }
}

@end
