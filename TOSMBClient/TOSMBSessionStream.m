//
//  TOSMBSessionStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOSMBSessionStream.h"
#import "TOSMBConstants.h"

#import "NSString+SMBNames.h"

#import "TOSMBSessionFilePrivate.h"


@interface TOSMBSessionStream ()

@property (nonatomic, copy) TOSMBSessionStreamFailBlock failHandler;

@end

@implementation TOSMBSessionStream

+(instancetype)streamForPath:(NSString *)path
{
    return [[self alloc] initWithPath:path];
}

+(instancetype)streamWithSession:(smb_session *)session path:(NSString *)path
{
    TOSMBSessionStream *stream = [[self alloc] initWithSession:session path:path];
    return stream;
}

-(instancetype)initWithSession:(smb_session *)session path:(NSString *)path
{
    self = [super init];
    self.treeID = 0;
    self.fileID = 0;
    _smbSession = session;
    _path = path;
    return self;
}

-(instancetype)initWithPath:(NSString *)path
{
    self = [self initWithSession:smb_session_new() path:path];
    return self;
}

#pragma mark -

- (dispatch_block_t)cleanupBlock {
    return ^{
        
        //Release the background task handler, making the app eligible to be suspended now
        if (self.backgroundTaskIdentifier) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = 0;
        }
        
        if (self.treeID) {
            smb_tree_disconnect(self.smbSession, self.treeID);
        }
        
        if (self.smbSession && self.fileID) {
            smb_fclose(self.smbSession, self.fileID);
        }
        
        
        if (self.smbSession) {
            smb_session_destroy(self.smbSession);
            self.smbSession = nil;
        }
    };
}

#pragma mark -

-(TOSMBSessionFile *)requestContent
{
    return [self requestFileForItemAtPath:self.path
                                   inTree:self.treeID];
}

- (TOSMBSessionFile *)requestFileForItemAtPath:(NSString *)filePath inTree:(smb_tid)treeID
{
    const char *fileCString = self.path.formattedFilePath.UTF8String;
    smb_stat fileStat = smb_fstat(self.smbSession, treeID, fileCString);
    if (!fileStat)
        return nil;
    
    TOSMBSessionFile *file = [[TOSMBSessionFile alloc] initWithStat:fileStat
                                                            session:nil
                                                           filePath:filePath];
    
    smb_stat_destroy(fileStat);
    
    return file;
}

#pragma mark -

-(void)createFolderWithSuccessBlock:(TOSMBSessionStreamItemChangeSuccessBlock)successBlock
                          failBlock:(TOSMBSessionStreamFailBlock)failBlock
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
        TOSMBSessionFile *file = [self requestContent];
        
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
    
    self.cleanupBlock();
}

-(void)moveItemToPath:(NSString *)dst
         successBlock:(TOSMBSessionStreamItemChangeSuccessBlock)successBlock
            failBlock:(TOSMBSessionStreamFailBlock)failBlock
{
    NSString *srcShare = [self.path shareName];
    NSString *dstShare = [dst shareName];
    
    if ([srcShare isEqualToString:dstShare] == NO)
    {
        if (failBlock)
            failBlock([NSError errorWithDomain:TOSMBClientErrorDomain code:-3 userInfo:@{
                                                                                         NSLocalizedDescriptionKey : @"You can't move files between different shares",
                                                                                         }]);
        return;
    }
    
    NSString *srcPath = [self.path formattedFilePath];
    NSString *dstPath = [dst formattedFilePath];
    
    int result = smb_file_mv(self.smbSession,self.treeID,srcPath.UTF8String,dstPath.UTF8String);
    if (result != 0)
    {
        
        
        if (failBlock)
            failBlock(errorForErrorCode(result));
    }
    else
    {
        TOSMBSessionFile *file = [self requestFileForItemAtPath:dst
                                                         inTree:self.treeID];
        if (successBlock)
            successBlock(file);
    }
    
    self.cleanupBlock();
}

-(void)removeItemWithSuccessBlock:(dispatch_block_t)successBlock
                        failBlock:(TOSMBSessionStreamFailBlock)failBlock
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

-(NSError *)errorForResult:(int)result
{
    NSInteger errorCode = TOSMBSessionErrorCodeUnknown;
    NSString * errorDescription = localizedStringForErrorCode(errorCode);
    
    if (result == DSM_ERROR_NETWORK)
    {
        errorCode = -3;
        errorDescription = @"Undefined network error";
    }
    else if (result == DSM_ERROR_NT)
    {
        errorCode = -2;
        uint32_t status = smb_session_get_nt_status(self.smbSession);
        NSString *statusMessage = localizedStatusCode(status);
        errorDescription = [NSString stringWithFormat:@"NT status:%@",statusMessage];
    }
    
    return [NSError errorWithDomain:TOSMBClientErrorDomain
                               code:errorCode
                           userInfo:@{
                                      NSLocalizedDescriptionKey : errorDescription,
                                      }];
}

#pragma mark -

-(void)close
{
    _closed = YES;
}

-(void)openStream:(dispatch_block_t)successBlock failBlock:(TOSMBSessionStreamFailBlock)failBlock
{
    self.failHandler = failBlock;
    if ([self connectToShare])
    {
        if (!self.isClosed && [self findTargetFile])
        {
            if (!self.isClosed && [self openFile])
            {
                _opened = YES;
                if (successBlock)
                    successBlock();
            }
        }
    }
}

-(BOOL)connectToShare
{
    //Connect to share
    
    smb_tid treeID;
    //Next attach to the share we'll be using
    NSString *shareName = [self.path shareName];
    const char *shareCString = [shareName cStringUsingEncoding:NSUTF8StringEncoding];
    smb_tree_connect(self.smbSession, shareCString, &treeID);
    if (!treeID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeShareConnectionFailed)];
        self.cleanupBlock();
        return NO;
    }
    
    self.treeID = treeID;
    
    return YES;
}

-(BOOL)findTargetFile
{
    return YES;
}

-(BOOL)openFile
{
    return YES;
}

- (void)didFailWithError:(NSError *)error
{
    self.cleanupBlock();
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.failHandler)
            self.failHandler(error);
    });
}

@end
