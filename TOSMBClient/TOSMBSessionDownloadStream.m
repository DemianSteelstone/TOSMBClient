//
//  TOSMBSessionDownloadStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionDownloadStream.h"
#import "TOSMBSessionFile.h"
#import "TOSMBConstants.h"

@implementation TOSMBSessionDownloadStream

#pragma mark -

-(void)downloadFileToFileHandle:(NSFileHandle *)fileHandle
                  progressBlock:(TOSMBSessionDownloadStreamProgressBlock)progressBlock
                   successBlock:(dispatch_block_t)successBlock
                      failBlock:(TOSMBSessionStreamFailBlock)failBlock
{
    int64_t bytesRead = 0;
    NSInteger bufferSize = 65535;
    uint64_t totalBytesRead = 0;
    char *buffer = malloc(bufferSize);
    
    dispatch_block_t finishBlock = ^{
        free(buffer);
        [fileHandle closeFile];
        self.cleanupBlock();
    };
    
    TOSMBSessionStreamFailBlock errorBlock = ^(NSError *error){
        if (failBlock)
        {
            failBlock(error);
        }
        finishBlock();
    };
    
    do {
        //Read the bytes from the network device
        @try {
            bytesRead = smb_fread(self.smbSession, self.fileID, buffer, bufferSize);
        } @catch (NSException *exception) {
            errorBlock(errorForErrorCode(TOSMBSessionErrorCodeUnknown));
            return;
        } @finally {
            if (bytesRead < 0)
            {
                errorBlock(errorForErrorCode(TOSMBSessionErrorCodeFileDownloadFailed));
                return;
            }
            //Save them to the file handle (And ensure the NSData object is flushed immediately)
            [fileHandle writeData:[NSData dataWithBytes:buffer length:(NSUInteger)bytesRead]];
            
            //Ensure the data is properly written to disk before proceeding
            [fileHandle synchronizeFile];
            
            totalBytesRead += bytesRead;
            
            if (progressBlock)
            {
                progressBlock(bytesRead,totalBytesRead,self.file.fileSize);
            }
            
        }
    } while (bytesRead > 0);
    
    finishBlock();
    
    if (successBlock)
    {
        successBlock();
    }
}

#pragma mark -
-(BOOL)findTargetFileWithOoperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    BOOL success = [super findTargetFileWithOoperation:weakOperation];
    
    if (success && self.file.directory) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeDirectoryDownloaded)];
        self.cleanupBlock();
        return NO;
    }
    return success;
}

@end
