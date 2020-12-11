//
//  GDNetworkEncryptionRequestSerializer.m
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDNetworkEncryptionRequestSerializer.h"
#import "GDNetworkHandShakeRequest.h"
#import "GDNetworkPrivate.h"
#import "GDEncryptConfiguration.h"
#import "GDNewtworkLog.h"

@implementation GDNetworkEncryptionRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing _Nullable *)error {
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:parameters error:error] mutableCopy];
    
    if (parameters) {
        BOOL jsonTransmitWhileHandShakeFailed = [GDEncryptConfiguration sharedConfiguration].jsonTransmitWhileHandshakeFailed;
        GDNetworkHandShakeRequest *handShakeRequest = [GDNetworkHandShakeRequest sharedHandShakeRequest];
        
        NSString *aesKey = [handShakeRequest retrieveGlobalAESKeyIfNeeded];
        if (aesKey.length > 0) {
            [mutableRequest setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
            [mutableRequest setValue:[GDEncryptConfiguration sharedConfiguration].deviceID forHTTPHeaderField:@"eid"];
            [mutableRequest setValue:[GDEncryptConfiguration sharedConfiguration].aesXCrypt forHTTPHeaderField:@"x-crypt"];
            
            NSData *HTTPBody = mutableRequest.HTTPBody;
            HTTPBody = [GDNetworkEncryption dataEncryptAES:HTTPBody withKey:aesKey];
            [mutableRequest setHTTPBody:HTTPBody];
        }
        else if(!jsonTransmitWhileHandShakeFailed) {
            [GDNetworkPrivate raiseErrorWithCode:GDNetworkEncryptionHandShakeFail
                                          exception:nil
                                            request:nil
                                              error:error];
        }
    }
    
    return mutableRequest.copy;
}


@end
