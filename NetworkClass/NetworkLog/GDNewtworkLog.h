//
//  GDNewtworkLog.h
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GDNewtworkLog : NSObject

/**
 设置是否打印日志
 
 @param enable 是否打印日志，如果为YES，[GDNetworkLog logWithFormat:]才会打印信息
 */
+ (void)setLogEnable:(BOOL)enable;

/**
 打印日志
 
 @param format 日志格式
 */
+ (void)logWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

@end
