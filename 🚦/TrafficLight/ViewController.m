//
//  ViewController.m
//  🚦
//
//  Created by Maxime Bokobza on 15/12/12.
//  Copyright (c) 2012 Maxime Bokobza. All rights reserved.
//

#import "ViewController.h"


@interface ViewController () <NSURLConnectionDelegate>

@end


@implementation ViewController

- (void)lightTapped:(NSUInteger)lightIndex state:(NSString *)state {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://xn--468h.ws/instructions"]];
    [request setHTTPMethod:@"POST"];
    NSString *body = [NSString stringWithFormat:@"instruction=%@_%@",
                      @[@"red", @"orange", @"green"][lightIndex],
                      state];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

@end
