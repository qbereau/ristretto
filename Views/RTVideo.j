/*
 * RTVideo.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

RTVideoLoadStatusInitialized    = 0;
RTVideoLoadStatusLoading        = 1;
RTVideoLoadStatusCompleted      = 2;
RTVideoLoadStatusError          = 3;

RTVideoFileTypeH264             = 0;
RTVideoFileTypeWebM             = 1;
RTVideoFileTypeOGV              = 2;
RTVideoFileTypeMP4              = 3;

@implementation RTVideo : CPObject
{
    id              _delegate;

    CPString        _mp4;
    CPString        _h264;
    CPString        _webm;
    CPString        _ogv;

    BOOL            _loop;
    BOOL            _showControls;
    BOOL             _autoPlay;
    BOOL            _preload;

    RTElement       _element;
    CGSize          _size;
    int             _duration;
    unsigned        _loadStatus;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _size       = CGSizeMake(-1, -1);
        _duration   = 0;
        _loadStatus = RTVideoLoadStatusInitialized;
        _autoPlay   = YES;
    }
    return self;
}

- (id)initByReferencingFile:(CPString)aFilename forFileType:(RTFileType)aFileType
{
    self = [self init];

    if (self)
    {
        [self _setSourceURLFromString:aFilename forFileType:aFileType];
    }

    return self;
}

- (id)initByReferencingURL:(CPURL)aURL forFileType:(RTFileType)aFileType
{
    return [self initByReferencingFile:[aURL absoluteString] forFileType:aFileType];
}

- (id)initWithContentsOfFile:(CPString)aFilename forFileType:(RTFileType)aFileType
{
    self = [self initByReferencingFile:aFilename forFileType:aFileType];

    if (self)
        [self load];

    return self;
}

- (id)initWithContentsOfURL:(CPURL)aURL forFileType:(RTFileType)aFileType
{
    return [self initWithContentsOfFile:[aURL absoluteString] forFileType:aFileType];
}

- (void)_setSourceURLFromString:(CPString)aSource forFileType:(RTFileType)aFileType
{
    var source = [CPString stringWithString:aSource];
    if (![[RTRenderer sharedRenderer] supportsFilePrefix] && [source hasPrefix:@"file:"])
        source = [source substringFromIndex:5];

    switch (aFileType)
    {
        case RTVideoFileTypeH264:
            _h264 = source;
            break;
        case RTVideoFileTypeWebM:
            _webm = source;
            break;
        case RTVideoFileTypeOGV:
            _ogv = source;
            break;
        case RTVideoFileTypeMP4:
            _mp4 = source;
            break;
    }
}

- (void)setSourceURL:(CPURL)aURL forFileType:(RTFileType)aFileType
{
    [self _setSourceURLFromString:[aURL absoluteString] forFileType:aFileType];
}

- (CPString)mp4
{
    return _mp4;
}

- (CPString)h264
{
    return _h264;
}

- (CPString)webm
{
    return _webm;
}

- (CPString)ogg
{
    return _ogv;
}

- (void)setLoop:(BOOL)aLoop
{
    _loop = aLoop;
}

- (BOOL)loop
{
    return _loop;
}

- (void)setPreload:(BOOL)aPreload
{
    _preload = aPreload;
}

- (BOOL)preload
{
    return _preload;
}

- (void)setShowControls:(BOOL)aShow
{
    _showControls = aShow;
}

- (BOOL)showControls
{
    return _showControls;
}

- (void)setAutoPlay:(BOOL)aPlay
{
    _autoPlay = aPlay;
}

- (BOOL)autoPlay
{
    return _autoPlay;
}

- (void)setDuration:(int)aDuration
{
    _duration = aDuration;
}

- (int)duration
{
    return _duration;
}

- (void)setSize:(CGSize)aSize
{
    _size = CGSizeMakeCopy(aSize);
}

- (CGSize)size
{
    return _size;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (void)setElement:(RTElement)anElement
{
    _element = anElement;
    [_element setDelegate:self];
    [_element setVideo:self];
}

- (RTElement)element
{
    return _element;
}

- (void)setVideo:(RTVideo)aVideo
{
    _video = aVideo;
}

- (RTVideo)video
{
    return _video;
}

- (void)_videoPlayerIsReady
{
    if ([_delegate respondsToSelector:@selector(_videoPlayerIsReady)])
        [_delegate _videoPlayerIsReady];
}

- (void)_videoDidLoad
{
    _loadStatus = RTVideoLoadStatusCompleted;

    if ([_delegate respondsToSelector:@selector(_videoDidLoad)])
        [_delegate _videoDidLoad];
}

- (void)_videoDidError
{
    _loadStatus = RTVideoLoadStatusError;

    if ([_delegate respondsToSelector:@selector(_videoDidError)])
        [_delegate _videoDidError];
}

@end
