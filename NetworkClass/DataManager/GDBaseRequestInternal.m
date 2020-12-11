//
//  GDBaseRequestInternal.m
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDBaseRequestInternal.h"
#import "GDRequestFormData.h"
#import "GDNetworkConsole.h"
#import "GDNetEnvironmentConfigureManager.h"
#import "GDNetworkPrivate.h"
#import "GDNetworkEncryptionRequestSerializer.h"
#import "GDNetworkEncryptionResponseSerializer.h"
#import <AFNetworking/AFURLRequestSerialization.h>
#import "GDNewtworkLog.h"

#define GDNetworkIncompleteDownloadFolderName @"Incomplete"

@implementation GDBaseRequestInternal

- (void)prepare{
    if (!_request || !_engine) {
        return;
    }
    
    /// 下载请求
    self.downloadRequest = ([_request fileDownloadRequest] != nil) || ([_request downloadRequestResumeData] != nil);
    self.fileDownloadRequest = [_request fileDownloadRequest];
    self.downloadRequestResumeData = [_request downloadRequestResumeData];
    self.downloadDirectory = [_request downloadDirectory];
    
    /// 上传请求
    self.uploadRequest = [_request fileUploadRequest] != nil;
    self.fileUploadRequest = [_request fileUploadRequest];
    self.uploadFileData = [_request uploadFileData];
    self.uploadFileURL = [_request uploadFileURL];
    
    /// 缓存
    self.ignoreCache = [_request ignoreCache];
    self.cacheVersion = [_request cacheVersion];
    self.cacheTimeInSeconds = [_request cacheTimeInSeconds];
    self.cacheSensitiveArgument = [_request cacheSensitiveArgument];
    self.invalidateRequestWhileCacheHited = [_request invalidateRequestWhileCacheHited];
    
    /// 请求基本数据
    self.requestArgument = [_request params];
    self.timeoutInterval = [_request timeoutInterval];
    self.formDataArrray = [_request requestFormData];
    self.customeRequest = [_request customeRequest];
    self.requestPriority = _request.requestPriority;
    
    /// 构建最终请求
    self.requestURLString = [self buildCurrentURLString];
    self.httpMethod = [self buildCurrentHTTPMethod];
    self.requestSerializer = [self buildCurrentRequestSeializer];
    self.cacheAbsolutelyPath = [self buildCacheAbsolutelyPath];
}

- (NSString *)buildCurrentURLString {
    NSURLRequest *customeRequest = self.customeRequest;
    if (customeRequest) {
        return customeRequest.URL.absoluteString;
    }
    
    NSString *urlPath = [[_request requestUrl] copy];
    NSURL *url = [NSURL URLWithString:urlPath];
    if (url.host && url.host.length > 0) {
        return urlPath;
    }
    
    NSString *baseURL = nil;
    if ([_request useCDN]) {
        NSString *cdnUrl = [[_request cdnUrl] copy];
        if (cdnUrl.length > 0) {
            baseURL = cdnUrl;
        }
        else if (_engine.configuration.cdnUrl.length > 0) {
            baseURL = _engine.configuration.cdnUrl;
        }
    }
    else if([_request useInsta]){
        NSString *instaUrl = [[_request instaUrl] copy];
        if (instaUrl.length > 0) {
            baseURL = instaUrl;
        }
        else if (_engine.configuration.instaUrl.length > 0) {
            baseURL = _engine.configuration.instaUrl;
        }
        NSString *requestUrlString = [urlPath copy];
        urlPath = [requestUrlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    else {
        NSString *baseUrl = [[_request baseUrl] copy];
        if (baseUrl.length > 0) {
            baseURL = baseUrl;
        }
        else if(_engine.configuration.baseUrl.length > 0) {
            baseURL = _engine.configuration.baseUrl;
        }
    }
    
    NSString *requestURL = [NSString stringWithFormat:@"%@%@",baseURL,urlPath];
    NSURL *holeUrlPath = [NSURL URLWithString:requestURL];
    if(!holeUrlPath){
        ///针对urlpath序列化出错的情况进行拦截
        NSString *encodeString = [self encodeString:requestURL];
        NSURL *encodeUrl = [NSURL URLWithString:encodeString];
        if(!encodeUrl){
            ///不能让request出现nil的情况，可以请求失败
            requestURL = baseURL;
        }
        else{
            requestURL = encodeString;
        }
    }
    return requestURL;
}

- (NSString *)buildCurrentHTTPMethod {
    NSURLRequest *customeRequest = self.customeRequest;
    if (customeRequest) {
        return customeRequest.HTTPMethod;
    }
    switch ([_request requestType]) {
        case GDRequestTypeGET:
            return @"GET";
            break;
        case GDRequestTypePOST:
            return @"POST";
            break;
        case GDRequestTypePUT:
            return @"PUT";
            break;
        case GDRequestTypeHEAD:
            return @"HEAD";
            break;
        case GDRequestTypePATCH:
            return @"PATCH";
            break;
        case GDRequestTypeDELETE:
            return @"DELETE";
            break;
    }
}

- (NSString *)encodeString:(NSString *)urlString{
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)urlString,
                                                              NULL,
                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8));
    return encodedString;
}

