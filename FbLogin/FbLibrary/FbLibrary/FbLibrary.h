//
//  FbLibrary.h
//  FbLibrary
//
//  Created by HsuanLee on 2016/2/2.
//  Copyright © 2016年 lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FbLibrary : NSObject

/**
 *  Facebook Login
 *
 *  @param vc 哪個viewController
 */
- (void)Login:(UIViewController*)vc;
/**
 *  實體化
 */
+ (instancetype)sharedManager;
@end
