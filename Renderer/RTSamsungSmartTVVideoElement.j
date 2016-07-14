/*
 * RTSamsungSmartTVVideoElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTSamsungSmartTVVideoElement : RTCanvasElement
{
{
    id              _delegate;

    DOMObject       _domVid;

    RTVideo         _video;

    int             _loadStatus;

    CGPoint         _posVideo;
    CGSize          _sizeVideo;

    JSObject        _videoPlayer;
    JSObject        _videoPlugin;
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

        _canvas = document.createElement('canvas');
        _canvas.setAttribute("id", "canvas_"+[_view UID])
        _domObject.appendChild(_canvas);

        _videoPlayer                = window.parent.Player;
        _videoPlayer.init();

        _videoPlugin                = window.parent.document.getElementById('pluginPlayer');
        _videoPlugin.style.position = "absolute";
        _videoPlugin.style.zIndex   = "99";
        _videoPlugin.OnBufferingComplete = function() { [self play]; }
        _videoPlugin.OnRenderingComplete = function() { [self restart]; }
    }
    return self;
}

- (void)release
{
    [super release];

    _videoPlugin.style.zIndex   = "-99";
    _videoPlayer.deinit();
}

- (void)setVideo:(RTVideo)aVideo
{
    _video = aVideo;

    [self _load];
}

- (void)_load
{
    _videoPlayer.setVideoURL([_video h264]);
    _videoPlugin.InitPlayer([_video h264]);

    if ([_delegate respondsToSelector:@selector(_videoPlayerIsReady)])
        [_delegate _videoPlayerIsReady];

    if ([_delegate respondsToSelector:@selector(_videoDidLoad)])
        [_delegate _videoDidLoad];
}

- (void)_appendWebM
{

}

- (void)_appendH264
{

}

- (void)_appendOGG
{

}

- (void)play
{
    _videoPlugin.StartPlayback();
}

- (void)restart
{
    alert('restart');
    _videoPlayer.restart();
}

- (void)pause
{
    _videoPlayer.pause();
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (void)resizeTo:(CGSize)aSize
{
    [super resizeTo:aSize];
}

- (void)moveVideoTo:(CGPoint)aPoint
{
    _posVideo = aPoint;
}

- (void)resizeVideoTo:(CGRect)aSize
{
    _sizeVideo = aSize;
}

- (void)render
{
    [self renderRect:nil];
}

- (void)renderRect:(CGRect)aRect
{
    // We need to calculate the abolute position of the video based on it's parents
    var currentView = _view,
        parentView  = nil,
        pos         = CGPointMakeZero();
    while (parentView = [currentView superview])
    {
        pos.x += [parentView frameOrigin].x;
        pos.y += [parentView frameOrigin].y;
        currentView = parentView;
    }

    var x       = aRect ? aRect.origin.x : 0,
        y       = aRect ? aRect.origin.y : 0,
        w       = aRect ? aRect.size.width : [_view frameSize].width,
        h       = aRect ? aRect.size.height : [_view frameSize].height;

    var ctx = _canvas.getContext("2d");
    ctx.clearRect(x, y, w, h);

    _videoPlugin.style.left     = pos.x + "px";
    _videoPlugin.style.top      = pos.y + "px";
    _videoPlugin.style.width    = _sizeVideo.width + "px";
    _videoPlugin.style.height   = _sizeVideo.height + "px";
    _videoPlugin.SetDisplayArea(pos.x / 1.33333, pos.y / 1.33333, _sizeVideo.width / 1.33333, _sizeVideo.height / 1.33333);
}
