//
//  TOSMBSessionRenameTask.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionRenameTaskPrivate.h"

@implementation TOSMBSessionRenameTask



- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        newName:(NSString *)newName
                       delegate:(id<TOSMBSessionMoveTaskDelegate>)delegate
{
    NSString *newNamePath = [self newPathForPath:srcPath name:newName];
    return [self initWithSession:session sourcePath:srcPath dstPath:newNamePath delegate:delegate];
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        newName:(NSString *)newName
                 successHandler:(TOSMBSessionMoveTaskSuccessBlock)successHandler
                    failHandler:(TOSMBSessionTaskFailBlock)failHandler
{
    NSString *newNamePath = [self newPathForPath:srcPath name:newName];
    return [self initWithSession:session sourcePath:srcPath dstPath:newNamePath successHandler:successHandler failHandler:failHandler];
}

-(NSString *)newPathForPath:(NSString *)path name:(NSString *)name
{
    NSString *contentPath = [path stringByDeletingLastPathComponent];
    NSString *newNamePath = [contentPath stringByAppendingPathComponent:name];
    return newNamePath;
}

@end
