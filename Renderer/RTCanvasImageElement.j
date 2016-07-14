/*
 * RTCanvasImageElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTCanvasImageElement : RTCanvasElement
{
    id              _delegate;
    CPString        _filename;
    Image           _image;
    CGSize          _imageSize;

    CGPoint         _posImg;
    CGSize          _renderImgSize;
}

- (id)initWithView:(RTView)aView
{
    if (self = [super initWithView:aView])
    {

    }
    return self;
}

- (void)setFilename:(CPString)aFilename
{
    _filename = aFilename;
}

- (void)setImageSize:(CGSize)aSize
{
    _imageSize = CGSizeMakeCopy(aSize);
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (CGSize)imageSize
{
    return _imageSize;
}

- (void)load
{
    _image = new Image();

    // NOTE: Copied from Capp's RTImage
    // FIXME: We need a better/performance way of doing this.
    _image.onload = function ()
        {
            [self _imageDidLoad];
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            [self _derefFromImage];
        };

    _image.onerror = function ()
        {
            [self _imageDidError];
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            [self _derefFromImage];
        };

    _image.onabort = function ()
        {
            [self _imageDidAbort];
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            [self _derefFromImage];
        };

    _image.src = _filename;
}

- (void)_derefFromImage
{
    _image.onload = null;
    _image.onerror = null;
    _image.onabort = null;
}

/* @ignore */
- (void)_imageDidLoad
{
    if (!_imageSize || (_imageSize.width == -1 && _imageSize.height == -1))
        _imageSize = CGSizeMake(_image.width, _image.height);

    if ([_delegate respondsToSelector:@selector(elementDidLoad:)])
        [_delegate elementDidLoad:self];
}

/* @ignore */
- (void)_imageDidError
{
    if ([_delegate respondsToSelector:@selector(elementDidError:)])
        [_delegate elementDidError:self];
}

/* @ignore */
- (void)_imageDidAbort
{
    if ([_delegate respondsToSelector:@selector(elementDidAbort:)])
        [_delegate elementDidAbort:self];
}

- (void)moveImageTo:(CGPoint)aPoint
{
    _posImg = aPoint;
    [self render];
}

- (void)resizeImageTo:(CGRect)aSize
{
    _renderImgSize = aSize;
    [self render];
}

- (void)render
{
    [self renderRect:nil];
}

- (void)renderRect:(CGRect)aRect
{
    [super renderRect:aRect];

    var ctx = _canvas.getContext("2d");
    ctx.clearRect(0, 0, [_view frameSize].width, [_view frameSize].height);

    if (!_image)
        return;


    if (_renderImgSize && _posImg && _imageSize)
    {
        ctx.drawImage(_image, 0, 0, _imageSize.width, _imageSize.height, _posImg.x, _posImg.y, _renderImgSize.width, _renderImgSize.height);
    }
    else
    {
        ctx.drawImage(_image, 0, 0, [_view frameSize].width, [_view frameSize].height);
    }
}

@end
