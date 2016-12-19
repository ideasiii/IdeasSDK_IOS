//
//  trackerLib.m
//  trackerLib
//
//  Created by admin on 2015/12/28.
//  Copyright © 2015年 admin. All rights reserved.
//

#import "trackerLib.h"
#import "model.h"

@interface trackerLib (){
    int sq;
    NSInputStream *iStream;
    NSOutputStream *oStream;
    CLLocationManager *locationManager;
    /**
     *  app 傳來的東西
     */
    NSMutableDictionary *appInfo;
    /**
     *  記錄init 回傳回來的資料
     */
    NSDictionary *initInfo;
    /**
     *  識別裝置id
     */
    NSString *discernID;
    /**
     *  access log
     */
    NSMutableDictionary *mutableLogDic;
    /**
     *  連線 ip
     */
    NSString *connIp;
    /**
     *  連線的 port
     */
    int connPort;
    /**
     *  可否傳 tracker （要經過sign up 成功才能）
     */
    BOOL availableTracker;
    /**
     *  使用者位置
     */
    NSString *userLocation;
}

@end

@implementation trackerLib

#pragma mark - Response
/**
 *  Response Header & body
 */
- (void)serverResponse:(NSData*)data length:(NSInteger)len{
    NSData *headerData = nil;
    NSRange range = NSMakeRange(0, 16);
    headerData = [data subdataWithRange:range];
    
    // 將回傳的data轉成16進制
    NSArray *hexList = [model dataToHexString:headerData];
    int nLength = [model hexStringToInt:[hexList objectAtIndex:0]];
    NSString *nStatus = [model comparisonResponseStatus:[hexList objectAtIndex:2]];
    int nSequence = [model hexStringToInt:[hexList objectAtIndex:3]];
    
    // 中斷 scoket連線
    [self scoketDiscontinue];
    
    unsigned long commendID = strtoul([[hexList objectAtIndex:1] UTF8String],0,0);
    if(commendID == AUTHORIZATION_RESPONSE){
        // Response body
        if(len > 16){
            NSData *bodyData = nil;
            NSRange bodyRange = NSMakeRange(16, len-17);
            bodyData = [data subdataWithRange:bodyRange];
            NSError *error;
            initInfo = [NSJSONSerialization JSONObjectWithData:bodyData options:NSJSONReadingMutableContainers error:&error];
            if(error != nil){
                NSLog(@" body json error = %@ ", error);
            }
            else{
                NSLog(@" init body json = %@ ", initInfo);
                [self writeSignUpRequest];
            }
        }
    }
    else if(commendID == SIGN_UP_RESPONSE){
        unsigned long commendID = strtoul([[hexList objectAtIndex:2] UTF8String],0,0);
        if(commendID == STATUS_ROK){
            availableTracker = YES;
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate=self;
            locationManager.desiredAccuracy=kCLLocationAccuracyBest;
            locationManager.distanceFilter=kCLDistanceFilterNone;
            [locationManager startMonitoringSignificantLocationChanges];
            locationManager.delegate = self;
            // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
            if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [locationManager requestWhenInUseAuthorization];
            }
            [locationManager startUpdatingLocation];
        }
        NSMutableDictionary *resObject = [[NSMutableDictionary alloc]init]; // server回傳結果
        [resObject setObject:[NSNumber numberWithInt:nLength] forKey:@"length"];
        [resObject setObject:[hexList objectAtIndex:1] forKey:@"commandId"];
        [resObject setObject:nStatus forKey:@"commandStatus"];
        [resObject setObject:[NSNumber numberWithInt:nSequence] forKey:@"sequence"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TrackerResponse" object:nil];
        // 將結果存入 NSUserDefaults
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:resObject forKey:@"resInfo"];
        [userDefaults synchronize];
    }
}

#pragma mark - NSStreamDelegate

