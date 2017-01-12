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

@interface TOSMBSessionUploadTask ()

@property (nonatomic, strong) NSFileHandle *sourceFilehandle;
@property (nonatomic) long long fileSize;

@property (nonatomic, weak) id <TOSMBSessionUploadTaskDelegate> delegate;
@property (nonatomic, copy) TOSMBSessionUploadTaskSuccessBlock successHandler;

@end

@implementation TOSMBSessionUploadTask

@dynamic delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
{
    if ((self = [super initWithSession:session path:dstPath])) {
        
        self.sourceFilehandle = [NSFileHandle fileHandleForReadingAtPath:srcPath];
        self.isNewFile = YES;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:srcPath error:NULL];
        self.fileSize = [attributes fileSize];
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

- (void)didSendBytes:(NSInteger)recentCount bytesSent:(NSInteger)totalCount {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(uploadTask:didSendBytes:totalBytesSent:totalBytesExpectedToSend:)]) {
            [weakSelf.delegate uploadTask:weakSelf
                             didSendBytes:recentCount
                           totalBytesSent:totalCount
                 totalBytesExpectedToSend:weakSelf.fileSize];
        }
        if (weakSelf.progressHandler) {
            weakSelf.progressHandler(totalCount, weakSelf.fileSize);
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
    
    NSData *data;
    NSInteger chunkSize = 65471;
    
    ssize_t bytesWritten = 0;
    ssize_t totalBytesWritten = 0;
    
    [self.sourceFilehandle seekToFileOffset:0];
    
    while (((data = [self.sourceFilehandle readDataOfLength: chunkSize]).length > 0))
    {
        NSUInteger bufferSize = data.length;
        void *buffer = malloc(bufferSize);
        [data getBytes:buffer length:bufferSize];
        
        bytesWritten = smb_fwrite(self.smbSession, self.fileID, buffer, bufferSize);
        
        free(buffer);
        totalBytesWritten += bytesWritten;
        [self didSendBytes:bytesWritten bytesSent:totalBytesWritten];
    }
    
    // Get uploaded file info
    TOSMBSessionFile *file = [self requestFileForItemAtPath:self.smbFilePath inTree:self.treeID];
    [self didFinishWithItem:file];
    
    self.cleanupBlock();
}

@end
