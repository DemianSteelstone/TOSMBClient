//
//  TOSMBSessionStream.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TOSMBSessionFile;

typedef void(^TOSMBSessionStreamFailBlock)( NSError* _Nonnull error);
typedef void(^TOSMBSessionStreamItemChangeSuccessBlock)( TOSMBSessionFile * _Nonnull folder);

@interface TOSMBSessionStream : NSObject

@property (nonatomic, strong, nullable) TOSMBSessionFile *file;
@property (nonnull,readonly) NSString *path;

- (void)close;
- (BOOL)open:(NSError * _Nonnull __autoreleasing * _Nonnull)error;

@end