/**
 *  讀取 sever 端回傳的訊息
 */
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    //當訊息從主機由iStream端進入時
    //    NSStreamEventOpenCompleted = 1UL << 0,//輸入輸出流打開完成
    //    NSStreamEventHasBytesAvailable = 1UL << 1,//有字節可讀
    //    NSStreamEventHasSpaceAvailable = 1UL << 2,//可以發放字節
    //    NSStreamEventErrorOccurred = 1UL << 3,// 連接出現錯誤
    //    NSStreamEventEndEncountered = 1UL << 4// 連接結束
    int i = eventCode;
    switch (i) {
        case NSStreamEventOpenCompleted:
            NSLog(@"輸入輸出流打開完成");
            break;
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"有字節可讀");
            NSMutableData *data = [[NSMutableData alloc] init];
            
            //定義接收串流的大小
            uint8_t buf[MAX_DATA_LEN];
            NSInteger len = 0;
            len = [(NSInputStream *)stream read:buf maxLength:MAX_DATA_LEN];
            [data appendBytes:(const void *) buf length:len];
            
            [self serverResponse:data length:len];
            break;
        }
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"可以發送字節");
            break;
        case NSStreamEventErrorOccurred:{
            NSLog(@" 連接出現錯誤");
            NSMutableDictionary *resObject = [[NSMutableDictionary alloc]init]; // server回傳結果
            [resObject setObject:[NSNumber numberWithInt:0] forKey:@"length"];
            [resObject setObject:@"-1" forKey:@"commandId"];
            [resObject setObject:@"Connection error" forKey:@"commandStatus"];
            [resObject setObject:[NSNumber numberWithInt:0] forKey:@"sequence"];
            // 將結果存入 NSUserDefaults
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:resObject forKey:@"resInfo"];
            [userDefaults synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrackerResponse" object:nil];
            break;
        }
        case NSStreamEventEndEncountered:
            NSLog(@"連接結束");
    }
}

#pragma mark - 事件
/**
 *  init
 */
- (void)writeInitRequest{
    [self scoketConnection];
    if([oStream streamStatus] == NSStreamStatusOpening){
        sq++;
        NSLog(@"sq = %i",sq);
        struct CMP_INIT_PACKET cmpPacket;
        cmpPacket.cmpHeader.command_id = htonl( AUTHORIZATION_REQUEST );
        cmpPacket.cmpHeader.command_status = htonl( STATUS_ROK );
        cmpPacket.cmpHeader.sequence_number = [model checkSequence:htonl( sq )];
        
        cmpPacket.cmpBody.cmptype = htonl(1);
        
        int nTotal_len;
        nTotal_len = sizeof(cmpPacket.cmpHeader) + sizeof(cmpPacket.cmpBody.cmptype);
        cmpPacket.cmpHeader.command_length = htonl(nTotal_len);
        
        NSMutableData *data = [[NSMutableData alloc]init];
        [data appendBytes:&cmpPacket length: nTotal_len];
        [oStream write:(const uint8_t *)&cmpPacket maxLength:nTotal_len];
    }
    else{
        NSLog(@"init connection fail outputStream: %lu", (unsigned long)[oStream streamStatus]);
    }
}

/**
 *  Sign up
 */
- (void)writeSignUpRequest{
    NSArray *serverAry = [initInfo objectForKey:@"server"];
    NSDictionary *signUp = [serverAry objectAtIndex:0];
    connIp = [signUp objectForKey:@"ip"];
    connPort = [[signUp objectForKey:@"port"] intValue];
    [self scoketConnection];
    if([oStream streamStatus] == NSStreamStatusOpening){
        sq++;
        NSLog(@"sq = %i",sq);
        struct CMP_SIGN_UP_PACKET cmpPacket;
        cmpPacket.cmpHeader.command_id = htonl( SIGN_UP_REQUEST );
        cmpPacket.cmpHeader.command_status = htonl( STATUS_ROK );
        cmpPacket.cmpHeader.sequence_number = [model checkSequence:htonl( sq )];
        
        cmpPacket.cmpBody.cmptype = htonl(1);
        
        int nTotal_len;
        
        NSString *JSONString;
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self getUserInfo] options:0 error:&error];
        if (!jsonData) {
            NSLog(@"JSON error: %@", error);
        } else {
            JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            NSLog(@"JSON OUTPUT: %@",JSONString);
        }
        NSString *strSignUp = JSONString;
        
        int nBody_len = 0;
        nBody_len += sizeof(cmpPacket.cmpBody.cmptype);
        nBody_len += strSignUp.length;
        nBody_len++;
        
        strcpy(cmpPacket.cmpBody.cmpdata, [strSignUp UTF8String]);
        
        nTotal_len = sizeof(cmpPacket.cmpHeader) + nBody_len;
        cmpPacket.cmpHeader.command_length = htonl(nTotal_len);
        
        NSMutableData *data = [[NSMutableData alloc]init];
        [data appendBytes:&cmpPacket length: nTotal_len];
        [oStream write:(const uint8_t *)&cmpPacket maxLength:nTotal_len];
    }
    else{
        NSLog(@"sign up connection fail outputStream: %lu", (unsigned long)[oStream streamStatus]);
    }
}

