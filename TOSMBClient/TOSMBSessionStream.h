//
//  TOSMBSessionStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "bdsm.h"

static const uint64_t TOSMBSessionStreamChunkSize = 65535;

@class TOSMBSessionFile;

typedef void(^TOSMBSessionStreamFailBlock)( NSError* _Nonnull error);
typedef void(^TOSMBSessionStreamFolderCreateSuccessBlock)( TOSMBSessionFile * _Nonnull folder);

@interface TOSMBSessionStream : NSObject

@property (nonatomic, strong, nullable) TOSMBSessionFile *file;
@property (nonnull,readonly) NSString *path;


@property (nonatomic) smb_tid treeID;
@property (nonatomic) smb_fd fileID;
@property (nonatomic, assign, nullable) smb_session *smbSession;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, readonly, nonnull) dispatch_block_t cleanupBlock;

@property (nonatomic, getter=isOpened, readonly) BOOL opened;
@property (nonatomic, getter=isClosed, readonly) BOOL closed;

+ (_Nonnull instancetype)streamForPath:(NSString * _Nonnull )path;

- (_Nonnull instancetype)initWithPath:(NSString * _Nonnull )path;

- (nullable TOSMBSessionFile *)requestContent;

- (nullable TOSMBSessionFile *)requestFileForItemAtPath:(NSString * _Nonnull )filePath
                                                 inTree:(smb_tid)treeID;
- (void)didFailWithError:(nonnull NSError *)error;

- (void)openStream:(_Nullable dispatch_block_t)successBlock
         failBlock:(_Nullable TOSMBSessionStreamFailBlock)failBlock;



-(void)createFolderWithSuccessBlock:(_Nullable TOSMBSessionStreamFolderCreateSuccessBlock)successBlock
                          failBlock:(_Nullable TOSMBSessionStreamFailBlock)failBlock;

-(void)removeItemWithSuccessBlock:(_Nullable dispatch_block_t)successBlock
                        failBlock:(_Nullable TOSMBSessionStreamFailBlock)failBlock;


// Overload
- (BOOL)findTargetFile;
- (BOOL)openFile;

- (void)close;

@end
