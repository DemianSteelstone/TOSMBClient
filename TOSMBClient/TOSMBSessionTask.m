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
#import "TOSMBShare.h"

@interface TOSMBSessionTask ()

@end

@implementation TOSMBSessionTask

- (instancetype)initWithSession:(TOSMBSession *)session share:(nonnull TOSMBShare *)share {
    if((self = [super init])) {
        self.session = session;
        self.share = share;
    }
    
    return self;
}

#pragma mark - Properties

- (NSBlockOperation *)taskOperation {
    if (!_taskOperation) {
        _taskOperation = [[NSBlockOperation alloc] init];
        
        __weak typeof(self) weakSelf = self;
        [_taskOperation addExecutionBlock:^{
            [weakSelf prepare];
        }];
        
        _taskOperation.completionBlock = ^{
            weakSelf.taskOperation = nil;
        };
    }
    return _taskOperation;
}

#pragma mark - Task Methods

-(void)prepare
{
    BOOL prepeared = YES;
    
    NSError *error = [self.session attemptConnectionToShare:self.share];
    
    if (self.share.connected == NO)
    {
        NSError *error = nil;
        prepeared = [self.share connectToShare:&error];
    }
    
    if (!error && prepeared)
    {
        [self performTask];
    }
    else
    {
        [self didFailWithError:error];
    }
}

- (void)performTask {
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
    self.state = TOSMBSessionTaskStateCancelled;
    
    self.taskOperation = nil;
}

-(BOOL)isCanceled
{
    return self.state == TOSMBSessionTaskStateCancelled;
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
