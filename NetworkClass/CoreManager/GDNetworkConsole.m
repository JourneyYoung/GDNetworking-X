//
//  GDNetworManager.m
//  GDNetwork
//
//  Created by Journey on 2018/3/13.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDNetworkConsole.h"
#import "GDBaseRequest.h"
#import "GDRequestFormData.h"
#import "GDNetEnvironmentConfigureManager.h"
#import <AFNetworking/AFURLSessionManager.h>
#import <AFNetworking/AFURLRequestSerialization.h>

#import "GDNewtworkLog.h"

#import "GDBaseRequestInternal.h"
#import "GDNetworkPrivate.h"
#import "GDNetworkEncryptionRequestSerializer.h"
#import "GDNetworkEncryptionResponseSerializer.h"

#import <pthread.h>


@interface GDNetworkConsole(){
    pthread_mutex_t _lock;
}

@property (nonatomic, strong) AFURLSessionManager *sessionManager;
@property (nonatomic, strong) GDNetEnvironmentConfigureManager *configuration;
/// 根据请求的sessionTask的hash值来保存现有的请求，防止请求重新发送
@property (nonatomic, strong) NSMutableSet<GDBaseRequest *> *requests;

@end

@implementation GDNetworkConsole

+ (instancetype)defaultConsole{
    static GDNetworkConsole *defaultEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        GDNetEnvironmentConfigureManager *configuration = [GDNetEnvironmentConfigureManager defaultConfiguration];
        defaultEngine = [[GDNetworkConsole alloc] initWithConfiguration:configuration];
    });
    return defaultEngine;
}

+ (instancetype)engineWithConfiguration:(GDNetEnvironmentConfigureManager *)configuration{
    return [[self alloc] initWithConfiguration:configuration];
}

- (instancetype)initWithConfiguration:(GDNetEnvironmentConfigureManager *)configurtion{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        
        _configuration = configurtion;
        _requests = [NSMutableSet<GDBaseRequest *> set];
        _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configurtion.sessionConfiguration];
        _sessionManager.securityPolicy = configurtion.securityPolicy;
        _sessionManager.completionGroup = configurtion.completionGroup;
        _sessionManager.completionQueue = configurtion.completionQueue;
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        [self setUpRedirectionBlock];
    }
    return self;
}

- (void)startRequest:(GDBaseRequest *)request{
    BOOL success = [self recordRequest:request];
    if (!success) {
        [GDNewtworkLog logWithFormat:@"Warning:请求`%@`已经开始 无法开始请求",request];
    }
    else {
        [self prepareForRequest:request];
        dispatch_async(self.configuration.requestQueue, ^{
            [request triggerRequestWillStartAccessoryCallBack];
            [self startRequestInternal:request];
        });
    }
}

- (void)startRequestWithoutCache:(GDBaseRequest *)request{
    BOOL success = [self recordRequest:request];
    if (!success) {
        [GDNewtworkLog logWithFormat:@"Warning:请求`%@`已经开始 无法开始请求",request];
    }
    else {
        [self prepareForRequest:request];
        dispatch_async(self.configuration.requestQueue, ^{
            [request triggerRequestWillStartAccessoryCallBack];
            [self startRequestWithoutCacheInternal:request];
        });
    }
}

