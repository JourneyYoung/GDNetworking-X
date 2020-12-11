//
//  GDBaseRequest.m
//  GDNetwork
//
//  Created by Journey on 2018/3/12.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDBaseRequest.h"
#import "GDNetworkConsole.h"
#import "AFNetworking.h"
#import "GDNewtworkLog.h"
#import "GDNetworkPrivate.h"
#import "GDNetEnvironmentConfigureManager.h"
#import "GDBaseRequestInternal.h"

NSString *const GDNetworkErrorDomain = @"GDNetworkErrorDomain";

@interface GDBaseRequest ()

@end

@implementation GDBaseRequest

- (instancetype)init{
    self = [super init];
    if(!self){
        return nil;
    }
    _requestAccessories = [NSMutableSet<id<GDBaseRequestStateProtocol>> setWithCapacity:1];
    _successTargetActionSet = [NSMutableSet<GDNetworkTargetAction *> setWithCapacity:1];
    _failureTargetActionSet = [NSMutableSet<GDNetworkTargetAction *> setWithCapacity:1];
    _cacheHittedTargetActionSet = [NSMutableSet<GDNetworkTargetAction *> setWithCapacity:1];
    
    return self;
}

- (NSMutableSet<id<GDBaseRequestStateProtocol>> *)requestAccessories{
    @synchronized (_requestAccessories){
        return _requestAccessories;
    }
}

- (void)addReuestAccessory:(id<GDBaseRequestStateProtocol>)requestAccessory{
    @synchronized (_requestAccessories){
        [_requestAccessories addObject:requestAccessory];
    }
}

#pragma mark - Target Action

- (NSMutableSet<GDNetworkTargetAction *> *)successTargetActionSet{
    @synchronized (_successTargetActionSet) {
        return _successTargetActionSet;
    }
}

-(NSMutableSet<GDNetworkTargetAction *> *)failureTargetActionSet{
    @synchronized (_failureTargetActionSet) {
        return _failureTargetActionSet;
    }
}

- (NSMutableSet<GDNetworkTargetAction *> *)cacheHittedTargetActionSet {
    @synchronized (_cacheHittedTargetActionSet) {
        return _cacheHittedTargetActionSet;
    }
}

- (void)addTarget:(id)target successAction:(SEL)action{
    GDNetworkTargetAction *targetAction = [[GDNetworkTargetAction alloc] initWithTarget:target action:action];
    @synchronized (_successTargetActionSet){
        [_successTargetActionSet addObject:targetAction];
    }
}

- (void)addTarget:(id)target failureAction:(SEL)action{
    GDNetworkTargetAction *targetAction = [[GDNetworkTargetAction alloc] initWithTarget:target action:action];
    @synchronized (_failureTargetActionSet){
        [_failureTargetActionSet addObject:targetAction];
    }
}

#pragma mark - 请求动作

- (void)start{
    [self.requestConsole startRequest:self];
}

- (void)startWithSuccessBlock:(GDRequestCompletionBlock)successBlock
                 failureBlock:(nullable GDRequestCompletionBlock)failureBlock{
    self.successCompletionBlock = successBlock;
    self.failureCompletionBlock = failureBlock;
    [self start];
}

- (void)suspend{
    if (self.requestState == GDRequestStateRunning) {
        [self.task suspend];
        [self changeRequestState:GDRequestStateSuspend];
    }
    else {
        [GDNewtworkLog logWithFormat:@"Warning:请求`%@` 还未开始，不能执行suspend操作",self];
    }
}

- (void)resume {
    if (self.requestState == GDRequestStateSuspend) {
        [self.task resume];
        [self changeRequestState:GDRequestStateRunning];
    }
    else {
        [GDNewtworkLog logWithFormat:@"Warning:请求`%@` 还未开始，不能执行resume操作",self];
    }
}

- (void)stop{
    [self.requestConsole cancelRequest:self];
}

