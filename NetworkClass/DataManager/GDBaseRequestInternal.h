//
//  GDBaseRequestInternal.h
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDBaseRequest.h"

@class GDRequestFormData;
@class GDNetworkConsole;
@class AFHTTPRequestSerializer;
@class AFURLSessionManager;

NS_ASSUME_NONNULL_BEGIN

@interface GDBaseRequestInternal : NSObject

@property (nonatomic, weak) GDBaseRequest *request;
@property (nonatomic, weak) GDNetworkConsole *engine;

#pragma mark - Common Request

@property (nonatomic, copy) NSString *requestURLString;
@property (nonatomic, strong) id requestArgument;
@property (nonatomic, copy) NSString *httpMethod;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) AFHTTPRequestSerializer *requestSerializer;
@property (nonatomic, copy) NSArray<GDRequestFormData *> *formDataArrray;
@property (nonatomic, assign) GDRequestPriority requestPriority;

@property (nonatomic, copy) NSURLRequest *customeRequest;

#pragma mark - Download Request

@property (nonatomic, assign) BOOL downloadRequest;
@property (nonatomic, copy) NSURLRequest *fileDownloadRequest;
@property (nonatomic, copy) NSData *downloadRequestResumeData;
@property (nonatomic, strong) NSURL *downloadDirectory;

#pragma mark - Upload Request

@property (nonatomic, assign) BOOL uploadRequest;
@property (nonatomic, copy) NSURLRequest *fileUploadRequest;
@property (nonatomic, copy) NSData *uploadFileData;
@property (nonatomic, strong) NSURL *uploadFileURL;

#pragma mark - Cache

@property (nonatomic, assign) BOOL ignoreCache;
@property (nonatomic, assign) BOOL invalidateRequestWhileCacheHited;
@property (nonatomic, assign) NSTimeInterval cacheTimeInSeconds;
@property (nonatomic, copy) NSString *cacheSensitiveArgument;
@property (nonatomic, assign) long long cacheVersion;
@property (nonatomic, copy) NSString *cacheAbsolutelyPath;

/// 准备保存快照，此方法不是线程安全的
/// 因为该方法中大都是对request的原始数据进行读取，保存至本类的属性中。
/// 如果同时外部进行读写request的原始数据则会造成线程安全问题，所以尽量
/// 保证该方法是在主线程中进行的
- (void)prepare;

///========================
///     Serizalization
///========================

/// 序列化请求数据
- (NSURLRequest *)serializeRequestWithError:(NSError **)error;

/// 反序列化返回数据
- (void)serializeResponseWithError:(NSError **)error;

///========================
///          Task
///========================

- (NSURLSessionUploadTask *)uploadTaskWithSessionManager:(AFURLSessionManager *)sessionManager
                                       completionHandler:(nullable void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionDownloadTask *)downloadTaskWithSessionManager:(AFURLSessionManager *)sessionManager
                                           completionHandler:(nullable void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

- (NSURLSessionDataTask *)dataTaskWithSessionManager:(AFURLSessionManager *)sessionManager
                                   completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler;

///========================
///   response validator
///========================

- (BOOL)validateResponseDataWithError:(NSError **)error;

///========================
///     resume data
///========================

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSURL *)downloadPath;

- (void)saveDownloadResumeData:(NSData *)resumeData;

- (void)removeLatestResumeData;

///========================
///          cache
///========================

/// 通过快照数据判断请求的缓存数据是否过期，如果没有过期，将请求缓存数据(GDNetworkCacheMetaData)取出
- (BOOL)checkCacheWithError:(NSError **)error;

/// 保存缓存数据
- (BOOL)saveAsCacheIfNeededWithError:(NSError **)error;

/// 清除缓存
- (BOOL)cleanCache;

@end

NS_ASSUME_NONNULL_END
