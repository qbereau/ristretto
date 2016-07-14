/*
 * RTSVGVideoElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */


@implementation RTSVGVideoElement : RTSVGElement
{
    id              _delegate;

    DOMObject       _vp;
    DOMObject       _fo;

    RTVideo         _video;

    CGPoint         _posVideo;
    CGSize          _sizeVideo;
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
        if ([[RTRenderer sharedRenderer] isTiny])
        {
            _contentNode = document.createElementNS(SVG_NS, "video");
            _contentNode.setAttribute("id", "content_"+[_view UID]);
            _domObject.appendChild(_contentNode);
        }
        else
        {
            _fo = document.createElementNS(SVG_NS, "foreignObject");
            _fo.setAttribute("width", [_view frameSize].width);
            _fo.setAttribute("height", [_view frameSize].height);
            var bodyNode = document.createElementNS(XHTML, "body");
            bodyNode.setAttribute("xmlns", XHTML);
            bodyNode.setAttribute("style", "margin: 0;");

            /*_contentNode = document.createElementNS(XHTML, "video");
            _contentNode.setAttribute("id", "content_"+[_view UID]);
            _contentNode.setAttribute("loop", "loop");*/

            /*
            var params = {
                            kioskmode: 'true',
                            controller: 'false',
                            autoplay: 'true',
                            enablejavascript: 'true',
                            postdomevents: 'true',
                            loop: 'true',
                            scale: 'tofit'
                        };
            _contentNode = document.createElementNS(XHTML, "object");
            _contentNode.setAttribute("width", [_view frameSize].width);
            _contentNode.setAttribute("height", [_view frameSize].height);
            _contentNode.setAttribute("type", 'video/quicktime');
            for (var name in params) {
                var param = document.createElementNS(XHTML, 'param' );
                param.setAttribute('name', name);
                param.setAttribute('value', params[name]);
                _contentNode.appendChild(param);
            }
            bodyNode.appendChild(_contentNode);
            _fo.appendChild(bodyNode);
            _vp.appendChild(_fo);
            */
        }

    }
    return self;
}

- (void)setVideo:(RTVideo)aVideo
{
    _video = aVideo;

    [self _load];
}

- (CGPoint)videoOffset
{
    return _posVideo;
}

- (CGSize)videoSize
{
    return _sizeVideo;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (void)_load
{
    if ([[RTRenderer sharedRenderer] isTiny])
    {
        var srcVid = [_video h264];
        if (CPBrowserIsOperatingSystem(CPHMP100))
        {
            if ([_video mp4])
                srcVid = [_video mp4];
            else
                srcVid = [_video h264];
        }
        else if (CPBrowserIsOperatingSystem(CPHMP200))
        {
            if ([_video h264])
                srcVid = [_video h264];
            else
                srcVid = [_video mp4];
        }

        _contentNode.setAttributeNS(XLINK, "href", srcVid);
        _contentNode.setAttribute("repeatCount", [_video loop] ?  "indefinite" : 1);
        _contentNode.setAttribute("initialVisibility", "always");
        _contentNode.setAttribute("begin", [_video autoPlay] ? 0 : "indefinite");

        if ([_delegate respondsToSelector:@selector(_videoDidLoad)])
            [_delegate _videoDidLoad];
    }
    else
    {
        _contentNode.setAttribute("data", [_video h264]);
    }

    if ([_delegate respondsToSelector:@selector(_videoPlayerIsReady)])
        [_delegate _videoPlayerIsReady];
    });
}

- (void)play
{
    if ([[RTRenderer sharedRenderer] isTiny])
    {
        _contentNode.beginElement();
    }
}

- (void)pause
{
    if ([[RTRenderer sharedRenderer] isTiny])
    {
        _contentNode.pauseElement();
    }
}

- (void)moveVideoTo:(CGPoint)aPoint
{
    _posVideo = aPoint;

    [self render];
}

- (void)resizeVideoTo:(CGRect)aSize
{
    _sizeVideo = aSize;

    [self render];
}

- (void)render
{
    [self update];
}

- (void)_updateContentNode
{
    var w       = _sizeVideo ? _sizeVideo.width : [_view frameSize].width,
        h       = _sizeVideo ? _sizeVideo.height : [_view frameSize].height,
        x       = _posVideo ? _posVideo.x : 0,
        y       = _posVideo ? _posVideo.y : 0;


    _contentNode.setAttribute("x", x);
    _contentNode.setAttribute("y", y);
    _contentNode.setAttribute("width", w);
    _contentNode.setAttribute("height", h);

    if ([_view scaling] === RTScaleToFit || [_view scaling] === RTScaleNone)
    {
        _contentNode.setAttribute("preserveAspectRatio", "none");
    }
    else
    {
        var ratio = "";
        switch ([_view alignment])
        {
            case RTAlignLeft:
            case RTAlignTopLeft:
            case RTAlignBottomLeft:
                ratio = "xMin";
                break;

            case RTAlignRight:
            case RTAlignTopRight:
            case RTAlignBottomRight:
                ratio = "xMax";
                break;

            default:
                ratio = "xMid";
                break;
        }

        switch ([_view alignment])
        {
            case RTAlignTop:
            case RTAlignTopLeft:
            case RTAlignTopRight:
                ratio += "YMin";
                break;

            case RTAlignBottom:
            case RTAlignBottomLeft:
            case RTAlignBottomRight:
                ratio += "YMax";
                break;

            default:
                ratio += "YMid";
                break;
        }
        _contentNode.setAttribute("preserveAspectRatio", ratio);
    }
}

@end
