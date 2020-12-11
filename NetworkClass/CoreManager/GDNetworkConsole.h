//
//  GDNetworManager.h
//  GDNetwork
//
//  Created by Journey on 2018/3/13.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>


@class GDBaseRequest;
@class GDNetEnvironmentConfigureManager;

NS_ASSUME_NONNULL_BEGIN

@interface GDNetworkConsole : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)defaultConsole;

- (instancetype)initWithConfiguration:(GDNetEnvironmentConfigureManager *)configurtion NS_DESIGNATED_INITIALIZER;
+ (instancetype)engineWithConfiguration:(GDNetEnvironmentConfigureManager *)configuration;

/// 请求的配置
@property (nonatomic, strong, readonly) GDNetEnvironmentConfigureManager *configuration;

///添加请求
- (void)startRequest:(GDBaseRequest *)request;

/// 发起一次性请求，不需要缓存
- (void)startRequestWithoutCache:(GDBaseRequest *)request;

///取消某个请求
- (void)cancelRequest:(GDBaseRequest *)request;

///取消所有正在飞的请求
- (void)cancelAllRequests;

/// 清空请求的缓存
- (BOOL)cleanCacheForRequest:(GDBaseRequest *)request;

///工厂创建请求路径
//- (NSString *)creatRequestUrl:(GDBaseRequest *)request;

@end


NS_ASSUME_NONNULL_END
