//
//  TOSMBSessionStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOSMBSessionStreamPrivate.h"
#import "TOSMBConstants.h"

#import "NSString+SMBNames.h"

#import "TOSMBSessionFilePrivate.h"

#import "TOSMBShare.h"

@interface TOSMBSessionStream ()

@property (nonatomic, copy) TOSMBSessionStreamFailBlock failHandler;

@end

@implementation TOSMBSessionStream

+(instancetype)streamWithShare:(TOSMBShare *)share
                      itemPath:(NSString *)path
{
    TOSMBSessionStream *stream = [[self alloc] initWithShare:share
                                                    itemPath:path];
    return stream;
}

-(instancetype)initWithShare:(TOSMBShare *)share
                    itemPath:(NSString *)path
{
    self = [super init];
    
    self.fileID = 0;
    _share = share;
    _path = path;
    return self;
}

-(void)dealloc
{
    [self close];
}

-(void)close
{
    if (self.share && self.fileID)
    {
        smb_fclose(self.share.smbSession, self.fileID);
        self.fileID = 0;
    }
}

#pragma mark -

-(BOOL)open:(NSError **)error
{
    if ([self findTargetFile:error])
    {
        return [self openFile:error];
    }
    return NO;
}

-(BOOL)findTargetFile:(NSError **)error
{
    _file = [self.share requestItemAtPath:self.path];
    if (!_file)
    {
        *error = errorForErrorCode(TOSMBSessionErrorCodeFileNotFound);
        return NO;
    }
    return YES;
}

-(uint32_t)permissions
{
    return 0;
}

-(BOOL)openFile:(NSError **)error
{
    smb_fd fileID = 0;;
    //Open the file handle
    NSString *path = [self.path formattedFilePath];
    smb_fopen(self.share.smbSession, self.share.treeID, path.UTF8String, self.permissions, &fileID);
    if (!fileID) {
        *error = errorForErrorCode(TOSMBSessionErrorCodeFileNotFound);
        return NO;
    }
    
    self.fileID = fileID;
    return YES;
}

@end
