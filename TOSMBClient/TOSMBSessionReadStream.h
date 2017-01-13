//
//  TOSMBSessionReadStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionStream.h"

typedef void(^TOSMBSessionReadStreamMoveSuccessBlock)(TOSMBSessionFile *item);

@interface TOSMBSessionReadStream : TOSMBSessionStream

-(void)moveItemToPath:(NSString *)path
         successBlock:(TOSMBSessionReadStreamMoveSuccessBlock)successBlock
            failBlock:(TOSMBSessionStreamFailBlock)failBlock;

@end
