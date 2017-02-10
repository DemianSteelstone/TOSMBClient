//
//  TOSMBSessinCopyTaskPrivate.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#ifndef TOSMBSessinCopyTaskPrivate_h
#define TOSMBSessinCopyTaskPrivate_h

#import "TOSMBSessionCopyTask.h"
#import "TOSMBSessionTaskPrivate.h"

@interface TOSMBSessionCopyTask () <TOSMBSessionConcreteTask>

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                       delegate:(id<TOSMBSessionCopyTaskDelegate>)delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                progressHandler:(TOSMBSessionTaskProgressBlock)progressHandler
                 successHandler:(TOSMBSessionCopyTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler;

@end

#endif /* TOSMBSessinCopyTaskPrivate_h */
