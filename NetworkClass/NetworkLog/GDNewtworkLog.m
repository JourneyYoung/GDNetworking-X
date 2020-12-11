//
//  GDNewtworkLog.m
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDNewtworkLog.h"

static NSString *logFileName = @"GDNetworkingLogger";

@interface  GDNewtworkLog ()

@property (nonatomic, assign) BOOL logEnable;

@end

@implementation GDNewtworkLog

+ (instancetype)sharedLog {
    static GDNewtworkLog *sharedLog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLog = [[GDNewtworkLog alloc] init];
        [sharedLog creatLogFile];
        sharedLog.logEnable = YES;
    });
    return sharedLog;
}


/**
 0723更新待更新，写入本地文件
 */
- (void)creatLogFile{
    
}

+ (void)setLogEnable:(BOOL)enable {
    [GDNewtworkLog sharedLog].logEnable = enable;
}

+ (void)logWithFormat:(NSString *)format, ... {
    BOOL logEnable = [GDNewtworkLog sharedLog].logEnable;
    if (logEnable) {
        va_list argptr;
        va_start(argptr, format);
        NSString *logString = [[NSString alloc] initWithFormat:[format description] arguments:argptr];
        printf("[GDNetworkLog %s] %s\n",[[[NSDate date] description] UTF8String],[logString UTF8String]);
        va_end(argptr);
    }
}

@end
