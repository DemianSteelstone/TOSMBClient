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
#import "NSString+SMBNames.h"
#import "TOSMBShare.h"

@interface TOSMBSessionCopyTask ()

@property (nonatomic, weak) id <TOSMBSessionCopyTaskDelegate> delegate;
@property (nonatomic,strong) TOSMBShare *dstShare;
@property (nonatomic, copy) TOSMBSessionCopyTaskSuccessBlock successHandler;
@property (nonatomic, strong) NSString *srcPath;
@property (nonatomic, strong) NSString *dstPath;

@end

@implementation TOSMBSessionCopyTask

@dynamic delegate;

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                       dstPath:(NSString *)dstPath
{
    TOSMBShare *share = [[TOSMBShare alloc] initWithShareName:srcPath.shareName];
    self = [super initWithSession:session share:share];
    
    if ([srcPath.shareName isEqualToString:dstPath.shareName])
    {
        _dstShare = share;
    }
    else
    {
        _dstShare = [[TOSMBShare alloc] initWithShareName:dstPath.shareName];
    }
    
    _srcPath = srcPath;
    _dstPath = dstPath;
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

-(void)performTask
{
    if (_dstShare.connected == NO)
    {
        NSError *error = nil;
        BOOL success = [_dstShare connectToShare:&error];
        if (!success)
        {
            [self didFailWithError:error];
            return;
        }
    }
}

-(void)startCopy
{
    NSError *error = nil;
    
    uint64_t totalBytesWritten = 0;
    uint64_t totalBytesRead = 0;
    
    TOSMBSessionReadStream *readStream = [TOSMBSessionReadStream streamWithShare:self.share
                                                                        itemPath:self.srcPath];
    
    TOSMBSessionWriteStream *writeStream = [TOSMBSessionWriteStream streamWithShare:self.dstShare
                                                                        itemPath:self.dstPath];
    
    if (!self.isCanceled && [readStream open:&error])
    {
        if (!self.isCanceled && [writeStream open:&error])
        {
            uint64_t expectedSize = readStream.file.fileSize;
            
            while (totalBytesRead < expectedSize) {
                
                NSData *data = [readStream readChunk:&error];
                if (self.isCanceled || error)
                {
                    break;
                }
                
                totalBytesRead +=data.length;
                totalBytesWritten += [writeStream writeData:data error:&error];
                
                if (self.isCanceled || error)
                {
                    break;
                }
                
                [self didCopyBytes:data.length
                  totalCopiedBytes:totalBytesWritten
                      expectedSize:expectedSize];
            }
        }
    }
    
    if (error)
    {
        [self didFailWithError:error];
    }
    else
    {
        if (!self.isCanceled)
        {
            TOSMBSessionFile *file = [self.dstShare requestItemAtPath:self.dstPath];
            [self didFinishWithItem:file];
        }
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
