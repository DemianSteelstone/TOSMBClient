//
//  TOSMBSessionRemoveTask.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 12.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionRemoveTaskPrivate.h"
#import "TOSMBShare.h"
#import "NSString+SMBNames.h"

@interface TOSMBSessionRemoveTask ()

@property (nonatomic,copy) dispatch_block_t successHandler;
@property (nonatomic, strong) NSString *path;

@property (nonatomic, weak) id <TOSMBSessionRemoveTaskDelegate> delegate;

@end

@implementation TOSMBSessionRemoveTask

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
                      delegate:(id<TOSMBSessionRemoveTaskDelegate>)delegate
{
    self = [self initWithSession:session path:srcPath];
    self.delegate = delegate;
    return self;
}

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                successHandler:(dispatch_block_t)successHandler
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
    
    [self.share removeItemAtPath:self.path
                    successBlock:^{
                        [weakSelf didFinish];
                    } failBlock:^(NSError * _Nonnull error) {
                        [weakSelf didFailWithError:error];
                    }];
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
