//
//  GDChainRequestManger.h
//  AFNetworking
//
//  Created by Journey on 2018/4/19.
//

#import <Foundation/Foundation.h>

@class GDChainRequest;

@interface GDChainRequestManger : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared chain request agent.
+ (GDChainRequestManger *)sharedAgent;

///  Add a chain request.
- (void)addChainRequest:(GDChainRequest *)request;

///  Remove a previously added chain request.
- (void)removeChainRequest:(GDChainRequest *)request;

@end
