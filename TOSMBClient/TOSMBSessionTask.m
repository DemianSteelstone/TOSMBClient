//
// TOSMBSessionTask.h
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

#import "TOSMBSessionTaskPrivate.h"
#import "TOSMBSessionStreamPrivate.h"

@interface TOSMBSessionTask ()

@end

@implementation TOSMBSessionTask

- (instancetype)initWithSession:(TOSMBSession *)session stream:(nonnull TOSMBSessionStream *)stream {
    if((self = [super init])) {
        self.session = session;
        self.stream = stream;
    }
    
    return self;
}

#pragma mark - Properties

- (NSBlockOperation *)taskOperation {
    if (!_taskOperation) {
        _taskOperation = [[NSBlockOperation alloc] init];
        
        __weak typeof(self) weakSelf = self;
        __weak NSBlockOperation *weakOperation = _taskOperation;
        [_taskOperation addExecutionBlock:^{
            [weakSelf prepareWithOperation:weakOperation];
        }];
        
        _taskOperation.completionBlock = ^{
            weakSelf.taskOperation = nil;
        };
    }
    return _taskOperation;
}

#pragma mark - Task Methods

-(BOOL)connectToSMBDeviceOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    //First, check to make sure the server is there, and to acquire its attributes
    __block NSError *error = nil;
    dispatch_sync(self.session.serialQueue, ^{
        error = [self.session attemptConnectionWithSessionPointer:self.stream.smbSession];
    });
    if (error) {
        [self didFailWithError:error];
        return NO;
    }
    
    if (weakOperation.isCancelled) {
        self.stream.cleanupBlock();
        return NO;
    }
    
    return YES;
}

-(BOOL)prepareWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation
{
    if ([self connectToSMBDeviceOperation:weakOperation])
    {
        __weak typeof(self) weakSelf = self;
        [self.stream openStream:^{
            [weakSelf performTaskWithOperation:weakOperation];
        } failBlock:^(NSError *error) {
            [weakSelf didFailWithError:error];
        }];
    }
    
    return NO;
}

- (void)performTaskWithOperation:(__weak NSBlockOperation *)operation {
    return;
}

#pragma mark - Public Control Methods

- (void)start
{
    if (self.state == TOSMBSessionTaskStateRunning)
        return;
    
    [self.session.taskQueue addOperation:self.taskOperation];
    self.state = TOSMBSessionTaskStateRunning;
}

- (void)cancel
{
    if (self.state != TOSMBSessionTaskStateRunning)
        return;
    
    [self.taskOperation cancel];
    [self.stream close];
    self.state = TOSMBSessionTaskStateCancelled;
    
    self.taskOperation = nil;
}

#pragma mark - Private Control Methods

- (void)fail
{
    if (self.state != TOSMBSessionTaskStateRunning)
        return;
    
    [self cancel];
    
    self.state = TOSMBSessionTaskStateFailed;
}

#pragma mark - Feedback Methods -

- (void)didFailWithError:(NSError *)error
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(task:didCompleteWithError:)])
            [self.delegate task:self didCompleteWithError:error];
        if (self.failHandler)
            self.failHandler(error);
    });
}

@end
