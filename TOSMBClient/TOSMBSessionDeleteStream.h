//
//  TOSMBSessionDeleteStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 19.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionStream.h"

@interface TOSMBSessionDeleteStream : TOSMBSessionStream

-(void)removeItemWithSuccessBlock:(_Nullable dispatch_block_t)successBlock
                        failBlock:(_Nullable TOSMBSessionStreamFailBlock)failBlock;

@end
