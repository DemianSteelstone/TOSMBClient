//
//  TOSMBSessionCreateFolderTask.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 12.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionCreateFolderTaskPrivate.h"

@interface TOSMBSessionCreateFolderTask ()

@property (nonatomic,copy) TOSSMBSessionCreateFolderTaskSuccessBlock successHandler;

@property (nonatomic, weak) id <TOSMBSessionCreateFolderTaskDelegate> delegate;

@end

@implementation TOSMBSessionCreateFolderTask
@dynamic delegate;

-(instancetype)initWithSession:(TOSMBSession *)session path:(NSString *)smbPath
{
    self = [super initWithSession:session path:smbPath];
    self.isNewFile = YES;
    self.dontOpenFile = YES;
    return self;
}

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                      delegate:(id<TOSMBSessionCreateFolderTaskDelegate>)delegate
{
    self = [super initWithSession:session path:srcPath];
    self.delegate = delegate;
    return self;
}

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                successHandler:(TOSSMBSessionCreateFolderTaskSuccessBlock)successHandler
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
    
    int result = smb_directory_create(self.smbSession,self.treeID,fileCString);
    if (result)
    {
        [self didFailWithError:errorForErrorCode(result)];
    }
    else
    {
        TOSMBSessionFile *file = [self requestFileForItemAtPath:self.smbFilePath inTree:self.treeID];
        [self didFinishWithItem:file];
    }
    
    self.cleanupBlock();
}

- (void)didFinishWithItem:(TOSMBSessionFile *)folder {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(createFolderTask:didCreateFolder:)]) {
            [weakSelf.delegate createFolderTask:weakSelf
                                didCreateFolder:folder];
        }
        if (weakSelf.successHandler) {
            weakSelf.successHandler(folder);
        }
    });
}


@end
