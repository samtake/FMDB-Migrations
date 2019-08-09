//
//  GetDBHelper.m
//  FMDB-Migrations
//
//  Created by 黄龙山 on 2019/8/9.
//  Copyright © 2019 黄龙山. All rights reserved.
//

#import "GetDBHelper.h"
#import <FMDB.h>



@interface GetDBHelper()
@property(nonatomic,strong) FMDatabaseQueue *queue;


//模型
@property(nonatomic,strong)t_AppUser *userModel;

@end


@implementation GetDBHelper

-(instancetype)init{
    self = [super init];
    if (self) {
        [self creatGetDBHelper];
    }
    return self;
}


+(GetDBHelper *)sharedInstance{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    _dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}


#pragma mark  - 数据库所有表的创建，仅仅是创好表。
-(void)creatGetDBHelper{
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:@"GetDB.sqlite"];
    NSLog(@"数据库存储路径filePath = %@",filePath);
    self.queue = [FMDatabaseQueue  databaseQueueWithPath:filePath];
    [self  creat_t_AppUser];
}

-(void)creat_t_AppUser{
    [self.queue  inDatabase:^(FMDatabase *db) {
        BOOL  create = [db  executeUpdate:@"CREATE TABLE IF NOT EXISTS t_AppUser(u_key INTEGER  PRIMARY KEY,u_id TEXT ,u_first_name TEXT,u_last_name TEXT)"];
        
        if (create) {
            NSLog(@"fmdb  创建本地t_AppUser列表成功");
        } else {
            NSLog(@"fmdb  创建本地t_AppUser列表失败");
        }
    }];
}


#pragma mark  - 对user表的操作

-(void)insert_t_AppUser_withModel:(t_AppUser *)model{
    model.u_first_name=@"这是beta 1.0";
    model.u_last_name=@"这是添加的字段值";
    
    NSString *insertsql_t_AppUser = [NSString  stringWithFormat:@"INSERT INTO  t_AppUser  (u_id,u_first_name,u_last_name)VALUES('%d','%@','%@');",model.u_id,model.u_first_name,model.u_last_name];
    NSLog(@"insertsql_t_AppUser=%@",insertsql_t_AppUser);
    [self.queue  inDatabase:^(FMDatabase *db) {
        BOOL res = [db executeUpdate:insertsql_t_AppUser];
        if (!res) {
            NSLog(@"FMDB 添加数据 失败");
        } else {
            NSLog(@"FMDB 添加数据 成功");
        }
    }];
}


-(void)delete_t_AppUser_withU_id:(int)u_id{
    NSString *sql = [NSString  stringWithFormat:@"DELETE   FROM  t_AppUser  WHERE  u_id = '%d' ",u_id];
    
    NSLog(@"sql=%@",sql);
    [self.queue inDatabase:^(FMDatabase *db) {
        BOOL res = [db  executeUpdate:sql];
        if (!res) {
            NSLog(@"FMDB 删除数据 失败");
        } else {
            NSLog(@"FMDB 删除数据 成功");
        }
    }];
}

-(NSMutableArray *)select_t_AppUser{
    NSString *selectsql_t_AppUser = [NSString stringWithFormat:@"Select  *   FROM  t_AppUser "];
    NSMutableArray *__block arr=[NSMutableArray new];

    [self.queue  inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:selectsql_t_AppUser];
        NSMutableDictionary *dict = rs.columnNameToIndexMap;
        NSLog(@"dict=%@",dict);
        while ([rs  next]) {
            if ([rs  stringForColumn:@"u_key"].length>0) {
                NSMutableDictionary * dic=[NSMutableDictionary new];
                [dic setObject:[rs  stringForColumn:@"u_first_name"] forKey:@"u_first_name"];
                [dic setObject:[NSString stringWithFormat:@"%d",[rs  intForColumn:@"u_id"]] forKey:@"u_id"];
                [arr addObject:dic];
            }
        }
    }];
    return arr;
}


#pragma mark - 数据库升级的操作
//获取表名
- (NSArray *)getAllTableNames
{
    __block NSMutableArray *results = [NSMutableArray array];
    [self.queue  inDatabase:^(FMDatabase *db) {
        FMResultSet  *rs = [db  executeQuery:@"SELECT * FROM sqlite_master WHERE type= 'table' ;"];
        while ([rs next]) {
            NSString *name = [rs stringForColumn:@"name"];
            if ([name isKindOfClass:[NSNull class]]) {
                name = @"";
            }
            [results addObject:name];
        }
    }];
    return results;
}

//修改表名,添加后缀“_bak”，把旧的表当做备份表
-(void)addBakToOldTable{
    for (NSString *tableName in [self getAllTableNames]) {
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@_bak",tableName,tableName];
        [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
            Boolean res = [db executeUpdate:sql];
            if (!res) {
                NSLog(@"修改表名 失败");
            } else {
                NSLog(@"修改表名 成功");
            }
        }];
    }
}
//获取_bak表的字段信息
- (NSArray *)getBakTableInfo{
    __block NSMutableArray *results = [NSMutableArray array];
    NSString *sql = @"PRAGMA table_info('t_AppUser_bak')";
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString *name = [rs stringForColumn:@"name"];
            if ([name isKindOfClass:[NSNull class]]) {
                name = @"";
            }
            [results addObject:name];
        }
    }];
    NSLog(@"_bak表的字段信息=%@",results);
    return results;
}


//把t_AppUser_bak表中的数据复制到t_AppUser
-(void)copyDataFromBak{
    //重新创建新的表
    [self creat_t_AppUser];
    //数据迁移
    NSString *strTemp = [(NSArray *)[self getBakTableInfo]componentsJoinedByString:@","];
    NSString *sql =[NSString stringWithFormat:@"INSERT INTO t_AppUser ( %@ ) SELECT %@ FROM t_AppUser_bak",strTemp,strTemp];
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        Boolean res = [db executeUpdate:sql];
        if (!res) {
            NSLog(@"复制 失败");
        } else {
            NSLog(@"复制 成功");
        }
    }];
}


//删除_bak表
-(void)dropBakTables:(NSString *)bakTable{
//    for (NSString *tableName in [self getAllTableNames]) {
//        if ([tableName containsString:@"_bak"]) {//这里不再需要使用COMPANY来判断表是否存在了
//            NSLog(@"tableName=%@",tableName);
//            NSString *sql =[NSString stringWithFormat:@"DROP TABLE %@;",tableName];
//            [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
//                Boolean res = [db executeUpdate:sql];
//                if (!res) {
//                    NSLog(@"删除表 失败");
//                } else {
//                    NSLog(@"删除表 成功");
//                }
//            }];
//        }
//    }
    NSString *sql =[NSString stringWithFormat:@"DROP TABLE %@;",bakTable];
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        Boolean res = [db executeUpdate:sql];
        if (!res) {
            NSLog(@"删除表 失败");
        } else {
            NSLog(@"删除表 成功");
        }
    }];
}
@end
