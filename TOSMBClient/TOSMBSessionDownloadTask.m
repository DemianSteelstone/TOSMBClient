//
// TOSMBDownloadTask.m
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

#import "TOSMBSessionDownloadTaskPrivate.h"
#import "TOSMBSessionDownloadStream.h"

// -------------------------------------------------------------------------

@interface TOSMBSessionDownloadTask ()

@property (nonatomic, strong, readwrite) NSString *sourceFilePath;
@property (nonatomic, strong, readwrite) NSString *destinationFilePath;

/** Feedback handlers */
@property (nonatomic, weak) id<TOSMBSessionDownloadTaskDelegate> delegate;
@property (nonatomic, copy) TOSMBSessionDownloadTaskSuccsessBlock successHandler;

@end

@implementation TOSMBSessionDownloadTask

@dynamic delegate;

-(instancetype)initWithSession:(TOSMBSession *)session path:(NSString *)path
{
    TOSMBSessionDownloadStream *stream = [TOSMBSessionDownloadStream streamForPath:path];
    self = [super initWithSession:session stream:stream];
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                       filePath:(NSString *)filePath
                destinationPath:(NSString *)destinationPath
{
    if ((self = [self initWithSession:session path:filePath])) {
        
        _destinationFilePath = destinationPath;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                       filePath:(NSString *)filePath
                destinationPath:(NSString *)destinationPath
                       delegate:(id<TOSMBSessionDownloadTaskDelegate>)delegate
{
    if ((self = [self initWithSession:session
                             filePath:filePath
                      destinationPath:destinationPath])) {
        
        self.delegate = delegate;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                       filePath:(NSString *)filePath
                destinationPath:(NSString *)destinationPath
                progressHandler:(TOSMBSessionTaskProgressBlock)progressHandler
                 successHandler:(TOSMBSessionDownloadTaskSuccsessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler
{
    if ((self = [self initWithSession:session
                             filePath:filePath
                      destinationPath:destinationPath])){
        self.progressHandler = progressHandler;
        _successHandler = successHandler;
        self.failHandler = failHandler;
    }
    
    return self;
}

#pragma mark - Public Control Methods -

- (void)didSucceed
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didFinishDownloadingToPath:)])
            [self.delegate downloadTask:self didFinishDownloadingToPath:self.destinationFilePath];
        
        if (self.successHandler)
            self.successHandler(self.destinationFilePath);
    });
}

- (void)didFailWithError:(NSError *)error
{
    [super didFailWithError:error];
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didCompleteWithError:)])
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [self.delegate downloadTask:self didCompleteWithError:error];
#pragma clang diagnostic pop        
        if (self.failHandler)
            self.failHandler(error);
    });
}

- (void)didDownloadBytes:(uint64_t)bytesWritten
          totalBytesDownloaded:(uint64_t)totalBytesWritten
         totalBytesExpected:(uint64_t)totalBytesExpected
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didWriteBytes:totalBytesReceived:totalBytesExpectedToReceive:)])
            [self.delegate downloadTask:self
                          didWriteBytes:bytesWritten
                     totalBytesReceived:totalBytesWritten
            totalBytesExpectedToReceive:totalBytesExpected];
        
        if (self.progressHandler)
            self.progressHandler(totalBytesWritten, totalBytesExpected);
    }];
}

#pragma mark - Downloading -

- (void)performTaskWithOperation:(__weak NSBlockOperation *)weakOperation
{
    if (weakOperation.isCancelled)
        return;
    
    __weak typeof(self) weakSelf = self;
    
    TOSMBSessionDownloadStream *downloadStream = (TOSMBSessionDownloadStream *)self.stream;
    
   NSError *error = nil;
    
    NSData *data = [NSData data];
    [data writeToFile:self.destinationFilePath options:NSDataWritingAtomic error:&error];
    if (error != nil)
    {
        [self didFailWithError:error];
        return;
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:[NSURL fileURLWithPath:self.destinationFilePath] error:&error];
    
    if (error != nil)
    {
        [self didFailWithError:error];
        return;
    }
    
    uint64_t totalBytesRead = 0;
    uint64_t expectedSize = downloadStream.file.fileSize;
    
    while (totalBytesRead < expectedSize) {
        NSData *data = [downloadStream readChunk:&error];
        
        if (error)
        {
            break;
        }
        else
        {
            int64_t bytesRead = data.length;
            totalBytesRead += bytesRead;
            
            //Save them to the file handle (And ensure the NSData object is flushed immediately)
            [fileHandle writeData:data];
            
            [self didDownloadBytes:bytesRead totalBytesDownloaded:totalBytesRead totalBytesExpected:expectedSize];
        }
    };
    
    //Ensure the data is properly written to disk before proceeding
    [fileHandle synchronizeFile];
    
    [fileHandle closeFile];
    
    if (error)
    {
        [weakSelf didFailWithError:error];
    }
    else
    {
        [weakSelf didSucceed];
    }
    
    downloadStream.cleanupBlock();
}

@end
