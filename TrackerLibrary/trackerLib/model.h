//
//  model.h
//  trackerLib
//
//  Created by admin on 2015/12/28.
//  Copyright © 2015年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>


#define ConnectionInitIP                @"54.199.198.94"
#define Port                            6607

#pragma mark - commend id
#define GENERIC_NACK                    0x00000000
#define BIND_REQUEST                    0x00000001
#define BIND_RESPONSE                   0x80000001
#define AUTHENTICATION_REQUEST          0x00000002
#define AUTHENTICATION_RESPONSE         0x80000002
#define ACCESS_LOG_REQUEST              0x00000003
#define ACCESS_LOG_RESPONSE             0x80000003
#define SIGN_UP_REQUEST                 0x00000005
#define SIGN_UP_RESPONSE                0x80000005
#define ENQUIRE_LINK_REQUEST            0x00000015
#define ENQUIRE_LINK_RESPONSE           0x80000015
#define UNBIND_REQUEST                  0x00000006
#define UNBIND_RESPONSE                 0x80000006
#define AUTHORIZATION_REQUEST           0x00000004
#define AUTHORIZATION_RESPONSE          0x80000004
#define FIRMWARE_UPDATE_REQUEST         0x00000007
#define FIRMWARE_UPDATE_RESPONSE        0x80000007
#define USER_ACCOUNT_UPDATE_REQUEST     0x00000008
#define USER_ACCOUNT_UPDATE_RESPONSE    0x80000008
#define CLIENT_REBOOT_REQUEST           0x00000010
#define CLIENT_REBOOT_RESPONSE          0x80000010
#define CONFIG_REQUEST                  0x00000011
#define CONFIG_RESPONSE                 0x80000011
#define POWER_PORT_SETTING_REQUEST      0x00000012
#define POWER_PORT_SETTING_RESPONSE     0x80000012
#define POWER_PORT_STATE_REQUEST        0x00000013
#define POWER_PORT_STATE_RESPONSE       0x80000013

#pragma mark - commend status
#define STATUS_ROK                      0x00000000
#define STATUS_RINVMSGLEN               0x00000001
#define STATUS_RINVCMDLEN               0x00000002
#define STATUS_RINVCMDID                0x00000003
#define STATUS_RINVBNDSTS               0x00000004
#define STATUS_RALYBND                  0x00000005
#define Reserved_1                      0x00000006
#define Reserved_2                      0x00000007
#define STATUS_RSYSERR                  0x00000008
#define Reserved_3                      0x00000009
#define Reserved_4                      0x0000000A
#define Reserved_5                      0x0000000B
#define Reserved_6                      0x0000000C
#define Reserved_7                      0x0000000D
#define Reserved_8                      0x0000000E
#define Reserved_9                      0x0000000F
#define STATUS_RBINDFAIL                0x00000010
#define STATUS_RPPSFAIL                 0x00000011
#define STATUS_RPPSTAFAIL               0x00000012
#define STATUS_RINVBODY                 0x00000040
#define STATUS_RINVCTRLID               0x00000041

#define MAX_DATA_LEN	2048

@interface model : NSObject

#pragma mark - header
struct CMP_HEADER
{
    int command_length;
    int command_id;
    int command_status;
    int sequence_number;
};

#pragma mark -  body
struct CMP_INIT_BODY
{
    int cmptype;
};
struct CMP_ACCESS_LOG_BODY
{
    int cmptype;
    char cmpdata[MAX_DATA_LEN];
};
struct CMP_SIGN_UP_BODY
{
    int cmptype;
    char cmpdata[MAX_DATA_LEN];
};

#pragma mark - Packet
struct CMP_INIT_PACKET
{
    struct CMP_HEADER cmpHeader;
    struct CMP_INIT_BODY cmpBody;
};
struct CMP_SIGN_UP_PACKET
{
    struct CMP_HEADER cmpHeader;
    struct CMP_SIGN_UP_BODY cmpBody;
};
struct CMP_ACCESS_LOG_PACKET
{
    struct CMP_HEADER cmpHeader;
    struct CMP_ACCESS_LOG_BODY cmpBody;
};

#pragma makr - 方法
/**
 *  檢查 sequence 是否超過最大值
 */
+(int)checkSequence:(int)aSeq;
/**
 *  將 16進制 字串轉成 int
 */
+ (int)hexStringToInt:(NSString*)hexStr;
/**
 *  Data 轉 16進制 string
 */
+ (NSArray *)dataToHexString:(NSData *)data;
/**
 *  commend id
 */
+ (NSString*)comparisonResponseID:(NSString*)number;
/**
 *  commend status
 */
+ (NSString*)comparisonResponseStatus:(NSString*)number;

@end
