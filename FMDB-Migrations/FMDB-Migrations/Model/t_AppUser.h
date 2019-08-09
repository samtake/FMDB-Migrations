//
//  t_AppUser.h
//  FMDB-Migrations
//
//  Created by 黄龙山 on 2019/8/9.
//  Copyright © 2019 黄龙山. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface t_AppUser : NSObject
@property(nonatomic,assign)int u_id;
@property(nonatomic,copy)NSString *u_first_name;
@property(nonatomic,copy)NSString *u_last_name;
@end

NS_ASSUME_NONNULL_END
