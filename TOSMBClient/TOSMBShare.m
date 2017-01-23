//
//  TOSMBStreamSession.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 20.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBShare.h"
#import "NSString+SMBNames.h"
#import "TOSMBConstants.h"

#import "TOSMBSessionFilePrivate.h"

@implementation TOSMBShare

-(instancetype)initWithShareName:(NSString *)shareName
{
    self = [super init];
    
    _shareName = shareName;
    _smbSession = smb_session_new();
    
    return self;
}

-(void)dealloc
{
    [self cleanup];
}

-(BOOL)connected
{
    return self.treeID != 0;
}

-(void)cleanup
{
    if (self.treeID) {
        smb_tree_disconnect(self.smbSession, self.treeID);
        self.treeID = 0;
    }
    
    if (self.smbSession) {
        smb_session_destroy(self.smbSession);
        self.smbSession = nil;
    }
}

-(BOOL)connectToShare:(NSError *__autoreleasing  _Nonnull *)error
{
    smb_tid treeID;
    
    const char *sn = _shareName.UTF8String;
    smb_tree_connect(self.smbSession, sn, &treeID);
    if (!treeID) {
        *error = errorForErrorCode(TOSMBSessionErrorCodeShareConnectionFailed);
        [self cleanup];
        return NO;
    }
    
    self.treeID = treeID;
    
    return YES;
}

#pragma mark - Get item

- (TOSMBSessionFile *)requestItemAtPath:(NSString *)filePath
{
    NSString *formattedPath = filePath.formattedFilePath;
    const char *p = formattedPath.UTF8String;
    smb_stat fileStat = smb_fstat(self.smbSession, self.treeID, p);
    if (!fileStat)
        return nil;
    
    TOSMBSessionFile *file = [[TOSMBSessionFile alloc] initWithStat:fileStat
                                                           filePath:filePath];
    
    smb_stat_destroy(fileStat);
    
    return file;
}

#pragma mark - Create Folder

-(void)createFolderAtPath:(NSString *)path
             successBlock:(TOSMBSessionShareItemChangeSuccessBlock)successBlock
                failBlock:(TOSMBSessionShareFailBlock)failBlock
{
    NSString *formattedFilePath = [path formattedFilePath];
    const char *p = formattedFilePath.UTF8String;
    int result = smb_directory_create(self.smbSession,self.treeID,p);
    if (result)
    {
        if (failBlock)
            failBlock(errorForErrorCode(result));
    }
    else
    {
        TOSMBSessionFile *file = [self requestItemAtPath:path];
        
        if (file == nil)
        {
            if (failBlock)
                failBlock(errorForErrorCode(TOSMBSessionErrorCodeFileNotFound));
        }
        else
        {
            if (successBlock)
                successBlock(file);
        }
    }
}

#pragma mark - Move

-(void)moveItemFromPath:(NSString *)srcPath
                 toPath:(NSString *)dstPath
           successBlock:(TOSMBSessionShareItemChangeSuccessBlock)successBlock
              failBlock:(TOSMBSessionShareFailBlock)failBlock
{
    NSString *srcShare = [srcPath shareName];
    NSString *dstShare = [dstPath shareName];
    
    if ([srcShare isEqualToString:dstShare] == NO)
    {
        if (failBlock)
            failBlock([NSError errorWithDomain:TOSMBClientErrorDomain code:-3 userInfo:@{
                                                                                         NSLocalizedDescriptionKey : @"You can't move files between different shares",
                                                                                         }]);
        return;
    }
    
    NSString *srcShortPath = [srcPath formattedFilePath];
    NSString *dstShortPath = [dstPath formattedFilePath];
    
    const char *srcP = srcShortPath.UTF8String;
    const char *dstP = dstShortPath.UTF8String;
    
    uint32_t result = smb_file_mv(self.smbSession,self.treeID,srcP,dstP);
    if (result != 0)
    {
        if (failBlock)
            failBlock(errorForErrorCode(result));
    }
    else
    {
        TOSMBSessionFile *file = [self requestItemAtPath:dstPath];
        if (successBlock)
            successBlock(file);
    }
}

#pragma mark - Remove

-(void)removeItemAtPath:(NSString *)path
           successBlock:(dispatch_block_t)successBlock
              failBlock:(TOSMBSessionShareFailBlock)failBlock
{
    TOSMBSessionFile *item = [self requestItemAtPath:path];
    
    int result = 0;
    
    if (item.directory)
    {
        result = [self removeFolderAtPath:path];
    }
    else
    {
        result = [self removeFileAtPath:path];
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
}

-(uint32_t)removeFolderAtPath:(NSString *)path
{
    NSString *folderContentPath = [path stringByAppendingPathComponent:@"*"];
    NSString *formattedPath = [path formattedFilePath];
    NSString *folderContentFormattedPath = [folderContentPath formattedFilePath];
    
    const char *ffp = folderContentFormattedPath.UTF8String;
    
    smb_stat_list statList = smb_find(self.smbSession, self.treeID, ffp);
    size_t listCount = smb_stat_list_count(statList);
    
    uint32_t result = 0;
    
    for (NSInteger i = 0; i < listCount; i++) {
        smb_stat item = smb_stat_list_at(statList, i);
        
        const char* name = smb_stat_name(item);
        NSString *nameStr = [[NSString alloc] initWithBytes:name
                                                     length:strlen(name)
                                                   encoding:NSUTF8StringEncoding];
        if ([nameStr isEqualToString:@".."] || [nameStr isEqualToString:@"."])
        {
            continue;
        }
        
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
    {
        const char *fp = formattedPath.UTF8String;
        result = smb_directory_rm(self.smbSession,self.treeID,fp);
    }
    
    smb_stat_list_destroy(statList);
    return result;
}

-(uint32_t)removeFileAtPath:(NSString *)path
{
    NSString *formattedPath = [path formattedFilePath];
    const char *fp = formattedPath.UTF8String;
    return smb_file_rm(self.smbSession,self.treeID,fp);
}

@end
