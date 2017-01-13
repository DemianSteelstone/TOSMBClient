//
// TOSMBSessionTaskPrivate.h
// Copyright 2015-2016 Timothy Oliver
//
// This file is dual-licensed under both the MIT License, and the LGPL v2.1 License.
//
// -------------------------------------------------------------------------------
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
// -------------------------------------------------------------------------------

#ifndef TOSMBSessionTaskPrivate_h
#define TOSMBSessionTaskPrivate_h

@import UIKit;

#import "TOSMBSessionTask.h"
#import "TOSMBSession.h"
#import "TOSMBSessionFilePrivate.h"
#import "TOSMBSessionPrivate.h"
#import "smb_defs.h"
#import "smb_file.h"
#import "smb_dir.h"
#import "smb_session.h"
#import "smb_share.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TOSMBSessionConcreteTask <NSObject>

- (void)performTaskWithOperation:(__weak NSBlockOperation *)weakOperation;

@end

@interface TOSMBSessionTask ()

@property (nonatomic, weak) TOSMBSession *session;
@property (nonatomic, strong) TOSMBSessionFile *file;
@property (nonatomic, assign) TOSMBSessionTaskState state;

@property (nonatomic) smb_tid treeID;
@property (nonatomic) smb_fd fileID;

@property (nonatomic) BOOL isNewFile;
@property (nonatomic) BOOL dontOpenFile;
@property (nonatomic) BOOL dontCheckFolder;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, assign, nullable) smb_session *smbSession;
@property (nonatomic, strong, null_resettable) NSBlockOperation *taskOperation;
@property (nonatomic, readonly) dispatch_block_t cleanupBlock;

/** Feedback handlers */
@property (nonatomic, weak) id<TOSMBSessionTaskDelegate> delegate;
@property (nonatomic, copy) TOSMBSessionTaskProgressBlock progressHandler;
@property (nonatomic, copy) TOSMBSessionTaskFailBlock failHandler;

- (instancetype)initWithSession:(TOSMBSession *)session path:(NSString *)smbPath;

- (TOSMBSessionFile *)requestFileForItemAtPath:(NSString *)filePath inTree:(smb_tid)treeID;

- (void)fail;
- (void)didFailWithError:(NSError *)error;

-(NSString *)formattedFilePath;

@end

NS_ASSUME_NONNULL_END

#endif /* TOSMBSessionTaskPrivate_h */
