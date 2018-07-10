//
//  NSImageView+NSImageView_MyImageView.m
//  wechat_restore
//
//  Created by 郜俊博 on 2018/7/10.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import "NSImageView+NSImageView_Exten.h"

@implementation NSImageView (NSImageView_Exten)

- (void)setImageWithURL:(NSString *)url placeholderImage:(NSImage *)placeholder
{
    // 先设置placeholder
    self.image = placeholder;
    
    // 异步下载完了之后再加载新的图片
    if (url)
    {
        // 子线程下载
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            // NSURLSession *session = [NSURLSession alloc ] ini
            
            NSData *data          = [NSURLConnection sendSynchronousRequest:request
                                                          returningResponse:nil
                                                                      error:nil];
            // 主线程更新
            dispatch_async(dispatch_get_main_queue(), ^{
                if (data)
                {
                    self.image = [[NSImage alloc] initWithData:data];
                    [self setNeedsDisplay];
                }
            });
        });
    }
}


@end
