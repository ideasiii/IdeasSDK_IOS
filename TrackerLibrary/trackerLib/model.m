//
//  model.m
//  trackerLib
//
//  Created by admin on 2015/12/28.
//  Copyright © 2015年 admin. All rights reserved.
//

#import "model.h"

@implementation model

/**
 *  將 16進制 字串轉成 int
 *
 *  @param hexStr 16進制字串
 */
+ (int)hexStringToInt:(NSString*)hexStr{
    int n = 0;
    sscanf([hexStr UTF8String], "%x", &n);
    return n;
}

/**
 *  Data 轉 16進制 string
 */
+ (NSArray *)dataToHexString:(NSData *)data
{
    if (data == nil) {
        return nil;
    }
    NSMutableArray *hexIntList = [[NSMutableArray alloc]init];
    NSMutableString* hexString = [NSMutableString string];
    const unsigned char *p = [data bytes];
    for (int i=0; i < [data length]; i++) {
        [hexString appendFormat:@"%02x", *p++];
        if((i+1) % 4 == 0){
            [hexIntList addObject:[NSString stringWithFormat:@"0x%@",hexString]];
            hexString = [NSMutableString string];
        }
    }
    NSLog(@"Reponse header = %@",hexIntList);
    return hexIntList;
}

/**
 *  commend status
 *
 *  @param number 回傳的值
 */
+ (NSString*)comparisonResponseStatus:(NSString*)number{
    NSString *str;
    unsigned long commendID = strtoul([number UTF8String],0,0);
    switch (commendID) {
        case STATUS_ROK:
            str = @"No Error";
            break;
        case STATUS_RINVMSGLEN:
            str = @"Message Length is invalid";
            break;
        case STATUS_RINVCMDLEN:
            str = @"Command Length is invalid";
            break;
        case STATUS_RINVCMDID:
            str = @"Invalid Command ID";
            break;
        case STATUS_RINVBNDSTS:
            str = @"Incorrect BIND Status for given command";
            break;
        case STATUS_RALYBND:
            str = @"Already in Bound State";
            break;
        case Reserved_1:
            str = @"Reserved";
            break;
        case Reserved_2:
            str = @"Reserved";
            break;
        case STATUS_RSYSERR:
            str = @"System Error";
            break;
        case Reserved_3:
            str = @"Reserved";
            break;
        case Reserved_4:
            str = @"Reserved";
            break;
        case Reserved_5:
            str = @"Reserved";
            break;
        case Reserved_6:
            str = @"Reserved";
            break;
        case Reserved_7:
            str = @"Reserved";
            break;
        case Reserved_8:
            str = @"Reserved";
            break;
        case Reserved_9:
            str = @"Reserved";
            break;
        case STATUS_RBINDFAIL:
            str = @"Bind Failed";
            break;
        case STATUS_RPPSFAIL:
            str = @"Power Port Setting Fail";
            break;
        case STATUS_RPPSTAFAIL:
            str = @"Get Power State Fail";
            break;
        case STATUS_RINVBODY:
            str = @"Invalid Packet Body Data";
            break;
        case STATUS_RINVCTRLID:
            str = @"Invalid Controller ID";
            break;
        default:
            str = @"commend status error";
            break;
    }
    return str;
}

/**
 *  commend ID
 *
 *  @param number 回傳的值
 */
+ (NSString*)comparisonResponseID:(NSString*)number{
    NSString *str;
    unsigned long commendID = strtoul([number UTF8String],0,0);
    switch (commendID) {
        case GENERIC_NACK:
            str = @"Generic nack";
            break;
        case BIND_RESPONSE:
            str = @"Bind response";
            break;
        case AUTHENTICATION_RESPONSE:
            str = @"Authentication response";
            break;
        case ACCESS_LOG_RESPONSE:
            str = @"Access log response";
            break;
        case SIGN_UP_RESPONSE:
            str = @"Sign up response";
            break;
        case ENQUIRE_LINK_RESPONSE:
            str = @"Enquire link response";
            break;
        case UNBIND_RESPONSE:
            str = @"Unbind response";
            break;
        case AUTHORIZATION_RESPONSE:
            str = @"Authorization response";
            break;
        case FIRMWARE_UPDATE_RESPONSE:
            str = @"Update response";
            break;
        case USER_ACCOUNT_UPDATE_RESPONSE:
            str = @"User account update response";
            break;
        case CLIENT_REBOOT_RESPONSE:
            str = @"Reboot response";
            break;
        case CONFIG_RESPONSE:
            str = @"Configuration response";
            break;
        case POWER_PORT_SETTING_RESPONSE:
            str = @"Power port setting response";
            break;
        case POWER_PORT_STATE_RESPONSE:
            str = @"Power port state response";
            break;
    }
    return str;
}

/**
 *  檢查 sequence 是否超過最大值
 */
+(int)checkSequence:(int)aSeq
{
    if (0x7FFFFFFF <= aSeq)
    {
        aSeq = 0x00000001;
    }
    return aSeq;
}

@end
