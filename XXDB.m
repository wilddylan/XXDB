//
//  XXDB.m
//  XXDB
//
//  Created by xx-nb on 14-9-13.
//  Copyright (c) 2014年 xx-nb. All rights reserved.
//

#import "XXDB.h"
#import <objc/objc-runtime.h>

@interface XXDB ()

@property (nonatomic, retain) NSString * dbPath;
@property (nonatomic, assign) sqlite3 * db;

@end

static XXDB * db_user;
static dispatch_once_t once;

@implementation XXDB

#pragma mark - DBMethods
- (instancetype)initWithPathWithPath: (NSSearchPathDirectory)path
                        databaseName: (NSString *)DBName {
    
    self = [super init];
    if (self) {
        self.db = nil;
        
        self.dbPath = [NSSearchPathForDirectoriesInDomains(path, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:DBName];
    }
    
    /*
     if [NSFileManager defaultManager] fileExists:path] 
     {
        you diy.  wtf!!
     }
     */
    return self;
}

#pragma makr - shareInstance
+ (XXDB *)shareInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        db_user = [[self alloc] init];
        
        db_user.db = nil;
        db_user.dbPath = nil;
        
        NSLog(@"设置单例请先设置好您的数据库路径 Path");
    });
    
    return db_user;
}

#pragma mark - set db_path
- (void)setDbPathWithPath: (NSString *)path {
    self.dbPath = path;
}


#pragma mark tables
- (BOOL)createTableWithSQL: (NSString *)SQL {
    
    // kind of open
    if ([self openDatabase] == YES) {
        
        char * error;
        int result = sqlite3_exec(_db, [SQL UTF8String], NULL, NULL, &error);
        
        if (result == SQLITE_OK) {
            return YES;
        } else {
            NSLog(@"%s", error);
            return NO;
        }
    } else {
        NSLog(@"%@", [self errorWithMessage:@"openDB Failure"]);
        return NO;
    }
}

- (BOOL) createTableByClassAttributes: (id)classModel {
    
    // 得到类名 当表名、  也为了下边的反射、
    NSString *className = NSStringFromClass([classModel class]);
    
    // 初始化一个装sql的可变string
    NSMutableString * sqlQuery = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (", className];
    
    const char * cClassName = [className UTF8String];
    
    id classM = objc_getClass(cClassName);
    
    // i 计数 、  outCount 放我们的属性个数
    unsigned int outCount, i;
    
    // 反射得到属性的个数 、
    objc_property_t * properties = class_copyPropertyList(classM, &outCount);
    
    // 循环 得到属性名称  拼接数据库语句
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        // 获得属性名称
        NSString * attributeName = [NSString stringWithUTF8String:property_getName(property)];
        
        if (i == outCount - 1) {
            [sqlQuery appendFormat:@"%@ TEXT)", attributeName];
            break;
        }
        
        // 开始做拼接
        [sqlQuery appendFormat:@"%@ TEXT, ", attributeName];
    }
    
    if ([self openDatabase] == YES) {
        
        char * error;
        int result = sqlite3_exec(_db, [sqlQuery UTF8String], NULL, NULL, &error);
        if (result == SQLITE_OK) {
            return YES;
        } else {
            NSLog(@"%@", [self errorWithMessage:[NSString stringWithFormat:@"%s", error]]);
            return NO;
        }
    } else {
        NSLog(@"%@", [self errorWithMessage:@"openDB Failure"]);
        return NO;
    }
}

- (BOOL)dropTableWithTableName: (NSString *)tableName {
    
    if ([self openDatabase] == YES) {
        
        NSString * deleteSQL = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
        
        char * error;
        int result = sqlite3_exec(_db, [deleteSQL UTF8String], NULL, NULL, &error);
        if (result == SQLITE_OK) {
            return YES;
        } else {
            NSLog(@"%s", error);
            return NO;
        }
    } else {
        NSLog(@"%@", [self errorWithMessage:@"openDB Failure"]);
        return NO;
    }
}

#pragma mark open/close db
- (BOOL)openDatabase {
    
    if (nil != _db) {
        return YES;
    }
    
    int result = sqlite3_open([_dbPath UTF8String], &_db);
    if (result == SQLITE_OK) {
        
        return YES;
    } else {
        NSLog(@"%@", [self errorWithMessage:@"openDB Failure"]);
        return NO;
    }
}

