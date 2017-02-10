//
//  TOSMBSessionRemoveTask.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 12.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionTask.h"

@protocol TOSMBSessionRemoveTaskDelegate <TOSMBSessionTaskDelegate>
@optional

- (void)removeTaskDidCompletedSuccessfull:(TOSMBSessionTask *)task;

@end


@interface TOSMBSessionRemoveTask : TOSMBSessionTask

@end
