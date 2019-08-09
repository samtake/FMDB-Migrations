查了下数据迁移，思路大概如下：
- 获取数据库中旧的表
- 修改表名,添加后缀“_bak”，并备份旧表
- 创建新的表，并做数据迁移
- 删除备份表

有这么一个需求：Beta 1.0版本数据库只有两个字段u_id和u_first_name，后面随着需求的更改迭代需要添加u_last_name，并退出Beta 2.0。如何实现？

###先看Beta1.0
模型的声明
 ```
@property(nonatomic,assign)int u_id;
@property(nonatomic,copy)NSString *u_first_name;
```

数据库单例
```
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
```
创建表
```
-(void)creatGetDBHelper{
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:@"GetDB.sqlite"];
    NSLog(@"数据库存储路径filePath = %@",filePath);
    self.queue = [FMDatabaseQueue  databaseQueueWithPath:filePath];
    [self  creat_t_AppUser];
}

-(void)creat_t_AppUser{
    [self.queue  inDatabase:^(FMDatabase *db) {
        BOOL  create = [db  executeUpdate:@"CREATE TABLE IF NOT EXISTS t_AppUser(u_key INTEGER  PRIMARY KEY,u_id TEXT ,u_first_name TEXT)"];
        
        if (create) {
            NSLog(@"fmdb  创建本地t_AppUser列表成功");
        } else {
            NSLog(@"fmdb  创建本地t_AppUser列表失败");
        }
    }];
}
```
添加操作
```
-(void)insert_t_AppUser_withModel:(t_AppUser *)model{
    model.u_first_name=@"这是beta 1.0";
    //唯一值。
    NSString *insertsql_t_AppUser = [NSString  stringWithFormat:@"INSERT INTO  t_AppUser  (u_id,u_first_name)VALUES('%d','%@');",model.u_id,model.u_first_name];
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
```
删除操作
```
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
```

查询操作
```
-(NSMutableArray *)select_t_AppUser{
    NSString *selectsql_t_AppUser = [NSString stringWithFormat:@"Select  *   FROM  t_AppUser "];
    NSMutableArray *__block arr=[NSMutableArray new];
    [self.queue  inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:selectsql_t_AppUser];
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
```
运行之后的log
```
2019-08-09 21:48:02.965035+0800 FMDB-Migrations[18322:395347] 数据库存储路径filePath = /Users/samtake/Library/Developer/CoreSimulator/Devices/5F2978C1-3DEF-4BFF-92B3-9955E7A4AA53/data/Containers/Data/Application/87A1E0E9-F8BE-4571-855E-53061060BCBA/Library/Caches/GetDB.sqlite
2019-08-09 21:48:02.969024+0800 FMDB-Migrations[18322:395347] fmdb  创建本地t_AppUser列表成功
2019-08-09 21:48:02.969307+0800 FMDB-Migrations[18322:395347] 数据库存储路径filePath = /Users/samtake/Library/Developer/CoreSimulator/Devices/5F2978C1-3DEF-4BFF-92B3-9955E7A4AA53/data/Containers/Data/Application/87A1E0E9-F8BE-4571-855E-53061060BCBA/Library/Caches/GetDB.sqlite
2019-08-09 21:48:02.970733+0800 FMDB-Migrations[18322:395347] fmdb  创建本地t_AppUser列表成功
2019-08-09 21:48:02.971002+0800 FMDB-Migrations[18322:395347] insertsql_t_AppUser=INSERT INTO  t_AppUser  (u_id,u_first_name)VALUES('0','这是beta 1.0');
2019-08-09 21:48:02.972915+0800 FMDB-Migrations[18322:395347] FMDB 添加数据 成功
2019-08-09 21:48:02.973510+0800 FMDB-Migrations[18322:395347] dict={
    "u_first_name" = 2;
    "u_id" = 1;
    "u_key" = 0;
}
2019-08-09 21:48:02.974340+0800 FMDB-Migrations[18322:395347] 数据库查询结果=(
        {
        "u_first_name" = "\U8fd9\U662fbeta 1.0";
        "u_id" = 0;
    }
)

```
在 FMResultSet 这个对象中有一个属性columnNameToIndexMap。它是一个NSMutableDictionary对象。其中key表示的是指定结果集中对应列的名称，value表示的是指定结果集中对应的列号，答应出来从获取每个表的信息
```
NSMutableDictionary *dict = rs.columnNameToIndexMap;
        NSLog(@"dict=%@",dict);
```
或者执行`open /Users/samtake/Library/Developer/CoreSimulator/Devices/5F2978C1-3DEF-4BFF-92B3-9955E7A4AA53/data/Containers/Data/Application/87A1E0E9-F8BE-4571-855E-53061060BCBA/Library/Caches/`并打开GetDB.sqlite来查看数据表字段

###再看Beta2.0
在模型里面添加字段u_last_name，并修改插入语句`[NSString  stringWithFormat:@"INSERT INTO  t_AppUser  (u_id,u_first_name,u_last_name)VALUES('%d','%@','%@');",model.u_id,model.u_first_name,model.u_last_name]`，执行build返回失败。这时候需要我们按照开头的思路来

### 获取数据库中旧的表
```
- (NSArray *)getAllTableNames
{
    __block NSMutableArray *results = [NSMutableArray array];
    [self.queue  inDatabase:^(FMDatabase *db) {
        FMResultSet  *rs = [db  executeQuery:@"SELECT * FROM sqlite_master WHERE type= 'table' ;"];
        while ([rs next]) {
            NSString *name = [rs stringForColumn:@"name"];
            NSString *sql = [rs stringForColumn:@"sql"];
            if ([name isKindOfClass:[NSNull class]]) {
                name = @"";
            }
            if ([sql isKindOfClass:[NSNull class]]) {
                sql = @"";
            }
            NSDictionary *tableDict = @{@"name":name?:@"", @"sql":sql?:@""};
            [results addObject:tableDict];
        }
    }];
    return results;
}
```
### 修改表名,添加后缀“_bak”，把旧的表当做备份表
```
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
```
### 把t_AppUser_bak表中的数据复制到t_AppUser
```
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
```
### 删除备份表
```
NSString *sql =[NSString stringWithFormat:@"DROP TABLE %@;",bakTable];
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        Boolean res = [db executeUpdate:sql];
        if (!res) {
            NSLog(@"删除表 失败");
        } else {
            NSLog(@"删除表 成功");
        }
    }];
```
以上就是数据迁移的主体逻辑，后续还会做一些修改
- 某些地方逻辑不严谨
- 函数待抽取，以及添加宏定义
- 复杂模型的拼接优化

[demo链接🔗]([https://github.com/samtake/FMDB-Migrations](https://github.com/samtake/FMDB-Migrations)
)

[我的简书](https://www.jianshu.com/u/95eaa7893b88)


