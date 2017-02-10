//
//  TOSMBSessionReadStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionReadStream.h"
#import "TOSMBSessionStreamPrivate.h"

#import "NSString+SMBNames.h"
#import "TOSMBConstants.h"

#import "TOSMBShare.h"

@implementation TOSMBSessionReadStream

#pragma mark -

-(NSData *)readChunk:(NSError *__autoreleasing *)error
{
    int64_t bytesRead = 0;
    NSInteger bufferSize = 64000;
    char *buffer = malloc(bufferSize);
    
    bytesRead = smb_fread(self.share.smbSession, self.fileID, buffer, bufferSize);
    if (bytesRead < 0)
    {
        *error = errorForErrorCode(TOSMBSessionErrorCodeFileReadFailed);
    }
    
    NSData *data = [NSData dataWithBytes:buffer length:(NSUInteger)bytesRead];
    
    free(buffer);
    
    if (*error)
        return nil;
    return data;
}

#pragma mark -

-(uint32_t)permissions
{
    return SMB_MOD_RO;
}

@end
