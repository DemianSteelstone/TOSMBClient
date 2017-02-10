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

@class TOSMBShare;

static const uint64_t TOSMBSessionStreamChunkSize = 64000;

@interface TOSMBSessionStream ()

@property (nonatomic) smb_fd fileID;
@property (nonatomic, strong, nonnull) TOSMBShare *share;

+ (_Nonnull instancetype)streamWithShare:(TOSMBShare * _Nonnull)session
                                itemPath:(NSString * _Nonnull)path;

- (uint32_t)permissions;
- (BOOL)findTargetFile:(NSError * __autoreleasing  _Nullable *  _Nullable)error;
@end

#endif /* TOSMBSessionStreamPrivate_h */
