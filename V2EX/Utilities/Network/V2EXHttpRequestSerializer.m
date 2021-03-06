//
//  V2EXHttpRequestSerializer.m
//  V2EX
//
//  Created by WildCat on 2/7/14.
//  Copyright (c) 2014 WildCat. All rights reserved.
//

#import "V2EXHttpRequestSerializer.h"

#define TIMEOUT 10

@implementation V2EXHttpRequestSerializer

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *request = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    [request setAllHTTPHeaderFields:headers];
    [request setTimeoutInterval:TIMEOUT];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    return request;
}

@end
