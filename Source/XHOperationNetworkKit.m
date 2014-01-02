//
//  XHOperationNetworkKit.m
//  XHOperationNetworkKit
//
//  Created by 曾 宪华 on 14-1-2.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507. All rights reserved.
//

#import "XHOperationNetworkKit.h"

@interface XHOperationNetworkKit () <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    NSURLConnection *_connection;
    NSMutableData *_responseData;
    NSURLResponse *_response;
    XHJSONSuccessHandler _jsonSuccessHandler;
    XHHTTPSuccessHandler _successHandler;
    XHHTTPFailureHandler _failureHandler;
    XHHTTPProgressHandler _progressHandler;
}

@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, readwrite, getter = isFinished) BOOL finished;

@end

@implementation XHOperationNetworkKit

#pragma mark - NSOperation Overrides

- (void)main
{
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    _connection = [[NSURLConnection alloc] initWithRequest:[self request] delegate:self startImmediately:NO];
    [_connection scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
    [_connection start];
    
    while (![self isFinished] && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
    {
        
    };
}

#pragma mark - Instance Methods

- (void)setProgressHandler:(XHHTTPProgressHandler)progressHandler {
    _progressHandler = [progressHandler copy];
}

- (void)setJSONSuccessHandler:(XHJSONSuccessHandler)jsonSuccessHandler {
    _jsonSuccessHandler = [jsonSuccessHandler copy];
}

- (void)setSuccessHandler:(XHHTTPSuccessHandler)successHandler
{
    _successHandler = [successHandler copy];
}

- (void)setFailureHandler:(XHHTTPFailureHandler)failureHandler
{
    _failureHandler = [failureHandler copy];
}

- (id)initWithRequest:(NSURLRequest *)request
   jsonSuccessHandler:(XHJSONSuccessHandler)jsonSuccessHandler
       failureHandler:(XHHTTPFailureHandler)failureHandle {
    self = [super init];
    if (self) {
        [self setRequest:request];
        [self setJSONSuccessHandler:jsonSuccessHandler];
        [self setFailureHandler:failureHandle];
    }
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request successHandler:(XHHTTPSuccessHandler)successHandler failureHandler:(XHHTTPFailureHandler)failureHandler
{
    self = [super init];
    if (self)
    {
        [self setRequest:request];
        [self setSuccessHandler:successHandler];
        [self setFailureHandler:failureHandler];
    }
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request
{
    return [self initWithRequest:request successHandler:nil failureHandler:nil];
}

#pragma mark - NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (_failureHandler)
    {
        _failureHandler(_responseData, _response, error);
    }
    [self setFinished:YES];
}

#pragma mark - NSURLConnectionDataDelegate Methods

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)_response;
    BOOL success = [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)] containsIndex:[response statusCode]];
    
    if ((success && _successHandler)) {
        _successHandler(_responseData, _response);
    } else if ((success && _jsonSuccessHandler)) {
        NSError *parseError;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:_responseData options:0 error:&parseError];
        _jsonSuccessHandler(JSON, _response);
    } else if (!success && _failureHandler) {
        _failureHandler(_responseData, _response, nil);
    }
    
    [self setFinished:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _responseData = [NSMutableData new];
    _response = response;
}

@end