- (void)clearCompletionBlock{
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (void)startWithoutCache {
    [self.requestConsole startRequestWithoutCache:self];
}


- (NSString *)description{
    return [NSString stringWithFormat:@"%@: { URL: %@, Method: %@ }"
            ,[super description]
            ,_internalRequest.requestURLString
            ,_internalRequest.httpMethod];
}

@end

@implementation GDBaseRequest(BasRequestInfo)

- (GDNetworkConsole *)requestConsole{
    return [GDNetworkConsole defaultConsole];
}

- (NSString *)requestUrl{
    return nil;
}

- (NSString *)baseUrl{
    return nil;
}

- (id)params{
    return nil;
}

- (NSURLRequest *)customeRequest{
    return nil;
}

- (GDRequestPriority)requestPriority{
    return GDRequestPriorityDefualt;
}

- (NSString *)requestAuthorizationUsername{
    return nil;
}

- (NSString *)requestAuthorizationPassword {
    return nil;
}

- (NSDictionary *)requestHeaderFieldValueDictionary{
    return nil;
}

- (NSInteger)timeoutInterval{
    return 60.f;
}

- (GDRequestType)requestType{
    return GDRequestTypeGET;
}

- (GDRequestSerializerType)requestSerializerType{
    return GDRequestSerializerTypeJSON;
}

- (GDResponseSerializerType)responseSerializerType{
    return GDResponseSerializerTypeJSON;
}

- (void)requestSuccessFilter{
    
}

- (void)requestFailureFilter{
    
}

- (NSArray<GDRequestFormData *> *)requestFormData{
    return nil;
}

- (id)jsonValidator{
    return nil;
}

- (BOOL)responseValidator{
    NSInteger statusCode = [self responseStatusCode];
    if(self.useInsta){
        ///insta接口返回400时因为需要登录，所以这里也判断为请求cheng'g
        if(statusCode == 400){
            return YES;
        }
    }
    if (statusCode >= 200 && statusCode <= 299) {
        return YES;
    } else {
        return NO;
    }
}

@end

@implementation GDBaseRequest (Upload)

- (NSURLRequest *)fileUploadRequest{
    return nil;
}

- (NSURL *)uploadFileURL{
    return nil;
}

- (NSData *)uploadFileData{
    return nil;
}

@end

@implementation GDBaseRequest (Download)

- (BOOL)saveResumeDataWhileCancelDownloadRequest{
    return YES;
}

- (NSData *)downloadRequestResumeData{
    if(self.downloadResumeDataURL){
        return [[NSData alloc] initWithContentsOfURL:[_internalRequest incompleteDownloadTempPathForDownloadPath:self.downloadResumeDataURL] options:NSDataReadingMappedIfSafe error:nil];
    }
    return nil;

}

- (NSURL *)downloadResumeDataURL {
    if (_downloadResumeDataURL) {
        return _downloadResumeDataURL;
    }
    
    NSURLRequest *fileDownloadRequest = self.internalRequest.fileDownloadRequest;
    if (!fileDownloadRequest) {
        return nil;
    }
    NSString *uniqueCode = [GDNetworkPrivate uniqueCodeForRequest:fileDownloadRequest];
    NSURL *downloadResumeDirectory = self.requestConsole.configuration.downloadResumeDirectory;
    NSURL *absolutelyResumePath = [downloadResumeDirectory URLByAppendingPathComponent:uniqueCode];
    _downloadResumeDataURL = absolutelyResumePath;
    return absolutelyResumePath;
}

- (NSURLRequest *)fileDownloadRequest{
    return nil;
}

- (NSURL *)downloadDirectory{
    return nil;
}

@end

@implementation GDBaseRequest (CDN)

- (BOOL)useCDN{
    return NO;
}

- (NSString *)cdnUrl{
    return nil;
}

- (BOOL)useInsta{
    return NO;
}

- (NSString *)instaUrl{
    return nil;
}

@end

@implementation GDBaseRequest (Cache)

-(void)addTarget:(id)target cacheHittedAction:(SEL)action{
    GDNetworkTargetAction *targetAction = [[GDNetworkTargetAction alloc] initWithTarget:target action:action];
    @synchronized (_cacheHittedTargetActionSet) {
        [_cacheHittedTargetActionSet addObject:targetAction];
    }
}

- (void)startWithSuccessBlock:(GDRequestCompletionBlock)successBlock
             cacheHittedBlock:(GDRequestCompletionBlock)cacheHittedBlock
                 failureBlock:(GDRequestCompletionBlock)failureBlock{
    self.successCompletionBlock = successBlock;
    self.cacheHittedBlock = cacheHittedBlock;
    self.failureCompletionBlock = failureBlock;
    [self start];
}

- (void)requestCacheHittedFilter{
    
}

- (BOOL)ignoreCache{
    return YES;
}

- (id)cacheSensitiveArgument{
    return nil;
}

- (BOOL)invalidateRequestWhileCacheHited{
    return NO;
}

- (NSTimeInterval)cacheTimeInSeconds{
    return 0;
}

- (long long)cacheVersion{
    return 0;
}

- (BOOL)cleanCache{
    return [[self requestConsole] cleanCacheForRequest:self];
}

@end

