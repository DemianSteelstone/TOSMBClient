//
//  TOSMBSessionDeleteStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 19.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionDeleteStream.h"

#import "NSString+SMBNames.h"
#import "TOSMBConstants.h"
#import "TOSMBSessionFile.h"

@implementation TOSMBSessionDeleteStream

-(void)removeItemWithSuccessBlock:(dispatch_block_t)successBlock
                        failBlock:(TOSMBSessionStreamFailBlock)failBlock
{
    int result = 0;
    
    if (self.file.directory)
    {
        result = [self removeFolderAtPath:self.path];
    }
    else
    {
        result = [self removeFileAtPath:self.path];
    }
    
    if (result)
    {
        uint32_t status = smb_session_get_nt_status(self.smbSession);
        NSString *err = localizedStatusCode(status);
        NSLog(@"TOSMBSessionReadStream :: Delete failed. NT status %@",err);
        if (failBlock)
            failBlock(errorForErrorCode(TOSMBSessionErrorCodeDeleteFailed));
    }
    else
    {
        if (successBlock)
            successBlock();
    }
    self.cleanupBlock();
}

-(uint32_t)removeFolderAtPath:(NSString *)path
{
    NSString *folderContentPath = [path stringByAppendingPathComponent:@"*"];
    NSString *formattedPath = [path formattedFilePath];
    NSString *folderContentFormattedPath = [folderContentPath formattedFilePath];
    
    smb_stat_list statList = smb_find(self.smbSession, self.treeID, folderContentFormattedPath.UTF8String);
    size_t listCount = smb_stat_list_count(statList);
    
    uint32_t result = 0;
    
    for (NSInteger i = 0; i < listCount; i++) {
        smb_stat item = smb_stat_list_at(statList, i);
        
        const char* name = smb_stat_name(item);
        NSString *nameStr = [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSUTF8StringEncoding];
        if ([nameStr isEqualToString:@".."] || [nameStr isEqualToString:@"."])
            continue;
        
        NSString *pathWithName = [path stringByAppendingPathComponent:nameStr];
        
        BOOL isDir = smb_stat_get(item, SMB_STAT_ISDIR) != 0;
        
        if (isDir)
            result = [self removeFolderAtPath:pathWithName];
        else
            result = [self removeFileAtPath:pathWithName];
        
        if (result != 0)
            break;
    }
    
    if (result == 0)
        result = smb_directory_rm(self.smbSession,self.treeID,formattedPath.UTF8String);
    smb_stat_list_destroy(statList);
    return result;
}

-(uint32_t)removeFileAtPath:(NSString *)path
{
    NSString *formattedPath = [path formattedFilePath];
    return smb_file_rm(self.smbSession,self.treeID,formattedPath.UTF8String);
}

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

@end
