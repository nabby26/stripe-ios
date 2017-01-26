//
//  STPSourcePoller.m
//  Stripe
//
//  Created by Ben Guo on 1/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient+Private.h"
#import "STPAPIRequest.h"
#import "STPSource.h"
#import "STPSourcePoller.h"

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const DefaultPollInterval = 1.5;
static NSTimeInterval const MaxPollInterval = 24;

@interface STPSourcePoller ()

@property (nonatomic, weak) STPAPIClient *apiClient;
@property (nonatomic) NSString *sourceID;
@property (nonatomic) NSString *clientSecret;
@property (nonatomic, copy) STPSourceCompletionBlock completion;
@property (nonatomic, nullable) STPSource *latestSource;
@property (nonatomic) NSTimeInterval pollInterval;
@property (nonatomic) BOOL shouldStopPolling;

@end

@implementation STPSourcePoller

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
                     clientSecret:(NSString *)clientSecret
                         sourceID:(NSString *)sourceID
                       completion:(STPSourceCompletionBlock)completion {
    self = [super init];
    if (self) {
        _apiClient = apiClient;
        _sourceID = sourceID;
        _clientSecret = clientSecret;
        _completion = completion;
        _pollInterval = DefaultPollInterval;
        _shouldStopPolling = NO;
        [self pollAfter:0];
    }
    return self;
}

- (void)pollAfter:(NSTimeInterval)interval {
    if (!self.apiClient) {
        [self stopPolling];
        return;
    }
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_after(time, queue, ^{
        [self.apiClient retrieveSourceWithId:self.sourceID
                                clientSecret:self.clientSecret
                          responseCompletion:^(STPSource *source, NSHTTPURLResponse *response, NSError *error) {
                              [self continueWithSource:source response:response error:error];
                          }];
    });
}

- (void)continueWithSource:(STPSource *)source
                  response:(NSHTTPURLResponse *)response
                     error:(NSError *)error {
    if (self.shouldStopPolling) {
        return;
    }
    NSUInteger status = response.statusCode;
    if (!response || (status >= 400 && status < 500)) {
        self.completion(nil, error);
    } else if (status == 200) {
        self.pollInterval = DefaultPollInterval;
        if (!self.latestSource || source.status != self.latestSource.status) {
            self.completion(source, nil);
        }
        self.latestSource = source;
        if ([self shouldContinuePollingSource:source]) {
            [self pollAfter:self.pollInterval];
        }
    } else {
        // Backoff on 500, otherwise reset poll interval
        if (status == 500) {
            self.pollInterval = MIN(self.pollInterval*2, MaxPollInterval);
        } else {
            self.pollInterval = DefaultPollInterval;
        }
        [self pollAfter:self.pollInterval];
    }
}

- (BOOL)shouldContinuePollingSource:(nullable STPSource *)source {
    if (!source) {
        return NO;
    }
    return source.status == STPSourceStatusPending;
}

- (void)stopPolling {
    self.shouldStopPolling = YES;
}

@end

NS_ASSUME_NONNULL_END