- (AFHTTPRequestSerializer *)buildCurrentRequestSeializer {
    AFHTTPRequestSerializer *currentRequestSeializer;
    
    switch (_request.requestSerializerType) {
        case GDRequestSerializerTypeHTTP:
            currentRequestSeializer = [AFHTTPRequestSerializer serializer];
            break;
        case GDRequestSerializerTypeJSON:
            currentRequestSeializer = [AFJSONRequestSerializer serializer];
            break;
        case GDRequestSerializerTypeEncryption:
            currentRequestSeializer = [GDNetworkEncryptionRequestSerializer serializer];
            break;
    }
    
    if(_request.requestAuthorizationUsername.length > 0
       && _request.requestAuthorizationPassword.length > 0) {
        NSString *username = _request.requestAuthorizationUsername;
        NSString *password = _request.requestAuthorizationPassword;
        
        [currentRequestSeializer setAuthorizationHeaderFieldWithUsername:username
                                                                password:password];
    }
    else if (_engine.configuration.requestAuthorizationUsername.length > 0
             && _engine.configuration.requestAuthorizationPassword.length > 0) {
        NSString *username = _engine.configuration.requestAuthorizationUsername;
        NSString *password = _engine.configuration.requestAuthorizationPassword;
        
        [currentRequestSeializer setAuthorizationHeaderFieldWithUsername:username
                                                                password:password];
    }
    
    NSDictionary *configurationHTTPHeaderFields = [_engine.configuration.requestHeaderFieldValueDictionary copy];
    [configurationHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id _Nonnull field, id _Nonnull value, BOOL * _Nonnull stop) {
        if ([field isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
            [currentRequestSeializer setValue:value forHTTPHeaderField:field];
        }
        else {
            [GDNewtworkLog logWithFormat:@"Warning:请求`%@`中requestHeaderFieldValueDictionary必须由字符串组成", _engine.configuration];
        }
    }];
    NSDictionary *requestHTTPHeaderFields = [[_request requestHeaderFieldValueDictionary] copy];
    [requestHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id _Nonnull field, id _Nonnull value, BOOL * _Nonnull stop) {
        if ([field isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
            [currentRequestSeializer setValue:value
                           forHTTPHeaderField:field];
        }
        else {
            [GDNewtworkLog logWithFormat:@"Warning:请求`%@`中requestHeaderFieldValueDictionary必须由字符串组成",NSStringFromClass(_request.class)];
        }
    }];
    
    return currentRequestSeializer;
}

