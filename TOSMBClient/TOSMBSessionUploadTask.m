//
// TOSMBSessionUploadTake.m
// Copyright 2015-2016 Timothy Oliver
//
// This file is dual-licensed under both the MIT License, and the LGPL v2.1 License.
//
// -------------------------------------------------------------------------------
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
// -------------------------------------------------------------------------------

#import "TOSMBSessionUploadTaskPrivate.h"
#import "TOSMBSessionPrivate.h"
#import "TOSMBSessionWriteStream.h"

@interface TOSMBSessionUploadTask ()

@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, weak) id <TOSMBSessionUploadTaskDelegate> delegate;
@property (nonatomic, copy) TOSMBSessionUploadTaskSuccessBlock successHandler;

@end

@implementation TOSMBSessionUploadTask

@dynamic delegate;

-(instancetype)initWithSession:(TOSMBSession *)session path:(NSString *)path
{
    TOSMBSessionWriteStream *stream = [TOSMBSessionWriteStream streamForPath:path];
    self = [super initWithSession:session stream:stream];
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
{
    if ((self = [self initWithSession:session path:dstPath])) {
        
        self.filePath = srcPath;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                       delegate:(id<TOSMBSessionUploadTaskDelegate>)delegate {
    if ((self = [self initWithSession:session sourcePath:srcPath dstPath:dstPath])) {
        self.delegate = delegate;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                progressHandler:(TOSMBSessionTaskProgressBlock)progressHandler
                 successHandler:(TOSMBSessionUploadTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler {
    if ((self = [self initWithSession:session sourcePath:srcPath dstPath:dstPath])) {
        self.progressHandler = progressHandler;
        self.successHandler = successHandler;
        self.failHandler = failHandler;
    }
    
    return self;
}

#pragma mark - delegate helpers

- (void)didSendBytes:(long long)sendBytes totalBytesSent:(long long)totalBytesSent totalBytesExpectedToSend:(long long)totalBytesExpectedToSend {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(uploadTask:didSendBytes:totalBytesSent:totalBytesExpectedToSend:)]) {
            [weakSelf.delegate uploadTask:weakSelf
                             didSendBytes:sendBytes
                           totalBytesSent:totalBytesSent
                 totalBytesExpectedToSend:totalBytesExpectedToSend];
        }
        if (weakSelf.progressHandler) {
            weakSelf.progressHandler(totalBytesSent, totalBytesExpectedToSend);
        }
    });
}

- (void)didFinishWithItem:(TOSMBSessionFile *)file {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(uploadTaskDidFinishUploading:)]) {
            [weakSelf.delegate uploadTaskDidFinishUploading:file];
        }
        if (weakSelf.successHandler) {
            weakSelf.successHandler(file);
        }
    });
}

#pragma mark - task

- (void)performTaskWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation {
    
    if (weakOperation.isCancelled)
        return;
    
    TOSMBSessionWriteStream *uploadStream = (TOSMBSessionWriteStream *)self.stream;
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
    [fileHandle seekToFileOffset:0];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:NULL];
    long long expectedSize = [attributes fileSize];
    
    NSData *data;
    ssize_t totalBytesWritten = 0;
    NSError *error = nil;
    
    while (((data = [fileHandle readDataOfLength: TOSMBSessionStreamChunkSize]).length > 0))
    {
        [uploadStream writeData:data error:&error];
        
        if (error)
        {
            break;
        }
        
        NSUInteger bufferSize = data.length;
        totalBytesWritten += bufferSize;
        
        [self didSendBytes:bufferSize totalBytesSent:totalBytesWritten totalBytesExpectedToSend:expectedSize];
        
    }
    if (error)
    {
        [self didFailWithError:error];
    }
    else
    {
        TOSMBSessionFile *file = [uploadStream requestFileForItemAtPath:uploadStream.path
                                                         inTree:uploadStream.treeID];
        [self didFinishWithItem:file];
    }
    
    uploadStream.cleanupBlock();
}

@end