/**
 *  access log request
 */
- (void)writeAccsessLogRequest:(NSDictionary *)dic
{
    if(! availableTracker){
        NSMutableDictionary *resObject = [[NSMutableDictionary alloc]init]; // server回傳結果
        [resObject setObject:[NSNumber numberWithInt:0] forKey:@"length"];
        [resObject setObject:@"-1" forKey:@"commandId"];
        [resObject setObject:@"stop Tracker" forKey:@"commandStatus"];
        [resObject setObject:[NSNumber numberWithInt:0] forKey:@"sequence"];
        // 將結果存入 NSUserDefaults
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:resObject forKey:@"resInfo"];
        [userDefaults synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TrackerResponse" object:nil];
        NSLog(@"can not start tracker cause startTarcker fail or stopTracker run");
        return;
    }
    NSArray *serverAry = [initInfo objectForKey:@"server"];
    NSDictionary *log = [serverAry objectAtIndex:1];
    connIp = [log objectForKey:@"ip"];
    connPort = [[log objectForKey:@"port"] intValue];
    [self scoketConnection];
    if([oStream streamStatus] == NSStreamStatusOpening){

        /*
             ID : 識別id
             TIME : 現在時間
             TYPE
             SOURCE_FROM
             PAGE
             PRODUCTION
             PRICE
         */

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString *today = [formatter stringFromDate:[NSDate date]];

        mutableLogDic = [dic mutableCopy];
        [mutableLogDic setObject:discernID forKey:@"ID"];
        [mutableLogDic setObject:today forKey:@"DATE"];
        if(userLocation != nil && userLocation.length > 0){
            [mutableLogDic setObject:userLocation forKey:@"LOCATION"];
        }
        sq++;
        NSLog(@"sq = %i",sq);
        struct CMP_ACCESS_LOG_PACKET cmpPacket;
        cmpPacket.cmpHeader.command_id = htonl( ACCESS_LOG_REQUEST );
        cmpPacket.cmpHeader.command_status = htonl( STATUS_ROK );
        cmpPacket.cmpHeader.sequence_number = [model checkSequence:htonl( sq )];
        
        cmpPacket.cmpBody.cmptype = htonl(1);

        int nTotal_len;
        NSString *JSONString;
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableLogDic options:0 error:&error];
        if (!jsonData) {
            NSLog(@"JSON error: %@", error);
        } else {
            JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            NSLog(@"JSON OUTPUT: %@",JSONString);
        }
        NSString *strAccessLog = JSONString;
        
        int nBody_len = 0;
        nBody_len += sizeof(cmpPacket.cmpBody.cmptype);
        nBody_len += strAccessLog.length;
        nBody_len++;
        
        strcpy(cmpPacket.cmpBody.cmpdata, [strAccessLog UTF8String]);
        
        nTotal_len = sizeof(cmpPacket.cmpHeader) + nBody_len;
        cmpPacket.cmpHeader.command_length = htonl(nTotal_len);
        
        NSMutableData *data = [[NSMutableData alloc]init];
        [data appendBytes:&cmpPacket length: nTotal_len];
        [oStream write:(const uint8_t *)&cmpPacket maxLength:nTotal_len];
    }
    else{
        NSLog(@"log connection fail outputStream: %lu", (unsigned long)[oStream streamStatus]);
    }
}