- (void)cancelRequest:(GDBaseRequest *)request{
    if (![self isRequestInQueue:request]) {
        [GDNewtworkLog logWithFormat:@"Warning:请求`%@`还未开始或者已经结束 无法取消请求",request];
        return;
    }
    NSURLSessionTask *task = request.task;
    if ([task isKindOfClass:[NSURLSessionDownloadTask class]] &&
        [request saveResumeDataWhileCancelDownloadRequest]) {
        [((NSURLSessionDownloadTask *)task) cancelByProducingResumeData:^(NSData * _Nullable resumeData) {}];
    }
    else {
        [task cancel];
    }
    [self removeRequest:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests{
    pthread_mutex_lock(&_lock);
    NSDictionary<NSString *,GDBaseRequest *> *copyRecord = [self.requests copy];
    pthread_mutex_unlock(&_lock);
    [copyRecord enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                    GDBaseRequest * _Nonnull request,
                                                    BOOL * _Nonnull stop) {
        [request stop];
    }];
}

- (BOOL)cleanCacheForRequest:(GDBaseRequest *)request{
    return [request.internalRequest cleanCache];
}

#pragma mark - Request In Queue

- (void)startRequestInternal:(GDBaseRequest *)request {
    if (request.internalRequest.uploadRequest || request.internalRequest.downloadRequest) {
        [self startRequestWithoutCacheInternal:request];
        return;
    }
    
    if (![request.internalRequest checkCacheWithError:nil]) { /// 不使用缓存
        [self startRequestWithoutCacheInternal:request];
        return;
    }
    
    if (request.internalRequest.invalidateRequestWhileCacheHited) {
        dispatch_async(self.configuration.completionQueue, ^{
            [request triggerRequestDidStartAccessoryCallBack];
            [request triggerRequestWillStopAccessoryCallBack];
            [request.internalRequest validateResponseDataWithError:nil];
            [request requestSuccessFilter];
            [request triggerRequestSuccessCallBack];
            [request triggerRequestDidStopAccessoryCallBack];
        });
        [self removeRequest:request];
    }
    else {
        [self startRequestWithoutCacheInternal:request];
        dispatch_async(self.configuration.completionQueue, ^{
            [request.internalRequest validateResponseDataWithError:nil];
            [request triggerRequestCacheHittedCallBack];
            [request requestCacheHittedFilter];
        });
    }
    [GDNewtworkLog logWithFormat:@"Note:请求`%@`缓存命中",request];
}

- (void)startRequestWithoutCacheInternal:(GDBaseRequest *)request {
    NSError *serializeError = nil;
    /// 获取NSURLRequest
    NSURLRequest *originRequest = [request.internalRequest serializeRequestWithError:&serializeError];
    request.request = originRequest;
    /// 请求序列化错误
    if (serializeError) {
        [request triggerRequestDidStartAccessoryCallBack];
        request.responseError = serializeError;
        [request requestFailureFilter];
        [request triggerRequestFailureCallBack];
        [request triggerRequestDidStopAccessoryCallBack];
        [self removeRequest:request];
        
        return;
    }
    
    /// 全局过滤globalRequestFilter
    id<GDRequestFilterProtocol> requestFilter = self.configuration.requestFilter;
    if ([requestFilter respondsToSelector:@selector(filterURLRquest:ofRquest:)]) {
        originRequest = [requestFilter filterURLRquest:originRequest ofRquest:request];
    }
    request.request = originRequest;
    
    /// 获取NSURLSessionTask
    NSURLSessionTask *sessionTask = nil;
    __weak typeof(self) weakSelf = self;
    if (request.internalRequest.uploadRequest) {
        void (^completionHandler)(NSURLResponse * _Nonnull, id  _Nullable, NSError * _Nullable) = ^
        (NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [weakSelf handleResponseForRequest:request
                           withURLResponse:response
                                      data:responseObject
                                     error:error];
        };
        
        sessionTask = [request.internalRequest uploadTaskWithSessionManager:self.sessionManager
                                                          completionHandler:completionHandler];
    }
    else if (request.internalRequest.downloadRequest) {
        void (^completionHandler)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^
        (NSURLResponse *response, NSURL *filePath, NSError *error) {
            /// 请求完成则立即移除历史的断点续传数据
            [request.internalRequest removeLatestResumeData];
            if (error || !filePath) {
                // 从`NSError`的`userInfo`字典中可以获取到下载缓存数据
                NSDictionary *userInfo = error.userInfo;
                NSData *resumeData = userInfo[NSURLSessionDownloadTaskResumeData];
                [request.internalRequest saveDownloadResumeData:resumeData];
                
                [weakSelf handleResponseForDownloadRequest:request
                                       withURLResponse:response
                                                  data:nil
                                                 error:error];
            } else {
                NSData *fileData = [[NSData alloc] initWithContentsOfURL:filePath options:NSDataReadingMappedIfSafe error:nil];
                [weakSelf handleResponseForDownloadRequest:request
                                       withURLResponse:response
                                                  data:fileData
                                                 error:error];
            }
        };
        
        sessionTask = [request.internalRequest downloadTaskWithSessionManager:self.sessionManager
                                                            completionHandler:completionHandler];
    }
    else {
        void (^completionHandler)(NSURLResponse * _Nonnull, id _Nullable, NSError * _Nullable) = ^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [weakSelf handleResponseForRequest:request
                           withURLResponse:response
                                      data:responseObject
                                     error:error];
        };
        
        sessionTask = [request.internalRequest dataTaskWithSessionManager:self.sessionManager
                                                        completionHandler:completionHandler];
    }
    
    [request changeRequestState:GDRequestStateRunning];
    request.task = sessionTask;
    [sessionTask resume];
    
    [request triggerRequestDidStartAccessoryCallBack];
}

