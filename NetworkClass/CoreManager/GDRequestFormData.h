//
//  GDRequestFormData.h
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GDRequestFormData : NSObject

/// 传入fileURL
@property (nonatomic, strong, nullable) NSURL *fileURL;
/// 传入文件输入流,优先级比fileURL高
@property (nonatomic, strong, nullable) NSInputStream *inputStream;
/// inputStream的长度
@property (nonatomic, assign) int64_t inputStreamLength;
/// 传入文件二进制数据,优先级比inputStream高
@property (nonatomic, strong, nullable) NSData *formData;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *fileName;
/// 文件类型，决定请求的`Content-Type`
@property (nonatomic, copy) NSString *mineType;

/// 根据Dictionary初始化GDFormData,Dictionary中的Key就是GDFormData中的Property
- (instancetype)initWithAttributes:(NSDictionary *)attribute;

@end


NS_ASSUME_NONNULL_END
