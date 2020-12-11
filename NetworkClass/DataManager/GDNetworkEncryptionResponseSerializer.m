//
//  GDNetworkEncryptionResponseSerializer.m
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDNetworkEncryptionResponseSerializer.h"
#import "GDNetworkHandShakeRequest.h"
#import "GDNetworkPrivate.h"
#import "GDEncryptConfiguration.h"
#import "GDNewtworkLog.h"

@implementation GDNetworkEncryptionResponseSerializer

- (instancetype)init {
    self = [super init];
    if (self) {
        NSSet *acceptableMIMETypes = [GDEncryptConfiguration sharedConfiguration].acceptableMIMETypes;
        if (acceptableMIMETypes.count > 0) {
            self.acceptableContentTypes = acceptableMIMETypes;
        }
    }
    return self;
}

#pragma mark - AFURLResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing _Nullable *)error {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return [super responseObjectForResponse:response data:data error:error];
    }
    /// JSON
    BOOL jsonTransmitWhileHandShakeFailed = [GDEncryptConfiguration sharedConfiguration].jsonTransmitWhileHandshakeFailed;
    NSString *MIMEType = response.MIMEType;
    if (jsonTransmitWhileHandShakeFailed &&
        [MIMEType isEqualToString:@"application/json"]) {
        return [super responseObjectForResponse:response data:data error:error];
    }
    
    /// Encryption
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    GDNetworkHandShakeRequest *handShakeRequest = [GDNetworkHandShakeRequest sharedHandShakeRequest];
    
    /// 加密密钥失效的情况
    NSArray *refetchStatusCodes = [GDEncryptConfiguration sharedConfiguration].refetchStatusCodes;
    
    if ([refetchStatusCodes containsObject:@(httpResponse.statusCode)]) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkCacheExpired
                                      exception:nil
                                        request:nil
                                          error:error];
        
        [handShakeRequest refetchGlobalAESKey];
        
        return [super responseObjectForResponse:response data:data error:error];
    }
    
    /// 加密密钥未失效的情况
    NSString *aesKey = [handShakeRequest retrieveGlobalAESKeyIfNeeded];
    NSData *decryptData = [GDNetworkEncryption dataDecryptAES:data withKey:aesKey];
    
    if (decryptData.length == 0) {
        [GDNetworkPrivate raiseErrorWithCode:GDNetworkEncryptionHandShakeFail
                                      exception:nil
                                        request:nil
                                          error:error];
        
        [handShakeRequest refetchGlobalAESKey];
    }
    return [super responseObjectForResponse:response data:decryptData error:error];
}

@end
