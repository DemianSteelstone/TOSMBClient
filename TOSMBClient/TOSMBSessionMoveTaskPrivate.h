//
//  TOSMBSessionMoveTaskPrivate.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#ifndef TOSMBSessionMoveTaskPrivate_h
#define TOSMBSessionMoveTaskPrivate_h

#import "TOSMBSessionMoveTask.h"
#import "TOSMBSessionTaskPrivate.h"

@interface TOSMBSessionMoveTask () <TOSMBSessionConcreteTask>

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                       delegate:(id<TOSMBSessionMoveTaskDelegate>)delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                 successHandler:(TOSMBSessionMoveTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler;

@end

#endif /* TOSMBSessionMoveTaskPrivate_h */
