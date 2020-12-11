//
//  GDEncryptConfiguration.m
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDEncryptConfiguration.h"
#import "GDNetworkPrivate.h"
#import "GDNetworkHandShakeRequest.h"

@implementation GDEncryptConfiguration

+ (instancetype)sharedConfiguration {
    static GDEncryptConfiguration *configuration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        configuration = [[GDEncryptConfiguration alloc] init];
    });
    return configuration;
}

- (NSString *)currentAESKey {
    return [[GDNetworkHandShakeRequest sharedHandShakeRequest] retrieveGlobalAESKeyIfNeeded];
}

@end
