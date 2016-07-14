/*
 * RTLabel.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

 RTTextAlignmentLeft    = 0;
 RTTextAlignmentCenter  = 1;
 RTTextAlignmentRight   = 2;

 RTBaselineAdjustmentAlignBaselines = 0;
 RTBaselineAdjustmentAlignCenters   = 1;
 RTBaselineAdjustmentNone           = 2;

@implementation RTLabel : RTView
{
    CPString            _text;
    CPFont              _font;
    CPColor             _textColor;
    RTTextAlignment     _textAlignment;
    float               _minimumFontSize;
    BOOL                _adjustsFontSizeToFitWidth;
    RTBaseline          _baselineAdjustment;
    int                 _numberOfLines;
    CGSize              _shadowOffset;
    CPColor             _shadowColor;

    RTElement           _element;
}

- (id)initWithFrame:(CPRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _adjustsFontSizeToFitWidth = NO;

        _textAlignment              = RTTextAlignmentLeft;
        _font                       = [CPFont systemFontOfSize:12];
        _textColor                  = [CPColor blackColor];
        _adjustsFontSizeToFitWidth  = NO;
        _baselineAdjustment         = RTBaselineAdjustmentAlignBaselines;
        _numberOfLines              = 1;
        _minimumFontSize            = 0;
        _shadowOffset               = nil;
        _shadowColor                = nil;

        _element = [[RTRenderer sharedRenderer] createTextElement:self];
    }
    return self;
}

- (void)setText:(CPString)aText
{
    _text = aText;

    [_element update];
}

- (CPString)text
{
    return _text;
}

- (void)setFont:(CPFont)aFont
{
    _font = aFont;

    [_element update];
}

- (CPFont)font
{
    return _font;
}

- (void)setTextColor:(CPColor)aColor
{
    _textColor = aColor;

    [_element update];
}

- (CPFont)textColor
{
    return _textColor;
}

- (void)setTextAlignment:(RTTextAlignment)anAlignment
{
    _textAlignment = anAlignment;

    [_element update];
}

- (RTTextAlignment)textAlignment
{
    return _textAlignment;
}

- (void)setNumberOfLines:(int)aNbLines
{
    _numberOfLines = aNbLines;

    [_element update];
}

- (int)numberOfLines
{
    return _numberOfLines;
}

- (void)setMinimumFontSize:(float)aMinFontSize
{
    _minimumFontSize = aMinFontSize;

    [_element update];
}

- (float)minimumFontSize
{
    return _minimumFontSize;
}

- (void)setBaselineAdjustment:(RTBaselineAdjustment)aBaseline
{
    _baselineAdjustment = aBaseline;

    [_element update];
}

- (RTBaselineAdjustment)baselineAdjustment
{
    return _baselineAdjustment;
}

- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjust
{
    _adjustsFontSizeToFitWidth = adjust;

    [_element update];
}

- (BOOL)adjustsFontSizeToFitWidth
{
    return _adjustsFontSizeToFitWidth;
}

- (void)setShadowOffset:(CGSize)aOffset
{
    _shadowOffset = aOffset;

    [_element update];
}

- (BOOL)shadowOffset
{
    return _shadowOffset;
}

- (void)setShadowColor:(CPColor)aColor
{
    _shadowColor = aColor;

    [_element update];
}

- (BOOL)shadowColor
{
    return _shadowColor;
}

@end
