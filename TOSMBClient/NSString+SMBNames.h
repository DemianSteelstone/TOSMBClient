//
//  NSString+SMBNames.h
//  TOSMBClient
//
//  Created by Demian Steelstone on 13.01.17.
//  Copyright © 2017 TimOliver. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SMBNames)

- (NSString *)shareName;
- (NSString *)stringByExcludingSharePath;
- (NSString *)formattedFilePath;

@end
