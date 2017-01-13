//
//  TOSMBSessionUploadStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionUploadStream.h"

#import "TOSMBConstants.h"
#import "NSString+SMBNames.h"

@implementation TOSMBSessionUploadStream

#pragma mark -

-(void)upload:(NSString *)path
progressBlock:(TOSMBSessionUploadStreamProgressBlock)progressBlock
 successBlock:(TOSMBSessionUploadStreamSuccessBlock)successBlock
    failBlock:(TOSMBSessionStreamFailBlock)failBlock
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    long long expectedSize = [attributes fileSize];
    
    NSData *data;
    NSInteger chunkSize = 65471;
    
    ssize_t bytesWritten = 0;
    ssize_t totalBytesWritten = 0;
    
    [fileHandle seekToFileOffset:0];
    
    while (((data = [fileHandle readDataOfLength: chunkSize]).length > 0))
    {
        NSUInteger bufferSize = data.length;
        void *buffer = malloc(bufferSize);
        [data getBytes:buffer length:bufferSize];
        @try {
            bytesWritten = smb_fwrite(self.smbSession, self.fileID, buffer, bufferSize);
        } @catch (NSException *exception) {
            free(buffer);
            
            if (failBlock)
                failBlock(errorForErrorCode(TOSMBSessionErrorCodeUnknown));
            
        } @finally {
            totalBytesWritten += bytesWritten;
            if (progressBlock)
            {
                progressBlock(bytesWritten,totalBytesWritten,expectedSize);
            }
            free(buffer);
        }
    }
    
    // Get uploaded file info
    TOSMBSessionFile *file = [self requestFileForItemAtPath:self.path
                                                     inTree:self.treeID];
    if (successBlock)
        successBlock(file);
    
    self.cleanupBlock();
}

#pragma mark -
-(BOOL)findTargetFileWithOoperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    //Find the target file
    //Get the file info we'll be working off
    NSString *path = [self.path formattedFilePath];
    self.file = [self requestFileForItemAtPath:path inTree:self.treeID];
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock();
        return NO;
    }
    
    return YES;
}

-(BOOL)openFileWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
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
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock();
        return NO;
    }
    return YES;
}

@end
