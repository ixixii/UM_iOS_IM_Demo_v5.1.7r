//
//  ECManager.h
//  CCPiPhoneSDK
//
//  Created by jiazy on 14/11/6.
//  Copyright (c) 2014年 ronglian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ECMessageManager.h"
#import "ECDeviceDelegate.h"
#import "ECLoginInfo.h"
#import "ECError.h"

#import "ECVoIPManager.h"
#import "ECMeetingManager.h"
#import "ECPersonInfo.h"
#import "ECUserState.h"

#import "ECDeviceHeaders.h"

/**
 * 设备类 使用该类的单例操作
 */
@interface ECDevice : NSObject<UIApplicationDelegate>

/**
 @brief 单例
 @discussion 获取该类单例进行操作
 @return 返回类实例
 */
+(ECDevice*)sharedInstance;

/**
 @brief 切换服务器环境
 @discussion 调用登录接口前，调用该接口切换服务器环境；不调用该函数，默认使用的是生产环境；
 @param isSandBox 是否沙盒环境
 @return 是否成功 0:成功 非0失败
 */
-(NSInteger)SwitchServerEvn:(BOOL)isSandBox;

/**
 @brief 登录
 @discussion 异步函数，建立与平台的连接
 @param info 登录所需信息
 @param completion 执行结果回调block
 */
-(void)login:(ECLoginInfo *)info completion:(void(^)(ECError* error)) completion;

/**
 @brief 退出登录
 @discussion 异步函数，断开与平台的连接;该函数调用后SDK不再主动重连服务器
 @param completion 执行结果回调block
 */
-(void)logout:(void(^)(ECError* error)) completion;

/**
 @brief 设置个人信息
 @param person 个人信息
 @param completion 执行结果回调block
 */
-(void)setPersonInfo:(ECPersonInfo*)person completion:(void(^)(ECError* error, ECPersonInfo* person)) completion;

/**
 @brief 获取个人信息
 @param completion 执行结果回调block
 */
-(void)getPersonInfo:(void(^)(ECError* error, ECPersonInfo* person)) completion;

/**
 @brief 获取其他人信息
 @param userAcc 用户账号
 @param completion 执行结果回调block
 */
-(void)getOtherPersonInfoWith:(NSString *)userAcc completion:(void(^)(ECError* error, ECPersonInfo* person)) completion;

/**
 @brief 获取他人状态
 @param completion 执行结果回调block
 */
-(void)getUserState:(NSString *)userAcc completion:(void(^)(ECError* error, ECUserState* state)) completion;

/**
 @brief 私有云设置
 @param companyid 公司ID
 @param companyPwd 公司密码
 */
-(void)setPrivateCloudCompanyId:(NSString*)companyid andCompanyPwd:(NSString*)companyPwd;

/**
 @brief device代理
 @discussion 用于监听通知事件
 */
@property (nonatomic, assign) id<ECDeviceDelegate> delegate;

/**
 @brief 即时消息管理类
 @discussion 用于群组管理，消息发送，录音、放音等操作
 */
@property (nonatomic, readonly, strong) id<ECMessageManager> messageManager;

/**
 @brief VoIP管理类
 @discussion 用于VoIP相关操作；如果SDK只是IM版本，该实例为nil
 */
@property (nonatomic, readonly, strong) id<ECVoIPManager> VoIPManager;

/**
 @brief 会议管理类
 @discussion 用于会议相关操作；如果SDK只是IM版本，该实例为nil
 */
@property (nonatomic, readonly, strong) id<ECMeetingManager> meetingManager;
@end
