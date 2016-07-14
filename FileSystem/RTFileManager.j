/*
 * RTFileManager.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@import <Foundation/CPObject.j>


RTFileErrorNone                 = 0;
RTFileErrorQuotaExceeded        = 1;
RTFileErrorNotFound             = 2;
RTFileErrorSecurity             = 3;
RTFileErrorInvalidModification  = 4;
RTFileErrorInvalidState         = 5;
RTFileErrorUnknown              = 6;

RTDirectoryEnumerationSkipsSubdirectoryDescendants = 1;

// Notification
RTFileManagerIsReady = "RTFileManagerIsReady";

RTFileMgr = nil;

@implementation RTFileManager : CPObject
{
    BOOL            _isReady    @accessors(readonly, getter = isReady);
}

+ (id)defaultManager
{
    if (!RTFileMgr)
    {
        if (window && window.navigator)
        {
            RTFileMgr = [[RTFileManager alloc] initWithHTML5FileManager];
        }
    }

    return RTFileMgr;
}

- (id)init
{
    [CPException raise:CPUnsupportedMethodException reason:"Can't init abstract class. Use concrete class"];
    return nil;
}

- (id)_init
{
    self = [super init];
    if (self)
    {
        _isReady = NO;
    }
    return self;
}

- (id)initWithHTML5FileManager
{
    RTFileMgr = [RTHTML5FileManager new];
    return RTFileMgr;
}

- (void)createDirectoryAtPath:(CPString)path
  withIntermediateDirectories:(BOOL)createIntermediates
                   attributes:(CPDictionary)attributes
                      success:(Function)success
                        error:(Function)error
{

}

- (void)createDirectoryAtPath:(CPString)path
  withIntermediateDirectories:(BOOL)createIntermediates
                   attributes:(CPDictionary)attributes
                     delegate:(id)delegate
{

}

- (void)createFileAtPath:(CPString)path
                contents:(CPData)contents
              attributes:(CPDictionary)attributes
                 success:(Function)success
                   error:(Function)error
{

}

- (void)createFileAtPath:(CPString)path
                contents:(CPData)contents
              attributes:(CPDictionary)attributes
                delegate:(id)delegate
{

}

- (void)removeItemAtPath:(CPString)path
                 success:(Function)success
                   error:(Function)error
{

}

- (void)removeItemAtPath:(CPString)path
                delegate:(id)delegate
{

}

- (void)contentsOfDirectoryAtPath:(CPString)path
                          success:(Function)success
                            error:(Function)error
{

}

- (void)contentsOfDirectoryAtPath:(CPString)path
                         delegate:(id)delegate
{

}

- (void)           enumeratorAtURL:(CPURL)url
        includingPropertiesForKeys:(CPArray)keys
                           options:(RTDirectoryEnumerationOptions)mask
                           success:(Function)success
                             error:(Function)error
{

}

- (void)           enumeratorAtURL:(CPURL)url
        includingPropertiesForKeys:(CPArray)keys
                           options:(RTDirectoryEnumerationOptions)mask
                          delegate:(id)delegate
{

}

- (void)fileExistsAtPath:(CPString)path
                 success:(Function)success
                   error:(Function)error
{

}

- (void)fileExistsAtPath:(CPString)path
                delegate:(id)delegate
{

}

- (void)copyItemAtPath:(CPString)srcPath
                toPath:(CPString)dstPath
                success:(Function)success
                  error:(Function)error
{

}

- (void)copyItemAtPath:(CPString)srcPath
                toPath:(CPString)dstPath
              delegate:(id)delegate
{

}

- (void)moveItemAtPath:(CPString)srcPath
                toPath:(CPString)dstPath
               success:(Function)success
                 error:(Function)error
{

}

- (void)moveItemAtPath:(CPString)srcPath
                toPath:(CPString)dstPath
              delegate:(id)delegate
{

}

- (void)contentsAtPath:(CPString)path
               success:(Function)success
                 error:(Function)error
{

}

- (void)contentsAtPath:(CPString)path
              delegate:(id)delegate
{

}

@end
