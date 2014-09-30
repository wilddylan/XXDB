XXDB
====

you can use it for simply DB work
while use it, you may read xxdb.h for how to use it

====

//
//  XXDB.h
//  XXDB
//
//  Created by xx-nb on 14-9-13.
//  Copyright (c) 2014年 xx-nb. All rights reserved.
//

/**
 * XXDB - DBUser
 * Version: 1.0
 */

#import <Foundation/Foundation.h>

/*
 please add libsqlite3.0.dylib
 请添加libsqlite3.0.dylib库
 */
#warning - MRC
#import <sqlite3.h>

@interface XXDB : NSObject

#pragma mark - DBMethods
/*
 create database using path and DBName
 使用路径、数据库名称创建数据库 如果数据库存在
 */
- (instancetype)initWithPathWithPath: (NSSearchPathDirectory)path
                        databaseName: (NSString *)DBName;
#pragma mark - Warning!
/*
 单例的设置 - 可选使用单例 - 只允许全程1个数据库
 */
+ (XXDB *)shareInstance;

/*
 设置数据库路径
 */
- (void)setDbPathWithPath: (NSString *)path;

#pragma mark tables
/*
 create table for database with SQL
 使用数据库语句创建表
 */
- (BOOL)createTableWithSQL: (NSString *)SQL;

/*
 通过模型与模型内的属性创建数据表
 */
- (BOOL)createTableByClassAttributes: (id)classModel;

/*
 drop table with tableName
 通过表名称删除表
 */
- (BOOL)dropTableWithTableName: (NSString *)tableName;

#pragma mark Open/Close DB
/*
 open/close database
 打开/关闭数据库
 */
- (BOOL)openDatabase;
- (BOOL)closeDatabase;

#pragma mark UpdateDB
/*
 Update
 Tip: without SELECT !!
 更新语句： 可用于除查询语句之外的所有数据库语句 包括创建、删除表等
 */
- (BOOL)updateDatabaseWithSQL: (NSString *)SQL;

/*
 通过类的属性 得到SQL插入语句 INSERT!!  测试外边拼接是否正确的... 大家淡定、 或者可以帮助你做测试
 */
- (NSString *)sqlQueryWithClassAttributes: (id)object
                                tableName:(NSString *)tableName;

#pragma mark SearchDB
/*
 search all Table members with tableName
 members type must be NSString !! 
 object is model what class you need !!
 使用表名称、 你想得到的对象模型查询所有表中的数据 如果表名称或者对象错误、有可能奔溃。。。。
 */
- (NSArray *)selectAllMembersWithTableName: (NSString *)tableName
                             objectModel:(id)object;

/*
 get allValues by columName
 通过字段得到所有值
 */
- (NSArray *)selectWithColumName: (NSString *)columName
                        tableName: (NSString *)tableName;

#pragma mark selectWithSqlQueryDict
/*
 get value with sql statement
 you must give columName(dict key) = value(dict value) - all string type.
 e.g  dict = {
                "name" = "xxdbuser",
                "age"  = "19"
                };
 object: model you want
 通过包含有你的约束条件的字典、 通过表名称、 你所给的模型、 返回包含有若干模型的数组
 */
- (NSArray *)selectWithSqlQueryDictionary: (NSDictionary *)sqlQueryDictionary
                                tableName: (NSString *)tableName
                                   model: (id)object;

#pragma mark - errorMessage
- (NSError*)errorWithMessage:(NSString*)message;
@end
