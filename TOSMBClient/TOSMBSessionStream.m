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

-(instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    
    self.treeID = 0;
    self.fileID = 0;
    _smbSession = smb_session_new();
    
    _path = path;
    
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

- (TOSMBSessionFile *)requestFileForItemAtPath:(NSString *)filePath inTree:(smb_tid)treeID
{
    const char *fileCString = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    smb_stat fileStat = smb_fstat(self.smbSession, treeID, fileCString);
    if (!fileStat)
        return nil;
    
    TOSMBSessionFile *file = [[TOSMBSessionFile alloc] initWithStat:fileStat session:nil parentDirectoryFilePath:filePath];
    
    smb_stat_destroy(fileStat);
    
    return file;
}

#pragma mark -

-(BOOL)connectToShareWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
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
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock();
        return NO;
    }
    
    return YES;
}

-(BOOL)findTargetFileWithOoperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    return YES;
}

-(BOOL)openFileWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    [self doesNotRecognizeSelector:_cmd];
    return NO;
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
