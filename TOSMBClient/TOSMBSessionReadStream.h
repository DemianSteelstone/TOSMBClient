//
//  TOSMBSessionReadStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionStream.h"

@interface TOSMBSessionReadStream : TOSMBSessionStream

-(NSData *)readChunk:(NSError **)error;

@end
