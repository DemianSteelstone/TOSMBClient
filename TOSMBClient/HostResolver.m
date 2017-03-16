//
//  HostResolver.m
//  DownloaderPlus
//
//  Created by Demian Steelstone on 16.03.17.
//  Copyright © 2017 Macsoftex. All rights reserved.
//

#import <arpa/inet.h>
#include <netdb.h>

#import "HostResolver.h"

@implementation HostResolver

+ (NSArray *)hostnamesForAddress:(NSString *)address {
    // Get the host reference for the given address.
    struct addrinfo      hints;
    struct addrinfo      *result = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags    = AI_NUMERICHOST;
    hints.ai_family   = PF_UNSPEC; /* Allow IPv4 or IPv6 */
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = 0;
    hints.ai_canonname = NULL;
    hints.ai_addr = NULL;
    hints.ai_next = NULL;
    
    int errorStatus = getaddrinfo([address cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
    if (errorStatus != 0) return @[[self getErrorDescription:errorStatus]];
    
    CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
    if (addressRef == nil) return nil;
    
    freeaddrinfo(result);
    CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
    if (hostRef == nil) return nil;
    CFRelease(addressRef);
    BOOL isSuccess = CFHostStartInfoResolution(hostRef, kCFHostNames, NULL);
    if (!isSuccess) return nil;
    
    // Get the hostnames for the host reference.
    CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
    NSMutableArray *hostnames = [NSMutableArray array];
    for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)hostnamesRef count]; currentIndex++) {
        [hostnames addObject:[(__bridge NSArray *)hostnamesRef objectAtIndex:currentIndex]];
    }
    
    return hostnames;
}

+ (NSString *)getErrorDescription:(NSInteger)errorCode
{
    NSString *errorDescription = @"";;
    switch (errorCode) {
        case EAI_ADDRFAMILY: {
            errorDescription = @" address family for hostname not supported";
            break;
        }
        case EAI_AGAIN: {
            errorDescription = @" temporary failure in name resolution";
            break;
        }
        case EAI_BADFLAGS: {
            errorDescription = @" invalid value for ai_flags";
            break;
        }
        case EAI_FAIL: {
            errorDescription = @" non-recoverable failure in name resolution";
            break;
        }
        case EAI_FAMILY: {
            errorDescription = @" ai_family not supported";
            break;
        }
        case EAI_MEMORY: {
            errorDescription = @" memory allocation failure";
            break;
        }
        case EAI_NODATA: {
            errorDescription = @" no address associated with hostname";
            break;
        }
        case EAI_NONAME: {
            errorDescription = @" hostname nor servname provided, or not known";
            break;
        }
        case EAI_SERVICE: {
            errorDescription = @" servname not supported for ai_socktype";
            break;
        }
        case EAI_SOCKTYPE: {
            errorDescription = @" ai_socktype not supported";
            break;
        }
        case EAI_SYSTEM: {
            errorDescription = @" system error returned in errno";
            break;
        }
        case EAI_BADHINTS: {
            errorDescription = @" invalid value for hints";
            break;
        }
        case EAI_PROTOCOL: {
            errorDescription = @" resolved protocol is unknown";
            break;
        }
        case EAI_OVERFLOW: {
            errorDescription = @" argument buffer overflow";
            break;
        }
    }
    return errorDescription;
}

@end
