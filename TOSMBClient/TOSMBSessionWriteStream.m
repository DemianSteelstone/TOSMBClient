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

-(void)writeData:(NSData *)data error:(NSError**)error
{
    ssize_t bytesWritten = 0;
    NSUInteger bufferSize = data.length;
    void *buffer = malloc(bufferSize);
    [data getBytes:buffer length:bufferSize];
    
    @try {
        bytesWritten = smb_fwrite(self.smbSession, self.fileID, buffer, bufferSize);
    }
    @catch (NSException *exception) {
        free(buffer);
        
        *error = errorForErrorCode(TOSMBSessionErrorCodeUnknown);
    } @finally {
        
        if (bytesWritten < 0)
        {
            *error = errorForErrorCode(bytesWritten);
        }
    }
    
    free(buffer);
}

#pragma mark -
-(BOOL)findTargetFile
{
    //Find the target file
    //Get the file info we'll be working off
    NSString *path = [self.path formattedFilePath];
    self.file = [self requestFileForItemAtPath:path inTree:self.treeID];
    
    return YES;
}

-(BOOL)openFile
{
    smb_fd fileID = 0;;
    //Open the file handle
    NSString *path = [self.path formattedFilePath];
    smb_fopen(self.smbSession, self.treeID, [path cStringUsingEncoding:NSUTF8StringEncoding], SMB_MOD_RW, &fileID);
    if (!fileID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        return NO;
    }
    
    self.fileID = fileID;
    
    return YES;
}

@end
