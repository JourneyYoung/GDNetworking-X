//
//  GDNetEnvironmentConfigureManager.m
//  GDNetwork
//
//  Created by Journey on 2018/3/13.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDNetEnvironmentConfigureManager.h"
#import "GDBaseRequest.h"
#import "AFSecurityPolicy.h"


@implementation GDNetEnvironmentConfigureManager

+ (instancetype)defaultConfiguration{
    GDNetEnvironmentConfigureManager *config = [[GDNetEnvironmentConfigureManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    return config;
}

+ (instancetype)networkConfigurationWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration{
    GDNetEnvironmentConfigureManager *configuration = [[GDNetEnvironmentConfigureManager alloc] initWithSessionConfiguration:sessionConfiguration];
    return configuration;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration{
    self = [super init];
    if(self){
        _baseUrl = nil;
        _cdnUrl = nil;
        _insUrl = nil;
        _instaUrl = nil;
        _commonParams = nil;
        _downloadDirectory = [NSURL fileURLWithPath:[self getDefaultDownloadDirectory] isDirectory:YES];
        _downloadResumeDirectory = [NSURL fileURLWithPath:[self getDownloadResumeDirectory] isDirectory:YES];
        _cacheDirectory = [NSURL fileURLWithPath:[self getDefaultCachedDirectory] isDirectory:YES];
        _securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        _completionGroup = NULL;
        _sessionConfiguration = sessionConfiguration;
        
        NSString *addressIdentifier = [NSString stringWithFormat:@"%p",self];
        addressIdentifier = [addressIdentifier stringByReplacingOccurrencesOfString:@"0x" withString:@""];
        NSString *requestQueueIdentifier = [NSString stringWithFormat:@"me.dingtone.network.requestConcurrentQueue.%@",addressIdentifier];
        NSString *responseQueueIdentifier = [NSString stringWithFormat:@"me.dingtone.network.responseConcurrentQueue.%@",addressIdentifier];
        
        _requestQueue = dispatch_queue_create([requestQueueIdentifier UTF8String], DISPATCH_QUEUE_CONCURRENT);
        _completionQueue = dispatch_queue_create([responseQueueIdentifier UTF8String], DISPATCH_QUEUE_CONCURRENT);
        _requestAccessories = [NSMutableSet<id<GDBaseRequestStateProtocol>> setWithCapacity:1];
    }
    return self;
}

- (NSString *)getDefaultDownloadDirectory{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *downloadDirectory = [NSString stringWithFormat:@"%@/GDNetwork/DownloadDirectory", documentDirectory];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:downloadDirectory])
    {
        NSError *error = nil;
        [manager createDirectoryAtPath:downloadDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    }
    return downloadDirectory;
}

- (NSString *)getDownloadResumeDirectory {
    NSString *downloadDirectory = _downloadDirectory.path;
    NSString *downloadResumeDirectory = [NSString stringWithFormat:@"%@/resume", downloadDirectory];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:downloadResumeDirectory])
    {
        NSError *error = nil;
        [manager createDirectoryAtPath:downloadResumeDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    }
    return downloadResumeDirectory;
}

- (NSString *)getDefaultCachedDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *cachedDirectory = [NSString stringWithFormat:@"%@/GDNetwork/CachedDirectory", documentDirectory];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:cachedDirectory])
    {
        NSError *error = nil;
        [manager createDirectoryAtPath:cachedDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    }
    return cachedDirectory;
}

- (NSMutableSet<id<GDBaseRequestStateProtocol>> *)requestAccessories{
    @synchronized (_requestAccessories) {
        return _requestAccessories;
    }
}

- (void)addReuestAccessory:(id<GDBaseRequestStateProtocol>)requestAccessory{
    @synchronized (_requestAccessories){
        [_requestAccessories addObject:requestAccessory];
    }
}

#pragma mark - 全局代理状态

static NSMutableSet<id<GDBaseRequestStateProtocol>> *gd_network_globalRequestAccessories = nil;
static NSString *kGDNetworkGlobalAccessoryIdentifier = @"kGDNetworkGlobalAccessoryIdentifier";

+ (NSMutableSet<id<GDBaseRequestStateProtocol>> *)globalRequestAccessories{
    @synchronized (kGDNetworkGlobalAccessoryIdentifier){
        return gd_network_globalRequestAccessories;
    }
}

+ (void)setGlobalRequestAccessories:(NSMutableSet<id<GDBaseRequestStateProtocol>> *)globalRequestAccessories{
    @synchronized (kGDNetworkGlobalAccessoryIdentifier) {
        gd_network_globalRequestAccessories = globalRequestAccessories;
    }
}

+ (void)addGlobalReuestAccessory:(id<GDBaseRequestStateProtocol>)globalRequestAccessories{
    @synchronized (kGDNetworkGlobalAccessoryIdentifier) {
        if(!gd_network_globalRequestAccessories){
            gd_network_globalRequestAccessories = [[NSMutableSet<id<GDBaseRequestStateProtocol>> alloc] initWithCapacity:1];
        }
        [gd_network_globalRequestAccessories addObject:globalRequestAccessories];
    }
}

@end
