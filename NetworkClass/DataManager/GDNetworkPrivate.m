//
//  GDNetworkPrivate.m
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//
/// 甘霖娘，没时间写注释了，自己悟吧~

#import "GDNetworkPrivate.h"
#import <CommonCrypto/CommonDigest.h>
#import "GDNewtworkLog.h"
#import "GDBaseRequestInternal.h"
#import "GDNetworkConsole.h"
#import "GDNetEnvironmentConfigureManager.h"
#import "GDNetworkEncryptionRequestSerializer.h"


@implementation GDNetworkPrivate

+ (void)raiseErrorWithCode:(GDNetworkErrorCode)errorCode
                 exception:(NSException *)exception
                   request:(GDBaseRequest *)request
                     error:(NSError *__autoreleasing  _Nullable *)error{
    NSString *errorDescription = nil;
    
    switch (errorCode) {
        case GDNetworkJSONValidateError:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@`JSON验证错误，请求返回数据`%@`与JSON验证结构`%@`",request,request.responseJSONObject,[request jsonValidator]];
        }
            break;
        case GDNetworkResponseValidateError:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@`验证错误，请看请求的`responseValidator`方法以获取更多信息",request];
        }
            break;
        case GDNetworkInvaildResponseType:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@`返回类型不是`NSHTTPURLResponse`",request];
        }
            break;
        case GDNetworkInvaildResponseDataType:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@`返回类型应该是`NSData`",request];
        }
            break;
        case GDNetworkInvalidCacheInSeconds:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@` 配置了无效的缓存时间`%.2f`",request,request.internalRequest.cacheTimeInSeconds];
        }
            break;
        case GDNetworkInvaildCache:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@` 没有缓存文件",request];
        }
            break;
        case GDNetworkInvaildCacheMetadata:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@` 缓存配置文件错误 原因:%@",request,exception.reason];
        }
            break;
        case GDNetworkCacheExpired:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@` 缓存失效",request];
        }
            break;
        case GDNetworkCacheVersionNotMatch:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@` 缓存版本号不匹配",request];
        }
            break;
        case GDNetworkCacheAPPVersionNotMatch:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@` 缓存的APP版本号不匹配",request];
        }
            break;
        case GDNetworkWriteCacheFailed:{
            errorDescription = [NSString stringWithFormat:@"Warning:请求`%@`缓存写入失败 原因：%@",request,exception.reason];
        }
            break;
        case GDNetworkEncryptionKeyExpired:{
            errorDescription = [NSString stringWithFormat:@"Warning:加密握手密钥失效，正在尝试重新握手!"];
        }
            break;
        case GDNetworkEncryptionHandShakeFail:{
            errorDescription = [NSString stringWithFormat:@"Warning:加密握手失败!"];
        }
            break;
    }
    
    if (error) {
        *error  = [NSError errorWithDomain:GDNetworkErrorDomain
                                      code:errorCode
                                  userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
    }
    
    [GDNewtworkLog logWithFormat:@"%@",errorDescription];
}