#pragma mark handle normal response

/// 检查上传请求已经普通http请求返回数据的合法性以及反序列化返回数据
- (void)handleResponseForRequest:(GDBaseRequest *)request
                 withURLResponse:(NSURLResponse *)response
                            data:(id)data
                           error:(NSError * _Nullable)error {
    [request triggerRequestWillStopAccessoryCallBack];
    
    NSError *typeError = nil;
    /// response
    request.response = response;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        request.responseStatusCode = ((NSHTTPURLResponse *)response).statusCode;
    }
    else {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkInvaildResponseType
                                      exception:nil
                                        request:request
                                          error:&typeError];
    }
    /// serializer
    if ([data isKindOfClass:[NSData class]]) {
        request.responseData = data;
        [request.internalRequest serializeResponseWithError:&error];
    }
    else {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkInvaildResponseDataType
                                      exception:nil
                                        request:request
                                          error:&typeError];
    }
    /// response validate
    NSError *checkError = nil;
    BOOL result = [request.internalRequest validateResponseDataWithError:&checkError];
    if (nil == checkError && nil == typeError && nil == error && result) {
        NSError *cacheError = nil;
        [request.internalRequest saveAsCacheIfNeededWithError:&cacheError];
        request.cacheError = cacheError;
        
        [request requestSuccessFilter];
        [request triggerRequestSuccessCallBack];
    }
    else {
        request.responseError =  checkError ?: (typeError ?: error);
        
        if([request useInsta]&&[error.domain isEqualToString:@"com.alamofire.error.serialization.response"]){
            ///这里只针对insta接口返回400报错的特殊处理！！！！！！！！
            ///其他接口不享受这个特殊待遇
            [request requestSuccessFilter];
            [request triggerRequestSuccessCallBack];
        }
        else{
            [request requestFailureFilter];
            [request triggerRequestFailureCallBack];
        }
    }
    /// set state
    if (error.domain && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        [request changeRequestState:GDRequestStateCancelled];
    }
    else {
        [request changeRequestState:GDRequestStateCompleted];
    }
    
    [request triggerRequestDidStopAccessoryCallBack];
    [self removeRequest:request];
}

#pragma mark handle download response

