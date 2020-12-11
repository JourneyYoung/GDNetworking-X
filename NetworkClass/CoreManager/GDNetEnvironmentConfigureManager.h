//
//  GDNetEnvironmentConfigureManager.h
//  GDNetwork
//
//  Created by Journey on 2018/3/13.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GDBaseRequest;
@class AFSecurityPolicy;

@protocol GDBaseRequestStateProtocol;

/// 请求过滤改装
@protocol GDRequestFilterProtocol <NSObject>
@optional

/**
 过滤并修改原始请求的hook方法
 
 @param request 对应的`GDBaseRequest`
 @param filterURLRquest 原始的`NSURLRequest`
 @return 修改后的`NSURLRequest`
 */
///其实吧，这个方法并没有什么鸡儿卵用==
- (NSURLRequest *)filterURLRquest:(NSURLRequest *)filterURLRquest
                         ofRquest:(GDBaseRequest *)request;

@end

@interface GDNetEnvironmentConfigureManager : NSObject

///init只允许内部调用
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype) defaultConfiguration;

/// 根据特定的NSURLSessionConfiguration来创建GDNetworkConfiguration
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration NS_DESIGNATED_INITIALIZER;
+ (instancetype)networkConfigurationWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

/// 对应的NSURLSessionConfiguration
@property (nonatomic, readonly) NSURLSessionConfiguration *sessionConfiguration;

///下面几个基地址都是全局设置，免除每个API都要单独复写的重复工作

@property (nonatomic, strong) NSString *baseUrl;

@property (nonatomic, strong) NSString *cdnUrl;

@property (nonatomic, strong) NSString *insUrl;

@property (nonatomic, strong) NSString *instaUrl;

/** 这个字典用来存放基础的信息，如appid,deviceToken等
 *  全局设置要分基地址
 *  server不用说
 *  Instagram接口是一套
 *  cdn接口默认无
 */
@property (nonatomic, strong, nullable) NSDictionary *commonParams;

///请求安全策略，defualt is AFSSLPinningModeNone
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;


///缓存设计
@property (nonatomic, strong) NSURL *cacheDirectory;

///下载存储的路径，下载接口功能暂时还没有计划
@property (nonatomic, strong) NSURL *downloadDirectory;

@property (nonatomic, readonly) NSURL *downloadResumeDirectory;


/// 请求头验证,决定请求头的Authorization字段
/// @note 默认为`nil`
/// @warning 如果在GDBaseRequest中配置了requestAuthorizationUsername，此属性将会失效
@property (nonatomic, copy, nullable) NSString *requestAuthorizationUsername;

/// 请求头验证,决定请求头的Authorization字段
/// @note 默认为`nil`
/// @warning 如果在GDBaseRequest中配置了requestAuthorizationUsername，此属性将会失效
@property (nonatomic, copy, nullable) NSString *requestAuthorizationPassword;

/// 请求头验证,自定义参数
/// @note 默认为`nil`
/// @warning 与GDNetwork中配置了requestHeaderFieldValueDictionay中的属性并存，并且GDNetwork中的requestHeaderFieldValueDictionay优先级更高
@property (nonatomic, strong, nullable) NSDictionary *requestHeaderFieldValueDictionary;

/// 请求所处的线程
/// @note 默认为"me.dingtone.network.requestConcurrentQueue"并发线程
@property (nonatomic, strong, nullable) dispatch_queue_t requestQueue;

/// 请求结束的回调线程
/// @note 默认为"me.dingtone.network.completedConcurrentQueue"并发线程
/// @warning 尽量不要将completionQueue修改为主线程因为syn(同步请求)一般实现原理通过信号量来实现双线程同步，如果将completionQueue修改为主线程则会造成DeadLock
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;

/// 请求结束的回调Group
/// @note 默认为`nil`
@property (nonatomic, strong, nullable) dispatch_group_t completionGroup;

/// 请求过滤代理
@property (nonatomic, weak, nullable) id<GDRequestFilterProtocol> requestFilter;

///请求状态接口
@property (nonatomic, strong, nullable)  NSMutableSet<id<GDBaseRequestStateProtocol> > *requestAccessories;

- (void)addReuestAccessory:(id<GDBaseRequestStateProtocol>)requestAccessory;

#pragma mark - class method & property

/// 全局请求状态代理
/// 可以利用此方法hook所有经过此框架的请求
/// @note 默认为`nil`
@property (nonatomic, strong, class, nullable) NSMutableSet<id<GDBaseRequestStateProtocol>> *globalRequestAccessories;

/// 添加全局的请求状态代理
+ (void)addGlobalReuestAccessory:(id<GDBaseRequestStateProtocol>)globalRequestAccessories;

@end


NS_ASSUME_NONNULL_END



























