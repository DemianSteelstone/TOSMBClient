//
//  TOSMBSessionStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "bdsm.h"

typedef void(^TOSMBSessionStreamFailBlock)(NSError *error);

@class TOSMBSessionFile;

@interface TOSMBSessionStream : NSObject

@property (nonatomic, strong) TOSMBSessionFile *file;
@property (readonly) NSString *path;


@property (nonatomic) smb_tid treeID;
@property (nonatomic) smb_fd fileID;
@property (nonatomic, assign, nullable) smb_session *smbSession;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, readonly) dispatch_block_t cleanupBlock;

@property (nonatomic) BOOL isNewFile;

@property (nonatomic) BOOL dontCheckFolder;

+ (instancetype)sessionForPath:(NSString *)path;

- (instancetype)initWithPath:(NSString *)path;

- (TOSMBSessionFile *)requestFileForItemAtPath:(NSString *)filePath inTree:(smb_tid)treeID;
- (void)didFailWithError:(NSError *)error;

- (void)openStream:(dispatch_block_t)successBlock failBlock:(TOSMBSessionStreamFailBlock)failBlock;

// Overload
- (BOOL)findTargetFileWithOoperation:(NSBlockOperation * _Nonnull __weak)weakOperation;
- (BOOL)openFileWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation;

@end
