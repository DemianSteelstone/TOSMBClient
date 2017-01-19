//
//  TOSMBSessionWriteStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionStream.h"

@class TOSMBSessionFile;

@interface TOSMBSessionWriteStream : TOSMBSessionStream

-(uint64_t)writeData:(NSData *)data error:(NSError**)error;

@end
