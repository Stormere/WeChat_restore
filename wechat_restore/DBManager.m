//
//  DBManager.m
//  wechat_restore
//
//  Created by 郜俊博 on 2018/7/3.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import "DBManager.h"
#import <sqlite3.h>
#import <objc/message.h>

 sqlite3 *db = nil;

@implementation DBManager

-(void)dealloc {
    if (db != nil) {
        int result = sqlite3_close(db);
        if (result == SQLITE_OK) {
            NSLog(@"成功关闭数据库.");
        } else {
            NSLog(@"%s",sqlite3_errstr(result)) ;
        }
        db = nil;
    }
}

-(void)initDB:(NSString *)file {
    int result = 0;
    if (db != nil) {
        NSLog(@"%s","数据库已经打开。");
        return;
    }
    result = sqlite3_open([file UTF8String], &db);
    if (result == SQLITE_OK) {
        NSLog(@"成功打开数据库.");
    } else {
        NSLog(@"%s",sqlite3_errstr(result)) ;
    }
}
-(void)closeDB{
    int result = sqlite3_close(db);
    db = nil;
    if (result == SQLITE_OK) {
        NSLog(@"成功关闭数据库.");
    } else {
        NSLog(@"%s",sqlite3_errstr(result)) ;
    }
}
-(NSMutableArray *)execQuery:(const char *) sql className:(const char *)className {
    
    if (db == nil) {
        return nil;
    }
    NSMutableArray *result = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmt;
    sqlite3_prepare(db,sql,-1,&stmt,NULL);
    int n_columns = sqlite3_column_count(stmt);
    int ret = 0;
    int type = 0;
    Class Model = objc_getClass(className);
    if(!Model){
        Model = objc_allocateClassPair([NSObject class], className, 0);
        ret = sqlite3_step(stmt);
        for (int i=0; i< n_columns; i++) {
            type = sqlite3_column_type(stmt,i);
            const char *property = [[NSString stringWithFormat:@"%s",(const char *)(char *)sqlite3_column_name(stmt,i)] cStringUsingEncoding:NSASCIIStringEncoding] ;
            switch(type) {
                case SQLITE_INTEGER:
                    class_addIvar(Model, property, sizeof(id), log2(sizeof(id)), "i");
                    break;
                case SQLITE_FLOAT:
                    class_addIvar(Model, property, sizeof(id), log2(sizeof(id)), "f");
                    break;
                case SQLITE_TEXT:
                {
                    class_addIvar(Model, property, sizeof(NSString *), log2(sizeof(NSString *)), @encode(NSString *));
                }
                    break;
                case SQLITE_NULL:
                    break;
            }
        }
        objc_registerClassPair(Model);
    }
    do {
        ret = sqlite3_step(stmt);
        if(ret == SQLITE_ROW) {
            id instance = [[Model alloc] init];
            for( int i= 0;i<n_columns;i++ ) {
                
                type = sqlite3_column_type(stmt,i);
                switch(type) {
                        case SQLITE_INTEGER:
                        {
                            Ivar ivar = class_getInstanceVariable(Model, (char *)sqlite3_column_name(stmt,i));
                            object_setIvar(instance, ivar, @(sqlite3_column_int(stmt,i)));
                        }
                            break;
                        case SQLITE_FLOAT:
                        {
                            Ivar ivar = class_getInstanceVariable(Model, (char *)sqlite3_column_name(stmt,i));
                            object_setIvar(instance, ivar, @(sqlite3_column_double(stmt,i)));
                        }
                            break;
                        case SQLITE_TEXT:
                        {
                            Ivar ivar = class_getInstanceVariable(Model, sqlite3_column_name(stmt,i));
                            object_setIvar(instance, ivar, [NSString stringWithFormat:@"%s",sqlite3_column_text(stmt,i)]);
                        }
                            break;
                        case SQLITE_NULL:
                            break;
                        default:
                            break;
                        
                }
            }
            [result addObject:instance];
        } else if(ret == SQLITE_DONE) {
            break;
        } else {
            NSLog(@"%s",sqlite3_errmsg(db)) ;
            break;
        }
    } while(true);
    sqlite3_finalize(stmt);
    return  result;
}

@end
