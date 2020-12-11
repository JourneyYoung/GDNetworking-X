//
//  GDNetworkHandShakeRequest.m
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDNetworkHandShakeRequest.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

#import "GDEncryptConfiguration.h"
#import "GDNewtworkLog.h"

#import <pthread.h>

NSString *GDNetworkEncryptionHandShakeFinishedNotification =
@"GDNetworkEncryptionHandShakeFinishedNotification";

@implementation GDNetworkEncryption

#pragma mark - RSA Encryption

+ (NSData *)rsaEncryptData:(NSData *)data publicKey:(NSString *)pubKey {
    if(!data || !pubKey){
        return nil;
    }
    SecKeyRef keyRef = [self rsaPublicKeyRefWithKeyString:pubKey];
    if(!keyRef){
        return nil;
    }
    return [self rsaEncryptData:data withKeyRef:keyRef];
}

+ (SecKeyRef)rsaPublicKeyRefWithKeyString:(NSString *)key{
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
    if(spos.location != NSNotFound && epos.location != NSNotFound){
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    // This will be base64 encoded, decode it.
    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];;
    data = [self rsaStripPublicKeyHeader:data];
    if(!data){
        return nil;
    }
    
    //a tag to read/write keychain storage
    NSString *tag = @"RSAUtil_PubKey";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil){
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }
    
    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if(status != noErr){
        return nil;
    }
    return keyRef;
}

