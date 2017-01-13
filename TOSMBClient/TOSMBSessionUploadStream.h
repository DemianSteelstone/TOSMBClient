//
//  TOSMBSessionUploadStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionWriteStream.h"

typedef void(^TOSMBSessionUploadStreamSuccessBlock)(TOSMBSessionFile *item);
typedef void(^TOSMBSessionUploadStreamProgressBlock)(uint64_t bytesWritten, uint64_t totalBytesWritten, uint64_t totalBytesExpected);

@interface TOSMBSessionUploadStream : TOSMBSessionWriteStream

-(void)upload:(NSString *)path
progressBlock:(TOSMBSessionUploadStreamProgressBlock)progressBlock
 successBlock:(TOSMBSessionUploadStreamSuccessBlock)successBlock
    failBlock:(TOSMBSessionStreamFailBlock)failBlock;

@end
