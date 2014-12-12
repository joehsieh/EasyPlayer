//
//  NJMusicFileFetcher.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NJAudioFileFetcher;

@protocol NJAudioFileFetcherDelegate <NSObject>

- (void)musicFileFetcher:(NJAudioFileFetcher *)inFetcher didReceiveData:(NSData *)inData;
- (void)musicFileFetcher:(NJAudioFileFetcher *)inFetcher didFailedWithError:(NSError *)inError;
- (void)musicFileFetcherDidFetchAllData:(NJAudioFileFetcher *)inFetcher;

@end
@interface NJAudioFileFetcher : NSObject <NSURLSessionDataDelegate>
@property (weak, nonatomic) id<NJAudioFileFetcherDelegate> delegate;
- (instancetype)initWithDelegate:(id<NJAudioFileFetcherDelegate>)inDelegate;
- (void)fetchMusicWithURL:(NSURL *)inURL;
@end
