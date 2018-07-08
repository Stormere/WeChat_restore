//
//  ContatctViewController.h
//  split
//
//  Created by 郜俊博 on 2018/7/8.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ContactDelegate  <NSObject>
@required//这个可以是required，也可以是optional
-(void)refreshTableView:(NSString *)wxid;
@end

@interface ContatctViewController : NSViewController

@property (nonatomic, weak)  id<ContactDelegate> delegate;


@end
