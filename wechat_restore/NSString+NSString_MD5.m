//
//  NSString+NSString_MD5.m
//  wechat_restore
//
//  Created by 郜俊博 on 2018/7/7.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import "NSString+NSString_MD5.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSString (NSString_MD5)

+(NSString *)MD5_Lower:(NSString *)str {
    const char* input = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (CC_LONG)strlen(input), result);
    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [digest appendFormat:@"%02x", result[i]];
    }
    return digest;
}

@end
