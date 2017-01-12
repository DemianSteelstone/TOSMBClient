//
//  TOSSMBSessionCreateFolderTaskPrivate.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 12.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#ifndef TOSSMBSessionCreateFolderTaskPrivate_h
#define TOSSMBSessionCreateFolderTaskPrivate_h

#import "TOSMBSessionCreateFolderTask.h"
#import "TOSMBSessionTaskPrivate.h"

typedef void(^TOSSMBSessionCreateFolderTaskSuccessBlock)(TOSMBSessionFile *folder);

@interface TOSMBSessionCreateFolderTask ()

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                       delegate:(id<TOSMBSessionCreateFolderTaskDelegate>)delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                 successHandler:(TOSSMBSessionCreateFolderTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler;
@end

#endif /* TOSSMBSessionCreateFolderTaskPrivate_h */
