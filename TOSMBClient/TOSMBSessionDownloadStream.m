//
//  TOSMBSessionDownloadStream.m
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import "TOSMBSessionDownloadStream.h"
#import "TOSMBSessionStreamPrivate.h"
#import "TOSMBSessionFile.h"
#import "TOSMBConstants.h"

@implementation TOSMBSessionDownloadStream

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
