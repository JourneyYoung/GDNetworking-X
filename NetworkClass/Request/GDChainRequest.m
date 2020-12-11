//
//  GDChainRequest.m
//  AFNetworking
//
//  Created by Journey on 2018/4/19.
//

#import "GDChainRequest.h"
#import "GDBaseRequest.h"
#import "GDNetworkPrivate.h"
#import "GDChainRequestManger.h"

@interface GDChainRequest ()<GDBaseRequestDelegate>

@property (nonatomic, strong) NSMutableArray <GDBaseRequest *> *requestArray;

@property (nonatomic, strong) NSMutableArray <GDChainCallback> *requestCallBackArray;

@property (nonatomic, assign) NSInteger nextRequestIndex;

@property (nonatomic, strong) GDChainCallback emptyCallBack;

@end

@implementation GDChainRequest

- (instancetype)init{
    self = [super init];
    if(self){
        _nextRequestIndex = 0;
        _requestArray = [NSMutableArray array];
        _requestCallBackArray = [NSMutableArray array];
        _emptyCallBack = ^(GDChainRequest *chainRequest, GDBaseRequest *baseRequest){
            //do nothing
        };
    }
    return self;
}

- (void)start {
    if (_nextRequestIndex > 0) {
        return;
    }
    
    if ([_requestArray count] > 0) {
//        [self toggleAccessoriesWillStartCallBack];
        [self startNextRequest];
        [[GDChainRequestManger sharedAgent] addChainRequest:self];
    } else {
//        YTKLog(@"Error! Chain request array is empty.");
    }
}

- (void)stop {
//    [self toggleAccessoriesWillStopCallBack];
    [self clearRequest];
    [[GDChainRequestManger sharedAgent] removeChainRequest:self];
//    [self toggleAccessoriesDidStopCallBack];
}

- (void)addRequest:(GDBaseRequest *)request callback:(GDChainCallback)callback {
    [_requestArray addObject:request];
    if (callback != nil) {
        [_requestCallBackArray addObject:callback];
    } else {
        [_requestCallBackArray addObject:_emptyCallBack];
    }
}

- (NSArray<GDBaseRequest *> *)requestArray {
    return _requestArray;
}

- (BOOL)startNextRequest {
    if (_nextRequestIndex < [_requestArray count]) {
        GDBaseRequest *request = _requestArray[_nextRequestIndex];
        _nextRequestIndex++;
        request.delegate = self;
        [request clearCompletionBlock];
        [request start];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Network Request Delegate

-(void)requestSucced:(__kindof GDBaseRequest *)request {
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    GDChainCallback callback = _requestCallBackArray[currentRequestIndex];
    callback(self, request);
    if (![self startNextRequest]) {
        [request triggerRequestWillStopAccessoryCallBack];
        if ([_delegate respondsToSelector:@selector(chainRequestFinished:)]) {
            [_delegate chainRequestFinished:self];
            [[GDChainRequestManger sharedAgent] removeChainRequest:self];
        }
        [request triggerRequestDidStopAccessoryCallBack];
    }
}

-(void)requestFailed:(__kindof GDBaseRequest *)request{
    [request triggerRequestWillStopAccessoryCallBack];;
    if ([_delegate respondsToSelector:@selector(chainRequestFailed:failedBaseRequest:)]) {
        [_delegate chainRequestFailed:self failedBaseRequest:request];
        [[GDChainRequestManger sharedAgent] removeChainRequest:self];
    }
    [request triggerRequestDidStopAccessoryCallBack];
}

- (void)clearRequest {
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    if (currentRequestIndex < [_requestArray count]) {
        GDBaseRequest *request = _requestArray[currentRequestIndex];
        [request stop];
    }
    [_requestArray removeAllObjects];
    [_requestCallBackArray removeAllObjects];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<GDBaseRequestStateProtocol>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end
