//
//  FbLibrary.m
//  FbLibrary
//
//  Created by HsuanLee on 2016/2/2.
//  Copyright © 2016年 lee. All rights reserved.
//

#import "FbLibrary.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@implementation FbLibrary

/**
 *  Facebook Login
 *
 *  @param vc 哪個viewController
 */
- (void)Login:(UIViewController*)vc{
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithReadPermissions:@[@"email"] fromViewController:vc handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            // Process error
            NSLog(@"error %@",error);
        } else if (result.isCancelled) {
            // Handle cancellations
            NSLog(@"Cancelled");
        } else {
            if ([result.grantedPermissions containsObject:@"email"]) {
                [self fetchUserInfo];
            }
        }
    }];
}

-(void)fetchUserInfo {
    
    if ([FBSDKAccessToken currentAccessToken]) {
        NSLog(@"Token is available");
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, link, first_name, last_name, picture.type(large), email, birthday, bio ,location ,friends ,hometown , friendlists"}]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
             if (!error)
             {
                 // 將 FB 抓到的資料存在 NSUserDefaults
                 if(result != nil){
                     [userDefaults setObject:[result objectForKey:@"id"] forKey:@"FB_ID"];
                     [userDefaults setObject:[result objectForKey:@"name"] forKey:@"FB_NAME"];
                     [userDefaults setObject:[result objectForKey:@"email"] forKey:@"FB_EMAIL"];
                     [userDefaults synchronize];
                 }
             }
             else
             {
                 [userDefaults setObject:result forKey:@"FBError"];
                 [userDefaults synchronize];
             }
             [[NSNotificationCenter defaultCenter] postNotificationName:@"fbLoginResponse" object:nil];
         }];
    }
    else {
        NSLog(@"User is not Logged in");
    }
}

#pragma mark - 初始方法 - 實體化class必要寫法
- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}
/**
 *  實體化
 */
+ (instancetype)sharedManager {
    static FbLibrary *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end
