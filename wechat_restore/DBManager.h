//
//  DBManager.h
//  wechat_restore
//
//  Created by 郜俊博 on 2018/7/3.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBManager : NSObject

-(void)initDB:(NSString *)file ;
-(NSMutableArray *)execQuery:(const char *) sql className:(const char *)className;

-(void)closeDB;

@end