//
//  ECVoIPCallDelegate.h
//  CCPiPhoneSDK
//
//  Created by jiazy on 15/1/27.
//  Copyright (c) 2015年 ronglian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECDelegateBase.h"
#import "VoipCall.h"

/**
 * VoIP呼叫的代理
 */
@protocol ECVoIPCallDelegate <ECDelegateBase>

@optional

/**
 @brief 有呼叫进入
 @param callid      会话id
 @param caller      呼叫人
 @param callerphone 被叫人手机号
 @param callername  被叫人姓名
 @param calltype    呼叫类型
 */
- (NSString*)onIncomingCallReceived:(NSString*)callid withCallerAccount:(NSString *)caller withCallerPhone:(NSString *)callerphone withCallerName:(NSString *)callername withCallType:(CallType)calltype;

/**
 @brief 呼叫事件
 @param voipCall VoIP电话实体类的对象
 */
- (void)onCallEvents:(VoIPCall*)voipCall;

/**
 @brief 收到dtmf
 @param callid 会话id
 @param dtmf   键值
 */
- (void)onReceiveFrom:(NSString*)callid DTMF:(NSString*)dtmf;

/**
 @brief 视频分辨率发生改变
 @param callid       会话id
 @param voip         VoIP号
 @param isConference NO 不是, YES 是
 @param width        宽度
 @param height       高度
 */
- (void)onCallVideoRatioChanged:(NSString *)callid andVoIP:(NSString *)voip andIsConfrence:(BOOL)isConference andWidth:(NSInteger)width andHeight:(NSInteger)height;

/**
 @brief 收到对方切换音视频的请求
 @param callid  会话id
 @param requestType 请求音视频类型 视频:需要响应 音频:请求删除视频（不需要响应，双方自动去除视频）
 */
- (void)onSwitchCallMediaTypeRequest:(NSString *)callid withMediaType:(CallType)requestType;

/**
 @brief 收到对方应答切换音视频请求
 @param callid   会话id
 @param responseType 回复音视频类型
 */
- (void)onSwitchCallMediaTypeResponse:(NSString *)callid withMediaType:(CallType)responseType;

@end