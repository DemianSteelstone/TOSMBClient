//
//  TOSMBSessionWriteStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionWriteStream.h"
#import "TOSMBSessionStreamPrivate.h"

#import "TOSMBConstants.h"
#import "NSString+SMBNames.h"
#import "TOSMBShare.h"

@implementation TOSMBSessionWriteStream

#pragma mark -

-(ssize_t)writeData:(NSData *)data error:(NSError**)error
{
    ssize_t bytesWritten = 0;
    NSUInteger bufferSize = data.length;
    void *buffer = malloc(bufferSize);
    [data getBytes:buffer length:bufferSize];
    
    bytesWritten = smb_fwrite(self.share.smbSession, self.fileID, buffer, bufferSize);
    
    if (bytesWritten < 0)
    {
        *error = errorForErrorCode(bytesWritten);
    }
    
    free(buffer);
    return bytesWritten;
}

#pragma mark -
-(uint32_t)permissions
{
    return SMB_MOD_RW;
}

-(BOOL)findTargetFile:(NSError *__autoreleasing *)error
{
    return YES;
}

@end
