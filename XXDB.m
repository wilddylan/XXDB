//
//  XXDB.m
//  XXDB
//
//  Created by xx-nb on 14-9-13.
//  Copyright (c) 2014年 xx-nb. All rights reserved.
//

#import "XXDB.h"

@interface XXDB ()

@property (nonatomic, retain) NSString * dbPath;
@property (nonatomic, assign) sqlite3 * db;

@end
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
        do what? you diy.
     }
     */
    return self;
}

#pragma mark tables
- (BOOL)createTableWithSQL: (NSString *)SQL {
    
    // kind of open
    if (sqlite3_open([_dbPath UTF8String], &_db) == SQLITE_OK) {
        
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

- (BOOL)dropTableWithTableName: (NSString *)tableName {
    
    if (sqlite3_open([_dbPath UTF8String], &_db) == SQLITE_OK) {
        
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
    
    if (sqlite3_open([_dbPath UTF8String], &_db) == SQLITE_OK) {
        
        char * error;
        int result = sqlite3_exec(_db, [SQL UTF8String], NULL, NULL, &error);
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

#pragma mark - select DB
- (NSArray *)selectAllMembersWithTableName: (NSString *)tableName
                               objectModel:(id)object; {
    if (sqlite3_open([_dbPath UTF8String], &_db) == SQLITE_OK) {
        
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
    if (sqlite3_open([_dbPath UTF8String], &_db) == SQLITE_OK) {
        
        NSString * selectSQL = [NSString stringWithFormat:@"SELECT %@ FROM %@", columName, tableName];
        sqlite3_stmt * stmt = nil;
        
        int preResult = sqlite3_prepare_v2(_db, [selectSQL UTF8String], -1, &stmt, NULL);
        
        if (preResult == SQLITE_OK) {
            NSMutableArray * array = [NSMutableArray array];
            
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                [array addObject:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)]];
            }
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
    
    if (sqlite3_open([_dbPath UTF8String], &_db) == SQLITE_OK) {
        
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
