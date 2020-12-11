//
//  GDEncryptConfiguration.h
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GDEncryptConfiguration : NSObject

+ (instancetype)sharedConfiguration;

/// 密钥握手请求连接
@property (nonatomic, copy) NSString *handShakeURLString;
/// 密钥握手请求RSA请求公钥
@property (nonatomic, copy) NSString *handshakeRSAEncryptionKey;
/// 对应HTTPHeaderField的`x-crypt`，用于握手请求
@property (nonatomic, copy) NSString *handShakeXCrypt;
/// 设备的DK
@property (nonatomic, copy) NSString *deviceToken;
/// 对应HTTPHeaderField的`eid`
@property (nonatomic, copy) NSString *deviceID;
/// 对应HTTPHeaderField的`x-crypt`，用于全局加密请求
@property (nonatomic, copy) NSString *aesXCrypt;
/// 重新密钥握手的返回状态码
@property (nonatomic, copy) NSArray<NSNumber *> *refetchStatusCodes;
/// 加密接受的MIMEType，默认支持@"application/json", @"text/json", @"text/javascript"类型
@property (nonatomic, copy) NSSet<NSString *> *acceptableMIMETypes;

/// 当握手请求失败的时候是否进行明文传输
@property (nonatomic, assign) BOOL jsonTransmitWhileHandshakeFailed;

/**
 获取当前握手的密钥
 */
@property (nonatomic, copy, readonly) NSString *currentAESKey;

@end
