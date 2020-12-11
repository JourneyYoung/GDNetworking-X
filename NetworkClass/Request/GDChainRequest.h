//
//  GDChainRequest.h
//  AFNetworking
//
//  Created by Journey on 2018/4/19.
//

#import <Foundation/Foundation.h>

@class GDChainRequest;
@class GDBaseRequest;

@protocol  GDBaseRequestStateProtocol;

@protocol GDChainRequestDelegate <NSObject>

@optional

///  Tell the delegate that the chain request has finished successfully.
///
///  @param chainRequest The corresponding chain request.
- (void)chainRequestFinished:(GDChainRequest *)chainRequest;

///  Tell the delegate that the chain request has failed.
///
///  @param chainRequest The corresponding chain request.
///  @param request      First failed request that causes the whole request to fail.
- (void)chainRequestFailed:(GDChainRequest *)chainRequest failedBaseRequest:(GDBaseRequest*)request;

@end

typedef void (^GDChainCallback)(GDChainRequest *chainRequest, GDBaseRequest *baseRequest);

@interface GDChainRequest : NSObject

- (NSArray <GDBaseRequest *> *)requestArray;

@property (nonatomic, weak, nullable) id<GDChainRequestDelegate> delegate;

@property (nonatomic, strong, nullable) NSMutableArray<id<GDBaseRequestStateProtocol>> *requestAccessories;

- (void)addAccessory:(id<GDBaseRequestStateProtocol>)accessory;

- (void)start;

- (void)stop;

- (void)addRequest:(GDBaseRequest *)request callback:(nullable GDChainCallback)callback;

@end
