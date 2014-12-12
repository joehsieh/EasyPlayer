//
//  NJMusicFileFetcher.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJAudioFileFetcher.h"
@interface NJAudioFileFetcher()
@property (nonatomic, strong) NSURLSession *URLSession;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSOperationQueue *queue;
@end

@implementation NJAudioFileFetcher

- (instancetype)initWithDelegate:(id<NJAudioFileFetcherDelegate>)inDelegate
{
    self = [super init];
    if (self) {
        self.queue = [[NSOperationQueue alloc] init];
        self.URLSession = [NSURLSession sessionWithConfiguration: [NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];
        self.delegate = inDelegate;
        NSAssert(self.delegate, @"delegate must exist");
    }
    return self;
}

- (void)cancel
{
    [self.task cancel];
}

- (void)fetchMusicWithURL:(NSURL *)inURL
{
    self.task = [self.URLSession dataTaskWithURL:inURL];
    [self.task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (!error) {
        [self.delegate musicFileFetcherDidFetchAllData:self];
    }
    else {
        [self.delegate musicFileFetcher:self didFailedWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.delegate musicFileFetcher:self didReceiveData:data];
}

@end
