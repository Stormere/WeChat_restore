//
//  DBManager.m
//  wechat_restore
//
//  Created by 郜俊博 on 2018/7/3.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import "DBManager.h"
#import <sqlite3.h>
#include <iostream>
#include <vector>
#include "SqliteModel.hpp"

using namespace std;

static  vector<SqliteModel *> dbArray(10);

dispatch_semaphore_t event = dispatch_semaphore_create(1) ; //

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
    for (int i=0; i<dbArray.size(); i++) {
        
        if (dbArray[i] != nil) {
            if (strcmp(path, dbArray[i]->path) == 0) {
                break;
            }
        } else {
            dbArray[i] = (SqliteModel *)malloc(sizeof(SqliteModel));
            dbArray[i]->path = (char *)malloc(strlen(path));
            memcpy(dbArray[i]->path, path, strlen(path));
            int result = sqlite3_open(path, &(dbArray[i]->db));
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
    for (int i=0; i<dbArray.size(); i++) {
        if (dbArray[i] -> db != nil) {
            int result = sqlite3_close(dbArray[i] -> db);
            if (result == SQLITE_OK) {
                NSLog(@"成功关闭数据库.");
            } else {
                NSLog(@"%s",sqlite3_errstr(result)) ;
            }
            dbArray[i] -> db = nil;
        }
    }
}


-(NSMutableArray *)execQuery:(const char *) sql dbPath:(const char *)path{
    sqlite3 *_db = nil;
    for (int i=0; i<dbArray.size(); i++) {
        if (dbArray[i] != nil) {
            if (strcmp(path, dbArray[i] -> path) == 0 ) {
                _db = dbArray[i]->db;
                break;
            }
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
    do {
        ret = sqlite3_step(stmt);
        if(ret == SQLITE_ROW) {
            NSMutableDictionary *dict= [[NSMutableDictionary alloc] init];
            for( int i= 0;i<n_columns;i++ ) {
                type = sqlite3_column_type(stmt,i);
                NSString *filed = [NSString stringWithCString:(char *)sqlite3_column_name(stmt, i) encoding:NSUTF8StringEncoding];
                switch(type) {
                        case SQLITE_INTEGER:
                        {
                            [dict setValue:@(sqlite3_column_int(stmt, i)) forKey:filed];
                        }
                            break;
                        case SQLITE_FLOAT:
                        {
                            [dict setValue:@(sqlite3_column_double(stmt, i)) forKey:filed];
                        }
                            break;
                        case SQLITE_TEXT:
                        {
                            [dict setValue:[NSString stringWithCString:(char *)sqlite3_column_text(stmt, i) encoding:NSUTF8StringEncoding]  forKey:filed];
                        }
                            break;
                        case SQLITE_BLOB:
                        {
                            const void * blob = sqlite3_column_blob(stmt, i);
                            int sizw = sqlite3_column_bytes(stmt, i);
                            NSData *data = [[NSData alloc] initWithBytes:blob length:sizw];
                            [dict setValue:data  forKey:filed];
                        }
                            break;
                        case SQLITE_NULL:
                            break;
                        default:
                            break;
                }
            }
            [result addObject:dict];
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
