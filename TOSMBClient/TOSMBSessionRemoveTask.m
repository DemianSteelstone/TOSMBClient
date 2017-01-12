//
//  TOSMBSessionRemoveTask.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 12.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionRemoveTaskPrivate.h"

@interface TOSMBSessionRemoveTask ()

@property (nonatomic,copy) dispatch_block_t successHandler;

@property (nonatomic, weak) id <TOSMBSessionRemoveTaskDelegate> delegate;

@end

@implementation TOSMBSessionRemoveTask

@dynamic delegate;

-(instancetype)initWithSession:(TOSMBSession *)session path:(NSString *)smbPath
{
    self = [super initWithSession:session path:smbPath];
    self.dontOpenFile = YES;
    return self;
}

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                      delegate:(id<TOSMBSessionRemoveTaskDelegate>)delegate
{
    self = [super initWithSession:session path:srcPath];
    self.delegate = delegate;
    return self;
}

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                successHandler:(dispatch_block_t)successHandler
                   failHandler:(TOSMBSessionTaskFailBlock)failHandler
{
    self = [super initWithSession:session path:srcPath];
    self.successHandler = successHandler;
    self.failHandler = failHandler;
    return self;
}

#pragma mark -
- (void)performTaskWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation {
    
    if (weakOperation.isCancelled)
        return;
    
    const char *fileCString = [self.formattedFilePath cStringUsingEncoding:NSUTF8StringEncoding];
    
    int result = 0;
    
    if (self.file.directory)
    {
        result = smb_directory_rm(self.smbSession,self.treeID,fileCString);
    }
    else
    {
        result = smb_file_rm(self.smbSession,self.treeID,fileCString);
    }
    
    if (result)
    {
        [self didFailWithError:errorForErrorCode(result)];
    }
    else
    {
        [self didFinish];
    }
}

- (void)didFinish {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(removeTaskDidCompletedSuccessfull:)]) {
            [weakSelf.delegate removeTaskDidCompletedSuccessfull:weakSelf];
        }
        if (weakSelf.successHandler) {
            weakSelf.successHandler();
        }
    });
}

@end
