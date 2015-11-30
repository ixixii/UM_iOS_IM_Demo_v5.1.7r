//
//  ECUserState.h
//  CCPiPhoneSDK
//
//  Created by jiazy on 15/9/15.
//  Copyright (c) 2015年 ronglian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECEnumDefs.h"

/**
 *  个人状态类
 */
@interface ECUserState : NSObject

/**
 @brief 用户账号
 */
@property (nonatomic, copy) NSString *userAcc;

/**
 @brief 用户是否在线
 */
@property (nonatomic, assign) BOOL isOnline;

/**
 @brief 用户网络类型
 */
@property (nonatomic, assign) ECNetworkType network;

/**
 @brief 用户终端类型
 */
@property (nonatomic, assign) ECDeviceType deviceType;
@end
