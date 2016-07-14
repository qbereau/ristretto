/*
 * RTCanvasVideoElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

RTVideoLoadStatusInitialized    = 0;
RTVideoLoadStatusLoadedData     = 1;
RTVideoLoadStatusLoadedMetaData = 2;

@implementation RTCanvasVideoElement : RTCanvasElement
{
    id              _delegate;

    DOMObject       _domVid;
    CPTimer         _timer;

    RTVideo         _video;

    int             _loadStatus;

    CGPoint         _posVideo;
    CGSize          _sizeVideo;
}

- (id)initWithView:(RTView)aView
{
    if (self = [super initWithView:aView])
    {
        _loadStatus = RTVideoLoadStatusInitialized;

        if (_canvas)
        {
            _domObject.removeChild(_canvas);
        }

        _posVideo   = CGPointMakeZero();
        _sizeVideo  = CGSizeMakeZero();

        _domVid                 = document.createElement('video');
        _domVid.style.overflow  = "hidden";
        _domVid.style.position  = "absolute";
        _domVid.visibility      = "visible";
        _domVid.zIndex          = 0;
        _domVid.setAttribute("id", "video_"+[_view UID]);
        _domObject.appendChild(_domVid);

        _canvas = document.createElement('canvas');
        _canvas.setAttribute("id", "canvas_"+[_view UID])
        _domObject.appendChild(_canvas);
    }
    return self;
}

- (void)release
{
    [super release];

    if (_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)setVideo:(RTVideo)aVideo
{
    _video = aVideo;

    [self _load];
}

- (void)_load
{
    if ([_video loop])
        _domVid.setAttribute("loop", "loop");

    if ([_video autoPlay])
        _domVid.setAttribute("autoplay", "autoplay");

    if ([_video showControls] || CPBrowserIsOperatingSystem(CPiOS))
        _domVid.setAttribute("controls", "true");

    if ([_video preload])
        _domVid.setAttribute("preload", "preload");

    _domVid.volume = [_view volume];

    if ((CPBrowserIs(CPSafariBrowser) || CPBrowserIs(CPIEBrowser)))
    {
        [self _appendH264];
    }
    else if (CPBrowserIs(CPOperaBrowser))
    {
        [self _appendOGG];
        [self _appendWebM];
        [self _appendH264];
    }
    else if (CPBrowserIs(CPFirefoxBrowser) || CPBrowserIs(CPChromeBrowser))
    {
        [self _appendWebM];
        [self _appendOGG];
        [self _appendH264];
    }
    else
    {
        [self _appendH264];
        [self _appendWebM];
        [self _appendOGG];
    }


    if (CPFeatureIsCompatible(CPHTMLCanvasDrawVideo))
       _domVid.setAttribute("style", "display:none;");

    _domVid.addEventListener("loadedmetadata", function(){
        [_video setSize:CGSizeMake(_domVid.videoWidth, _domVid.videoHeight)];
        [_video setDuration:_domVid.duration];

        _loadStatus |= RTVideoLoadStatusLoadedMetaData;

        if (_loadStatus & RTVideoLoadStatusLoadedData)
        {
            if ([_delegate respondsToSelector:@selector(_videoDidLoad)])
                [_delegate _videoDidLoad];
        }
    });

    _domVid.addEventListener("loadeddata", function(){
        _loadStatus |= RTVideoLoadStatusLoadedData;

        if (_loadStatus & RTVideoLoadStatusLoadedMetaData)
        {
            if ([_delegate respondsToSelector:@selector(_videoDidLoad)])
                [_delegate _videoDidLoad];
        }
    });

    if ([_delegate respondsToSelector:@selector(_videoPlayerIsReady)])
            [_delegate _videoPlayerIsReady];
    });

}

- (void)_appendWebM
{
    if ([_video webm])
    {
        var webm = document.createElement("source");
        webm.setAttribute("type", "video/webm");
        webm.setAttribute("src", [_video webm]);
        _domVid.appendChild(webm);
    }
}

- (void)_appendH264
{
    if ([_video h264])
    {
        var h264 = document.createElement("source");
        h264.setAttribute("type", "video/mp4");
        h264.setAttribute("src", [_video h264]);
        _domVid.appendChild(h264);
    }
}

- (void)_appendOGG
{
    if ([_video ogg])
    {
        var ogg = document.createElement("source");
        ogg.setAttribute("type", "video/ogg");
        ogg.setAttribute("src", [_video ogg]);
        _domVid.appendChild(ogg);
    }
}

- (void)play
{
    _domVid.play();

    if (CPFeatureIsCompatible(CPHTMLCanvasDrawVideo))
       _timer = [CPTimer scheduledTimerWithTimeInterval:0.033 target:self selector:@selector(render) userInfo:nil repeats:YES];
}

- (void)pause
{
    _domVid.pause();

    if (CPFeatureIsCompatible(CPHTMLCanvasDrawVideo))
    {
       [_timer invalidate];
       _timer = nil;
    }
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (void)resizeTo:(CGSize)aSize
{
    [super resizeTo:aSize];

    _domVid.style.width     = aSize.width + "px";
    _domVid.style.height    = aSize.height + "px";
}

- (void)moveVideoTo:(CGPoint)aPoint
{
    _posVideo = aPoint;

    if (CPFeatureIsCompatible(CPHTMLCanvasDrawVideo))
    {
        [self render];
    }
    else
    {
        _domVid.style.left      = _posVideo.x + "px";
        _domVid.style.top       = _posVideo.y + "px";
    }
}

- (void)resizeVideoTo:(CGRect)aSize
{
    _sizeVideo = aSize;

    if (CPFeatureIsCompatible(CPHTMLCanvasDrawVideo))
    {
        [self render];
    }
    else
    {
        _domVid.style.width     = _sizeVideo.width + "px";
        _domVid.style.height    = _sizeVideo.height + "px";

        if (_domVid.videoWidth > 0 && _domVid.videoHeight > 0)
        {
            var actualRatio     = _domVid.videoWidth / _domVid.videoHeight,
                targetRatio     = _sizeVideo.width / _sizeVideo.height,
                adjustmentRatio = actualRatio / targetRatio;
            _domVid.style.webkitTransform = "scale("+adjustmentRatio+")";
        }
    }
}

- (void)render
{
    [self renderRect:nil];
}

- (void)renderRect:(CGRect)aRect
{
    var x       = aRect ? aRect.origin.x : 0,
        y       = aRect ? aRect.origin.y : 0,
        w       = aRect ? aRect.size.width : [_view frameSize].width,
        h       = aRect ? aRect.size.height : [_view frameSize].height;

    var ctx = _canvas.getContext("2d");
    ctx.clearRect(x, y, w, h);

    if (CPFeatureIsCompatible(CPHTMLCanvasDrawVideo))
    {
        if (_sizeVideo && _posVideo && [_video size])
        {
            ctx.drawImage(_domVid, 0, 0, [_video size].width, [_video size].height, _posVideo.x, _posVideo.y, _sizeVideo.width, _sizeVideo.height);
        }
        else
        {
            ctx.drawImage(_domVid, x, y, w, h);
        }
    }

}
