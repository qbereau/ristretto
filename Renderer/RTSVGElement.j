/*
 * RTSVGElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTSVGElement : RTElement
{
    DOMObject       _cp;
    DOMObject       _clipRect;

    DOMObject       _contentNode;

    // Background Images
    DOMObject       _bgvp;
    DOMObject       _bgImgPattern;
    DOMObject       _bgImg;

    // 3-Parts
    DOMObject       _bgImg0;
    DOMObject       _bgImg1;
    DOMObject       _bgImg2;

    // 9-Parts
    DOMObject       _bgImgTL;
    DOMObject       _bgImgTM;
    DOMObject       _bgImgTR;
    DOMObject       _bgImgML;
    DOMObject       _bgImgMM;
    DOMObject       _bgImgMR;
    DOMObject       _bgImgBL;
    DOMObject       _bgImgBM;
    DOMObject       _bgImgBR;
}

- (id)initWithView:(RTView)aView
{
    if (self = [super _initWithView:aView])
    {
        _domObject = document.createElementNS(SVG_NS, 'g');
        _domObject.setAttribute("id", "g_"+[_view UID]);

        _cp = document.createElementNS(SVG_NS, "clipPath");
        _cp.setAttribute("id", "cp_"+[_view UID]);
        _domObject.appendChild(_cp);

        _clipRect = document.createElementNS(SVG_NS, "rect");
        _clipRect.setAttribute("id", "cpr_"+[_view UID]);
        _cp.appendChild(_clipRect);

        _contentNode = document.createElementNS(SVG_NS, "rect");
        _contentNode.setAttribute("id", "content_"+[_view UID]);
        _domObject.appendChild(_contentNode);
    }
    return self;
}

- (DOMObject)graphicsContext
{
    return _contentNode;
}

- (void)moveTo:(CGPoint)aPoint
{
    _domObject.setAttribute("transform", [CPString stringWithFormat:"translate(%d, %d)", aPoint.x, aPoint.y]);
}

- (void)resizeTo:(CGSize)aSize
{
    _domObject.setAttribute("viewBox", "0 0 " + aSize.width + " " + aSize.height);

    _clipRect.setAttribute("width", aSize.width);
    _clipRect.setAttribute("height", aSize.height);

    _contentNode.setAttribute("width", aSize.width);
    _contentNode.setAttribute("height", aSize.height);
}

- (void)hide:(BOOL)isHidden
{
    _domObject.setAttribute("visibility", isHidden ? "hidden" : "visible");
}

- (void)clip:(BOOL)shouldClip
{

}

- (void)setOpacity:(float)aOpacity
{
    _domObject.setAttribute("opacity", aOpacity);
}

- (void)_updateContentNode
{
    _clipRect.setAttribute("width", [_view frameSize].width);
    _clipRect.setAttribute("height", [_view frameSize].height);

    _contentNode.setAttribute("x", 0);
    _contentNode.setAttribute("y", 0);
    _contentNode.setAttribute("width", [_view frameSize].width);
    _contentNode.setAttribute("height", [_view frameSize].height);

    var patternImage            = [[_view backgroundColor] patternImage],
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


    if (bgType == BackgroundTransparentColor || bgType == BackgroundTrivialColor)
    {
        if (![_view backgroundColor] || [[_view backgroundColor] alphaComponent] == 0)
            _contentNode.setAttribute("style", "fill-opacity: 0");
        else
        {
            _contentNode.setAttribute("style", "fill-opacity: 1");
            _contentNode.setAttribute("style", "fill: " + [[_view backgroundColor] cssString]);
        }

        if (_bgvp && _domObject)
        {
            _domObject.removeChild(_bgvp);
            _bgvp = nil;
        }
    }
    else if (bgType == BackgroundImage)
    {
        if (![[RTRenderer sharedRenderer] isTiny])
        {
            // SVG supports Patterns
            if (!_bgImgPattern)
            {
                _bgImgPattern = document.createElementNS(SVG_NS, "pattern");
                _bgImgPattern.setAttribute("id", "bg_img_pattern_"+[_view UID]);
                _bgImgPattern.setAttribute("width", [patternImage size].width);
                _bgImgPattern.setAttribute("height", [patternImage size].height);
                _bgImgPattern.setAttribute("patternUnits", "userSpaceOnUse");
                _domObject.appendChild(_bgImgPattern);

                if (!_bgImg)
                {
                    _bgImg = document.createElementNS(SVG_NS, "image");
                    _bgImg.setAttribute("id", "bg_img_"+[_view UID]);
                    _bgImgPattern.appendChild(_bgImg);
                }
            }

            _bgImg.setAttributeNS(XLINK, "href", [patternImage filename]);
            _bgImg.setAttribute("x", x);
            _bgImg.setAttribute("y", y);
            _bgImg.setAttribute("width", [patternImage size].width);
            _bgImg.setAttribute("height", [patternImage size].height);

            _contentNode.setAttribute("fill", "url(#" + "bg_img_pattern_"+[_view UID] + ")");
        }
        else
        {
            // But not SVG Tiny :(
            if ([patternImage size].width >= [_view frameSize].width &&
                [patternImage size].height >= [_view frameSize].height)
            {
                // No need to repeat the image
                var elID = "bg_img_"+[_view UID],
                    img = document.getElementById(elID) || document.createElementNS(SVG_NS, "image");
                img.setAttribute("id", elID);
                img.setAttributeNS(XLINK, "href", [patternImage filename]);
                img.setAttribute("preserveAspectRatio", "xMinYMin");
                img.setAttribute("x", 0);
                img.setAttribute("y", 0);
                img.setAttribute("width", [patternImage size].width);
                img.setAttribute("height", [patternImage size].height);
                _domObject.appendChild(img);
            }
            else
            {
                var repeatHeight = function(x)
                {
                    if ([patternImage size].height <= [_view frameSize].height)
                    {
                        var end = Math.floor([_view frameSize].height / [patternImage size].height),
                            h   = Math.abs([_view frameSize].height - [patternImage size].height);

                        for (var i = 0; i < end; ++i)
                        {
                            var y       = [patternImage size].height * i,
                                elID    = "bg_img_x_" + x + "_y_" + i + "_"+[_view UID],
                                img = document.getElementById(elID) || document.createElementNS(SVG_NS, "image");
                            img.setAttribute("id", elID);
                            img.setAttributeNS(XLINK, "href", [patternImage filename]);
                            img.setAttribute("preserveAspectRatio", "none");
                            img.setAttribute("x", x);
                            img.setAttribute("y", y);
                            img.setAttribute("width", [patternImage size].width);
                            img.setAttribute("height", [patternImage size].height);
                            _domObject.appendChild(img);
                        }

                        var elID = "bg_img_x_" + x + "_y_" + end + "_"+[_view UID],
                            img = document.getElementById(elID) || document.createElementNS(SVG_NS, "image");
                        img = document.createElementNS(SVG_NS, "image");
                        img.setAttribute("id", elID);
                        img.setAttributeNS(XLINK, "href", [patternImage filename]);
                        img.setAttribute("preserveAspectRatio", "none");
                        img.setAttribute("x", x);
                        img.setAttribute("y", [patternImage size].height * end);
                        img.setAttribute("width", [patternImage size].width);
                        img.setAttribute("height", h);
                        _domObject.appendChild(img);
                    }
                }

                if ([patternImage size].width <= [_view frameSize].width)
                {
                    var end = Math.floor([_view frameSize].width / [patternImage size].width),
                        w   = Math.abs([_view frameSize].width - [patternImage size].width);

                    for (var i = 0; i < end; ++i)
                    {
                        var x = [patternImage size].width * i,
                            elID = "bg_img_x_" + i + "_y_" + 0 + "_" +[_view UID],
                            img = document.getElementById(elID) || document.createElementNS(SVG_NS, "image");
                        img = document.createElementNS(SVG_NS, "image");
                        img.setAttribute("id", elID);
                        img.setAttributeNS(XLINK, "href", [patternImage filename]);
                        img.setAttribute("preserveAspectRatio", "none");
                        img.setAttribute("x", x);
                        img.setAttribute("y", 0);
                        img.setAttribute("width", [patternImage size].width);
                        img.setAttribute("height", [patternImage size].height);
                        _domObject.appendChild(img);


                        repeatHeight(x);
                    }

                    x = [patternImage size].width * end;

                    var elID = "bg_img_x_" + end + "_y_" + 0 + "_" +[_view UID],
                        img = document.getElementById(elID) || document.createElementNS(SVG_NS, "image");
                    img = document.createElementNS(SVG_NS, "image");
                    img.setAttribute("id", elID);
                    img.setAttributeNS(XLINK, "href", [patternImage filename]);
                    img.setAttribute("preserveAspectRatio", "none");
                    img.setAttribute("x", x);
                    img.setAttribute("y", 0);
                    img.setAttribute("width", [patternImage size].width);
                    img.setAttribute("height", [patternImage size].height);

                    _domObject.appendChild(img);

                    repeatHeight(x);
                }

                repeatHeight(0);
            }
        }
    }
    else if (bgType == BackgroundHorizontalThreePartImage || bgType == BackgroundVerticalThreePartImage)
    {
        _contentNode.setAttribute("style", "fill-opacity:0");

        var slice0  = [patternImage imageSlices][0],
            slice1 = [patternImage imageSlices][1],
            slice2  = [patternImage imageSlices][2];

        if (!_bgvp)
        {
            _bgvp = document.createElementNS(SVG_NS, "svg");
            _bgvp.setAttribute("id", "bg_vp_"+[_view UID]);
            _domObject.appendChild(_bgvp);
        }
        else if (_bgImgTL)
        {
            _bgvp.removeChild(_bgImgTL);
            _bgvp.removeChild(_bgImgTM);
            _bgvp.removeChild(_bgImgTR);
            _bgvp.removeChild(_bgImgML);
            _bgvp.removeChild(_bgImgMM);
            _bgvp.removeChild(_bgImgMR);
            _bgvp.removeChild(_bgImgBL);
            _bgvp.removeChild(_bgImgBM);
            _bgvp.removeChild(_bgImgBR);

            _bgImgTL = nil;
            _bgImgTM = nil;
            _bgImgTR = nil;
            _bgImgML = nil;
            _bgImgMM = nil;
            _bgImgMR = nil;
            _bgImgBL = nil;
            _bgImgBM = nil;
            _bgImgBR = nil;
        }

        _bgvp.setAttribute("width", [_view frameSize].width);
        _bgvp.setAttribute("height", [_view frameSize].height);

        if (!_bgImg0)
        {
            _bgImg0 = document.createElementNS(SVG_NS, "image");
            _bgImg0.setAttribute("id", "bg_img_0_"+[_view UID]);
            _bgvp.appendChild(_bgImg0);
        }

        if (!_bgImg1)
        {
            _bgImg1 = document.createElementNS(SVG_NS, "image");
            _bgImg1.setAttribute("id", "bg_img_1_"+[_view UID]);
            _bgvp.appendChild(_bgImg1);
        }

        if (!_bgImg2)
        {
            _bgImg2 = document.createElementNS(SVG_NS, "image");
            _bgImg2.setAttribute("id", "bg_img_2_"+[_view UID]);
            _bgvp.appendChild(_bgImg2);
        }

        var x0 = 0,
            y0 = 0,
            w0 = 0,
            h0 = 0,

            x1 = 0,
            y1 = 0,
            w1 = 0,
            h1 = 0,

            x2 = 0,
            y2 = 0,
            w2 = 0,
            h2 = 0;

        if (bgType == BackgroundHorizontalThreePartImage)
        {
            x0 = 0;
            y0 = 0;
            w0 = [slice0 size].width;
            h0 = [slice0 size].height;

            x1 = [slice0 size].width;
            y1 = 0;
            w1 = [_view frameSize].width  - [slice2 size].width - [slice0 size].width;
            h1 = [slice1 size].height;

            x2 = [_view frameSize].width - [slice2 size].width;
            y2 = 0;
            w2 = [slice2 size].width;
            h2 = [slice2 size].height;

            if ([[RTRenderer sharedRenderer] isTiny])
            {
                x0 = [_view frameOrigin].x;
                y0 = [_view frameOrigin].y;

                x1 += [_view frameOrigin].x;
                y1 = [_view frameOrigin].y;

                x2 += [_view frameOrigin].x;
                y2 = [_view frameOrigin].y;
            }
        }
        else if (bgType == BackgroundVerticalThreePartImage)
        {
            x0 = 0;
            y0 = 0;
            w0 = [slice0 size].width;
            h0 = [slice0 size].height;

            x1 = 0;
            y1 = [slice0 size].height;
            w1 = [slice1 size].width;
            h1 = [_view frameSize].height  - [slice2 size].height - [slice0 size].height;

            x2 = 0;
            y2 = [_view frameSize].height - [slice2 size].height;
            w2 = [slice2 size].width;
            h2 = [slice2 size].height;

            if ([[RTRenderer sharedRenderer] isTiny])
            {
                x0 = [_view frameOrigin].x;
                y0 = [_view frameOrigin].y;

                x1 = [_view frameOrigin].x;
                y1 += [_view frameOrigin].y;

                x2 = [_view frameOrigin].x;
                y2 += [_view frameOrigin].y;
            }
        }

        _bgImg0.setAttributeNS(XLINK, "href", [slice0 filename]);
        _bgImg0.setAttribute("preserveAspectRatio", "none");
        _bgImg0.setAttribute("x", x0);
        _bgImg0.setAttribute("y", y0);
        _bgImg0.setAttribute("width", w0 + "px");
        _bgImg0.setAttribute("height", h0 + "px");

        _bgImg1.setAttributeNS(XLINK, "href", [slice1 filename]);
        _bgImg1.setAttribute("preserveAspectRatio", "none");
        _bgImg1.setAttribute("x", x1);
        _bgImg1.setAttribute("y", y1);
        _bgImg1.setAttribute("width", w1 + "px");
        _bgImg1.setAttribute("height", h1 + "px");

        _bgImg2.setAttributeNS(XLINK, "href", [slice2 filename]);
        _bgImg2.setAttribute("preserveAspectRatio", "none");
        _bgImg2.setAttribute("x", x2);
        _bgImg2.setAttribute("y", y2);
        _bgImg2.setAttribute("width",  w2 + "px");
        _bgImg2.setAttribute("height", h2 + "px");
    }
    else if (bgType == BackgroundNinePartImage)
    {
        _contentNode.setAttribute("style", "fill-opacity:0");

        var topLeft         = [patternImage imageSlices][0],
            topMiddle       = [patternImage imageSlices][1],
            topRight        = [patternImage imageSlices][2],
            middleLeft      = [patternImage imageSlices][3],
            middleMiddle    = [patternImage imageSlices][4],
            middleRight     = [patternImage imageSlices][5],
            bottomLeft      = [patternImage imageSlices][6],
            bottomMiddle    = [patternImage imageSlices][7],
            bottomRight     = [patternImage imageSlices][8];

        if (!_bgvp)
        {
            _bgvp = document.createElementNS(SVG_NS, "svg");
            _bgvp.setAttribute("id", "bg_vp_"+[_view UID]);
            _domObject.appendChild(_bgvp);
        }
        else if (_bgImg0)
        {
            _bgvp.removeChild(_bgImg0);
            _bgvp.removeChild(_bgImg1);
            _bgvp.removeChild(_bgImg2);

            _bgImg0 = nil;
            _bgImg1 = nil;
            _bgImg2 = nil;
        }

        _bgvp.setAttribute("width", [_view frameSize].width);
        _bgvp.setAttribute("height", [_view frameSize].height);

        if (!_bgImgTL)
        {
            _bgImgTL = document.createElementNS(SVG_NS, "image");
            _bgImgTL.setAttribute("id", "bg_img_tl_"+[_view UID]);
            _bgvp.appendChild(_bgImgTL);
        }

        if (!_bgImgTM)
        {
            _bgImgTM = document.createElementNS(SVG_NS, "image");
            _bgImgTM.setAttribute("id", "bg_img_tm_"+[_view UID]);
            _bgvp.appendChild(_bgImgTM);
        }

        if (!_bgImgTR)
        {
            _bgImgTR = document.createElementNS(SVG_NS, "image");
            _bgImgTR.setAttribute("id", "bg_img_tr_"+[_view UID]);
            _bgvp.appendChild(_bgImgTR);
        }

        if (!_bgImgML)
        {
            _bgImgML = document.createElementNS(SVG_NS, "image");
            _bgImgML.setAttribute("id", "bg_img_ml_"+[_view UID]);
            _bgvp.appendChild(_bgImgML);
        }

        if (!_bgImgMM)
        {
            _bgImgMM = document.createElementNS(SVG_NS, "image");
            _bgImgMM.setAttribute("id", "bg_img_mm_"+[_view UID]);
            _bgvp.appendChild(_bgImgMM);
        }

        if (!_bgImgMR)
        {
            _bgImgMR = document.createElementNS(SVG_NS, "image");
            _bgImgMR.setAttribute("id", "bg_img_mr_"+[_view UID]);
            _bgvp.appendChild(_bgImgMR);
        }

        if (!_bgImgBL)
        {
            _bgImgBL = document.createElementNS(SVG_NS, "image");
            _bgImgBL.setAttribute("id", "bg_img_bl_"+[_view UID]);
            _bgvp.appendChild(_bgImgBL);
        }

        if (!_bgImgBM)
        {
            _bgImgBM = document.createElementNS(SVG_NS, "image");
            _bgImgBM.setAttribute("id", "bg_img_bm_"+[_view UID]);
            _bgvp.appendChild(_bgImgBM);
        }

        if (!_bgImgBR)
        {
            _bgImgBR = document.createElementNS(SVG_NS, "image");
            _bgImgBR.setAttribute("id", "bg_img_br_"+[_view UID]);
            _bgvp.appendChild(_bgImgBR);
        }

        // Top - Left
        var x = 0,
            y = 0;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x = [_view frameOrigin].x;
            y = [_view frameOrigin].y;
        }

        _bgImgTL.setAttributeNS('http://www.w3.org/1999/xlink', "href", [topLeft filename]);
        _bgImgTL.setAttribute("preserveAspectRatio", "none");
        _bgImgTL.setAttribute("x", x);
        _bgImgTL.setAttribute("y", y);
        _bgImgTL.setAttribute("width", [topLeft size].width + "px");
        _bgImgTL.setAttribute("height", [topLeft size].height + "px");

        // Top - Middle
        x = [topLeft size].width;
        y = 0;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x += [_view frameOrigin].x;
            y = [_view frameOrigin].y;
        }

        _bgImgTM.setAttributeNS('http://www.w3.org/1999/xlink', "href", [topMiddle filename]);
        _bgImgTM.setAttribute("preserveAspectRatio", "none");
        _bgImgTM.setAttribute("x", x);
        _bgImgTM.setAttribute("y", y);
        _bgImgTM.setAttribute("width", [_view frameSize].width - [topLeft size].width - [topRight size].width + "px");
        _bgImgTM.setAttribute("height", [topMiddle size].height + "px");

        // Top - Right
        x = [_view frameSize].width - [topRight size].width;
        y = 0;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x += [_view frameOrigin].x;
            y = [_view frameOrigin].y;
        }

        _bgImgTR.setAttributeNS('http://www.w3.org/1999/xlink', "href", [topRight filename]);
        _bgImgTR.setAttribute("preserveAspectRatio", "none");
        _bgImgTR.setAttribute("x", x);
        _bgImgTR.setAttribute("y", y);
        _bgImgTR.setAttribute("width", [topRight size].width + "px");
        _bgImgTR.setAttribute("height", [topRight size].height + "px");

        // Middle - Left
        x = 0;
        y = [topLeft size].height;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x += [_view frameOrigin].x;
            y += [_view frameOrigin].y;
        }

        _bgImgML.setAttributeNS('http://www.w3.org/1999/xlink', "href", [middleLeft filename]);
        _bgImgML.setAttribute("preserveAspectRatio", "none");
        _bgImgML.setAttribute("x", x);
        _bgImgML.setAttribute("y", y);
        _bgImgML.setAttribute("width", [middleLeft size].width + "px");
        _bgImgML.setAttribute("height", [_view frameSize].height - [topLeft size].height - [bottomLeft size].height + "px");

        // Middle - Middle
        x = [middleLeft size].width;
        y = [topMiddle size].height;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x += [_view frameOrigin].x;
            y += [_view frameOrigin].y;
        }

        _bgImgMM.setAttributeNS('http://www.w3.org/1999/xlink', "href", [middleMiddle filename]);
        _bgImgMM.setAttribute("preserveAspectRatio", "none");
        _bgImgMM.setAttribute("x", x);
        _bgImgMM.setAttribute("y", y);
        _bgImgMM.setAttribute("width", [_view frameSize].width - [middleLeft size].width - [middleRight size].width + "px");
        _bgImgMM.setAttribute("height", [_view frameSize].height - [topMiddle size].height - [bottomMiddle size].height + "px");

        // Middle - Right
        x = [_view frameSize].width - [middleRight size].width;
        y = [topRight size].height;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x += [_view frameOrigin].x;
            y += [_view frameOrigin].y;
        }

        _bgImgMR.setAttributeNS('http://www.w3.org/1999/xlink', "href", [middleRight filename]);
        _bgImgMR.setAttribute("preserveAspectRatio", "none");
        _bgImgMR.setAttribute("x", x);
        _bgImgMR.setAttribute("y", y);
        _bgImgMR.setAttribute("width", [middleRight size].width + "px");
        _bgImgMR.setAttribute("height", [_view frameSize].height - [topRight size].height - [bottomRight size].height + "px");

        // Bottom - Left
        x = 0;
        y = [_view frameSize].height - [bottomLeft size].height;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x += [_view frameOrigin].x;
            y += [_view frameOrigin].y;
        }

        _bgImgBL.setAttributeNS('http://www.w3.org/1999/xlink', "href", [bottomLeft filename]);
        _bgImgBL.setAttribute("preserveAspectRatio", "none");
        _bgImgBL.setAttribute("x", x);
        _bgImgBL.setAttribute("y", y);
        _bgImgBL.setAttribute("width", [bottomLeft size].width + "px");
        _bgImgBL.setAttribute("height", [bottomLeft size].height + "px");

        // Bottom - Middle
        x = [bottomLeft size].width;
        y = [_view frameSize].height - [bottomMiddle size].height;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x += [_view frameOrigin].x;
            y += [_view frameOrigin].y;
        }

        _bgImgBM.setAttributeNS('http://www.w3.org/1999/xlink', "href", [bottomMiddle filename]);
        _bgImgBM.setAttribute("preserveAspectRatio", "none");
        _bgImgBM.setAttribute("x", x);
        _bgImgBM.setAttribute("y", y);
        _bgImgBM.setAttribute("width", [_view frameSize].width - [bottomLeft size].width - [bottomRight size].width + "px");
        _bgImgBM.setAttribute("height", [bottomMiddle size].height + "px");

        // Bottom - Right
        x = [_view frameSize].width - [bottomRight size].width;
        y = [_view frameSize].height - [bottomRight size].height;

        if ([[RTRenderer sharedRenderer] isTiny])
        {
            x += [_view frameOrigin].x;
            y += [_view frameOrigin].y;
        }

        _bgImgBR.setAttributeNS('http://www.w3.org/1999/xlink', "href", [bottomRight filename]);
        _bgImgBR.setAttribute("preserveAspectRatio", "none");
        _bgImgBR.setAttribute("x", x);
        _bgImgBR.setAttribute("y", y);
        _bgImgBR.setAttribute("width", [bottomRight size].width + "px");
        _bgImgBR.setAttribute("height", [bottomRight size].height + "px");

    }
}

- (void)update
{
    var w = [_view frameSize].width,
        h = [_view frameSize].height,
        posX = [_view frameOrigin].x,
        posY = [_view frameOrigin].y,
        parentW = [_view superview] ? [[_view superview] frameSize].width : 0,
        parentH = [_view superview] ? [[_view superview] frameSize].height : 0;

    _domObject.setAttribute("transform", [CPString stringWithFormat:"translate(%d, %d)", [_view frameOrigin].x, [_view frameOrigin].y]);
    _domObject.setAttribute("opacity", [_view alphaValue]);
    _domObject.setAttribute("viewBox", "0 0 " + w + " " + h);

    if ([_view superview])
    {
        _clipRect.setAttribute("x", 0);
        _clipRect.setAttribute("y", 0);
        _clipRect.setAttribute("width", [_view frameSize].width);
        _clipRect.setAttribute("height", [_view frameSize].height);

        _domObject.setAttribute("clip-path", "url(#cp_"+[_view UID]+")");
        _domObject.setAttribute("clip-rule", "nonzero");

        /*
        if ([_view clipsToBounds])
        {
            _domObject.setAttribute("clip-path", "url(#cp_"+[_view UID]+")");
            _domObject.setAttribute("clip-rule", "nonzero");
        }
        else
        {
            _domObject.removeAttribute("clip-path");
            _domObject.removeAttribute("clip-rule");
        }
        */
    }

    [self _updateContentNode];
}

@end
