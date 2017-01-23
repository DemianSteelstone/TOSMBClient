//
//  TOSMBStreamSession.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 20.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "bdsm.h"

@class TOSMBSessionFile;

typedef void(^TOSMBSessionShareFailBlock)( NSError* _Nonnull error);
typedef void(^TOSMBSessionShareItemChangeSuccessBlock)( TOSMBSessionFile * _Nonnull item);

@interface TOSMBShare : NSObject

@property (nonatomic) smb_tid treeID;
@property (nonatomic, assign, nullable) smb_session *smbSession;
@property (nonatomic, strong, nonnull) NSString *shareName;
@property (nonatomic, readonly) BOOL connected;

- (nonnull instancetype)initWithShareName:(NSString * _Nonnull)shareName;

- (BOOL)connectToShare:(NSError * _Nonnull __autoreleasing * _Nonnull)error;

- (TOSMBSessionFile *)requestItemAtPath:(NSString *)filePath;

- (void)createFolderAtPath:(NSString * _Nonnull)path
              successBlock:(_Nullable TOSMBSessionShareItemChangeSuccessBlock)successBlock
                 failBlock:(_Nullable TOSMBSessionShareFailBlock)failBlock;

- (void)moveItemFromPath:(NSString * _Nonnull)srcPath
                  toPath:(NSString * _Nonnull )dstPath
            successBlock:(_Nullable TOSMBSessionShareItemChangeSuccessBlock)successBlock
               failBlock:(_Nullable TOSMBSessionShareFailBlock)failBlock;

-(void)removeItemAtPath:(NSString *)path
           successBlock:(dispatch_block_t)successBlock
              failBlock:(TOSMBSessionShareFailBlock)failBlock;


@end
