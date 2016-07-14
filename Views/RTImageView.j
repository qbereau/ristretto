/*
 * RTImageView.j - Ported from Cappuccino's CPImageView
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@import <Foundation/CPNotificationCenter.j>

@import "RTImage.j"

RTNoImage       = 0;
RTImageOnly     = 1;
RTImageLeft     = 2;
RTImageRight    = 3;
RTImageBelow    = 4;
RTImageAbove    = 5;
RTImageOverlaps = 6;

var RTImageViewEmptyPlaceholderImage = nil;

/*!
    @ingroup appkit
    @class RTImageView

    This class is a control that displays an image.
*/
@implementation RTImageView : RTView
{
    CGRect              _imageRect;
    RTAlignment         _imageAlignment;

    RTImage             _image;
    RTElement           _element;

    RTScaling           _imageScaling;
}

+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:[RTView class]];

    RTImageViewEmptyPlaceholderImage = [[RTImage alloc] initWithContentsOfFile:[bundle pathForResource:@"empty.png"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _element = [[RTRenderer sharedRenderer] createImageElement:self];
    }

    return self;
}

/*!
    Returns the view's image.
*/
- (RTImage)image
{
    return _image;
}

/*! @ignore */
- (void)setImage:(RTImage)anImage
{
    var oldImage = _image;

    if (oldImage === anImage)
        return;

    _image = anImage;
    [_image setDelegate:self];

    [_element setFilename:[_image filename]];
    [_element setImageSize:[_image size]];
    [_element setDelegate:self];
    [_element load];
}

- (void)elementDidLoad:(RTElement)anElement
{
    [_image _imageDidLoad];
    [_image setSize:[anElement imageSize]];

    [self hideOrDisplayContents];
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)elementDidError:(RTElement)anElement
{
    [_image _imageDidError];
}

/* @ignore */
- (void)elementDidAbort:(RTElement)anElement
{
    [_image _imageDidAbort];
}

/*!
    Sets the type of image alignment that should be used to
    render the image.
    @param anImageAlignment the type of scaling to use
*/
- (void)setImageAlignment:(RTAlignment)anImageAlignment
{
    if (_imageAlignment == anImageAlignment)
        return;

    _imageAlignment = anImageAlignment;

    if (![self image])
        return;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (unsigned)imageAlignment
{
    return _imageAlignment;
}

/*!
    Sets the type of image scaling that should be used to
    render the image.
    @param anImageScaling the type of scaling to use
*/
- (void)setImageScaling:(RTImageScaling)anImageScaling
{
    _imageScaling = anImageScaling;

    if (!_image)
        return;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (unsigned)imageScaling
{
    return _imageScaling;
}

/*!
    Toggles the display of the image view.
*/
- (void)hideOrDisplayContents
{
    if ([self isHidden])
        return;

    if (![self image])
    {
        [_element hide:YES];
    }
    else
    {
        [_element hide:NO];
    }
}

/*!
    Returns the view's image rectangle
*/
- (CGRect)imageRect
{
    return _imageRect;
}

/*!
    Add a description
*/
- (void)layoutSubviews
{
    if (![self image])
        return;

    var bounds = [self bounds],
        image = [self image],
        x = 0.0,
        y = 0.0,
        insetWidth = 0.0,
        insetHeight = 0.0,
        boundsWidth = CGRectGetWidth(bounds),
        boundsHeight = CGRectGetHeight(bounds),
        width = boundsWidth - insetWidth,
        height = boundsHeight - insetHeight,
        size = [image size];

    if (!size || (size.width == -1 && size.height == -1))
        return;

    if (_imageScaling === RTScaleToFit)
    {
        [_element resizeImageTo:CGSizeMake(ROUND(width), ROUND(height))];
    }
    else if (_imageScaling === RTScaleProportionally)
    {
        if (width >= size.width && height >= size.height)
        {
            width = size.width;
            height = size.height;
        }
        else
        {
            var imageRatio = size.width / size.height,
                viewRatio = width / height;
            if (viewRatio > imageRatio)
                width = height * imageRatio;
            else
                height = width / imageRatio;
        }
        [_element resizeImageTo:CGSizeMake(ROUND(width), ROUND(height))];
    }
    else if (_imageScaling == RTScaleNone)
    {
        width = size.width;
        height = size.height;
        [_element resizeImageTo:CGSizeMake(ROUND(size.width), ROUND(size.height))];
    }

    var x,
        y;

    switch (_imageAlignment)
    {
        case RTAlignLeft:
        case RTAlignTopLeft:
        case RTAlignBottomLeft:
            x = 0.0;
            break;

        case RTAlignRight:
        case RTAlignTopRight:
        case RTAlignBottomRight:
            x = boundsWidth - width;
            break;

        default:
            x = (boundsWidth - width) / 2.0;
            break;
    }

    switch (_imageAlignment)
    {
        case RTAlignTop:
        case RTAlignTopLeft:
        case RTAlignTopRight:
            y = 0.0;
            break;

        case RTAlignBottom:
        case RTAlignBottomLeft:
        case RTAlignBottomRight:
            y = boundsHeight - height;
            break;

        default:
            y = (boundsHeight - height) / 2.0;
            break;
    }

    [_element moveImageTo:CGPointMake(x, y)];
}

@end

var RTImageViewImageKey          = @"RTImageViewImageKey",
    RTImageViewImageScalingKey   = @"RTImageViewImageScalingKey",
    RTImageViewImageAlignmentKey = @"RTImageViewImageAlignmentKey";
