//
//  GDNetworkPrivate.h
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDBaseRequest.h"

@class GDBaseRequestInternal;


/// 按顺序调度主线程 防止deadlock
FOUNDATION_STATIC_INLINE void gd_network_dispatch_sync_main_queue_safety( void (^ _Nonnull block)(void)) {
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

FOUNDATION_STATIC_INLINE void gd_network_dispatch_async_main_queue_safety( void (^ _Nonnull block)(void)) {
    dispatch_async(dispatch_get_main_queue(), block);
}


@interface GDNetworkPrivate : NSObject

/// 异常报告
+ (void)raiseErrorWithCode:(GDNetworkErrorCode)errorCode
                 exception:(nullable NSException *)exception
                   request:(nullable GDBaseRequest *)request
                     error:(NSError * _Nullable *)error;

/// JSON校验方法
+ (BOOL)checkJson:(id)json withValidator:(id)validatorJson;

/// 获取request的唯一标识
+ (NSString *)uniqueCodeForRequest:(NSURLRequest *)request;

/// 获取二进制数据的sha1码
+ (NSString *)SHA1WithData:(NSData *)fileData;

/// 获取下载缓存路径的唯一标识
+ (NSString *)md5StringFromString:(NSString *)string;

/// 获取app版本号
+ (NSString *)appVersionString;

@end


@interface GDNetworkTargetAction : NSObject

@property (nonatomic, weak, nullable) id target;
@property (nonatomic, assign) SEL action;

- (instancetype)initWithTarget:(id)target action:(SEL)action;

@end

@interface GDNetworkCacheMetaData : NSObject <NSCoding,NSSecureCoding>

/// 缓存的返回数据
@property (nonatomic, strong) NSURLResponse *response;
/// 缓存的版本号
@property (nonatomic, assign) long long version;
/// 缓存的敏感请求数据
@property (nonatomic, copy, nullable) NSString *sensitiveArgumentString;
/// 缓存日期
@property (nonatomic, strong) NSDate *creationDate;
/// APP版本
/// @warning APP版本不一致则认定缓存数据失效
@property (nonatomic, copy) NSString *appVersionString;
/// 缓存数据
@property (nonatomic, strong) NSData *cacheData;

@end


///思路来自猿题库
@interface GDBaseRequest (Private)

/// 触发请求即将开始的回调
- (void)triggerRequestWillStartAccessoryCallBack;

/// 触发请求已经开始的回调
- (void)triggerRequestDidStartAccessoryCallBack;

/// 触发请求即将结束的回调
- (void)triggerRequestWillStopAccessoryCallBack;

/// 触发请求已经结束的回调
- (void)triggerRequestDidStopAccessoryCallBack;

/// 触发缓存成功的回调
- (void)triggerRequestCacheHittedCallBack;

/// 触发请求成功的回调
- (void)triggerRequestSuccessCallBack;

/// 触发请求结束的回调
- (void)triggerRequestFailureCallBack;

/// 改变请求状态
- (void)changeRequestState:(GDRequestState)state;

@end

@interface GDBaseRequest(){
    NSURL *_downloadResumeDataURL;
}

@property (nonatomic, strong) GDBaseRequestInternal *internalRequest;
/// synthesize基本信息
@property (nonatomic, strong, nullable) NSURLRequest *request;
@property (nonatomic, strong, nullable) NSURLSessionTask *task;
@property (nonatomic, strong, nullable) NSURLResponse *response;
@property (nonatomic, strong, nullable) NSData *responseData;
@property (nonatomic, copy, nullable) NSString *responseString;
//@property (nonatomic, strong, nullable) id responseJSONObject;
@property (nonatomic, strong, nullable) NSError *responseError;
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, assign) GDRequestState requestState;
/// synthesize回调信息
@property (nonatomic, strong, nullable) NSMutableSet< GDNetworkTargetAction*> *successTargetActionSet;
@property (nonatomic, strong, nullable) NSMutableSet<GDNetworkTargetAction *> *cacheHittedTargetActionSet;
@property (nonatomic, strong, nullable) NSMutableSet<GDNetworkTargetAction *> *failureTargetActionSet;
@property (nonatomic, strong, nullable) NSMutableSet<id<GDBaseRequestStateProtocol> > *requestAccessories;
/// synthesize下载信息
@property (nonatomic, copy, nullable) GDRequestProgressBlock downloadProgressBlock;
@property (nonatomic, strong, nullable) NSURL *downloadDestinationURL;
/// synthesize缓存信息
@property (nonatomic, assign, getter=isCacheHited) BOOL cacheHited;
@property (nonatomic, strong, nullable) NSError *cacheError;
/// 缓存命中的回调Block
@property (nonatomic, copy, nullable) GDRequestCompletionBlock cacheHittedBlock;


@end






