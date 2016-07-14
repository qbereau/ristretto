@import <Foundation/CPData.j>

@implementation CPData (FileManager)

+ (CPData)dataWithBlob:(JSObject)aBlob
{
    return [[CPData alloc] initWithBlob:aBlob];
}

- (CPData)initWithBlob:(JSObject)aBlob
{
    self = [super init];
    if (self)
    {
        self._blob = aBlob;
    }
    return self;
}

- (JSObject)blob
{
    return self._blob;
}

- (void)setBlob:(JSObject)aBlob
{
    // Note: By setting this, we indirectly clearMutableData()
    [self setRawString:nil];

    self._blob = aBlob;
}

- (void)writeToFile:(CPString)path
         atomically:(BOOL)atomically
            success:(JSObject)success
              error:(JSObject)error
{
    [[RTFileManager defaultManager] createFileAtPath:path
                                            contents:self
                                          attributes:nil
                                            success:function()
                                            {
                                                success();
                                            }
                                            error:function(e)
                                            {
                                                error(e);
                                            }];
}

- (void)writeToFile:(CPString)path
         atomically:(BOOL)atomically
         delegate:(id)delegate
{
    [[RTFileManager defaultManager] createFileAtPath:path
                                            contents:self
                                          attributes:nil
                                            success:function()
                                            {
                                                if ([delegate respondsToSelector:@selector(writeToFile:error:)])
                                                    [delegate writeToFile:path error:RTFileErrorNone];
                                            }
                                            error:function(e)
                                            {
                                                if ([delegate respondsToSelector:@selector(writeToFile:error:)])
                                                    [delegate writeToFile:path error:e];
                                            }];
}

@end
