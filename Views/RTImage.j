/*
 * RTImage.j - Ported from Cappuccino's CPImage
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@import <Foundation/CPBundle.j>
@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>
@import <Foundation/CPString.j>

@import "../Cappuccino/CPGeometry.j"


RTImageLoadStatusInitialized    = 0;
RTImageLoadStatusLoading        = 1;
RTImageLoadStatusCompleted      = 2;
RTImageLoadStatusCancelled      = 3;
RTImageLoadStatusInvalidData    = 4;
RTImageLoadStatusUnexpectedEOF  = 5;
RTImageLoadStatusReadError      = 6;

RTImageDidLoadNotification      = @"RTImageDidLoadNotification";

// Image Names
RTImageNameColorPanel               = @"RTImageNameColorPanel";
RTImageNameColorPanelHighlighted    = @"RTImageNameColorPanelHighlighted";

var imagesForNames = { },
    ImageDescriptionFormat = "%s {\n   filename: \"%s\",\n   size: { width:%f, height:%f }\n}";

function RTImageInBundle(aFilename, aSize, aBundle)
{
    if (!aBundle)
        aBundle = [CPBundle mainBundle];

    if (aSize)
        return [[RTImage alloc] initWithContentsOfFile:[aBundle pathForResource:aFilename] size:aSize];

    return [[RTImage alloc] initWithContentsOfFile:[aBundle pathForResource:aFilename]];
}

/*!
    @ingroup appkit
    @class RTImage

    RTImage is used to represent images in the Cappuccino framework. It supports loading
    all image types supported by the browser.

    @par Delegate Methods

    @delegate -(void)imageDidLoad:(RTImage)image;
    Called when the specified image has finished loading.
    @param image the image that loaded

    @delegate -(void)imageDidError:(RTImage)image;
    Called when the specified image had an error loading.
    @param image the image with the loading error

    @delegate -(void)imageDidAbort:(RTImage)image;
    Called when the image loading was aborted.
    @param image the image that was aborted
*/
@implementation RTImage : CPObject
{
    CGSize      _size;
    CPString    _filename;
    CPString    _name;

    id          _delegate;
    unsigned    _loadStatus;
}

- (id)init
{
    return [self initByReferencingFile:@"" size:CGSizeMake(-1, -1)];
}

/*!
    Initializes the image, by associating it with a filename. The image
    denoted in \c aFilename is not actually loaded. It will
    be loaded once needed.
    @param aFilename the file containing the image
    @param aSize the image's size
    @return the initialized image
*/
- (id)initByReferencingFile:(CPString)aFilename size:(CGSize)aSize
{
    self = [super init];

    if (self)
    {
        _size = CPSizeCreateCopy(aSize);
        _filename = aFilename;
        _loadStatus = RTImageLoadStatusInitialized;

        if (![[RTRenderer sharedRenderer] supportsFilePrefix] && [_filename substringToIndex:5] === "file:")
            _filename = [_filename substringFromIndex:5];
    }

    return self;
}

- (id)initByReferencingURL:(CPURL)aURL size:(CGSize)aSize
{
    return [self initByReferencingFile:[aURL absoluteString] size:aSize];
}

/*!
    Initializes the image. Loads the specified image into memory.
    @param aFilename the image to load
    @param aSize the size of the image
    @return the initialized image.
*/
- (id)initWithContentsOfFile:(CPString)aFilename size:(CGSize)aSize
{
    self = [self initByReferencingFile:aFilename size:aSize];

    if (self)
        [self load];

    return self;
}

- (id)initWithContentsOfURL:(CPURL)aURL size:(CGSize)aSize
{
    return [self initWithContentsOfFile:[aURL absoluteString] size:aSize];
}

/*!
    Initializes the receiver with the contents of the specified
    image file. The method loads the data into memory.
    @param aFilename the file name of the image
    @return the initialized image
*/
- (id)initWithContentsOfFile:(CPString)aFilename
{
    self = [self initByReferencingFile:aFilename size:CGSizeMake(-1, -1)];

    if (self)
        [self load];

    return self;
}

- (id)initWithContentsOfURL:(CPURL)aURL
{
    return [self initByReferencingFile:[aURL absoluteString]];
}

/*!
    Returns the path of the file associated with this image.
*/
- (CPString)filename
{
    return _filename;
}

/*!
    Sets the size of the image.
    @param the size of the image
*/
- (void)setSize:(CGSize)aSize
{
    _size = CGSizeMakeCopy(aSize);
}

/*!
    Returns the size of the image
*/
- (CGSize)size
{
    return _size;
}

+ (id)imageNamed:(CPString)aName
{
    var image = imagesForNames[aName];

    if (image)
        return image;

    return nil;
}

