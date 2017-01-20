//
//  TOSMBSessionCopyTask.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessinCopyTaskPrivate.h"
#import "TOSMBSessionReadStream.h"
#import "TOSMBSessionWriteStream.h"
#import "TOSMBSessionStreamPrivate.h"

@interface TOSMBSessionCopyTask ()

@property (nonatomic, weak) id <TOSMBSessionCopyTaskDelegate> delegate;
@property (nonatomic,strong) TOSMBSessionWriteStream *writeStream;
@property (nonatomic, copy) TOSMBSessionCopyTaskSuccessBlock successHandler;

@end

@implementation TOSMBSessionCopyTask

@dynamic delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
{
    
    TOSMBSessionReadStream *readStream = [TOSMBSessionReadStream streamForPath:srcPath];
    TOSMBSessionWriteStream *writeStream = [TOSMBSessionWriteStream streamWithSession:readStream.smbSession path:dstPath];
    
    self = [super initWithSession:session stream:readStream];
    _writeStream = writeStream;
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                       delegate:(id<TOSMBSessionCopyTaskDelegate>)delegate
{
    self = [self initWithSession:session
                      sourcePath:srcPath
                  dstPath:dstPath];
    self.delegate = delegate;
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                progressHandler:(TOSMBSessionTaskProgressBlock)progressHandler
                 successHandler:(TOSMBSessionCopyTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler
{
    self = [self initWithSession:session
                      sourcePath:srcPath
                         dstPath:dstPath];
    self.progressHandler = progressHandler;
    self.successHandler = successHandler;
    self.failHandler = failHandler;
    
    return self;
}

-(void)performTaskWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    if (weakOperation.isCancelled)
        return;
    
    __weak typeof(self) weakSelf = self;
    
    [self.writeStream openStream:^{
        [weakSelf startCopyWithOperation:weakOperation];
    } failBlock:^(NSError *error) {
        [weakSelf didFailWithError:error];
    }];
}

-(void)startCopyWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    NSError *error = nil;
    
    uint64_t totalBytesWritten = 0;
    uint64_t expectedSize = self.stream.file.fileSize;
    
    TOSMBSessionReadStream *readStream = (TOSMBSessionReadStream *)self.stream;
    
    while (totalBytesWritten < expectedSize) {
        
        if (weakOperation.isCancelled)
        {
            [self end];
            return;
        }
        
        NSData *data = [readStream readChunk:&error];
        if (error)
        {
            break;
        }
        
        totalBytesWritten += [self.writeStream writeData:data error:&error];
        
        if (error)
        {
            break;
        }
        
        [self didCopyBytes:data.length
          totalCopiedBytes:totalBytesWritten
              expectedSize:expectedSize];
    }
    
    if (error)
    {
        [self didFailWithError:error];
    }
    else
    {
        TOSMBSessionFile *file = [self.writeStream requestContent];
        [self didFinishWithItem:file];
    }
    
    [self end];
}

-(void)end
{
    self.stream.cleanupBlock();
//    self.writeStream.cleanupBlock();
}

- (void)didFinishWithItem:(TOSMBSessionFile *)item {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(copyTask:didFinishCopy:)]) {
            [weakSelf.delegate copyTask:weakSelf
                          didFinishCopy:item];
        }
        if (weakSelf.successHandler) {
            weakSelf.successHandler(item);
        }
    });
}

- (void)didCopyBytes:(uint64_t)copiedBytes totalCopiedBytes:(uint64_t)totalCopiedBytes expectedSize:(uint64_t)expectedSize
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(copyTask:didCopyBytes:totalBytesCopied:totalBytesExpectedToCopy:)]) {
            [weakSelf.delegate copyTask:weakSelf
                             didCopyBytes:copiedBytes
                           totalBytesCopied:totalCopiedBytes
                 totalBytesExpectedToCopy:expectedSize];
        }
        if (weakSelf.progressHandler) {
            weakSelf.progressHandler(totalCopiedBytes, expectedSize);
        }
    });
}

@end
