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
#include <vector>
#include "SqliteModel.hpp"

using namespace std;

static  vector<SqliteModel *> sqlites(10);

dispatch_semaphore_t event = dispatch_semaphore_create(1) ; //提交验证码的信号量

@interface DBManager()



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

-(void)initPath:(const char *)path {
    
    dispatch_semaphore_wait(event,DISPATCH_TIME_FOREVER);
    for (int i=0; i<sqlites.size(); i++) {
        
        if (sqlites[i] != nil) {
            if (strcmp(path, sqlites[i]->path) == 0) {
                break;
            }
        } else {
            sqlites[i] = (SqliteModel *)malloc(sizeof(SqliteModel));
            
            sqlites[i]->path = (char *)malloc(strlen(path));
            memcpy(sqlites[i]->path, path, strlen(path));
            int result = sqlite3_open(path, &(sqlites[i]->db));
            if (result == SQLITE_OK) {
                NSLog(@"成功打开数据库.");
            } else {
                NSLog(@"%s",sqlite3_errstr(result)) ;
            }
            break;
        }
        
       
    }
    dispatch_semaphore_signal(event);

}

-(void)dealloc {
    for (int i=0; i<sqlites.size(); i++) {
        if (sqlites[i] -> db != nil) {
            int result = sqlite3_close(sqlites[i] -> db);
            if (result == SQLITE_OK) {
                NSLog(@"成功关闭数据库.");
            } else {
                NSLog(@"%s",sqlite3_errstr(result)) ;
            }
            sqlites[i] -> db = nil;
        }
    }
}


-(NSMutableArray *)execQuery:(const char *) sql className:(const char *)className dbPath:(const char *)path{
    
    sqlite3 *_db = nil;
    for (int i=0; i<sqlites.size(); i++) {
        if (strcmp(path, sqlites[i] -> path) == 0 ) {
            _db = sqlites[i]->db;
            break;
        }
    }
    
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
                            
//                            char *buffer = (char *)malloc(sqlite3_column_bytes(stmt, i));
//
//                            sprintf(buffer, "%s",sqlite3_column_text(stmt,i));
                            
                            if (strcmp("MessageModel", className)== 0 && strcmp("Message", sqlite3_column_name(stmt,i) ) == 0) {
                                
                                printf("00000000000000%s\n",sqlite3_column_text(stmt,i));
                                NSLog(@"%@",[NSString stringWithCString:(char *)sqlite3_column_text(stmt, i) encoding:NSUTF8StringEncoding] );

                            }
                            object_setIvar(instance, ivar, [NSString stringWithCString:(char *)sqlite3_column_text(stmt, i) encoding:NSUTF8StringEncoding] );
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
