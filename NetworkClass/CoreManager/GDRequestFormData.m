//
//  GDRequestFormData.m
//  GDNetwork
//
//  Created by Journey on 2018/4/18.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import "GDRequestFormData.h"

@implementation GDRequestFormData

- (instancetype)initWithAttributes:(NSDictionary *)attribute {
    self = [super init];
    if (self) {
        _fileURL = [attribute objectForKey:@"fileURL"];
        _inputStream = [attribute objectForKey:@"inputStream"];
        _inputStreamLength = [[attribute objectForKey:@"inputStreamLength"] longLongValue];
        _formData = [attribute objectForKey:@"formData"];
        
        _name = [attribute objectForKey:@"name"];
        _fileName = [attribute objectForKey:@"fileName"];
        _mineType = [attribute objectForKey:@"mineType"];
    }
    return self;
}


@end
