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

@implementation TOSMBSessionReadStream

#pragma mark -

-(NSData *)readChunk:(NSError *__autoreleasing *)error
{
    int64_t bytesRead = 0;
    NSInteger bufferSize = 64000;
    char *buffer = malloc(bufferSize);
    
    bytesRead = smb_fread(self.smbSession, self.fileID, buffer, bufferSize);
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

-(BOOL)findTargetFile
{
    //Find the target file
    //Get the file info we'll be working off
    
    self.file = [self requestContent];
    
    if (self.file == nil) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        self.cleanupBlock();
        return NO;
    }
    
    return YES;
}

-(BOOL)openFile
{
    smb_fd fileID = 0;;
    //Open the file handle
    NSString *path = [self.path formattedFilePath];
    smb_fopen(self.smbSession, self.treeID, [path cStringUsingEncoding:NSUTF8StringEncoding], SMB_MOD_RO, &fileID);
    if (!fileID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        return NO;
    }
    
    self.fileID = fileID;
    return YES;
}

@end
