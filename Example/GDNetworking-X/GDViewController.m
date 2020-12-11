//
//  GDViewController.m
//  GDNetworking-X
//
//  Created by journeyyoung on 04/18/2018.
//  Copyright (c) 2018 journeyyoung. All rights reserved.
//

#import "GDViewController.h"
#import "GDTestRequest.h"
@interface GDViewController ()<GDBaseRequestDelegate>

@end

@implementation GDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startTestRequest:(id)sender {
    GDTestRequest *request = [[GDTestRequest alloc]init];
    request.delegate = self;
    [request start];
}

- (void)requestSucced:(__kindof GDBaseRequest *)request{
    NSLog(@"%@",request.responseJSONObject);
}

- (void)requestFailed:(__kindof GDBaseRequest *)request {
    NSLog(@"%@",request.responseJSONObject);
}

@end