- (NSString *)buildCacheAbsolutelyPath {
    NSString *requestMethod = _httpMethod;
    NSString *requestUrl = _requestURLString;
    
    NSString *cacheFileName = [NSString stringWithFormat:@"Method:%@ Url:%@",requestMethod, requestUrl];
    
    if (_cacheSensitiveArgument != nil) {
        NSData *sensitiveArgumentData = [NSJSONSerialization dataWithJSONObject:_cacheSensitiveArgument
                                                                        options:NSJSONWritingPrettyPrinted
                                                                          error:nil];
        NSString *cacheSensitiveArgumentJSONString = [[NSString alloc] initWithData:sensitiveArgumentData
                                                                           encoding:NSUTF8StringEncoding];
        cacheFileName = [NSString stringWithFormat:@"%@  Argument:%@",cacheFileName,cacheSensitiveArgumentJSONString];
    }
    
    NSString *sha1CachFileName = [GDNetworkPrivate SHA1WithData:[cacheFileName dataUsingEncoding:NSUTF8StringEncoding]];
    sha1CachFileName = [sha1CachFileName stringByAppendingPathExtension:@"metadata"];
    
    NSURL *cacheDirectory = _engine.configuration.cacheDirectory;
    NSString *cacheMetadataAbsolutelyPath = [cacheDirectory.path stringByAppendingPathComponent:sha1CachFileName];
    
    return cacheMetadataAbsolutelyPath;
}

- (NSURLRequest *)serializeRequestWithError:(NSError * _Nullable __autoreleasing *)error{
    /// 判断是否是下载请求
    if (_downloadRequest) {
        return _fileDownloadRequest;
    }
    /// 判断是否是上传请求
    if (_uploadRequest) {
        return _fileUploadRequest;
    }
    /// 一般请求
    if (_customeRequest) {
        return _customeRequest;
    }
    
    /// build request with request seializer
    AFHTTPRequestSerializer *requestSerializer = _requestSerializer;
    requestSerializer.timeoutInterval = _timeoutInterval;
    
    NSString *requestURL = _requestURLString;
    id requestArguments = _requestArgument;
    NSString *httpMethod = _httpMethod;
    NSMutableURLRequest *urlRequest = nil;
    NSArray<GDRequestFormData *> *formDataArrray = _formDataArrray;
    
    if (formDataArrray && formDataArrray.count > 0) {
        void (^constructingBodyWithBlock)(id <AFMultipartFormData> formData) = ^(id<AFMultipartFormData>  _Nonnull formData) {
            /// 构造form请求
            [formDataArrray enumerateObjectsUsingBlock:^(GDRequestFormData * _Nonnull tempFormData, NSUInteger idx, BOOL * _Nonnull stop) {
                if (tempFormData.formData) {
                    [formData appendPartWithFileData:tempFormData.formData
                                                name:tempFormData.name
                                            fileName:tempFormData.fileName
                                            mimeType:tempFormData.mineType];
                }
                else if (tempFormData.inputStream) {
                    [formData appendPartWithInputStream:tempFormData.inputStream
                                                   name:tempFormData.name
                                               fileName:tempFormData.fileName
                                                 length:tempFormData.inputStreamLength
                                               mimeType:tempFormData.mineType];
                }
                else if (tempFormData.fileURL) {
                    [formData appendPartWithFileURL:tempFormData.fileURL
                                               name:tempFormData.name
                                           fileName:tempFormData.fileName
                                           mimeType:tempFormData.mineType
                                              error:error];
                }
            }];
        };
        
        /// 表单请求
        urlRequest = [requestSerializer multipartFormRequestWithMethod:httpMethod
                                                             URLString:requestURL
                                                            parameters:requestArguments
                                             constructingBodyWithBlock:constructingBodyWithBlock
                                                                 error:error];
    }
    else {
        /// 普通请求
        urlRequest = [requestSerializer requestWithMethod:httpMethod
                                                URLString:requestURL
                                               parameters:requestArguments
                                                    error:error];
    }
    
    return urlRequest.copy;
}

- (void)serializeResponseWithError:(NSError * _Nullable __autoreleasing *)error{
    switch (_request.responseSerializerType) {
        case GDResponseSerializerTypeString: {
            NSString *responseString = [[NSString alloc] initWithData:_request.responseData
                                                             encoding:NSUTF8StringEncoding];
            _request.responseString = responseString;
        }
            break;
        case GDResponseSerializerTypeJSON: {
            AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializer];
            jsonSerializer.removesKeysWithNullValues = YES;
            id responseObject = [jsonSerializer responseObjectForResponse:_request.response
                                                                     data:_request.responseData
                                                                    error:error];
            _request.responseJSONObject = responseObject;
        }
            break;
        case GDResponseSerializerTypeDecryption: {
            GDNetworkEncryptionResponseSerializer *decryptSerializer = [GDNetworkEncryptionResponseSerializer serializer];
            decryptSerializer.removesKeysWithNullValues = YES;
            id responseObject = [decryptSerializer responseObjectForResponse:_request.response
                                                                        data:_request.responseData
                                                                       error:error];
            _request.responseJSONObject = responseObject;
        }
            break;
        case GDResponseSerializerTypeData:
            break;
    }
}

