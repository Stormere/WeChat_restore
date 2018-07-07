//
//  PCMPlayer.h
//  play_pcm
//
//  Created by 郜俊博 on 2018/6/26.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface PCMPlayer : NSObject

// 播放并顺带附上数据
- (void)playWithData: (NSData *)data;

-(void)playWithPath:(char *)srcFile info:(int )verbose API_Fs_Hz:(int ) API_Fs_Hz;

// reset
- (void)resetPlay;

@end
