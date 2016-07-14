@import "RTData+FileManager.j"

window.URL = window.URL || window.webkitURL;

@implementation RTImage (FileManager)

+ (RTImage)imageWithData:(CPData)aData
{
    return [[RTImage alloc] initWithData:aData];
}

- (RTImage)initWithData:(CPData)aData
{
    if (!aData)
        return nil;

    if ([aData blob])
        return [self initWithBlob:[aData blob]];
    else if ([aData base64])
        return [[RTImage alloc] initByReferencingFile:"data:image/png;base64,"+[aData base64] size:CGSizeMake(-1, -1)];
}

+ (RTImage)imageWithBlob:(JSObject)aBlob
{
    return [[RTImage alloc] initWithBlob:aBlob];
}

- (RTImage)initWithBlob:(JSObject)aBlob
{
    self = [super init];
    if (self)
    {
        [self initWithContentsOfFile:window.URL.createObjectURL(aBlob)];
    }
    return self;
}

@end
