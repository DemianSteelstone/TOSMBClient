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
    uint64_t totalBytesRead = 0;
    
    NSError *error = nil;
    
    do {
        NSData *data = [self readChunk:&error];
        
        if (error)
        {
            break;
        }
        else
        {
            bytesRead = data.length;
            totalBytesRead += bytesRead;
            
            //Save them to the file handle (And ensure the NSData object is flushed immediately)
            [fileHandle writeData:data];
            
            //Ensure the data is properly written to disk before proceeding
            [fileHandle synchronizeFile];
            
            if (progressBlock)
            {
                progressBlock(bytesRead,totalBytesRead,self.file.fileSize);
            }
        }
    } while (bytesRead > 0);
    
    [fileHandle closeFile];
    
    if (error)
    {
        if (failBlock)
        {
            failBlock(error);
        }
    }
    else
    {
        if (successBlock)
        {
            successBlock();
        }
    }
    
    self.cleanupBlock();
}

#pragma mark -
-(BOOL)findTargetFile
{
    BOOL success = [super findTargetFile];
    
    if (success && self.file.directory) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeDirectoryDownloaded)];
        self.cleanupBlock();
        return NO;
    }
    return success;
}

@end
