//
//  TOSMBSessionMoveTask.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionMoveTaskPrivate.h"
#import "TOSMBSessionReadStream.h"

@interface TOSMBSessionMoveTask ()

@property (nonatomic, weak) id <TOSMBSessionMoveTaskDelegate> delegate;
@property (nonatomic, copy) TOSMBSessionMoveTaskSuccessBlock successHandler;
@property (nonatomic, strong) NSString *dstPath;

@end

@implementation TOSMBSessionMoveTask

@dynamic delegate;

-(instancetype)initWithSession:(TOSMBSession *)session path:(NSString *)smbPath
{
    TOSMBSessionReadStream *stream = [TOSMBSessionReadStream streamForPath:smbPath];
    self = [super initWithSession:session stream:stream];
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
{
    if ((self = [self initWithSession:session path:srcPath])) {
        
        _dstPath = dstPath;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                       delegate:(id<TOSMBSessionMoveTaskDelegate>)delegate {
    if ((self = [self initWithSession:session sourcePath:srcPath dstPath:dstPath])) {
        self.delegate = delegate;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                 successHandler:(TOSMBSessionMoveTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler {
    if ((self = [self initWithSession:session sourcePath:srcPath dstPath:dstPath])) {
        self.successHandler = successHandler;
        self.failHandler = failHandler;
    }
    
    return self;
}

-(void)performTaskWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    if (weakOperation.isCancelled)
        return;
    
    __weak typeof(self) weakSelf = self;
    TOSMBSessionReadStream *writeStream = (TOSMBSessionReadStream *)self.stream;
    
    [writeStream moveItemToPath:_dstPath
                   successBlock:^(TOSMBSessionFile *folder){
                       [weakSelf didFinishWithItem:folder];
                   } failBlock:^(NSError *error) {
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