- (NSURLSessionUploadTask *)uploadTaskWithSessionManager:(AFURLSessionManager *)sessionManager
                                       completionHandler:(void (^)(NSURLResponse * _Nonnull, id _Nonnull, NSError * _Nonnull))completionHandler {
    NSURLRequest *fileUploadRequest = _fileUploadRequest;
    NSData *uploadData = _uploadFileData;
    NSURL *uploadFileURL = _uploadFileURL;
    
    __weak typeof(self) weakSelf = self;
    void (^uploadProgressBlock)(NSProgress *progress) = ^(NSProgress *progress) {
        if (weakSelf.request.uploadProgressBlock) {
            gd_network_dispatch_async_main_queue_safety(^{
                weakSelf.request.uploadProgressBlock(progress);
            });
        }
    };
    
    NSURLSessionUploadTask *uploadTask = nil;
    if (uploadData) {
        uploadTask = [sessionManager uploadTaskWithRequest:fileUploadRequest
                                                  fromData:uploadData
                                                  progress:uploadProgressBlock
                                         completionHandler:completionHandler];
    }
    else {
        uploadTask = [sessionManager uploadTaskWithRequest:fileUploadRequest
                                                  fromFile:uploadFileURL
                                                  progress:uploadProgressBlock
                                         completionHandler:completionHandler];
    }
    
    [self assignTaskWithPriority:uploadTask];
    
    return uploadTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithSessionManager:(AFURLSessionManager *)sessionManager
                                           completionHandler:(void (^)(NSURLResponse * _Nonnull, NSURL * _Nonnull, NSError * _Nonnull))completionHandler{
    NSURLRequest *fileDownloadRequest = _fileDownloadRequest;
    NSData *resumeData = _downloadRequestResumeData;
    
    NSURL *downloadDirectory = _downloadDirectory;
    if (!downloadDirectory) {
        downloadDirectory = _engine.configuration.downloadDirectory;
    }
    __weak typeof(self) weakSelf = self;
    NSURL *(^destinationBlock)(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) = ^(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSData *fileData = [[NSData alloc] initWithContentsOfURL:targetPath options:NSDataReadingMappedIfSafe error:nil];
        NSString *sha1Name = [GDNetworkPrivate SHA1WithData:fileData];
        NSURL *downloadDestinationURL = [downloadDirectory URLByAppendingPathComponent:sha1Name];
        downloadDestinationURL = [downloadDestinationURL URLByAppendingPathExtension:response.suggestedFilename.pathExtension];
        weakSelf.request.downloadDestinationURL = downloadDestinationURL;
        NSFileManager *mgr = [NSFileManager defaultManager];
        /* 0723 Fix
         * 当原有file下存在文件时，先移除再下载
         */
        if([mgr fileExistsAtPath:weakSelf.request.downloadDirectory.path]){
            [mgr removeItemAtPath:weakSelf.request.downloadDirectory.path error:nil];
        }
        [mgr moveItemAtPath:targetPath.path toPath:weakSelf.request.downloadDirectory.path error:nil];
        return downloadDestinationURL;
    };
    
    void (^downloadProgressBlock)(NSProgress *progress) = ^(NSProgress *progress) {
        if (weakSelf.request.downloadProgressBlock) {
            gd_network_dispatch_async_main_queue_safety(^{
                if (!progress.kind) {
                    progress.kind = NSProgressKindFile;
                }
                weakSelf.request.downloadProgressBlock(progress);
            });
        }
    };
    
    NSURLSessionDownloadTask *downloadTask = nil;
    if (resumeData) {
        downloadTask = [sessionManager downloadTaskWithResumeData:resumeData
                                                         progress:downloadProgressBlock
                                                      destination:destinationBlock
                                                completionHandler:completionHandler];
    }
    else {
        downloadTask = [sessionManager downloadTaskWithRequest:fileDownloadRequest
                                                      progress:downloadProgressBlock
                                                   destination:destinationBlock
                                             completionHandler:completionHandler];
    }
    
    [self assignTaskWithPriority:downloadTask];
    
    return downloadTask;
}

- (NSURLSessionDataTask *)dataTaskWithSessionManager:(AFURLSessionManager *)sessionManager
                                   completionHandler:(void (^)(NSURLResponse * _Nonnull, id _Nullable, NSError * _Nullable))completionHandler{
    __weak typeof(self) weakSelf = self;
    void (^uploadProgress)(NSProgress *progress) = ^(NSProgress *progress) {
        if (weakSelf.request.uploadProgressBlock) {
            gd_network_dispatch_async_main_queue_safety(^{
                weakSelf.request.uploadProgressBlock(progress);
            });
        }
    };
    
    void (^downloadProgres)(NSProgress *progress) = ^(NSProgress *progress) {
        if (weakSelf.request.downloadProgressBlock) {
            gd_network_dispatch_async_main_queue_safety(^{
                weakSelf.request.downloadProgressBlock(progress);
            });
        }
    };
    
    /// 请求实例
    NSURLSessionDataTask *dataTask = [sessionManager dataTaskWithRequest:_request.request
                                                          uploadProgress:uploadProgress
                                                        downloadProgress:downloadProgres
                                                       completionHandler:completionHandler];
    
    [self assignTaskWithPriority:dataTask];
    
    return dataTask;
}

- (void)assignTaskWithPriority:(NSURLSessionTask *)task {
    /// 设置请求优先级
    switch (self.requestPriority) {
        case GDRequestPriorityLow:
            task.priority = NSURLSessionTaskPriorityLow;
            break;
        case GDRequestPriorityDefualt:
            task.priority = NSURLSessionTaskPriorityDefault;
            break;
        case GDRequestPriorityHigh:
            task.priority = NSURLSessionTaskPriorityHigh;
            break;
    }
}

///校验返回数据
- (BOOL)validateResponseDataWithError:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [_request responseValidator];
    if (!result) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkResponseValidateError
                                      exception:nil
                                        request:_request
                                          error:error];
        return result;
    }
    
    id jsonValidator = [_request jsonValidator];
    id responseJSONObject = [_request responseJSONObject];
    if (jsonValidator != nil && responseJSONObject != nil) {
        result = [GDNetworkPrivate checkJson:responseJSONObject
                                  withValidator:jsonValidator];
        
        if (!result) {
            [GDNetworkPrivate raiseErrorWithCode:GDNetworkJSONValidateError
                                          exception:nil
                                            request:_request
                                              error:error];
        }
    }
    
    return result;
}

