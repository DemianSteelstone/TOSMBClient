//
//  TOSSMBSessionRemoveTask_TOSSMBSessionRemoveTaskPrivate.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 12.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//



#ifndef TOSSMBSessionRemoveTaskPrivate_h
#define TOSSMBSessionRemoveTaskPrivate_h

#import "TOSMBSessionRemoveTask.h"
#import "TOSMBSessionTaskPrivate.h"

@interface TOSMBSessionRemoveTask () <TOSMBSessionConcreteTask>

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                       delegate:(id<TOSMBSessionRemoveTaskDelegate>)delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                 successHandler:(dispatch_block_t)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler;

@end

#endif /* TOSSMBSessionRemoveTaskPrivate_h */