- (BOOL)setName:(CPString)aName
{
    if (_name === aName)
        return YES;

    if (imagesForNames[aName])
        return NO;

    _name = aName;

    imagesForNames[aName] = self;

    return YES;
}

- (CPString)name
{
    return _name;
}

/*!
    Sets the receiver's delegate.
    @param the delegate
*/
- (void)setDelegate:(id)aDelegate
{

    _delegate = aDelegate;
}

/*!
    Returns the receiver's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Returns the load status, which will be RTImageLoadStatusCompleted if the image data has already been loaded.
*/
- (unsigned)loadStatus
{
    return _loadStatus;
}

- (void)setLoadStatus:(unsigned)aLoadStatus
{
    _loadStatus = aLoadStatus;
}

/*!
    Loads the image data from the file into memory. You
    should not call this method directly. Instead use
    one of the initializers.
*/

- (void)load
{
    if (_loadStatus == RTImageLoadStatusLoading)
        return;

    _loadStatus = RTImageLoadStatusLoading;
}

- (BOOL)isThreePartImage
{
    return NO;
}

- (BOOL)isNinePartImage
{
    return NO;
}

- (CPString)description
{
    var filename = [self filename],
        size = [self size];

    if (filename.indexOf("data:") === 0)
    {
        var index = filename.indexOf(",");

        if (index > 0)
            filename = [CPString stringWithFormat:@"%s,%s...%s", filename.substr(0, index), filename.substr(index + 1, 10), filename.substr(filename.length - 10)];
        else
            filename = "data:<unknown type>";
    }

    return [CPString stringWithFormat:ImageDescriptionFormat, [super description], filename, size.width, size.height];
}

- (void)_imageDidLoad
{
    _loadStatus = RTImageLoadStatusCompleted;

    // Release blob resource if file's a blob
    if ([_filename hasPrefix:'blob:'])
        window.URL.revokeObjectURL(_filename);
}

- (void)_imageDidError
{
    _loadStatus = RTImageLoadStatusReadError;
}

/* @ignore */
- (void)_imageDidAbort
{
    _loadStatus = RTImageLoadStatusCancelled;
}

@end

@implementation RTImage (CPCoding)

/*!
    Initializes the image with data from a coder.
    @param aCoder the coder from which to read the image data
    @return the initialized image
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithContentsOfFile:[aCoder decodeObjectForKey:@"CPFilename"] size:[aCoder decodeSizeForKey:@"CPSize"]];
}

/*!
    Writes the image data from memory into the coder.
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_filename forKey:@"CPFilename"];
    [aCoder encodeSize:_size forKey:@"CPSize"];
}

@end

@implementation CPThreePartImage : CPObject
{
    CPArray _imageSlices;
    BOOL    _isVertical;
}

- (id)initWithImageSlices:(CPArray)imageSlices isVertical:(BOOL)isVertical
{
    self = [super init];

    if (self)
    {
        _imageSlices = imageSlices;
        _isVertical = isVertical;
    }

    return self;
}

- (CPString)filename
{
    return @"";
}

- (CPArray)imageSlices
{
    return _imageSlices;
}

- (BOOL)isVertical
{
    return _isVertical;
}

- (BOOL)isThreePartImage
{
    return YES;
}

- (BOOL)isNinePartImage
{
    return NO;
}

@end

var CPThreePartImageImageSlicesKey  = @"CPThreePartImageImageSlicesKey",
    CPThreePartImageIsVerticalKey   = @"CPThreePartImageIsVerticalKey";

@implementation CPThreePartImage (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _imageSlices = [aCoder decodeObjectForKey:CPThreePartImageImageSlicesKey];
        _isVertical = [aCoder decodeBoolForKey:CPThreePartImageIsVerticalKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_imageSlices forKey:CPThreePartImageImageSlicesKey];
    [aCoder encodeBool:_isVertical forKey:CPThreePartImageIsVerticalKey];
}

@end


@implementation CPNinePartImage : CPObject
{
    CPArray _imageSlices;
}

- (id)initWithImageSlices:(CPArray)imageSlices
{
    self = [super init];

    if (self)
        _imageSlices = imageSlices;

    return self;
}

- (CPString)filename
{
    return @"";
}

- (CPArray)imageSlices
{
    return _imageSlices;
}

- (BOOL)isThreePartImage
{
    return NO;
}

- (BOOL)isNinePartImage
{
    return YES;
}

@end

var CPNinePartImageImageSlicesKey   = @"CPNinePartImageImageSlicesKey";

@implementation CPNinePartImage (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
        _imageSlices = [aCoder decodeObjectForKey:CPNinePartImageImageSlicesKey];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_imageSlices forKey:CPNinePartImageImageSlicesKey];
}

@end
