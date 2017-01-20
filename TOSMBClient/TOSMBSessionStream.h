//
//  TOSMBSessionStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TOSMBSessionFile;

typedef void(^TOSMBSessionStreamFailBlock)( NSError* _Nonnull error);
typedef void(^TOSMBSessionStreamItemChangeSuccessBlock)( TOSMBSessionFile * _Nonnull folder);

@interface TOSMBSessionStream : NSObject

@property (nonatomic, strong, nullable) TOSMBSessionFile *file;
@property (nonnull,readonly) NSString *path;

- (nullable TOSMBSessionFile *)requestContent;

- (void)openStream:(_Nullable dispatch_block_t)successBlock
         failBlock:(_Nullable TOSMBSessionStreamFailBlock)failBlock;

- (void)createFolderWithSuccessBlock:(_Nullable TOSMBSessionStreamItemChangeSuccessBlock)successBlock
                          failBlock:(_Nullable TOSMBSessionStreamFailBlock)failBlock;

- (void)moveItemToPath:( NSString * _Nonnull )path
         successBlock:(_Nullable TOSMBSessionStreamItemChangeSuccessBlock)successBlock
            failBlock:(_Nullable TOSMBSessionStreamFailBlock)failBlock;

- (void)close;

@end
