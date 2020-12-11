//
//  GDNetworkHandShakeRequest.h
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GDNetworkEncryption : NSObject

/// RSA加密
+ (NSData *)rsaEncryptData:(NSData *)data publicKey:(NSString *)pubKey;

/// AES128加密
+ (NSData *)dataEncryptAES:(NSData *)srcData withKey:(NSString *)key;

/// AES128解密
+ (NSData *)dataDecryptAES:(NSData *)encryptData withKey:(NSString *)key;

@end

#pragma mark - GDNetworkHandShakeRequest

@interface GDNetworkHandShakeRequest : NSObject

+ (instancetype)sharedHandShakeRequest;

- (NSString *)retrieveGlobalAESKeyIfNeeded;

- (void)refetchGlobalAESKey;

@end
