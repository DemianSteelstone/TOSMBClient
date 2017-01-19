//
//  TOSMBSessionWriteStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionWriteStream.h"

#import "TOSMBConstants.h"
#import "TOSMBSessionFile.h"
#import "NSString+SMBNames.h"

@implementation TOSMBSessionWriteStream

#pragma mark -

-(uint64_t)writeData:(NSData *)data error:(NSError**)error
{
    ssize_t bytesWritten = 0;
    NSUInteger bufferSize = data.length;
    void *buffer = malloc(bufferSize);
    [data getBytes:buffer length:bufferSize];
    
    bytesWritten = smb_fwrite(self.smbSession, self.fileID, buffer, bufferSize);
    
    if (bytesWritten == 0)
    {
        NSLog(@"Not written");
    }
    
    if (bytesWritten < 0)
    {
        *error = errorForErrorCode(bytesWritten);
    }
    
    free(buffer);
    return bytesWritten;
}

#pragma mark -
-(BOOL)findTargetFile
{
    //Find the target file
    //Get the file info we'll be working off
    self.file = [self requestContent];
    
    return YES;
}

-(BOOL)openFile
{
    smb_fd fileID = 0;;
    //Open the file handle
    NSString *path = [self.path formattedFilePath];
    smb_fopen(self.smbSession, self.treeID, path.UTF8String, SMB_MOD_RW, &fileID);
    if (!fileID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        return NO;
    }
    
    self.fileID = fileID;
    
    return YES;
}

@end