///处理下载请求的返回数据
- (void)handleResponseForDownloadRequest:(GDBaseRequest *)request
                         withURLResponse:(NSURLResponse *)response
                                    data:(NSData *)data
                                   error:(NSError * _Nullable)error {
    [request triggerRequestWillStopAccessoryCallBack];
    
    request.response = response;
    request.responseData = data;
    
    NSError *typeError = nil;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        request.responseStatusCode = ((NSHTTPURLResponse *)response).statusCode;
    }
    else {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkInvaildResponseType
                                   exception:nil
                                     request:request
                                       error:&typeError];
    }
    
    NSError *checkError = nil;
    [request.internalRequest validateResponseDataWithError:&checkError];
    
    if (!error && !checkError) {
        [request requestSuccessFilter];
        [request triggerRequestSuccessCallBack];
    }
    else {
        request.responseError = error ?: checkError;
        if([request useInsta]&&[error.domain isEqualToString:@"com.alamofire.error.serialization.response"]){
            ///这里只针对insta接口返回400报错的特殊处理！！！！！！！！
            ///其他接口不享受这个特殊待遇
            [request requestSuccessFilter];
            [request triggerRequestSuccessCallBack];
        }
        else{
            [request requestFailureFilter];
            [request triggerRequestFailureCallBack];
        }
    }
    
    if (error.domain && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        [request changeRequestState:GDRequestStateCancelled];
    }
    else {
        [request changeRequestState:GDRequestStateCompleted];
    }
    
    [request triggerRequestDidStopAccessoryCallBack];
    [self removeRequest:request];
}

#pragma mark - --------- Record Request ---------

/**
 判断请求是否在队列中
 
 @param request 要判断的请求
 @return 是否在队列中
 */
- (BOOL)isRequestInQueue:(GDBaseRequest *)request {
    pthread_mutex_lock(&_lock);
    BOOL isRequestInQueue = [self.requests containsObject:request];
    pthread_mutex_unlock(&_lock);
    return isRequestInQueue;
}

/**
 记录已经开始的请求
 
 @param request 要记录的请求
 @return 记录是否成功，如果请求已经开始就会记录失败
 */
- (BOOL)recordRequest:(GDBaseRequest *)request {
    if (!request) {
        return NO;
    }
    ///线程安全
    pthread_mutex_lock(&_lock);
    BOOL shouldRecordRequest = ![self.requests containsObject:request];
    if (shouldRecordRequest) {
        [self.requests addObject:request];
    }
    pthread_mutex_unlock(&_lock);
    
    return shouldRecordRequest;
}


/**
 移除记录的请求，一般是在请求结束时移除
 
 @param request 请求
 */
- (void)removeRequest:(GDBaseRequest *)request {
    if (!request) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    [self.requests removeObject:request];
    pthread_mutex_unlock(&_lock);
}

/// 清空变量 初始化internal
- (void)prepareForRequest:(GDBaseRequest *)request {
    request.response = nil;
    request.cacheHited = NO;
    request.cacheError = nil;
    request.responseError = nil;
    request.responseData = nil;
    
    request.internalRequest = [[GDBaseRequestInternal alloc] init];
    request.internalRequest.request = request;
    request.internalRequest.engine = self;
    [request.internalRequest prepare];
}

#pragma mark - HTTP Redirection

- (void)setUpRedirectionBlock {
    __weak typeof(self) weakSelf = self;
    
    NSURLRequest *(^redirectionBlock)(NSURLSession *, NSURLSessionTask *, NSURLResponse *, NSURLRequest *) = ^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return request;
        }
        
        pthread_mutex_lock(&strongSelf->_lock);
        NSSet<GDBaseRequest *> *requests = strongSelf.requests.copy;
        pthread_mutex_unlock(&strongSelf->_lock);
        
        __block GDBaseRequest *gdRequest = nil;
        [requests enumerateObjectsUsingBlock:^(GDBaseRequest * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.task == task) {
                gdRequest = obj;
                *stop = YES;
            }
        }];
        
        if (gdRequest && gdRequest.redirectionBlock) {
            __block NSURLRequest *redirectRequest = nil;
            gd_network_dispatch_async_main_queue_safety(^{
                redirectRequest = gdRequest.redirectionBlock(session,task,response,request);
            });
            return redirectRequest;
        }
        
        return request;
    };
    
    [self.sessionManager setTaskWillPerformHTTPRedirectionBlock:redirectionBlock];
}

#pragma mark - dealloc

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}


@end
