//
//  TOSMBSessionWriteStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionStream.h"

@class TOSMBSessionFile;

typedef void(^TOSMBSessionWriteStreamFolderCreateSuccessBlock)(TOSMBSessionFile *folder);

@interface TOSMBSessionWriteStream : TOSMBSessionStream

-(void)createFolderWithSuccessBlock:(TOSMBSessionWriteStreamFolderCreateSuccessBlock)successBlock failBlock:(TOSMBSessionStreamFailBlock)failBlock;

-(void)removeItemWithSuccessBlock:(dispatch_block_t)successBlock failBlock:(TOSMBSessionStreamFailBlock)failBlock;

@end
