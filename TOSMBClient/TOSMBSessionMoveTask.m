//
//  TOSMBSessionMoveTask.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionMoveTaskPrivate.h"

#import "TOSMBSessionStreamPrivate.h"
#import "TOSMBShare.h"
#import "NSString+SMBNames.h"

@interface TOSMBSessionMoveTask ()

@property (nonatomic, weak) id <TOSMBSessionMoveTaskDelegate> delegate;
@property (nonatomic, copy) TOSMBSessionMoveTaskSuccessBlock successHandler;
@property (nonatomic, strong) NSString *srcPath;
@property (nonatomic, strong) NSString *dstPath;

@end

@implementation TOSMBSessionMoveTask

@dynamic delegate;

-(instancetype)initWithSession:(TOSMBSession *)session
                    sourcePath:(NSString *)srcPath
                       dstPath:(NSString *)dstPath
{
    TOSMBShare *share = [[TOSMBShare alloc] initWithShareName:srcPath.shareName];
    self = [super initWithSession:session share:share];
    _srcPath = srcPath;
    _dstPath = dstPath;
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                       delegate:(id<TOSMBSessionMoveTaskDelegate>)delegate {
    self = [self initWithSession:session sourcePath:srcPath dstPath:dstPath];
    self.delegate = delegate;
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                 successHandler:(TOSMBSessionMoveTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler {
    self = [self initWithSession:session sourcePath:srcPath dstPath:dstPath];
    self.successHandler = successHandler;
    self.failHandler = failHandler;
    return self;
}

-(void)performTask
{
    __weak typeof(self) weakSelf = self;
    
    [self.share moveItemFromPath:self.srcPath
                          toPath:self.dstPath
                    successBlock:^(TOSMBSessionFile * _Nonnull item) {
                        [weakSelf didFinishWithItem:item];
                    } failBlock:^(NSError * _Nonnull error) {
                        [weakSelf didFailWithError:error];
                    }];
}

- (void)didFinishWithItem:(TOSMBSessionFile *)item {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(moveTask:didFinishMove:)]) {
            [weakSelf.delegate moveTask:weakSelf
                          didFinishMove:item];
        }
        if (weakSelf.successHandler) {
            weakSelf.successHandler(item);
        }
    });
}

@end
