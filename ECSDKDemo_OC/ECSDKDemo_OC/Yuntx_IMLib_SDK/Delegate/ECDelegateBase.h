//
//  ECDelegateBase.h
//  CCPiPhoneSDK
//
//  Created by jiazy on 14/11/13.
//  Copyright (c) 2014年 ronglian. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "ECError.h"
#import "ECEnumDefs.h"

/**
 * 该代理用于接收登录和注销状态
 */
@protocol ECDelegateBase <NSObject>

@optional

/**
 @brief 连接状态接口
 @discussion 监听与服务器的连接状态 V4.0版本接口
 @param error 连接的状态
 */
-(void)onConnected:(ECError*)error;

/**
 @brief 连接状态接口
 @discussion 监听与服务器的连接状态 V5.0版本接口
 @param state 连接的状态
 @param error 错误原因值
 */
-(void)onConnectState:(ECConnectState)state  failed:(ECError*)error;

/**
 @brief 个人信息版本号
 @param version 服务器上的个人信息版本号
 */
-(void)onServicePersonVersion:(unsigned long long)version;

@required

@end