#pragma mark - user info
-(NSMutableDictionary *)getUserInfo{
    /*
     {"PHONE":"+886922317143","FB_ID":"NA","ID":"a086c6c80549+8869223171431349333576093jugo.tw@gmail.com","DATE":"2015-12-23 18:56:57","OS":"Android4.4.4","MAC":"a086c6c80549","G_ACCOUNT":"jugo.tw@gmail.com","APP_ID":"1349333576093"}
     */
    
    // iphone 6 61056CD9-98E7-472F-9CF9-82B5646973D9
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *os = [NSString stringWithFormat:@"IOS%@",[[UIDevice currentDevice] systemVersion]];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    discernID = [NSString stringWithFormat:@"%@%@",uuid,[appInfo objectForKey:@"app_id"]];
    [dic setObject:discernID forKey:@"id"]; // MAC + Phone + APP ID + Email
    [dic setObject:[appInfo objectForKey:@"app_id"] forKey:@"app_id"];
    [dic setObject:os forKey:@"os"];
    [dic setObject:[appInfo objectForKey:@"fb_id"] forKey:@"FB_ID"];
    
    NSString *fbName = [appInfo objectForKey:@"fb_name"] ? : nil;
    NSString *fbEmail = [appInfo objectForKey:@"fb_email"] ? : nil;
    if(fbName != nil && fbName.length > 0){
        [dic setObject:fbName forKey:@"FB_NAME"];
    }
    if(fbEmail != nil && fbEmail.length > 0){
        [dic setObject:fbEmail forKey:@"FB_EMAIL"];
    }
//    [dic setObject:@"NA" forKey:@"MAC"];
//    [dic setObject:@"NA" forKey:@"PHONE"];
//    [dic setObject:@"NA" forKey:@"FB_ACCOUNT"];
//    [dic setObject:@"NA" forKey:@"G_ACCOUNT"];
//    [dic setObject:@"NA" forKey:@"T_ACCOUNT"];
    NSLog(@"dic = %@", dic);
    return dic;
}

#pragma mark - lib提供的三方法
/**
 *  傳送資料
 */
- (void)track:(NSDictionary *)parm{
    [self writeAccsessLogRequest:parm];
}

/**
 *  Tracking服務開始，登入APP ID
 */
- (void)startTracker:(NSString *)app_id{
    [self initValue];
    [self startTracker:app_id fbid:@"NA" fbName:nil fbEmail:nil];
}

/**
 *  如果有Fackbook id、nickname與Email則可用此function。
 */
- (void)startTracker:(NSString*)app_id fbid:(NSString*)fb_id fbName:(NSString*)fb_name fbEmail:(NSString*)fb_email{
    appInfo = [[NSMutableDictionary alloc]init];
    [appInfo setObject:app_id forKey:@"app_id"];
    [appInfo setObject:fb_id forKey:@"fb_id"];
    if(fb_name != nil && fb_name.length > 0){
       [appInfo setObject:fb_name forKey:@"fb_name"];
    }
    if(fb_email != nil && fb_email.length > 0){
       [appInfo setObject:fb_email forKey:@"fb_email"];
    }
    [self writeInitRequest];
}

/**
 *  Tracking服務停止
 */
- (void)stopTracker{
    availableTracker = NO;
    [self initValue];
}

#pragma mark - scoket 連線
/**
 *  scoket 連線
 */
- (void)scoketConnection
{
    if([oStream streamStatus] != NSStreamStatusOpening && [oStream streamStatus] != NSStreamStatusOpen){
        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)connIp, connPort, &readStream, &writeStream);
        
        if (readStream && writeStream) {
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            
            iStream = (__bridge NSInputStream *)readStream;
            [iStream setDelegate:self];
            [iStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [iStream open];
            
            oStream = (__bridge NSOutputStream *)writeStream;
            [oStream setDelegate:self];
            [oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [oStream open];
            NSLog(@"Open status of outputStream: %lu", (unsigned long)[oStream streamStatus]);
        }
    }
    else{
        NSLog(@"Opening");
    }
}

- (void)scoketDiscontinue
{
    [iStream close];
    [oStream close];
    
    [iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [iStream setDelegate:nil];
    [oStream setDelegate:nil];
    
    NSLog(@"Close status of outputStream: %lu", (unsigned long)[oStream streamStatus]);
    
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //第0個位置資訊，表示為最新的位置資訊
    CLLocation * currentLocation = [locations objectAtIndex:0];
    userLocation = [NSString stringWithFormat:@"%.8f,%.8f",currentLocation.coordinate.latitude,currentLocation.coordinate.longitude];
//    NSLog(@"location = %@", userLocation);
}

#pragma mark - init
- (void)initValue{
    sq = 0;
    connIp = ConnectionInitIP;
    connPort = Port;
    NSLog(@"initValue");
}
+ (instancetype)sharedManager {
    static trackerLib *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        if (self) {
        }
    });
    return sharedMyManager;
}
@end
