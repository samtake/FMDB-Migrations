//
//  AppDelegate.h
//  FMDB-Migrations
//
//  Created by 黄龙山 on 2019/8/9.
//  Copyright © 2019 黄龙山. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "t_AppUser.h"
#import "GetDBHelper.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