///校验json数据合法性
+ (BOOL)checkJson:(id)json withValidator:(id)validatorJson{
    if ([json isKindOfClass:[NSDictionary class]] &&
        [validatorJson isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = json;
        NSDictionary *validator = validatorJson;
        NSEnumerator *enumerator = [validator keyEnumerator];
        NSString *key;
        while ((key = [enumerator nextObject]) != nil) {
            id value = dict[key];
            id format = validator[key];
            BOOL result = [self checkJson:value withValidator:format];
            if (!result) {
                return NO;
            }
        }
        return YES;
    }
    else if ([json isKindOfClass:[NSArray class]] &&
             [validatorJson isKindOfClass:[NSArray class]]) {
        NSArray *validatorArray = (NSArray *)validatorJson;
        if (validatorArray.count > 0) {
            NSArray *array = json;
            NSDictionary *validator = validatorArray[0];
            for (id item in array) {
                BOOL result = [self checkJson:item withValidator:validator];
                if (!result) {
                    return NO;
                }
            }
        }
        return YES;
    }
    else if ([json isKindOfClass:[NSString class]] &&
             [validatorJson isKindOfClass:[NSString class]] &&
             [json isEqualToString:validatorJson]) {
        return YES;
    }
    else if ([json isKindOfClass:[NSNumber class]] &&
             [validatorJson isKindOfClass:[NSNumber class]] &&
             [json isEqualToNumber:validatorJson]) {
        return YES;
    }
    else if ([json isKindOfClass:validatorJson]) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)uniqueCodeForRequest:(NSURLRequest *)request{
    NSMutableData *uniqueData = [NSMutableData data];
    NSString *urlIdentifier = [NSString stringWithFormat:@"URL:{%@},",request.URL.absoluteString];
    [uniqueData appendData:[urlIdentifier dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *methodIdentifier = [NSString stringWithFormat:@"METHOD:{%@}",request.HTTPMethod];
    [uniqueData appendData:[methodIdentifier dataUsingEncoding:NSUTF8StringEncoding]];
    [uniqueData appendData:request.HTTPBody];
    return [self SHA1WithData:uniqueData.copy];
}

+ (NSString *)SHA1WithData:(NSData *)fileData{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(fileData.bytes,(CC_LONG)fileData.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

+ (NSString *)md5StringFromString:(NSString *)string{
    NSParameterAssert(string != nil && [string length] > 0);
    
    const char *value = [string UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }
    
    return outputString;
}

+ (NSString *)appVersionString{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

@end

@implementation GDNetworkTargetAction

- (instancetype)initWithTarget:(id)target action:(SEL)action{
    self = [super init];
    if (self) {
        NSAssert(target != nil, @"target cannot be nil in target-action callback");
        NSAssert(action != nil, @"action cannot be nil in target-action callback");
        
        _target = target;
        _action = action;
    }
    return self;
}

- (NSUInteger)hash{
    return [_target hash] ^ NSStringFromSelector(_action).hash;
}

- (BOOL)isEqual:(id)object{
    if (object == self) {
        return YES;
    }
    
    if ([object isMemberOfClass:[GDNetworkTargetAction class]]) {
        GDNetworkTargetAction *newTagetAction = (GDNetworkTargetAction *)object;
        if (newTagetAction.target != nil && _target != nil && newTagetAction.target == _target
            && newTagetAction.action == _action) {
            return YES;
        }
    }
    
    return NO;
}

@end


@implementation GDNetworkCacheMetaData


+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.version) forKey:NSStringFromSelector(@selector(version))];
    [aCoder encodeObject:self.sensitiveArgumentString forKey:NSStringFromSelector(@selector(sensitiveArgumentString))];
    [aCoder encodeObject:self.response forKey:NSStringFromSelector(@selector(response))];
    [aCoder encodeObject:self.creationDate forKey:NSStringFromSelector(@selector(creationDate))];
    [aCoder encodeObject:self.appVersionString forKey:NSStringFromSelector(@selector(appVersionString))];
    [aCoder encodeObject:self.cacheData forKey:NSStringFromSelector(@selector(cacheData))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.version = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(version))] longLongValue];
    self.sensitiveArgumentString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(sensitiveArgumentString))];
    self.response = [aDecoder decodeObjectOfClass:[NSURLResponse class] forKey:NSStringFromSelector(@selector(response))];
    self.creationDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(creationDate))];
    self.appVersionString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(appVersionString))];
    self.cacheData = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(cacheData))];
    
    return self;
}

@end

@implementation GDBaseRequest (Private)

- (NSArray *)getAllRequestAccessories {
    NSMutableSet<id<GDBaseRequestStateProtocol>> *allRequestAccessories = [NSMutableSet setWithSet:self.requestAccessories.copy];
    
    NSArray<id<GDBaseRequestStateProtocol>> *configurationRequestAccessories = [self requestConsole].configuration.requestAccessories.allObjects;
    [allRequestAccessories addObjectsFromArray:configurationRequestAccessories];
    
    NSArray<id<GDBaseRequestStateProtocol>> *globalRequestAccessories = GDNetEnvironmentConfigureManager.globalRequestAccessories.allObjects;
    [allRequestAccessories addObjectsFromArray:globalRequestAccessories];
    
    NSArray<id<GDBaseRequestStateProtocol>> *requestAccessories = self.requestAccessories.allObjects;
    [allRequestAccessories addObjectsFromArray:requestAccessories];
    
    return allRequestAccessories.allObjects;
}

