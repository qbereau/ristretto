/*
 * RTVideoView.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTVideoView : RTView
{
    id                  _delegate;
    CPString            _filename;
    RTElement           _element;
    RTVideo             _video;
    int                 _status;
    RTScaling           _scaling;
    RTAlignment         _alignment;
    float               _volume;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _element    = [[RTRenderer sharedRenderer] createVideoElement:self];
        _scaling    = RTScaleProportionally;
        _alignment  = RTAlignTopLeft;
    }

    return self;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (void)setFilename:(CPString)aFilename
{
    _filename = aFilename;
}

- (CPString)filename
{
    return _filename;
}

- (void)setElement:(RTElement)anElement
{
    _element = anElement;
}

- (RTElement)element
{
    return _element;
}

- (void)setVideo:(RTVideo)aVideo
{
    _video = aVideo;

    [_video setDelegate:self];
    [_video setElement:_element];
}

- (RTVideo)video
{
    return _video;
}

- (float)volume
{
    return _volume || 0.0;
}

- (void)setVolume:(float)aVolume
{
    _volume = aVolume;
}

- (void)play
{
    [_element play];
}

- (void)pause
{
    [_element pause];
}

- (void)_videoPlayerIsReady
{
    if ([_delegate respondsToSelector:@selector(videoPlayerIsReady:)])
        [_delegate videoPlayerIsReady:self];
}

- (void)_videoDidLoad
{
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];

    if ([_delegate respondsToSelector:@selector(videoDidLoad:)])
        [_delegate videoDidLoad:self];

    if ([_video autoPlay])
        [self play];
}

- (void)_videoDidError
{
    if ([_delegate respondsToSelector:@selector(videoDidError:)])
        [_delegate videoDidError:self];
}

- (void)setAlignment:(RTImageScaling)anAlignment
{
    if (_alignment == anAlignment)
        return;

    _alignment = anAlignment;

    if (!_video)
        return;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (unsigned)alignment
{
    return _alignment;
}

- (void)setScaling:(RTVideoScaling)aScaling
{
    _scaling = aScaling;

    if (!_video)
        return;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (unsigned)scaling
{
    return _scaling;
}

- (void)layoutSubviews
{
    if (!_video)
        return;

    var bounds = [self bounds],
        x = 0.0,
        y = 0.0,
        insetWidth = 0.0,
        insetHeight = 0.0,
        boundsWidth = CGRectGetWidth(bounds),
        boundsHeight = CGRectGetHeight(bounds),
        width = boundsWidth - insetWidth,
        height = boundsHeight - insetHeight,
        size = [_video size];

    if (!size || (size.width == -1 && size.height == -1))
        return;

    if (_scaling === RTScaleToFit)
    {
        [_element resizeVideoTo:CGSizeMake(ROUND(width), ROUND(height))];
    }
    else if (_scaling === RTScaleProportionally)
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
        [_element resizeVideoTo:CGSizeMake(ROUND(width), ROUND(height))];
    }
    else if (_scaling == RTScaleNone)
    {
        width = size.width;
        height = size.height;
        [_element resizeVideoTo:CGSizeMake(ROUND(size.width), ROUND(size.height))];
    }

    var x,
        y;

    switch (_alignment)
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

    switch (_alignment)
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

    [_element moveVideoTo:CGPointMake(x, y)];
}

@end
