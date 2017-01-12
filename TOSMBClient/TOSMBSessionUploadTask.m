//
// TOSMBSessionUploadTake.m
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

#import "TOSMBSessionUploadTaskPrivate.h"
#import "TOSMBSessionPrivate.h"

@interface TOSMBSessionUploadTask ()

@property (nonatomic, copy) NSString *path;

@property (nonatomic, strong) NSFileHandle *sourceFilehandle;
@property (nonatomic) long long fileSize;

@property (nonatomic, strong) TOSMBSessionFile *file;

@property (nonatomic, weak) id <TOSMBSessionUploadTaskDelegate> delegate;
@property (nonatomic, copy) void (^successHandler)(TOSMBSessionFile *file);

@end

@implementation TOSMBSessionUploadTask

@dynamic delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
{
    if ((self = [super initWithSession:session])) {
        
        self.path = dstPath;
        
        self.sourceFilehandle = [NSFileHandle fileHandleForReadingAtPath:srcPath];
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:srcPath error:NULL];
        self.fileSize = [attributes fileSize];
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                       delegate:(id<TOSMBSessionUploadTaskDelegate>)delegate {
    if ((self = [self initWithSession:session sourcePath:srcPath dstPath:dstPath])) {
        self.delegate = delegate;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                     sourcePath:(NSString *)srcPath
                        dstPath:(NSString *)dstPath
                progressHandler:(id)progressHandler
                 successHandler:(id)successHandler
                    failHandler:(id)failHandler {
    if ((self = [self initWithSession:session sourcePath:srcPath dstPath:dstPath])) {
        self.progressHandler = progressHandler;
        self.successHandler = successHandler;
        self.failHandler = failHandler;
    }
    
    return self;
}

#pragma mark - delegate helpers

- (void)didSendBytes:(NSInteger)recentCount bytesSent:(NSInteger)totalCount {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(uploadTask:didSendBytes:totalBytesSent:totalBytesExpectedToSend:)]) {
            [weakSelf.delegate uploadTask:weakSelf
                             didSendBytes:recentCount
                           totalBytesSent:totalCount
                 totalBytesExpectedToSend:weakSelf.fileSize];
        }
        if (weakSelf.progressHandler) {
            weakSelf.progressHandler(totalCount, weakSelf.fileSize);
        }
    });
}

- (void)didFinish {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(uploadTaskDidFinishUploading:)]) {
            [weakSelf.delegate uploadTaskDidFinishUploading:self.file];
        }
        if (weakSelf.successHandler) {
            weakSelf.successHandler(self.file);
        }
    });
}

#pragma mark - task

- (void)performTaskWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation {
    
    if (weakOperation.isCancelled)
        return;
    
    smb_tid treeID = 0;
    smb_fd fileID = 0;
    //---------------------------------------------------------------------------------------
    
    BOOL success = [self connectToSMBDeviceOperation:weakOperation];
    if (success)
    {
        success = [self connectToShare:&treeID operation:weakOperation];
        
        if (success)
        {
            success = [self findTargetFile:treeID operation:weakOperation];
            if (success)
            {
                success = [self openFileTreeId:treeID fileID:&fileID operation:weakOperation];
                
                if (success)
                {
                    NSData *data;
                    NSInteger chunkSize = 1024 * 1024;
                    
                    ssize_t bytesWritten = 0;
                    ssize_t totalBytesWritten = 0;
                    
                    while ((data = [self.sourceFilehandle readDataOfLength: chunkSize]).length != 0)
                    {
                        NSUInteger bufferSize = data.length;
                        void *buffer = malloc(bufferSize);
                        [data getBytes:buffer length:bufferSize];
                        
                        bytesWritten = smb_fwrite(self.smbSession, fileID, buffer, MIN(bufferSize, 65471));
                        free(buffer);
                        totalBytesWritten += bytesWritten;
                        [self didSendBytes:bytesWritten bytesSent:totalBytesWritten];
                    }
                    
                    // Get uploaded file info
                    success = [self findTargetFile:treeID operation:weakOperation];
                    [self didFinish];
                }
            }
        }
    }
}

-(BOOL)connectToSMBDeviceOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    self.smbSession = smb_session_new();
    
    //First, check to make sure the server is there, and to acquire its attributes
    __block NSError *error = nil;
    dispatch_sync(self.session.serialQueue, ^{
        error = [self.session attemptConnectionWithSessionPointer:self.smbSession];
    });
    if (error) {
        [self didFailWithError:error];
        self.cleanupBlock(0, 0);
        return NO;
    }
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock(0, 0);
        return NO;
    }
    
    return YES;
}

-(BOOL)connectToShare:(smb_tid*)treeID operation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    //Connect to share
    
    //Next attach to the share we'll be using
    NSString *shareName = [self.session shareNameFromPath:self.path];
    const char *shareCString = [shareName cStringUsingEncoding:NSUTF8StringEncoding];
    smb_tree_connect(self.smbSession, shareCString, treeID);
    if (!treeID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeShareConnectionFailed)];
        self.cleanupBlock(*treeID, 0);
        return NO;
    }
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock(*treeID, 0);
        return NO;
    }
    
    return YES;
}

-(NSString *)filePath
{
    NSString *formattedPath = [self.session filePathExcludingSharePathFromPath:self.path];
    formattedPath = [NSString stringWithFormat:@"\\%@",formattedPath];
    formattedPath = [formattedPath stringByReplacingOccurrencesOfString:@"/" withString:@"\\\\"];
    return formattedPath;
}

-(BOOL)findTargetFile:(smb_tid)treeID operation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    //Find the target file
    //Get the file info we'll be working off
    self.file = [self requestFileForItemAtPath:self.filePath inTree:treeID];
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock(treeID, 0);
        return NO;
    }
    
    if (self.file.directory) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeDirectoryDownloaded)];
        self.cleanupBlock(treeID, 0);
        return NO;
    }
    return YES;
}

-(BOOL)openFileTreeId:(smb_tid)treeID fileID:(smb_fd*)fileID operation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    //Open the file handle
    smb_fopen(self.smbSession, treeID, [self.filePath cStringUsingEncoding:NSUTF8StringEncoding], SMB_MOD_RW, fileID);
    if (!*fileID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        self.cleanupBlock(treeID, *fileID);
        return NO;
    }
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock(treeID, *fileID);
        return NO;
    }
    return YES;
}

@end
