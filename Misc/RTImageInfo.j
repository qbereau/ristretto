/*
 * RTImageInfo.j - Ported from http://blog.nihilogic.dk/
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

/*
 * Binary Ajax 0.1.5
 * Copyright (c) 2008 Jacob Seidelin, cupboy@gmail.com, http://blog.nihilogic.dk/
 * MIT License [http://www.opensource.org/licenses/mit-license.php]
 */

@import <Foundation/CPString.j>
@import <Foundation/CPURLConnection.j>

@implementation RTBinaryFile : CPObject
{
    String          data;
    int             dataOffset;
    int             dataLength;
}

- (id)initWithData:(String)aData offset:(int)anOffset
{
    if (self = [super init])
    {
        data = aData;

        dataOffset = anOffset;
        dataLength = data.length;
    }
    return self;
}

- (String)getRawData
{
    return data;
}

- (String)getByteAt:(int)iOffset
{
    return data.charCodeAt(iOffset + dataOffset) & 0xFF;
}

- (int)getLength
{
    return dataLength;
}

- (String)getSByteAt:(int)iOffset
{
    var iByte = [self getByteAt:iOffset];
    if (iByte > 127)
        return iByte - 256;
    else
        return iByte;
}

- (int)getShortAt:(int)iOffset isBigEndian:(BOOL)bBigEndian
{
    var iShort = bBigEndian ?
        ([self getByteAt:iOffset] << 8) + [self getByteAt:iOffset + 1]
        : ([self getByteAt:iOffset + 1] << 8) + [self getByteAt:iOffset]
    if (iShort < 0) iShort += 65536;
    return iShort;
}

- (int)getSShortAt:(int)iOffset isBigEndian:(BOOL)bBigEndian
{
    var iUShort = [self getShortAt:iOffset isBigEndian:bBigEndian];
    if (iUShort > 32767)
        return iUShort - 65536;
    else
    return iUShort;
}

- (int)getLongAt:(int)iOffset isBigEndian:(BOOL)bBigEndian
{
    var iByte1 = [self getByteAt:iOffset],
        iByte2 = [self getByteAt:iOffset + 1],
        iByte3 = [self getByteAt:iOffset + 2],
        iByte4 = [self getByteAt:iOffset + 3];

    var iLong = bBigEndian ?
        (((((iByte1 << 8) + iByte2) << 8) + iByte3) << 8) + iByte4
        : (((((iByte4 << 8) + iByte3) << 8) + iByte2) << 8) + iByte1;
    if (iLong < 0) iLong += 4294967296;
    return iLong;
}

- (int)getSLongAt:(int)iOffset isBigEndian:(BOOL)bBigEndian
{
    var iULong = [self getLongAt:iOffset isBigEndian:bBigEndian];
    if (iULong > 2147483647)
        return iULong - 4294967296;
    else
        return iULong;
}

- (String)getStringAt:(int)iOffset length:(int)iLength
{
    var aStr = [];
    for (var i=iOffset,j=0;i<iOffset+iLength;i++,j++) {
        aStr[j] = String.fromCharCode([self getByteAt:i]);
    }
    return aStr.join("");
}

- (String)getCharAt:(int)iOffset
{
    return String.fromCharCode([self getByteAt:iOffset]);
}

- (String)toBase64
{
    return window.btoa(data);
}

- (void)fromBase64:(String)strBase64
{
    data = window.atob(strBase64);
}

@end

@implementation RTBinaryAjax : CPObject
{
    id              delegate;
    CPString        binaryResponse;
    int             fileSize;
}

+ (void)requestWithURL:(CPString)aURL delegate:(id)aDelegate
{
    return [[RTBinaryAjax alloc] initWithURL:aURL delegate:aDelegate];
}

- (id)initWithURL:(CPString)aURL delegate:(id)aDelegate
{
    if (self = [super init])
    {
        delegate    = aDelegate;

        var req     = [CPURLRequest requestWithURL:aURL],
            conn    = [CPURLConnection connectionWithRequest:req delegate:self];
        if (!CPBrowserIsOperatingSystem(CPHMP100) && !CPBrowserIsOperatingSystem(CPHMP200))
            [conn _HTTPRequest]._nativeRequest.overrideMimeType('text/plain; charset=x-user-defined');

        [conn start];
    }
    return self;
}

- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (id)delegate
{
    return delegate;
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    binaryResponse = [[RTBinaryFile alloc] initWithData:data offset:0];

    if ([delegate respondsToSelector:@selector(receivedBinaryResponse:)])
        [delegate receivedBinaryResponse:binaryResponse];
}

- (void)connection:(CPURLConnection)connection didFailWithError:(CPString)error
{
    CPLog("error");
}

@end

 /*
 * ImageInfo 0.1.2 - A JavaScript library for reading image metadata.
 * Copyright (c) 2008 Jacob Seidelin, jseidelin@nihilogic.dk, http://blog.nihilogic.dk/
 * MIT License [http://www.nihilogic.dk/licenses/mit-license.txt]
 */

@implementation RTImageInfo : CPObject
{
    id          delegate;
    CPArray     files;
}

- (id)init
{
    if (self = [super init])
    {
        files = [];
    }
    return self;
}

- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (id)delegate
{
    return delegate;
}

- (void)loadInfo:(CPString)url
{
    [self _readFileData:url];
}

- (void)_readFileData:(CPString)url
{
    [RTBinaryAjax requestWithURL:url delegate:self];
}

- (JSObject)_readInfoFromData:(RTBinaryFile)data
{
    var offset = 0;

    if ([data getByteAt:0] == 0xFF && [data getByteAt:1] == 0xD8) {
        return [self _readJPEGInfo:data];
    }
    if ([data getByteAt:0] == 0x89 && [data getStringAt:1 length:3] == "PNG") {
        return [self _readPNGInfo:data];
    }
    if ([data getStringAt:0 length:3] == "GIF") {
        return [self _readGIFInfo:data];
    }
    if ([data getByteAt:0] == 0x42 && [data getByteAt:1] == 0x4D) {
        return [self _readBMPInfo:data];
    }

    return {
        format : "UNKNOWN"
    };
}

- (JSObject)_readJPEGInfo:(RTBinaryFile)data
{
    var w = 0;
    var h = 0;
    var comps = 0;
    var len = [data getLength];
    var offset = 2;
    while (offset < len) {
        var marker = [data getShortAt:offset isBigEndian:true];
        offset += 2;
        if (marker == 0xFFC0) {
            h = [data getShortAt:offset + 3 isBigEndian:true];
            w = [data getShortAt:offset + 5 isBigEndian:true];
            comps = [data getByteAt:offset + 7]
            break;
        } else {
            offset += [data getShortAt:offset isBigEndian:true];
        }
    }

    return {
        format : "JPEG",
        version : "",
        width : w,
        height : h,
        bpp : comps * 8,
        alpha : false
    }
}

- (JSObject)_readBMPInfo:(RTBinaryFile)data
{
    var w = [data getLongAt:18 isBigEndian:NO];
    var h = [data getLongAt:22 isBigEndian:NO];
    var bpp = [data getShortAt:28 isBigEndian:NO];
    return {
        format : "BMP",
        version : "",
        width : w,
        height : h,
        bpp : bpp,
        alpha : false
    }
}

- (JSObject)_readGIFInfo:(RTBinaryFile)data
{
    var version = [data getStringAt:3 length:3];
    var w = [data getShortAt:6 isBigEndian:NO];
    var h = [data getShortAt:8 isBigEndian:NO];

    var bpp = (([data getByteAt:10] >> 4) & 7) + 1;

    return {
        format : "GIF",
        version : version,
        width : w,
        height : h,
        bpp : bpp,
        alpha : false
    }
}

- (JSObject)_readPNGInfo:(RTBinaryFile)data
{
    var w = [data getLongAt:16 isBigEndian:true];
    var h = [data getLongAt:20 isBigEndian:true];

    var bpc = [data getByteAt:24];
    var ct = [data getByteAt:25];

    var bpp = bpc;
    if (ct == 4) bpp *= 2;
    if (ct == 2) bpp *= 3;
    if (ct == 6) bpp *= 4;

    var alpha = [data getByteAt:25] >= 4;

    return {
        format : "PNG",
        version : "",
        width : w,
        height : h,
        bpp : bpp,
        alpha : alpha
    }
}

- (void)receivedBinaryResponse:(RTBinaryFile)aBinaryFile
{
    var obj = [self _readInfoFromData:aBinaryFile];
    if ([delegate respondsToSelector:@selector(receivedImageInformation:)])
        [delegate receivedImageInformation:obj];
}

@end
