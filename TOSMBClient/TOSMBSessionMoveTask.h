//
//  TOSMBSessionMoveTask.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionTask.h"

@class TOSMBSessionMoveTask,TOSMBSessionFile;

typedef void(^TOSMBSessionMoveTaskSuccessBlock)(TOSMBSessionFile *file);

@protocol TOSMBSessionMoveTaskDelegate <TOSMBSessionTaskDelegate>
@optional

- (void)moveTask:(TOSMBSessionMoveTask *)moveTask didFinishMove:(TOSMBSessionFile *)file;

@end

@interface TOSMBSessionMoveTask : TOSMBSessionTask

@end
