//
//  TOSMBSessionStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "bdsm.h"

static const uint64_t TOSMBSessionStreamChunkSize = 65471;

@class TOSMBSessionFile;

typedef void(^TOSMBSessionStreamFailBlock)(NSError *error);
typedef void(^TOSMBSessionStreamFolderCreateSuccessBlock)(TOSMBSessionFile *folder);

@interface TOSMBSessionStream : NSObject

@property (nonatomic, strong) TOSMBSessionFile *file;
@property (readonly) NSString *path;


@property (nonatomic) smb_tid treeID;
@property (nonatomic) smb_fd fileID;
@property (nonatomic, assign, nullable) smb_session *smbSession;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, readonly) dispatch_block_t cleanupBlock;

@property (nonatomic, getter=isOpened, readonly) BOOL open;

+ (instancetype)streamForPath:(NSString *)path;

- (instancetype)initWithPath:(NSString *)path;

- (TOSMBSessionFile *)requestFileForItemAtPath:(NSString *)filePath inTree:(smb_tid)treeID;
- (void)didFailWithError:(NSError *)error;

- (void)openStream:(dispatch_block_t)successBlock failBlock:(TOSMBSessionStreamFailBlock)failBlock;



-(void)createFolderWithSuccessBlock:(TOSMBSessionStreamFolderCreateSuccessBlock)successBlock
                          failBlock:(TOSMBSessionStreamFailBlock)failBlock;

-(void)removeItemWithSuccessBlock:(dispatch_block_t)successBlock
                        failBlock:(TOSMBSessionStreamFailBlock)failBlock;


// Overload
- (BOOL)findTargetFile;
- (BOOL)openFile;

@end
