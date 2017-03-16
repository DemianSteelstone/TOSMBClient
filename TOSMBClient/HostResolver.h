//
//  HostResolver.h
//  DownloaderPlus
//
//  Created by Demian Steelstone on 16.03.17.
//  Copyright © 2017 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HostResolver : NSObject

+ (NSArray *)hostnamesForAddress:(NSString *)address;

@end