- (void)saveDownloadResumeData:(NSData *)resumeData{
    if (!resumeData) {
        return;
    }
    [resumeData writeToURL:[self incompleteDownloadTempPathForDownloadPath:_request.downloadResumeDataURL] atomically:YES];
}

//From YTK
- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSURL *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5URLString = [GDNetworkPrivate md5StringFromString:downloadPath.path];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return [NSURL fileURLWithPath:tempPath];
}

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:GDNetworkIncompleteDownloadFolderName];
    }
    
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        [GDNewtworkLog logWithFormat:@"Failed to create cache directory at %@", cacheFolder];
        cacheFolder = nil;
    }
    return cacheFolder;

}

- (void)removeLatestResumeData{
    /// 移除历史缓存记录
    if (_request.downloadResumeDataURL) {
        [[NSFileManager defaultManager] removeItemAtPath:[self incompleteDownloadTempPathForDownloadPath:_request.downloadResumeDataURL] error:nil];
    }
}

- (BOOL)checkCacheWithError:(NSError * _Nullable __autoreleasing *)error{
    /// 是否忽略缓存
    if (self.ignoreCache) {
        return NO;
    }
    
    /// 缓存时间是否合法
    if (self.cacheTimeInSeconds < 0) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkInvalidCacheInSeconds
                                      exception:nil
                                        request:_request
                                          error:error];
        return NO;
    }
    
    /// 检查缓存文件是否存在
    NSString *cacheAbsolutelyPath = self.cacheAbsolutelyPath;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:cacheAbsolutelyPath isDirectory:nil]) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkInvaildCache
                                      exception:nil
                                        request:_request
                                          error:error];
        return NO;
    }
    
    /// 获取缓存数据
    GDNetworkCacheMetaData *cacheMetadata = nil;
    @try {
        cacheMetadata = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheAbsolutelyPath];
    } @catch (NSException *exception) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkInvaildCacheMetadata
                                      exception:exception
                                        request:_request
                                          error:error];
        return NO;
    }
    
    /// 缓存数据不合法
    if (!cacheMetadata || ![cacheMetadata isMemberOfClass:[GDNetworkCacheMetaData class]]) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkInvaildCacheMetadata
                                      exception:nil
                                        request:_request
                                          error:error];
        return NO;
    }
    
    /// 检查缓存文件是否过期
    NSDate *creationDate = cacheMetadata.creationDate;
    NSTimeInterval duration = -[creationDate timeIntervalSinceNow];
    /// 缓存时间
    if (duration < 0 || duration > self.cacheTimeInSeconds) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkCacheExpired
                                      exception:nil
                                        request:_request
                                          error:error];
        return NO;
    }
    // 缓存版本号
    long long cacheVersionFileContent = self.cacheVersion;
    if (cacheVersionFileContent != self.cacheVersion) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkCacheVersionNotMatch
                                      exception:nil
                                        request:_request
                                          error:error];
        return NO;
    }
    
    /// APP版本号
    NSString *appVersionString = cacheMetadata.appVersionString;
    NSString *currentAppVersionString = [GDNetworkPrivate appVersionString];
    if (appVersionString || currentAppVersionString) {
        if (appVersionString.length != currentAppVersionString.length || ![appVersionString isEqualToString:currentAppVersionString]) {
            [GDNetworkPrivate raiseErrorWithCode:GDNetworkCacheAPPVersionNotMatch
                                          exception:nil
                                            request:_request
                                              error:error];
            return NO;
        }
    }
    
    _request.cacheHited = YES;
    _request.response = cacheMetadata.response;
    _request.responseData = cacheMetadata.cacheData;
    
    return YES;
}

