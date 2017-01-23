//
//  TOSMBSessionCreateFolderTask.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 12.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionCreateFolderTaskPrivate.h"
#import "TOSMBShare.h"
#import "NSString+SMBNames.h"

@interface TOSMBSessionCreateFolderTask ()

@property (nonatomic,copy) TOSSMBSessionCreateFolderTaskSuccessBlock successHandler;

@property (nonatomic, weak) id <TOSMBSessionCreateFolderTaskDelegate> delegate;
@property (nonatomic, strong) NSString *path;

@end

@implementation TOSMBSessionCreateFolderTask
@dynamic delegate;

-(instancetype)initWithSession:(TOSMBSession *)session
                          path:(NSString *)smbPath
{
    TOSMBShare *share = [[TOSMBShare alloc] initWithShareName:smbPath.shareName];
    self = [super initWithSession:session share:share];
    _path = smbPath;
    return self;
}

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                      delegate:(id<TOSMBSessionCreateFolderTaskDelegate>)delegate
{
    self = [self initWithSession:session path:srcPath];
    self.delegate = delegate;
    return self;
}

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                successHandler:(TOSSMBSessionCreateFolderTaskSuccessBlock)successHandler
                   failHandler:(TOSMBSessionTaskFailBlock)failHandler
{
    self = [self initWithSession:session path:srcPath];
    self.successHandler = successHandler;
    self.failHandler = failHandler;
    return self;
}

#pragma mark -
- (void)performTask {
    
    __weak typeof(self) weakSelf = self;
    
    [self.share createFolderAtPath:_path
                      successBlock:^(TOSMBSessionFile * _Nonnull item) {
                          [weakSelf didFinishWithItem:item];
                      } failBlock:^(NSError * _Nonnull error) {
                          [weakSelf didFailWithError:error];
                      }];
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
