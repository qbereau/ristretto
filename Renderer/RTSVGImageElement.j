/*
 * RTSVGImageElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTSVGImageElement : RTSVGElement
{
    DOMObject       _vp;

    id              _delegate;
    CPString        _filename;
    CGSize          _imageSize;

    CGPoint         _posImg;
    CGSize          _renderImgSize;
}

- (id)initWithView:(RTView)aView
{
    if (self = [super initWithView:aView])
    {
        if (_contentNode)
        {
            _domObject.removeChild(_contentNode);
        }

        // Create new viewport
        //_vp = document.createElementNS(SVG_NS, "g");
        //_vp.setAttribute("id", "viewport_"+[_view UID]);
        //_domObject.appendChild(_vp);

        _contentNode = document.createElementNS(SVG_NS, "image");
        _contentNode.setAttribute("id", "content_"+[_view UID]);
        _domObject.appendChild(_contentNode);
    }
    return self;
}

- (void)setFilename:(CPString)aFilename
{
    _filename = aFilename;

    _contentNode.setAttributeNS(XLINK, 'href', _filename);
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
    if (_imageSize.width == -1 || _imageSize.height == -1)
    {
        var ii = [[RTImageInfo alloc] init];
        [ii setDelegate:self];
        [ii loadInfo:_filename];

        // *************
        // Using Image()
        /*
        _image = new Image();

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
        */
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(_imageDidLoad)])
            [_delegate _imageDidLoad];
    }
}

/*
- (void)_derefFromImage
{
    _image.onload = null;
    _image.onerror = null;
    _image.onabort = null;
}

- (void)_imageDidLoad
{
    CPLog(_image.width + " - " + _image.height);
    if (!_imageSize || (_imageSize.width == -1 && _imageSize.height == -1))
        _imageSize = CGSizeMake(_image.width, _image.height);

    if ([_delegate respondsToSelector:@selector(_imageDidLoad)])
        [_delegate _imageDidLoad];
}

- (void)_imageDidError
{
    if ([_delegate respondsToSelector:@selector(_imageDidError)])
        [_delegate _imageDidError];
}

- (void)_imageDidAbort
{
    if ([_delegate respondsToSelector:@selector(_imageDidAbort)])
        [_delegate _imageDidAbort];
}
*/

- (void)receivedImageInformation:(JSObject)imageInfo
{
    _imageSize = CGSizeMake(imageInfo.width, imageInfo.height);

    if ([_delegate respondsToSelector:@selector(_imageDidLoad)])
        [_delegate _imageDidLoad];
}

- (CGPoint)imageOffset
{
    return _posImg;
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
    [self update];
}

- (void)_updateContentNode
{
    [super _updateContentNode];

    var w       = _renderImgSize ? _renderImgSize.width : [_view frameSize].width,
        h       = _renderImgSize ? _renderImgSize.height : [_view frameSize].height,
        x       = _posImg ? _posImg.x : 0,
        y       = _posImg ? _posImg.y : 0;

    _contentNode.setAttribute("x", x);
    _contentNode.setAttribute("y", y);
    _contentNode.setAttribute("width", w);
    _contentNode.setAttribute("height", h);
    _contentNode.setAttribute("style", "fill-opacity: 1");
    //_contentNode.setAttribute("preserveAspectRatio", "xMinYMin");
}

@end
