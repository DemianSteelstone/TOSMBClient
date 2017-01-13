//
//  TOSMBSessionDownloadStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionReadStream.h"

typedef void(^TOSMBSessionDownloadStreamProgressBlock)(uint64_t bytesWritten, uint64_t totalBytesWritten, uint64_t totalBytesExpected);

@interface TOSMBSessionDownloadStream : TOSMBSessionReadStream

-(void)downloadFileToFileHandle:(NSFileHandle *)fileHandle
                  progressBlock:(TOSMBSessionDownloadStreamProgressBlock)progressBlock
                   successBlock:(dispatch_block_t)successBlock
                      failBlock:(TOSMBSessionStreamFailBlock)failBlock;

@end