- (BOOL)closeDatabase {
    
    if (!_db) {
        return YES;
    }
    
    int result = sqlite3_close(_db);
    if (result == SQLITE_OK) {
        
        _db = nil;
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - updateDB
/*
 This includes `CREATE`, `UPDATE`, `INSERT`, `ALTER`, `COMMIT`, `BEGIN`, `DETACH`, `DELETE`, `DROP`, `END`, `EXPLAIN`, `VACUUM`, and `REPLACE`.
 */
- (BOOL)updateDatabaseWithSQL: (NSString *)SQL {
    
    if ([self openDatabase] == YES) {
        
        char * error;
        int result = sqlite3_exec(_db, [SQL UTF8String], NULL, NULL, &error);
        if (result == SQLITE_OK) {
            return YES;
        } else {
            
            NSLog(@"%s", error);
            return NO;
        }
    } else {
        NSLog(@"%@", [self errorWithMessage:@"openDB Failure"]);
        return NO;
    }
}

- (NSString *)sqlQueryWithClassAttributes: (id)object
                                tableName:(NSString *)tableName {
    
    NSString * className = NSStringFromClass([object class]);
    const char * cClassName = [className UTF8String];
    id objClass = objc_getClass(cClassName);
    
    unsigned int count, i;
    objc_property_t * properties = class_copyPropertyList(objClass, &count);
    
    NSMutableString * coluname = [NSMutableString string];
    for (i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        // 获得属性名称
        NSString * attributeName = [NSString stringWithUTF8String:property_getName(property)];
        
        if (i == count - 1) {
            [coluname appendFormat:@"%@", attributeName];
            break;
        }
        // 开始做拼接
        [coluname appendFormat:@"%@, ", attributeName];
    }
    
    NSMutableString * sqlQuery = [NSMutableString string];
    // initMutableString
    [sqlQuery appendFormat:@"INSERT INTO %@ (%@) VALUES (<#withYourValue#>)", tableName, coluname];
    
    return sqlQuery;
}

#pragma mark - select DB
- (NSArray *)selectAllMembersWithTableName: (NSString *)tableName
                               objectModel:(id)object; {
    if ([self openDatabase] == YES) {
        
        NSString * selectSQL = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
        sqlite3_stmt * stmt = nil;
        
        int preResult = sqlite3_prepare_v2(_db, [selectSQL UTF8String], -1, &stmt, NULL);
        
        if (preResult == SQLITE_OK) {
            NSMutableArray * array = [NSMutableArray array];
            
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                
                id model = [[[object class] alloc] init];
                for (int i=0; i<sqlite3_column_count(stmt); i++) {
                    [model setValue:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, i)] forKey:[NSString stringWithUTF8String:(const char *)sqlite3_column_name(stmt, i)]];
                }
                [array addObject:model];
                [model release];
            }
            
            sqlite3_finalize(stmt);
            return array;
        } else {
            NSLog(@"check your sqlQuery and Model");
            return nil;
        }
    } else {
        NSLog(@"%@", [self errorWithMessage:@"SqlQuery error"]);
        return nil;
    }
}

- (NSArray *)selectWithColumName: (NSString *)columName
                       tableName: (NSString *)tableName {
    if ([self openDatabase] == YES) {
        
        NSString * selectSQL = [NSString stringWithFormat:@"SELECT %@ FROM %@", columName, tableName];
        sqlite3_stmt * stmt = nil;
        
        int preResult = sqlite3_prepare_v2(_db, [selectSQL UTF8String], -1, &stmt, NULL);
        
        if (preResult == SQLITE_OK) {
            NSMutableArray * array = [NSMutableArray array];
            
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                [array addObject:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)]];
            }
            
            sqlite3_finalize(stmt);
            return array;
        } else {
            NSLog(@"check your sqlQuery");
            return nil;
        }
    } else {
        NSLog(@"%@", [self errorWithMessage:@"openDB Failure"]);
        return nil;
    }
}

#pragma mark selectWithSqlQuery
- (NSArray *)selectWithSqlQueryDictionary: (NSDictionary *)sqlQueryDictionary
                                tableName: (NSString *)tableName
                                    model: (id)object {
    
    // getAllKeys
    NSArray * keyArray = sqlQueryDictionary.allKeys;
    NSString * sqlQuery = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE ", tableName];
    
    if ([self openDatabase] == YES) {
        
        // foreach build sqlQuery
        for (NSString * key in keyArray) {
            sqlQuery = [sqlQuery stringByAppendingString:[NSString stringWithFormat:@"%@ = '%@' and ", key, sqlQueryDictionary[key]]];
        }
        sqlQuery = [sqlQuery substringToIndex:[sqlQuery length] - 4];
        
        sqlite3_stmt * stmt;
        
        int result = sqlite3_prepare_v2(_db, [sqlQuery UTF8String], -1, &stmt, NULL);
        if (result == SQLITE_OK) {
            NSMutableArray * array = [NSMutableArray array];
            
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                
                id model = [[[object class] alloc] init];
                for (int i=0; i<sqlite3_column_count(stmt); i++) {
                    [model setValue:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, i)] forKey:[NSString stringWithUTF8String:(const char *)sqlite3_column_name(stmt, i)]];
                }
                [array addObject:model];
                [model release];
            }
            
            sqlite3_finalize(stmt);
            return array;
        } else {
            NSLog(@"check your sqlQuery");
            return nil;
        }
        
    } else {
        NSLog(@"%@", [self errorWithMessage:@"openDB Failure"]);
        return nil;
    }
}

#pragma mark - errorMessage
- (NSError *)errorWithMessage:(NSString *)message {
    return [NSError errorWithDomain:@"XXDB" code:sqlite3_errcode(_db) userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
}

#pragma mark - dealloc
- (void)dealloc {
    [_dbPath release];
    
    [super dealloc];
}

@end
