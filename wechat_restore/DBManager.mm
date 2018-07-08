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
#include <iostream>


@interface DBManager()

@property (nonatomic )sqlite3 *db ;
@property(atomic,retain) NSMutableArray *sqliteModel;



@end


@implementation DBManager

+(id)allocWithZone:(NSZone *)zone{
    return [DBManager sharedInstance];
}
+(DBManager *) sharedInstance{
    static DBManager * s_instance_dj_singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        s_instance_dj_singleton = [[super allocWithZone:nil] init];
    });
    return s_instance_dj_singleton;
}
-(id)copyWithZone:(NSZone *)zone{
    return [DBManager sharedInstance];
}
-(id)mutableCopyWithZone:(NSZone *)zone{
    return [DBManager sharedInstance];
}

-(void)addSqliteModel:(NSString *)path {
   
   
    
}

-(void)dealloc {
    if (_db != nil) {
        int result = sqlite3_close(_db);
        if (result == SQLITE_OK) {
            NSLog(@"成功关闭数据库.");
        } else {
            NSLog(@"%s",sqlite3_errstr(result)) ;
        }
        _db = nil;
    }
}

-(void)initDB:(NSString *)file {
    int result = 0;
    if (_db != nil) {
        NSLog(@"%s","数据库已经打开。");
        return;
    }
    result = sqlite3_open([file UTF8String], &_db);
    if (result == SQLITE_OK) {
        NSLog(@"成功打开数据库.");
    } else {
        NSLog(@"%s",sqlite3_errstr(result)) ;
    }
}
-(void)closeDB{
    int result = sqlite3_close(_db);
    _db = nil;
    if (result == SQLITE_OK) {
        NSLog(@"成功关闭数据库.");
    } else {
        NSLog(@"%s",sqlite3_errstr(result)) ;
    }
}
-(NSMutableArray *)execQuery:(const char *) sql className:(const char *)className {
    
    if (_db == nil) {
        return nil;
    }
    NSMutableArray *result = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmt;
    sqlite3_prepare(_db,sql,-1,&stmt,NULL);
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
                case SQLITE_BLOB:
                {
                    class_addIvar(Model, property, sizeof(NSData *), log2(sizeof(NSData *)), @encode(NSData *));
                }
                    break;
                case SQLITE_NULL:
                    break;
                default:
                    break;
            }
        }
        objc_registerClassPair(Model);
        
        
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
                case SQLITE_BLOB:
                {
                    Ivar ivar = class_getInstanceVariable(Model, sqlite3_column_name(stmt,i));
                    const void * blob = sqlite3_column_blob(stmt, i);
                    //得到字段中数据的长度
                    int sizw = sqlite3_column_bytes(stmt, i);
                    //根据字节和长度得到data对象
                    NSData *data = [[NSData alloc] initWithBytes:blob length:sizw];
                    object_setIvar(instance, ivar, data);
                }
                    break;
                case SQLITE_NULL:
                    break;
                default:
                    break;
                    
            }
        }
        [result addObject:instance];
        
        
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
                        case SQLITE_BLOB:
                        {
                            Ivar ivar = class_getInstanceVariable(Model, sqlite3_column_name(stmt,i));
                            const void * blob = sqlite3_column_blob(stmt, i);
                            //得到字段中数据的长度
                            int sizw = sqlite3_column_bytes(stmt, i);
                            //根据字节和长度得到data对象
                            NSData *data = [[NSData alloc] initWithBytes:blob length:sizw];
                            object_setIvar(instance, ivar, data);                            
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
            NSLog(@"%s",sqlite3_errmsg(_db)) ;
            break;
        }
    } while(true);
    sqlite3_finalize(stmt);
    return  result;
}

@end
