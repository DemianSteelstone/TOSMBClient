//
//  TOSMBSessionStreamPrivate.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 20.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#ifndef TOSMBSessionStreamPrivate_h
#define TOSMBSessionStreamPrivate_h

#import "bdsm.h"
#import "TOSMBSessionStream.h"

static const uint64_t TOSMBSessionStreamChunkSize = 64000;

@interface TOSMBSessionStream ()

@property (nonatomic) smb_tid treeID;
@property (nonatomic) smb_fd fileID;
@property (nonatomic, assign, nullable) smb_session *smbSession;

@property (nonatomic, readonly, nonnull) dispatch_block_t cleanupBlock;

@property (nonatomic, getter=isOpened, readonly) BOOL opened;
@property (nonatomic, getter=isClosed, readonly) BOOL closed;

+ (_Nonnull instancetype)streamForPath:(NSString * _Nonnull )path;
+ (_Nonnull instancetype)streamWithSession:(smb_session * _Nonnull)session path:(NSString * _Nonnull)path;

- (_Nonnull instancetype)initWithPath:(NSString * _Nonnull )path;

- (nullable TOSMBSessionFile *)requestFileForItemAtPath:(NSString * _Nonnull )filePath
                                                 inTree:(smb_tid)treeID;

- (void)didFailWithError:(nonnull NSError *)error;

// Overload
- (BOOL)findTargetFile;
- (BOOL)openFile;

@end

#endif /* TOSMBSessionStreamPrivate_h */
