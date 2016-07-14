/*
 * RTHTML5FileManager.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@import "RTFileManager.j"

var DEFAULT_STORAGE_REQUEST_SIZE = 1024*1024*1024; // 1GB

BlobBuilder = window.MozBlobBuilder || window.WebKitBlobBuilder || window.BlobBuilder;

@implementation RTHTML5FileManager : RTFileManager
{
    FileSystem          _fs;

    int                 _deepEnumeratorCounter;
}

- (id)init
{
    self = [super _init];
    if (self)
    {
        if (CPBrowserIs(CPChromeBrowser))
        {
            window.webkitStorageInfo.queryUsageAndQuota(PERSISTENT,
                function(used, remaining)
                {
                    var storageSize = DEFAULT_STORAGE_REQUEST_SIZE;
                    if (DEFAULT_STORAGE_REQUEST_SIZE > remaining)
                        storageSize = remaining;

                    window.webkitStorageInfo.requestQuota(PERSISTENT, storageSize,
                        function(grantedBytes)
                        {
                            window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem;
                            window.requestFileSystem(PERSISTENT, storageSize,
                                function(fs)
                                {
                                    _fs = fs;

                                    _isReady = YES;
                                    [[CPNotificationCenter defaultCenter] postNotificationName:RTFileManagerIsReady
                                                                                        object:self];
                                }
                            );
                        },
                        function(e)
                        {
                            console.log('Error', e);
                        }
                    );
                },
                function(e)
                {
                    console.log('Error', e);
                }
            );
        }
    }
    return self;
}

- (int)_codeFromError:(FileError)anError
{
    if (!anError)
        return RTFileErrorUnknown;

    switch (anError.code)
    {
        case FileError.QUOTA_EXCEEDED_ERR:
          return RTFileErrorQuotaExceeded;
        case FileError.NOT_FOUND_ERR:
          return RTFileErrorNotFound;
        case FileError.SECURITY_ERR:
          return RTFileErrorSecurity;
        case FileError.INVALID_MODIFICATION_ERR:
          return RTFileErrorInvalidModification;
        case FileError.INVALID_STATE_ERR:
          return RTFileErrorInvalidState
        default:
          return RTFileErrorNone;
    };
}

- (CPString)_fixedPath:(CPString)aPath
{
    if (!aPath || aPath.length == 0)
        return "/";

    var fixedPath = [CPString stringWithString:aPath];
    if (fixedPath.substr(aPath.length - 1, 1) !== '/')
        fixedPath += "/";
    return fixedPath.split('/').slice(0, -1).join('/');
}

- (BOOL)_isRoot:(CPString)path
{
    if (!path)
        return NO;

    return !(path.split('/').length > 1);
}

- (CPString)_parentDir:(CPString)path
{
    if ([self _isRoot:path])
        return "";
    return path.split('/').slice(0, -1).join('/');
}

- (CPArray)_components:(CPString)path
{
    return [self _fixedPath:path].split('/').filter(function(el){return el.length > 0;});
}

- (CPString)_fileName:(CPString)path
{
    var cmp = [self _components:path];
    return (cmp.length > 1) ? cmp[cmp.length - 1] : cmp[0];
}

- (void)_createDir:(DirectoryEntry)rootDir
       recursively:(BOOL)recursively
           folders:(CPArray)folders
              path:(CPString)path
          callback:(Function)callback
{
    if (folders[0] == '.' || folders[0] == '')
        folders = folders.slice(1);

    rootDir.getDirectory(folders[0], {create: (rootDir.fullPath !== _fs.root.fullPath && !recursively && folders.length > 1) ? NO : YES },
        function(dirEntry)
        {
            if (folders.length)
            {
                return [self _createDir:dirEntry
                            recursively:recursively
                                folders:folders.slice(1)
                                   path:path
                               callback:callback];
            }
            else
            {
                callback(YES, nil);
            }
        },
        function(e)
        {
            callback(NO, e);
        }
    );
}

- (void)createDirectoryAtPath:(CPString)path
  withIntermediateDirectories:(BOOL)createIntermediates
                   attributes:(CPDictionary)attributes
                      success:(Function)success
                        error:(Function)error
{
    [self _createDir:_fs.root
         recursively:createIntermediates
             folders:path.split('/').filter(function(el){return el.length > 0;})
                path:path
            callback:function(res, err){

                if (err)
                {
                    error(err);
                }
                else
                {
                    success();
                }
            }];
}

- (void)createDirectoryAtPath:(CPString)path
  withIntermediateDirectories:(BOOL)createIntermediates
                   attributes:(CPDictionary)attributes
                     delegate:(id)delegate
{
    [self createDirectoryAtPath:path
    withIntermediateDirectories:createIntermediates
                     attributes:attributes
                     success:function()
                     {
                        if ([delegate respondsToSelector:@selector(createDirectoryAtPath:didCreate:error:)])
                            [delegate createDirectoryAtPath:path didCreate:YES error:RTFileErrorNone];
                     }
                     error:function(e)
                     {
                        if ([delegate respondsToSelector:@selector(createDirectoryAtPath:didCreate:error:)])
                            [delegate createDirectoryAtPath:path didCreate:NO error:[self _codeFromError:e]];
                     }];
}

- (void)createFileAtPath:(CPString)path
                contents:(CPData)contents
              attributes:(CPDictionary)attributes
                 success:(Function)success
                   error:(Function)error
{
    var cmp         = [self _components:path];
    var createFile = function()
        {
            [self _gotoDir:[self _parentDir:path]
                  dirEntry:_fs.root
                   success:function(dirEntry)
                    {
                        dirEntry.getFile(cmp[cmp.length - 1], {create: true, exclusive: false},
                            function(fileEntry)
                            {
                                fileEntry.createWriter(
                                    function(fileWriter)
                                    {
                                        fileWriter.onwriteend = function(e) {
                                            success();
                                        };

                                        fileWriter.onerror = function(e) {
                                            error(e);
                                        };

                                        if ([contents blob])
                                        {
                                            fileWriter.write([contents blob]);
                                        }
                                        else
                                        {
                                            bb.append([contents rawString]);
                                            fileWriter.write(bb.getBlob('text/plain'));
                                        }

                                    },
                                    function(e)
                                    {
                                        error(e);
                                    }
                                );
                            },
                            function(e)
                            {
                                error(e);
                            }
                        );
                    }
                    error:function(e)
                    {
                        error(e);
                    }
            ];
        }

    // Create all dir tree first then create the file
    if (cmp.length > 1)
    {
        [self _createDir:_fs.root
             recursively:YES
                 folders:cmp.slice(0, -1)
                    path:path
                callback:function(res, err){
                    if (res)
                        createFile();
                    else
                    {
                        error(err);
                    }
                }];
    }
    else
    {
        createFile();
    }
}

- (void)createFileAtPath:(CPString)path
                contents:(CPData)contents
              attributes:(CPDictionary)attributes
                delegate:(id)delegate
{
    [self createFileAtPath:path
                  contents:contents
                attributes:attributes
                success:function()
                {
                    if ([delegate respondsToSelector:@selector(createFileAtPath:didCreate:error:)])
                        [delegate createFileAtPath:path didCreate:YES error:RTFileErrorNone];
                }
                error:function(e)
                {
                    if ([delegate respondsToSelector:@selector(createFileAtPath:didCreate:error:)])
                        [delegate createFileAtPath:path didCreate:NO error:err];
                }];
}

- (void)removeItemAtPath:(CPString)path
                 success:(Function)success
                   error:(Function)error
{
    // Check if we are removing the root folder or one of it's directory
    // or if we need to go deeper
    if (path === "" || path === "/")
    {
        [self _contentsOfDirectoryAtPath:""
                           nativeObjects:YES
                                success:function(entries)
                                {
                                    var allDeleted = [entries count];
                                    for (var i = 0; i < [entries count]; ++i)
                                    {
                                        var entry = [entries objectAtIndex:i];
                                        if (entry.isDirectory)
                                        {
                                            entry.removeRecursively(
                                                function()
                                                {
                                                    --allDeleted;
                                                    if (allDeleted == 0)
                                                        success();
                                                },
                                                function(e)
                                                {
                                                    error(e);
                                                });
                                        }
                                        else
                                        {
                                            entry.remove(
                                                function()
                                                {
                                                    --allDeleted;

                                                    if (allDeleted == 0)
                                                        success();
                                                },
                                                function(e)
                                                {
                                                    error(e);
                                                });
                                        }
                                    }
                                }
                                error:function(e)
                                {
                                   error(e);
                                }];
    }
    else
    {
        [self _gotoDir:[self _parentDir:path]
              dirEntry:_fs.root
               success:function(dirEntry)
               {
                    var name = [self _fileName:path];
                    dirEntry.getFile(name, {create: false},
                        function(fileEntry)
                        {
                            fileEntry.remove(
                                function()
                                {
                                    success();
                                },
                                function(e)
                                {
                                    error(e);
                                }
                            );
                        },
                        function(e)
                        {
                            // Maybe it's not a file but a dir
                            dirEntry.getDirectory(name, {create: false},
                                function(subDirEntry)
                                {
                                    subDirEntry.removeRecursively(
                                        function()
                                        {
                                            success();
                                        },
                                        function(e)
                                        {
                                            error(e);
                                        }
                                    );
                                },
                                function(e)
                                {
                                    error(e);
                                }
                            );
                        }
                    );
               }
               error:function(e)
               {
                    error(e);
               }];
    }
}

- (void)removeItemAtPath:(CPString)path
                delegate:(id)delegate
{
    [self removeItemAtPath:path
                    success:function()
                    {
                        if ([delegate respondsToSelector:@selector(removeItemAtPath:didRemove:error:)])
                            [delegate removeItemAtPath:path didRemove:YES error:RTFileErrorNone];
                    }
                    error:function(e)
                    {
                        if ([delegate respondsToSelector:@selector(removeItemAtPath:didRemove:error:)])
                            [delegate removeItemAtPath:path didRemove:NO error:[self _codeFromError:e]];
                    }];
}

- (void)_gotoDir:(CPString)path
        dirEntry:(DirectoryEntry)dirEntry
         success:(Function)success
           error:(Function)error
{
    if (!path || path.length == 0 || path.split('/').length < 1)
    {
        success(dirEntry);
    }
    else
    {
        var components = path.split('/');
        dirEntry.getDirectory(components[0], {create:NO},
            function(dirEntry)
            {
                if (components.length == 1)
                {
                    success(dirEntry);
                }
                else
                {
                    [self _gotoDir:components.slice(1).join('/')
                          dirEntry:dirEntry
                           success:success
                             error:error];
                }
            },
            function(e)
            {
                error(e);
            });
    }
}

// nativeObject is used to determine is we should return File/Dir Entries or just CPStrings
- (void)_contentsOfDirectoryAtPath:(CPString)path
                     nativeObjects:(BOOL)nativeObjects
                           success:(Function)success
                             error:(Function)error
{
    [self _gotoDir:[self _parentDir:path]
            dirEntry:_fs.root
            success:function(dirEntry)
            {
                dirEntry.getDirectory([self _fixedPath:path], {create:NO},
                    function(dirEntry)
                    {
                        var dirReader   = dirEntry.createReader(),
                            entries     = [];

                        // Call the reader.readEntries() until no more results are returned.
                        var readEntries = function() {
                            dirReader.readEntries(
                                function(results) {
                                    if (!results.length)
                                    {
                                        success(entries);
                                    }
                                    else
                                    {
                                        for (var i = 0; i < results.length; ++i)
                                        {
                                            if (nativeObjects)
                                                entries.push(results[i]);
                                            else
                                                entries.push(results[i].fullPath);
                                        }
                                        readEntries();
                                    }
                                },
                                function(e)
                                {
                                    error(e);
                                }
                            );
                        };

                        readEntries();
                    },
                    function(e)
                    {
                        error(e);
                    }
                );
            }
            error:function(e)
            {
                error(e);
            }];
}

- (void)contentsOfDirectoryAtPath:(CPString)path
                          success:(Function)success
                            error:(Function)error
{
    [self _contentsOfDirectoryAtPath:path
                       nativeObjects:NO
                             success:success
                               error:error];
}

- (void)contentsOfDirectoryAtPath:(CPString)path
                         delegate:(id)delegate
{
    [self contentsOfDirectoryAtPath:path
                            success:function(entries)
                            {
                                if ([delegate respondsToSelector:@selector(contentsOfDirectoryAtPath:results:error:)])
                                    [delegate contentsOfDirectoryAtPath:path results:entries error:RTFileErrorNone];
                            }
                            error:function(e)
                            {
                                if ([delegate respondsToSelector:@selector(contentsOfDirectoryAtPath:results:error:)])
                                    [delegate contentsOfDirectoryAtPath:path results:nil error:[self _codeFromError:e]];
                            }];
}

- (void)           enumeratorAtURL:(CPURL)url
                           results:(CPArray)results
        includingPropertiesForKeys:(CPArray)keys
                           options:(RTDirectoryEnumerationOptions)mask
                           success:(Function)success
                             error:(Function)error
{
    ++_deepEnumeratorCounter;
    [self _contentsOfDirectoryAtPath:[url path]
                       nativeObjects:YES
                            success:function(entries)
                            {
                                --_deepEnumeratorCounter;

                                for (var i = 0; i < [entries count]; ++i)
                                {
                                    var entry = [entries objectAtIndex:i];
                                    if (entry.isDirectory)
                                    {
                                        [results addObject:[CPURL URLWithString:entry.fullPath]];

                                        if (!(mask & RTDirectoryEnumerationSkipsSubdirectoryDescendants))
                                        {
                                            [self              enumeratorAtURL:[CPURL URLWithString:entry.fullPath]
                                                                       results:results
                                                    includingPropertiesForKeys:keys
                                                                       options:mask
                                                                       success:success
                                                                         error:error];
                                        }
                                    }
                                }

                                if (_deepEnumeratorCounter == 0)
                                {
                                    success(results);
                                }
                            }
                            error:function(e)
                            {
                                error(e);
                            }];
}

- (void)           enumeratorAtURL:(CPURL)url
        includingPropertiesForKeys:(CPArray)keys
                           options:(RTDirectoryEnumerationOptions)mask
                          delegate:(id)delegate
{
    [self              enumeratorAtURL:url
                               results:[]
            includingPropertiesForKeys:keys
                               options:mask
                               success:function(res)
                               {
                                    if ([delegate respondsToSelector:@selector(enumeratorAtURL:enumerator:error:)])
                                        [delegate enumeratorAtURL:url enumerator:res error:RTFileErrorNone];
                               }
                               error:function(e)
                               {
                                    if ([delegate respondsToSelector:@selector(enumeratorAtURL:enumerator:error:)])
                                        [delegate enumeratorAtURL:url enumerator:nil error:[self _codeFromError:e]];
                               }];
}

- (void)fileExistsAtPath:(CPString)path
                 success:(Function)success
                   error:(Function)error
{
    [self _gotoDir:[self _parentDir:path]
          dirEntry:_fs.root
          success:function(dirEntry)
          {
            var name = [self _fileName:path];
            dirEntry.getFile(name, {create:NO},
                function(fileEntry)
                {
                    success(NO);
                },
                function(e)
                {
                    // File does not exist, maybe folder does
                    dirEntry.getDirectory(name, {create:NO},
                        function(dirEntry)
                        {
                            success(YES);
                        },
                        function(e)
                        {
                            error(e);
                        });
                });

          }
          error:function(e)
          {
                error(e);
          }];
}

- (void)fileExistsAtPath:(CPString)path
                delegate:(id)delegate
{
    [self fileExistsAtPath:path
                    success:function(isFolder)
                    {
                        if ([delegate respondsToSelector:@selector(fileExistsAtPath:doesExist:isFolder:error:)])
                            [delegate fileExistsAtPath:path doesExist:YES isFolder:isFolder error:RTFileErrorNone];
                    }
                    error:function(e)
                    {
                        if ([delegate respondsToSelector:@selector(fileExistsAtPath:doesExist:isFolder:error:)])
                            [delegate fileExistsAtPath:path doesExist:NO isFolder:NO error:[self _codeFromError:e]];
                    }];
}

- (void)copyItemAtPath:(CPString)srcPath
                toPath:(CPString)dstPath
               success:(JSObject)success
                 error:(JSObject)error
{
    [self _copyOrMoveItemAtPath:srcPath
                         toPath:dstPath
                     shouldMove:NO
                        success:function()
                        {
                            success();
                        }
                        error:function(e)
                        {
                            error(e);
                        }];
}

- (void)copyItemAtPath:(CPString)srcPath
                toPath:(CPString)dstPath
              delegate:(id)delegate
{
    [self copyItemAtPath:srcPath
                  toPath:dstPath
                success:function()
                {
                    if ([delegate respondsToSelector:@selector(copyItemAtPath:toPath:didCopy:error:)])
                        [delegate copyItemAtPath:srcPath toPath:dstPath didCopy:YES error:RTFileErrorNone];
                }
                error:function(e)
                {
                    if ([delegate respondsToSelector:@selector(copyItemAtPath:toPath:didCopy:error:)])
                        [delegate copyItemAtPath:srcPath toPath:dstPath didCopy:NO error:[self _codeFromError:e]];
                }];
}

- (void)moveItemAtPath:(CPString)srcPath
                toPath:(CPString)dstPath
               success:(Function)success
                 error:(Function)error
{
    [self _copyOrMoveItemAtPath:srcPath
                         toPath:dstPath
                     shouldMove:YES
                        success:function()
                        {
                            success();
                        }
                        error:function(e)
                        {
                            error(e);
                        }];
}

- (void)moveItemAtPath:(CPString)srcPath
                toPath:(CPString)dstPath
              delegate:(id)delegate
{
    [self moveItemAtPath:srcPath
                  toPath:dstPath
                success:function()
                {
                    if ([delegate respondsToSelector:@selector(moveItemAtPath:toPath:didMove:error:)])
                        [delegate moveItemAtPath:srcPath toPath:dstPath didMove:YES error:RTFileErrorNone];
                }
                error:function(e)
                {
                    if ([delegate respondsToSelector:@selector(moveItemAtPath:toPath:didMove:error:)])
                        [delegate moveItemAtPath:srcPath toPath:dstPath didMove:NO error:[self _codeFromError:e]];
                }];
}

- (void)_copyOrMoveItemAtPath:(CPString)srcPath
                       toPath:(CPString)dstPath
                   shouldMove:(BOOL)move
                      success:(Function)success
                        error:(Function)error
{
    var cmpSrc = [self _components:srcPath],
        cmpDst = [self _components:dstPath];

    var copyTo = function(srcFileDirEntry, dstDirEntry)
    {
        srcFileDirEntry.copyTo(dstDirEntry, nil,
            function()
            {
                success();
            },
            function(e)
            {
                error(e);
            });
    }

    var moveTo = function(srcFileDirEntry, dstDirEntry, newName)
    {
        srcFileDirEntry.moveTo(dstDirEntry, newName,
            function()
            {
                success();
            },
            function(e)
            {
                error(e);
            });
    }

    var createDirAndCopyOrMove = function(destination, folders, sourceEntry, destinationEntry, shouldMove)
    {
        [self _createDir:_fs.root
             recursively:YES
                 folders:folders
                    path:destination
                callback:function(res, err)
                {
                    if (res)
                    {
                        [self   _gotoDir:[self _parentDir:destination]
                                dirEntry:_fs.root
                                 success:function(destinationEntry)
                                 {
                                    if (shouldMove)
                                        moveTo(sourceEntry, destinationEntry);
                                    else
                                        copyTo(sourceEntry, destinationEntry);
                                 }
                                 error:function(e)
                                 {
                                    error(e);
                                 }];
                    }
                    else
                    {
                        error(nil);
                    }
                }];
    }

    [self   _gotoDir:[self _parentDir:srcPath]
            dirEntry:_fs.root
            success:function(srcDirEntry)
            {
                // Check if src is a file
                var srcName = [self _fileName:srcPath];
                srcDirEntry.getFile(srcName, {create:NO},
                    function(srcFileEntry)
                    {
                        var outPath = [CPString stringWithString:dstPath];
                        if ([outPath characterAtIndex:[outPath length] - 1] !== '/' && move)
                            outPath = [self _parentDir:outPath];

                        [self   _gotoDir:outPath
                                dirEntry:_fs.root
                                success:function(dstDirEntry)
                                {
                                    if (move)
                                    {
                                        var newName = nil;
                                        if ([dstPath characterAtIndex:[dstPath length] - 1] !== '/')
                                            newName = dstPath.substr(dstPath.lastIndexOf('/')+1);

                                        moveTo(srcFileEntry, dstDirEntry, newName);
                                    }
                                    else
                                        copyTo(srcFileEntry, dstDirEntry);
                                }
                                error:function(e)
                                {
                                    // Dir doest not exist, so we create it
                                    createDirAndCopyOrMove(dstPath, cmpDst, srcFileEntry, _fs.root, move);
                                }];
                    },
                    function(e)
                    {
                        // It's a not a file, let's check if it's a folder
                        srcDirEntry.getDirectory(srcName, {},
                            function(dirEntry)
                            {
                                [self   _gotoDir:dstPath
                                        dirEntry:_fs.root
                                         success:function(dstDirEntry)
                                        {
                                            if (move)
                                                moveTo(dirEntry, dstDirEntry, nil);
                                            else
                                                copyTo(dirEntry, dstDirEntry);
                                        }
                                        error:function(e)
                                        {
                                            createDirAndCopyOrMove(dstPath, cmpDst, dirEntry, _fs.root, move);
                                        }];
                            },
                            function(e)
                            {
                                // Folder doesn't exist
                                error(e);
                            });
                    });
            }
            error:function(e)
            {
                // File is in a non-existing folder
                error(e);
            }];
}

- (void)contentsAtPath:(CPString)path
               success:(Function)success
                 error:(Function)error
{
    [self   _gotoDir:[self _parentDir:path]
            dirEntry:_fs.root
            success:function(dirEntry)
            {
                var name = [self _fileName:path];
                dirEntry.getFile(name, {},
                    function(fileEntry)
                    {
                        fileEntry.file(function(file) {
                            var reader = new FileReader();

                            reader.onloadend = function(e) {
                                //var data = [CPData dataWithRawString:this.results];

                                var bb = new BlobBuilder();
                                bb.append(this.result);
                                var data = [CPData dataWithBlob:bb.getBlob()];
                                success(data);
                            };

                            //reader.readAsText(file);
                            reader.readAsArrayBuffer(file);
                        },
                        function(e)
                        {
                            error(e);
                        });
                    },
                    function(e)
                    {
                        error(e);
                    });
            }
            error:function(e)
            {
                error(e);
            }];
}

- (void)contentsAtPath:(CPString)path
              delegate:(id)delegate
{
    [self contentsAtPath:path
                success:function(data)
                {
                    if ([delegate respondsToSelector:@selector(contentsAtPath:contents:error:)])
                        [delegate contentsAtPath:path contents:data error:RTFileErrorNone];
                }
                error:function(e)
                {
                    if ([delegate respondsToSelector:@selector(contentsAtPath:contents:error:)])
                        [delegate contentsAtPath:path contents:nil error:[self _codeFromError:e]];
                }];
}

@end
