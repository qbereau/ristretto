@import "../Views/RTImageView.j"
@import "../Views/RTVideoView.j"

var SHARED_CACHE_MANAGER;

@implementation RTCacheManager : CPObject
{
    RTFileManager       _fileManager;
}

+ (RTCacheManager)sharedManager
{
    if (!SHARED_CACHE_MANAGER)
        SHARED_CACHE_MANAGER = [self new];

    return SHARED_CACHE_MANAGER;
}

- (id)init
{
    self = [super init];

    if (!self)
        return nil;

    _fileManager = [RTFileManager defaultManager];

    if (![_fileManager isReady])
    {
        [[CPNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fileManagerIsReady:)
                                                     name:RTFileManagerIsReady
                                                   object:nil];
        _fileManagerQueue = [CPArray new];
    }

    return self;
}

- (void)cacheURL:(CPURL)anURL success:(Function /* (CPData urlDATA) */)successCallback
{
    var loadURL = function()
    {
        var absString = [anURL absoluteString],
            filename = [CPString stringWithFormat:@"%@.%@", [[CPData dataWithRawString:absString] base64], [absString pathExtension]];

        var fileExists = function()
        {
            [_fileManager contentsAtPath:filename
                                 success:function(data)
                                 {
                                     successCallback(data);
                                 }
                                 error:function(e)
                                 {
                                     console.log("error");
                                 }];
        };

        var fileDoesNotExist = function()
        {
            var req = new CFHTTPRequest();
            req.onsuccess = function(data)
            {
                console.log(data);
                data = [CPData dataWithBlob:data];
                [data writeToFile:filename
                       atomically:NO
                          success:function()
                          {
                              console.log("yay");
                          }
                          error:function(e)
                          {
                              console.log("error");
                          }];
                successCallback(data);
            };
            req.open("GET", absString, true);
            req.send(null);
        };
        [_fileManager fileExistsAtPath:filename
                               success:fileExists
                               error:fileDoesNotExist];
    };

    if (_fileManagerQueue)
        [_fileManagerQueue addObject:loadURL];
    else
        loadURL();

}

- (void)fileManagerIsReady:(CPNotification)aNotif
{
    for (var i = [_fileManagerQueue count] - 1; i >= 0; i--)
    {
        var func = [_fileManagerQueue objectAtIndex:i];
        func();
    }
    _fileManagerQueue = nil;
}


@end

@implementation RTImageView (RTCacheManager)

- (void)setImageURL:(CPURL)anURL
{
    [[RTCacheManager sharedManager] cacheURL:anURL success:function(data)
    {
        [self setImage:[RTImage imageWithData:data]];
    }];
}

@end

@implementation RTVideoView (RTCacheManager)


- (void)setVideoURL:(CPURL)anURL
{
    [[RTCacheManager sharedManager] cacheURL:anURL success:function(data)
    {
        console.log(data);
    }];
}

@end

