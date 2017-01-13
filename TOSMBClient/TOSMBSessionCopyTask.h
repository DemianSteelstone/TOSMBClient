//
//  TOSMBSessionCopyTask.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionTask.h"

@class TOSMBSessionCopyTask,TOSMBSessionFile;

typedef void(^TOSMBSessionCopyTaskSuccessBlock)(TOSMBSessionFile *file);

@protocol TOSMBSessionCopyTaskDelegate <TOSMBSessionTaskDelegate>
@optional

- (void)copyTask:(TOSMBSessionCopyTask *)copyTask
    didCopyBytes:(uint64_t)bytesCopied
totalBytesCopied:(uint64_t)totalBytesCopied
totalBytesExpectedToCopy:(uint64_t)totalBytesExpectedToCopy;

- (void)copyTask:(TOSMBSessionCopyTask *)copyTask didFinishCopy:(TOSMBSessionFile *)file;

@end


@interface TOSMBSessionCopyTask : TOSMBSessionTask

@end
