//
//  GDChainRequestManger.m
//  AFNetworking
//
//  Created by Journey on 2018/4/19.
//

#import "GDChainRequestManger.h"
#import "GDChainRequest.h"

@interface GDChainRequestManger ()

@property (strong, nonatomic) NSMutableArray<GDChainRequest *> *requestArray;

@end

@implementation GDChainRequestManger

+ (GDChainRequestManger *)sharedAgent{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestArray = [NSMutableArray array];
    }
    return self;
}

- (void)addChainRequest:(GDChainRequest *)request{
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeChainRequest:(GDChainRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}


@end
