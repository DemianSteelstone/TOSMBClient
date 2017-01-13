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
    TOSMBSessionWriteStream *writeStream = [TOSMBSessionWriteStream streamForPath:dstPath];
    
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
                 successHandler:(TOSMBSessionCopyTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler
{
    self = [self initWithSession:session
                      sourcePath:srcPath
                         dstPath:dstPath];
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
        
    } failBlock:^(NSError *error) {
        [weakSelf didFailWithError:error];
    }];
}

-(void)startCopyWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    NSError *error = nil;
    
    uint64_t totalBytesRead = 0;
    uint64_t expectedSize = self.stream.file.fileSize;
    
    TOSMBSessionReadStream *readStream = (TOSMBSessionReadStream *)self.stream;
    
    while (totalBytesRead < expectedSize) {
        
        if (weakOperation.isCancelled)
        {
            readStream.cleanupBlock();
            self.writeStream.cleanupBlock();
            return;
        }
        
        NSData *data = [readStream readChunk:&error];
        if (error)
        {
            break;
        }
        
        totalBytesRead += data.length;
        
        [self.writeStream writeData:data error:&error];
        
        if (error)
        {
            break;
        }
        
        [self didCopyBytes:data.length
          totalCopiedBytes:totalBytesRead
              expectedSize:expectedSize];
    }
    
    if (error)
    {
        [self didFailWithError:error];
    }
    else
    {
        TOSMBSessionFile *file = [self.writeStream requestFileForItemAtPath:self.writeStream.path
                                                                     inTree:self.writeStream.treeID];
        [self didFinishWithItem:file];
    }
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
