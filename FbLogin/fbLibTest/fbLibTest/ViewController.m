//
//  ViewController.m
//  fbLibTest
//
//  Created by HsuanLee on 2016/2/2.
//  Copyright © 2016年 lee. All rights reserved.
//

#import "ViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "FbLibrary.h"

@interface ViewController ()

@end

@implementation ViewController
/**
 *  FB Login Response
 */
- (void)fbLoginResponse{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* FbId = [userDefaults objectForKey:@"FB_ID"];
    NSString* FbName = [userDefaults objectForKey:@"FB_NAME"];
    NSError *FbError = [userDefaults objectForKey:@"FBError"];
    NSLog(@"Login Facebook : FB_ID = %@ , FB_NAME = %@ , FB_ERROR = %@",FbId,FbName,FbError);
}
- (void)loginButtonClicked{
    [[FbLibrary sharedManager]Login:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // 註冊監聽
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(fbLoginResponse) name:@"fbLoginResponse" object:nil];

    // Do any additional setup after loading the view, typically from a nib.
    UIButton *btnLogin=[UIButton buttonWithType:UIButtonTypeCustom];
    [btnLogin setBackgroundImage:[UIImage imageNamed:@"icon-fb.png"] forState:UIControlStateNormal];

    btnLogin.frame=CGRectMake(100,150,225,40);
    btnLogin.center = self.view.center;
    [btnLogin setTitle: @"     Facebook 帳號登入" forState: UIControlStateNormal];
    [btnLogin addTarget:self action:@selector(loginButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnLogin];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
