//
//  SqliteModel.hpp
//  wechat_restore
//
//  Created by 郜俊博 on 2018/7/7.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#ifndef SqliteModel_hpp
#define SqliteModel_hpp

#include <stdio.h>
#include <stdlib.h>
#include "sqlite3.h"

class SqliteModel {
    
public:
    sqlite3 *db;
    char *path;
    
    SqliteModel(char *dbPath ) {
        db = NULL;
        path = dbPath;
    }
    ~SqliteModel() {
        if(path != NULL) {
            db = NULL;
            free(path);
            path = NULL;
        }
    }
private :
    
};

#endif /* SqliteModel_hpp */