+ (NSData *)rsaEncryptData:(NSData *)data withKeyRef:(SecKeyRef) keyRef{
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    void *outbuf = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for(int idx=0; idx<srclen; idx+=src_block_size){
        //NSLog(@"%d/%d block_size: %d", idx, (int)srclen, (int)block_size);
        size_t data_len = srclen - idx;
        if(data_len > src_block_size){
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        status = SecKeyEncrypt(keyRef,
                               kSecPaddingPKCS1,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0) {
            NSLog(@"SecKeyEncrypt fail. Error Code: %d", (int)status);
            ret = nil;
            break;
        }else{
            [ret appendBytes:outbuf length:outlen];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

+ (NSData *)rsaStripPublicKeyHeader:(NSData *)d_key {
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned long len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx     = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

#pragma mark - AES Encryption

+ (NSData *)dataEncryptAES:(NSData *)srcData withKey:(NSString *)key {
    //AES加密
    NSData *encodeData = [self aes128EncryptData:srcData key:key];
    //转base64
    NSData *encodeBase64Data = [encodeData base64EncodedDataWithOptions:0];
    
    return encodeBase64Data;
}

+ (NSData *)dataDecryptAES:(NSData *)encryptData withKey:(NSString *)key {
    if (!encryptData) {
        return nil;
    }
    NSData *originData = [[NSData alloc] initWithBase64EncodedData:encryptData options:0];
    //aes解密
    NSData *decodedData = [self aes128DecryptData:originData key:key];
    
    return decodedData;
}

+ (NSData *)aes128EncryptData:(NSData *)data key:(NSString *)key {
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

+ (NSData *)aes128DecryptData:(NSData *)data key:(NSString *)key {
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

@end

#pragma mark - GDNetworkHandShakeRequest

@interface GDNetworkHandShakeRequest() {
    NSString *_aesKey;
    NSString *_randomAES16BitKey;
    pthread_mutex_t _lock;
}

@end

@implementation GDNetworkHandShakeRequest

+ (instancetype)sharedHandShakeRequest {
    static GDNetworkHandShakeRequest *sharedHandShakeRequest = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHandShakeRequest = [[GDNetworkHandShakeRequest alloc] init];
    });
    return sharedHandShakeRequest;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (NSString *)retrieveGlobalAESKeyIfNeeded {
    /// 使用锁保证同一时刻只会发起一次请求
    pthread_mutex_lock(&_lock);
    /// 如果有全局加密密钥则直接返回密钥
    NSString *aesKey = _aesKey;
    if (aesKey) {
        pthread_mutex_unlock(&_lock);
        return aesKey;
    }
    
    /// 如果没有全局加密密钥则握手获取全局加密密钥
    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self retrieveGlobalAESKeyWithCompletionBlock:^{
        if (semaphore != NULL) {
            dispatch_semaphore_signal(semaphore);
        }
    }];
    
    if (semaphore != NULL) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    /// 重新获取AESKey
    NSString *newAesKey = _aesKey;
    pthread_mutex_unlock(&_lock);
    /// 解锁
    return newAesKey;
}

- (void)refetchGlobalAESKey {
    pthread_mutex_lock(&_lock);
    
    _aesKey = nil;
    
    /// 如果没有全局加密密钥则握手获取全局加密密钥
    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self retrieveGlobalAESKeyWithCompletionBlock:^{
        if (semaphore != NULL) {
            dispatch_semaphore_signal(semaphore);
        }
    }];
    
    if (semaphore != NULL) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    pthread_mutex_unlock(&_lock);
}

#pragma mark - Request

- (void)retrieveGlobalAESKeyWithCompletionBlock:(void (^)(void))completionBlock {
    /// 创建请求
    NSString *url = [GDEncryptConfiguration sharedConfiguration].handShakeURLString;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.f];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[GDEncryptConfiguration sharedConfiguration].deviceID forHTTPHeaderField:@"eid"];
    [request setValue:[GDEncryptConfiguration sharedConfiguration].handShakeXCrypt forHTTPHeaderField:@"x-crypt"];
    
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *timeStampString = [NSString stringWithFormat:@"%f", timeStamp * 1000];
    NSString *currentTimesTamp = [[timeStampString componentsSeparatedByString:@"."] firstObject];
    
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    [arguments setValue:currentTimesTamp forKey:@"ts"];
    [arguments setValue:[self randomAES16BitKey] forKey:@"appKey"];
    [arguments setValue:[GDEncryptConfiguration sharedConfiguration].deviceToken forKey:@"dk"];
    
    NSDictionary *argumentParamenter = arguments.copy;
    if ([NSJSONSerialization isValidJSONObject:argumentParamenter]) {
        NSData *argumentData = [NSJSONSerialization dataWithJSONObject:argumentParamenter.copy options:NSJSONWritingPrettyPrinted error:nil];
        NSData *HTTPBody = [GDNetworkEncryption rsaEncryptData:argumentData publicKey:[GDEncryptConfiguration sharedConfiguration].handshakeRSAEncryptionKey];
        HTTPBody = [HTTPBody base64EncodedDataWithOptions:0];
        [request setHTTPBody:HTTPBody];
    }
    
    /// 获取数据
    NSURLSession *defaultSession = [NSURLSession sharedSession];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionTask *sessionTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            !completionBlock ?: completionBlock();
            return;
        }
        
        strongSelf->_aesKey = nil;
        NSData *decryptData = [GDNetworkEncryption dataDecryptAES:data withKey:[strongSelf randomAES16BitKey]];
        strongSelf->_randomAES16BitKey = nil;
        
        if (decryptData) {
            NSError *error = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:decryptData
                                                                               options:NSJSONReadingMutableContainers
                                                                                 error:&error];
            NSString *key = [[responseDictionary valueForKey:@"data"] valueForKey:@"key"];
            if (key != nil && [key isKindOfClass:[NSString class]] && key.length > 0) {
                strongSelf->_aesKey = key;
            }
        }
        
        [GDNewtworkLog logWithFormat:@"握手请求完成，密钥为：%@", strongSelf->_aesKey];
        
        !completionBlock ?: completionBlock();
    }];
    [sessionTask resume];
}

#pragma mark - 生成随机数验签握手请求

- (NSString *)randomAES16BitKey {
    if (!_randomAES16BitKey) {
        _randomAES16BitKey = [self randomKeyByLength:16];
    }
    return _randomAES16BitKey;
}

- (NSString *)randomKeyByLength:(NSInteger)length {
    //ASCI码转换
    NSString *string = [[NSString alloc] init];
    for (int i = 0; i < length; i++) {
        int number = arc4random() % 36;
        if (number < 10) {
            int figure = arc4random() % 10;
            NSString *tempString = [NSString stringWithFormat:@"%d", figure];
            string = [string stringByAppendingString:tempString];
        }
        else {
            int figure = 0;
            if (arc4random() % 2 == 0) {
                figure = (arc4random() % 26) + 65;
            }
            else {
                figure = (arc4random() % 26) + 97;
            }
            char character = figure;
            NSString *tempString = [NSString stringWithFormat:@"%c", character];
            string = [string stringByAppendingString:tempString];
        }
    }
    return string;
}

@end
