//
//  TOSMBSessionReadStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionStream.h"

@interface TOSMBSessionReadStream : TOSMBSessionStream

-( NSData * _Nullable )readChunk:( NSError * _Nullable __autoreleasing * _Nullable)error;

@end
