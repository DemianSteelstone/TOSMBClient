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

-(void)createFolderWithSuccessBlock:(TOSMBSessionWriteStreamFolderCreateSuccessBlock)successBlock failBlock:(TOSMBSessionStreamFailBlock)failBlock
{
    NSString *path = [self.path formattedFilePath];
    const char *fileCString = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    int result = smb_directory_create(self.smbSession,self.treeID,fileCString);
    if (result)
    {
        if (failBlock)
            failBlock(errorForErrorCode(result));
    }
    else
    {
        TOSMBSessionFile *file = [self requestFileForItemAtPath:self.path
                                                         inTree:self.treeID];
        if (successBlock)
            successBlock(file);
    }
    
    self.cleanupBlock();
}

-(void)removeItemWithSuccessBlock:(dispatch_block_t)successBlock failBlock:(TOSMBSessionStreamFailBlock)failBlock
{
    NSString *path = [self.path formattedFilePath];
    const char *fileCString = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    int result = 0;
    
    if (self.file.directory)
    {
        result = smb_directory_rm(self.smbSession,self.treeID,fileCString);
    }
    else
    {
        result = smb_file_rm(self.smbSession,self.treeID,fileCString);
    }
    
    if (result)
    {
        if (failBlock)
            failBlock(errorForErrorCode(result));
    }
    else
    {
        if (successBlock)
            successBlock();
    }
    self.cleanupBlock();
}

#pragma mark -
-(BOOL)openFileWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    return YES;
}

@end
