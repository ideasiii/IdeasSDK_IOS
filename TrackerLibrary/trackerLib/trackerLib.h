//
//  trackerLib.h
//  trackerLib
//
//  Created by admin on 2015/12/28.
//  Copyright © 2015年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface trackerLib : NSObject<NSStreamDelegate,CLLocationManagerDelegate>

/**
 *  Tracking服務開始，登入APP ID
 */
- (void)startTracker:(NSString *)app_id;
/**
 *  如果有Fackbook id、nickname與Email則可用此function。
 */
- (void)startTracker:(NSString*)app_id fbid:(NSString*)fb_id fbName:(NSString*)fb_name fbEmail:(NSString*)fb_email;
/**
 *  傳送資料
 */
- (void)track:(NSDictionary *)parm;
/**
 *  Tracking服務停止
 */
- (void)stopTracker;
/**
 *  宣告
 */
+ (instancetype)sharedManager;

@end