- (void)triggerRequestWillStartAccessoryCallBack{
    gd_network_dispatch_async_main_queue_safety(^{
        [[self getAllRequestAccessories] enumerateObjectsUsingBlock:^(id<GDBaseRequestStateProtocol>  _Nonnull accessory, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([accessory respondsToSelector:@selector(requestWillStart:)]) {
                [accessory requestWillStart:self];
            }
        }];
    });
}

- (void)triggerRequestDidStartAccessoryCallBack {
    gd_network_dispatch_async_main_queue_safety(^{
        [[self getAllRequestAccessories] enumerateObjectsUsingBlock:^(id<GDBaseRequestStateProtocol>  _Nonnull accessory, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([accessory respondsToSelector:@selector(requestDidStart:)]) {
                [accessory requestDidStart:self];
            }
        }];
    });
}

- (void)triggerRequestWillStopAccessoryCallBack{
    gd_network_dispatch_async_main_queue_safety(^{
        [[self getAllRequestAccessories] enumerateObjectsUsingBlock:^(id<GDBaseRequestStateProtocol>  _Nonnull accessory, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([accessory respondsToSelector:@selector(requestWillStop:)]) {
                [accessory requestWillStop:self];
            }
        }];
    });
}

- (void)triggerRequestDidStopAccessoryCallBack {
    gd_network_dispatch_async_main_queue_safety(^{
        [[self getAllRequestAccessories] enumerateObjectsUsingBlock:^(id<GDBaseRequestStateProtocol>  _Nonnull accessory, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([accessory respondsToSelector:@selector(requestDidStop:)]) {
                [accessory requestDidStop:self];
            }
        }];
    });
}

- (void)triggerRequestCacheHittedCallBack{
    gd_network_dispatch_async_main_queue_safety(^{
        if (self.cacheHittedBlock) {
            self.cacheHittedBlock(self);
        }
        if ([self.delegate respondsToSelector:@selector(cacheHitted:)]) {
            [self.delegate cacheHitted:self];
        }
        
        NSArray *cacheHittedTargetActionArray = self.cacheHittedTargetActionSet.allObjects;
        [cacheHittedTargetActionArray enumerateObjectsUsingBlock:^(GDNetworkTargetAction * _Nonnull targetAction, NSUInteger idx, BOOL * _Nonnull stop) {
            id target = targetAction.target;
            SEL action = targetAction.action;
            if (target && [target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [target performSelector:action withObject:self];
#pragma clang diagnostic pop
            }
        }];
    });
}

- (void)triggerRequestSuccessCallBack {
    gd_network_dispatch_async_main_queue_safety(^{
        if (self.successCompletionBlock) {
            self.successCompletionBlock(self);
        }
        if ([self.delegate respondsToSelector:@selector(requestSucced:)]) {
            [self.delegate requestSucced:self];
        }
        
        NSArray *successTargetActionArray = self.successTargetActionSet.allObjects;
        [successTargetActionArray enumerateObjectsUsingBlock:^(GDNetworkTargetAction * _Nonnull targetAction, NSUInteger idx, BOOL * _Nonnull stop) {
            id target = targetAction.target;
            SEL action = targetAction.action;
            if (target && [target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [target performSelector:action withObject:self];
#pragma clang diagnostic pop
            }
        }];
    });
}

- (void)triggerRequestFailureCallBack {
    gd_network_dispatch_async_main_queue_safety(^{
        if (self.failureCompletionBlock) {
            self.failureCompletionBlock(self);
        }
        if ([self.delegate respondsToSelector:@selector(requestFailed:)]) {
            [self.delegate requestFailed:self];
        }
        
        NSArray *failureTargetActionArray = self.failureTargetActionSet.allObjects;
        [failureTargetActionArray enumerateObjectsUsingBlock:
         ^(GDNetworkTargetAction * _Nonnull targetAction, NSUInteger idx, BOOL * _Nonnull stop) {
             id target = targetAction.target;
             SEL action = targetAction.action;
             if (target && [target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                 [target performSelector:action withObject:self];
#pragma clang diagnostic pop
             }
         }];
    });
}

- (void)changeRequestState:(GDRequestState)state{
    gd_network_dispatch_async_main_queue_safety(^{
        self.requestState = state;
    });
}

@end