- (BOOL)saveAsCacheIfNeededWithError:(NSError * _Nullable __autoreleasing *)error{
    if (self.cacheTimeInSeconds > 0) {
        if (_request.responseData != nil) {
            @try {
                GDNetworkCacheMetaData *metadata = [[GDNetworkCacheMetaData alloc] init];
                metadata.version = _request.internalRequest.cacheVersion;
                if (self.cacheSensitiveArgument) {
                    NSData *sensitiveArgumentData = [NSJSONSerialization dataWithJSONObject:self.cacheSensitiveArgument
                                                                                    options:NSJSONWritingPrettyPrinted
                                                                                      error:nil];
                    metadata.sensitiveArgumentString = [[NSString alloc] initWithData:sensitiveArgumentData encoding:NSUTF8StringEncoding];
                }
                metadata.creationDate = [NSDate date];
                metadata.appVersionString = [GDNetworkPrivate appVersionString];
                metadata.response = _request.response;
                metadata.cacheData = _request.responseData;
                [NSKeyedArchiver archiveRootObject:metadata toFile:self.cacheAbsolutelyPath];
                
                return YES;
            } @catch (NSException *exception) {
                [GDNetworkPrivate raiseErrorWithCode:GDNetworkWriteCacheFailed
                                              exception:exception
                                                request:_request
                                                  error:error];
                
                return NO;
            }
        }
    }
    
    return NO;
}

- (BOOL)cleanCache{
    NSString *cacheAbsolutePath = self.cacheAbsolutelyPath;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    BOOL existFile = [fileManager fileExistsAtPath:cacheAbsolutePath isDirectory:nil];
    if (existFile) {
        return [fileManager removeItemAtPath:cacheAbsolutePath error:nil];
    }
    return NO;
}


@end
