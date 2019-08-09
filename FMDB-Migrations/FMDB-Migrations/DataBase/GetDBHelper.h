//
//  GetDBHelper.h
//  FMDB-Migrations
//
//  Created by 黄龙山 on 2019/8/9.
//  Copyright © 2019 黄龙山. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "t_AppUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface GetDBHelper : NSObject

+(GetDBHelper *)sharedInstance;

/*
 数据库所有表的创建，仅仅是创好表。
 */
-(void)creatGetDBHelper;


/*
 对user表的操作
 */
-(void)creat_t_AppUser;
-(void)insert_t_AppUser_withModel:(t_AppUser *)model;
-(void)delete_t_AppUser_withU_id:(int)u_id;
-(NSMutableArray *)select_t_AppUser;

/*
 数据库升级操作
 */
- (NSArray *)getAllTableNames;
-(void)addBakToOldTable;
- (NSArray *)getBakTableInfo;
-(void)copyDataFromBak;
-(void)dropBakTables;
-(void)dropBakTables:(NSString *)bakTable;
@end

NS_ASSUME_NONNULL_END
