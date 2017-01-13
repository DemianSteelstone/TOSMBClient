//
//  TOSMBSessionReadStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionReadStream.h"

#import "NSString+SMBNames.h"
#import "TOSMBConstants.h"

@implementation TOSMBSessionReadStream

#pragma mark -

-(void)moveItemToPath:(NSString *)dst
         successBlock:(TOSMBSessionReadStreamMoveSuccessBlock)successBlock
            failBlock:(TOSMBSessionStreamFailBlock)failBlock
{
    NSString *srcPath = [self.path formattedFilePath];
    NSString *dstPath = [dst formattedFilePath];
    
    const char *srcPathCString = [srcPath cStringUsingEncoding:NSUTF8StringEncoding];
    const char *dstPathCString = [dstPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    int result = smb_file_mv(self.smbSession,self.treeID,srcPathCString,dstPathCString);
    if (result)
    {
        if (failBlock)
            failBlock(errorForErrorCode(result));
    }
    else
    {
        TOSMBSessionFile *file = [self requestFileForItemAtPath:dstPath
                                                         inTree:self.treeID];
        if (successBlock)
            successBlock(file);
    }
    
    self.cleanupBlock();
}

#pragma mark -

-(BOOL)findTargetFileWithOoperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    //Find the target file
    //Get the file info we'll be working off
    NSString *path = [self.path formattedFilePath];
    self.file = [self requestFileForItemAtPath:path inTree:self.treeID];
    
    if (self.file == nil) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        self.cleanupBlock();
        return NO;
    }
    
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
