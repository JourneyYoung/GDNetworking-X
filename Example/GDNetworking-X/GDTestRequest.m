//
//  GDTestRequest.m
//  GDNetworking-X_Example
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 journeyyoung. All rights reserved.
//

#import "GDTestRequest.h"

@implementation GDTestRequest


- (NSString *)baseUrl{
    return @"http://54.241.20.16:8080/";
}

-(NSString *)requestUrl{
    return @"usercenter/user/get/countrycode";
}

- (GDRequestSerializerType)requestSerializerType{
    return GDRequestSerializerTypeJSON;
}

- (GDResponseSerializerType)responseSerializerType{
    return GDResponseSerializerTypeJSON;
}

- (GDRequestType)requestType{
    return GDRequestTypeGET;
}

///
- (id)jsonValidator{
    return @{
             @"result" : @1
             };
}


@end
