//
//  TOSMBSessionCreateFolderTask.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 12.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionTask.h"

@class TOSMBSessionFile;

@protocol TOSMBSessionCreateFolderTaskDelegate <TOSMBSessionTaskDelegate>
@optional

- (void)createFolderTask:(TOSMBSessionTask *)task didCreateFolder:(TOSMBSessionFile *)folder;

@end

@interface TOSMBSessionCreateFolderTask : TOSMBSessionTask

@end
